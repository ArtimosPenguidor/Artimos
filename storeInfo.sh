#!/bin/bash
gateway=`route -n | grep 'UG[ \t]' | awk '{print $2}'`
while true; do
	nmap -sP $gateway/24 | tr -d '()' | grep -vw "Host\|Starting\|done" > tempInfo.txt
	cat tempInfo.txt > info.txt
done
