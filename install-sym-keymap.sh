#!/bin/bash
set -ex
cd ~
apt-get -yyq install pigpio tmux
git clone https://github.com/larsks/gpio-watch.git
cd gpio-watch
make
make install
cd ..
rm -rf gpio-watch
mkdir -p /etc/gpio-scripts
mkdir -p /etc/sym-keymap
chmod 777 /etc/sym-keymap
cat << 'EOF' >/etc/gpio-scripts/17
#!/bin/bash
set -ex
user=$(ls /home)
tmux_sessions=$(su $user -c "tmux ls -F '#{session_id}'")

if [[ -f /etc/sym-keymap/keymap-shown ]]; then
        for session in $tmux_sessions
        do
		session=$session
		echo "suing user $user to close overlay"
                su $user -c "tmux send-keys -t '$session' Escape"
        done
        rm /etc/sym-keymap/keymap-shown
else
        touch /etc/sym-keymap/keymap-shown
        for session in $tmux_sessions
        do
		echo "suing user $user to open overay for session $session"
                su $user -c "tmux run-shell -t '$session' 'cat /etc/sym-keymap/keyboard'"
        done
fi;
EOF
sudo chmod +x /etc/gpio-scripts/17
sudo chmod 777 /etc/gpio-scripts/17

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
cat <<-'EOF' >/etc/systemd/system/sym-keymap-pigpiod.service
[Unit]
Description=runs pigpiod
After=local-fs.target

[Service]
ExecStart=pigpiod -g

[Install]
WantedBy=multi-user.target
EOF

# place onshot service to set pin 17 to 1 so gpio-watch catches changes
cat <<-'EOF' >/etc/systemd/system/sym-keymap-singler.service
[Unit]
Description=runs pigpiod
After=sym-keymap.service

[Service]
ExecStart=pigs w 17 1

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now sym-keymap-pigpiod.service
systemctl enable --now sym-keymap.service
systemctl enable --now sym-keymap-singler.service

echo "!! it worked. you should be able to press the button on the side and see a map of the hidden sym keyboard layer. this configuration should survive a restart. if it doesn't work, or stops working, you should try to bug @salsadrinker on the discord, but i'm not making any promises about support. have fun, i hope this works for you!"
