#!/bin/bash
watch -n 10 "cat /sys/class/power_supply/BAT0/uevent|grep ENERGY"
