#!/bin/bash
set -x
apt-get remove pigpio
rm /usr/bin/gpio-watch
rm -rf /etc/gpio-scripts/17
rm -rf /etc/sym-keymap
rm -rf /usr/sbin/sym-keymap.sh
systemctl stop sym-keymap.service
systemctl stop sym-keymap-pigpiod.service
systemctl stop sym-keymap-singler.service
systemctl disable sym-keymap.service
systemctl disable sym-keymap-pigpiod.service
systemctl disable sym-keymap-singler.service
rm -f /etc/systemd/system/sym-keymap.service
rm -f /etc/systemd/system/sym-keymap-pigpiod.service
rm -f /etc/systemd/system/sym-keymap-singler.service
