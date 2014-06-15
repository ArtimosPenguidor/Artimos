#!/bin/bash
interface=(`route -n | grep 'UG[ \t]' | awk '{print $8}'`)
gatemac=(`iwconfig $interface | grep -w $interface -A1 | awk '{print $6}'`)
frequency=(`iwconfig $interface  | grep Frequency | awk -F' ' '{ print $2 }' | cut -d ":" -f2 `)
frequencyWithoutDot=(`echo $frequency | sed -e 's/\.//g'`)
rm -f airodumpInfo-01.csv
airodump-ng --bssid $gatemac -C $frequencyWithoutDot -w airodumpInfo --output-format csv mon0 > /dev/null 2>&1 &

