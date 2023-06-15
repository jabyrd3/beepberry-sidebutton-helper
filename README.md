# Beepberry keyboard helper script
![looks like this](https://github.com/jabyrd3/beepberry-sidebutton-helper/blob/main/keymap.png?raw=true)
## Overview
Beepberry is very nice! The blackberry keyboard is a delight. As a TUI oriented device, though, there are lots of characters that someone will need to type and they aren't printed on the keyboard (these are mostly accessible using the right SYM key as a modifier). This script listens on pin 17 for presses of the programmable button on the right-side of the device to overlay an ascii keymap on top of any active tmux sessions to help you find the right key for ampersand or tilde or whatever. update: double click the side button to see some gomuks help

## Install
if you're feeling dangerous:

```
curl -s https://raw.githubusercontent.com/jabyrd3/beepberry-sidebutton-helper/main/install-sym-keymap.sh | sudo bash
```
Otherwise, run the install-sym-keymap.sh as sudo after you've read it :P. 

## Uninstall
Run the uninstall script in this repo as sudo, that should clean everything up. NOTE: if anything else you've built/installed relies on gpio-watch or pigpiod this will break them. User beware. Read the script to understand what it is doing before running it, if you've done anything with GPIO that isn't stock/standard.

## FAQS
q: is this good? did you do this well?

a: not originally, but then a8ksh4 from the discord gave me a handy bit of python and its lighter now :D.

q: does this work? are you using it?

a: yes and yes. works great for me. ymmv.

q: its not working for me, how can i fix it?

a: first, this will only ever work if you are in a tmux session. if you are and its still not working: look at `systemctl status sym-keymap.service` to see if something is breaking with the python script, or the 17 script it calls. I'll try to keep up with feedback / issues but you'll probably have better luck taking questions to the discord.

q: some of the keys on here are inaccurate

a: yep, i pulled the map from a repo for a slightly different driver than what beepberry is using atm, i think? feel free to open PRs with corrections if you find them. mostly the map is accurate though.

## Ideas
- [ ] switch combo to lock keyboard
- [ ] switch combo to invert / uninvert display
