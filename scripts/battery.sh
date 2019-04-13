#!/bin/bash
watch -n 10 "cat /sys/class/power_supply/BAT1/uevent|grep ENERGY"
