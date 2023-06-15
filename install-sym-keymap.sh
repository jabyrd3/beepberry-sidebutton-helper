#!/bin/bash
set -ex
cd ~
mkdir -p /etc/sym-keymap
chmod 777 /etc/sym-keymap
cat << 'EOF' >/etc/sym-keymap/17
#!/bin/bash
set -ex
tmux_sessions=$(tmux ls -F '#{session_id}')

if [[ -f /etc/sym-keymap/keymap-shown ]]; then
        for session in $tmux_sessions
        do
		session=$session
                tmux send-keys -t $session Escape
        done
        rm -f /etc/sym-keymap/keymap-shown
else
        touch /etc/sym-keymap/keymap-shown
        for session in $tmux_sessions
        do
                tmux run-shell -t $session "cat /etc/sym-keymap/$1"
        done
fi;
EOF
sudo chmod +x /etc/sym-keymap/17
sudo chmod 777 /etc/sym-keymap/17

# place keymaps
cat <<-'EOF' >/etc/sym-keymap/keyboard
┌────────┬────────┐       ┌──────┬──────┐
│  ctrl  │  pdown │       │ pgup │pw/esc│
├───┬───┬┴──┬───┬─┴─┬───┬─┴─┬───┬┴──┬───┤
│   │   │ pd│ pu│ \ │ ↑ │ ^ │ = │ { │ } │
├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┴───────┐
│ ? │   │ [ │ ] │ ← │ hm│ → │ v+│ v-│esc/bk/del │
├───┼───┼───┼───┼───┼───┼───┼───┼───┼─────┬─────┘
│alt│ k+│ k-│ • │ < │ ↓ │ > │mnu│ vx│ ent │
├───┴─┬─┴───┴┬──┴───┴───┴───┴───┴──┬┴─────┤
│shift│0/~/kx│ tab/space/&  │ sym  │rshift│
└─────┴──────┴──────────────┴──────┴──────┘
EOF
sudo chmod 777 /etc/sym-keymap/keyboard
cat <<-'EOF' >/etc/sym-keymap/watcher.py
#!/usr/bin/env python3
# a8ksh4

import RPi.GPIO as GPIO
import time
import sys
import subprocess
import os

PIN = 17
TAP_TIME = 0.5
user = os.listdir('/home')[0]
# Tap time is the maximum interval between button presses
# to increment the tap counter.  
#
# If button is relased longer than tap time and:
#     tap count is 1, we have a hold action,
#     tap count is >=2, we have a tap action.


##################################################
# Define functions here to performe actions
# Could just be a system call to run something
##################################################
def hold_message(seconds):
    print(f"Button held for {seconds} seconds")

def tap_message(taps):
    # print(f"Button tapped {taps} time(s)")
    if taps == 1:
        subprocess.check_call("su %s -c '/etc/sym-keymap/17 keyboard'" % user, shell=True)
    elif taps == 2:
        subprocess.check_call("su %s -c '/etc/sym-keymap/17 gomuks'" % user, shell=True)
##################################################
# Define actions here for hold times and tap counts
##################################################
hold_actions = { # holds are a minimum of 1 second, less than 1s is a tap
    1: hold_message,
    2: hold_message,
    3: hold_message,
}
tap_actions = {
    1: tap_message,
    2: tap_message,
    3: tap_message
}

def action_caller(name, number):
    if name == 'tap':
        if number in tap_actions:
            tap_actions[number](number)
    elif name == 'hold':
        if number in hold_actions:
            hold_actions[number](number)


if __name__ == '__main__':
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    press_time = None
    release_time = None
    tap_count = 0

    while True:
        pressed = not GPIO.input(PIN)

        if pressed:
            if press_time is None:
                # new press
                press_time = time.time()

        else: # released
            if press_time is not None:
                # just relased
                seconds_held = int(time.time() - press_time)
                press_time = None
                release_time = time.time()
                tap_count += 1

            elif release_time is not None:
                # still released
                time_released = time.time() - release_time
                seconds_released = int(time_released)

                if time_released > TAP_TIME:
                    # an event has happened!
                    if seconds_held == 0 and tap_count == 1:
                        # single tap
                        action_caller('tap', tap_count)
                    
                    elif seconds_held > 0 and tap_count == 1:
                        # hold
                        action_caller('hold', seconds_held)
                    
                    else:
                        # multiple taps
                        action_caller('tap', tap_count)

                    # reset
                    release_time = None
                    tap_count = 0
        time.sleep(0.1)
EOF
# place gomuks
cat <<-'EOF' >/etc/sym-keymap/gomuks
# gomuks 
  - /toggle rooms /toggle users to hide
  - use touchpad to nav up / down rooms
  - chat fuzzypicker: call + k, type part
    of a room's name, then call + space
    to nav and enter to go to room
  - plaintext mode: call + l (readonly)
  - ↑ (alt + y) and ↓ (alt+b) can be used to edit
  - after using commands that require selecting
    messages (e.g. /reply and /redact), you can
    move the selection with ↑ and ↓ confirm
    with Enter.

EOF
sudo chmod 777 /etc/sym-keymap/keyboard

# place systemctl watcher service
cat <<-'EOF' >/etc/systemd/system/sym-keymap.service
[Unit]
Description=runs gpio-watch to look for the programmable button being depressed. gpio-watch will then call /etc/gpio-scripts/17, shows or hides the sym keyboard layer key map for every tmux session.
Requires=sym-keymap-pigpiod.service
After=sym-keymap-pigpiod.service

[Service]
ExecStart=gpio-watch -e switch 17

[Install]
WantedBy=multi-user.target
EOF

# place systemctl pigpiod service
cat <<-'EOF' >/etc/systemd/system/sym-keymap.service
[Unit]
Description=runs a pythons script that polls pin 17 to fire events on hold/press 
After=local-fs.target

[Service]
ExecStart=python /etc/sym-keymap/watcher.py

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now sym-keymap.service

echo "!! it worked. you should be able to press the button on the side and see a map of the hidden sym keyboard layer. this configuration should survive a restart."
