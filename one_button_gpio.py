#!/usr/bin/env python3      

import RPi.GPIO as GPIO
import time
import sys

PIN = 17
TAP_TIME = 0.5

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
    print(f"Button tapped {taps} time(s)")

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
        