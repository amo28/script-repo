#!/bin/bash
# Pi Integration Script
# Version 1.0
# This script is intended to provision a fresh raspberry pi 3 image for production use with an app called Screenly.
# By Matthew Amalino

#Create bold and normal variables for using bolded text.
bold=$(tput bold)
normal=$(tput sgr0)

#Create jumpto function. Works similar to GOTO.
function jumpto
{
    label=$1
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}
start=${1:-"start"}
jumpto $start

: start:
clear
echo 
echo ${bold}Raspberry Pi Integration Script${normal}
echo 
echo This script will guide you through the process of integrating an imaged Raspberry Pi 3 for Screenly.
echo You can modify the hostname, IP stack, date and time, display rotation, or issue a reboot.
echo 

title="${bold}Choose your selection:${normal}"
prompt="Option:"
options=("Change Hostname" "Modify IP Stack" "Enable DHCP" "Update date and time" "Rotate Display" "Reboot" "Quit")

echo "$title"
PS3="$prompt "
select opt in "${options[@]}"; do 

    case "$REPLY" in

    1 ) echo "You picked ${bold}$opt${normal}"; jumpto option1;;
    2 ) echo "You picked ${bold}$opt${normal}"; jumpto option2;;
    3 ) echo "You picked ${bold}$opt${normal}"; jumpto option3;;
    4 ) echo "You picked ${bold}$opt${normal}"; jumpto option4auto;;
    5 ) echo "You picked ${bold}$opt${normal}"; jumpto option5;;
    6 ) echo "You picked ${bold}$opt${normal}"; jumpto reboot;;

    7 ) echo "Goodbye!"; jumpto exit;;
    * ) echo "Invalid option. Try another one.";continue;;

    esac
    break

done
echo 
: option1:
clear
echo "Current hostname is:"
sudo raspi-config nonint get_hostname
echo 
echo 
sleep .5
echo "Enter desired hostname:"
echo 
read newname
echo 
echo Updating raspi-config with hostname $newname
sudo raspi-config nonint do_hostname $newname
echo 
echo Done! Returning to main menu. Reboot for changes to take effect.
sleep 2
jumpto $start

: option2:
clear
echo 
read -n1 -p "Are you (a)dding a static IP or (m)odifying an existing static profile? [a,m,x]" staticresp
echo 
case $staticresp in
	a) echo "Adding a new static profile. OK."; sleep 1; jumpto option2add;;
	m) echo "Modifying a profile. OK."; sleep 1; jumpto option2modify;;
	x) echo "Returning to Main Menu."; sleep 1; jumpto $start;;
	*) echo "Enter a, m, or x(exit) only.";;
esac

: option2add:
echo 
echo This function will create a new network profile named static-eth0. 
echo This is intended for a fresh image only. 
echo If you already have a static profile, this function will not work.
echo Either modify your existing connection, or have it deleted by Enabling DHCP.
echo 
sleep 1
echo "Enter new IP address."
read newip
echo "Enter subnet mask prefix."
echo "Example -- Enter 24 for a 255.255.255.0 subnet."
echo "Example -- Enter 26 for a 255.255.255.192 subnet."
echo "Look up the correct prefix at http://www.subnet-calculator.com/"
read subnetpfx
echo "Enter gateway."
read newgateway
echo "Enter DNS1."
read dns1
echo "Enter DNS2."
read dns2
echo 
sudo nmcli con add con-name "static-eth0" ifname eth0 type ethernet ip4 $newip/$subnetpfx gw4 $newgateway
sudo nmcli con mod "static-eth0" ipv4.dns "$dns1,$dns2"
sudo nmcli con mod "dhcp-eth0" connection.interface-name -
echo 
echo Profile "static-eth0" now configured. Confirm output is correct below.
sudo nmcli con show "static-eth0"|grep ipv4
echo 
read -p "Press [Enter] to return to the Main Menu. Reboot for changes to take effect."
jumpto $start

: option2modify:
echo 
echo This function will modify an existing "static-eth0" connection.
sleep .5
echo The existing profile configuration is below:
echo 
nmcli con show "static-eth0"|grep ipv4
read -p "Press [Enter] to continue modifying this connection."
echo 
echo "Enter new IP address."
read modip
echo "Enter new subnet mask prefix."
echo "Example -- Enter 24 for a 255.255.255.0 subnet."
echo "Example -- Enter 26 for a 255.255.255.192 subnet."
echo "Look up the correct prefix at http://www.subnet-calculator.com/"
read modsubnetpfx
echo "Enter gateway."
read modgateway
echo "Enter DNS1."
read moddns1
echo "Enter DNS2."
read moddns2
echo "Applying config now. Changing IP to $modip/$modsubnetpfx. Changing gateway to $modgateway."
echo "Setting DNS to $moddns1 and $moddns2."
sudo nmcli con mod "static-eth0" ipv4.addresses "$modip/$modsubnetpfx $modgateway"
sudo nmcli con mod "static-eth0" ipv4.dns "$moddns1,$moddns2"
echo 
echo Reconfiguration is complete.
echo Review the below output to confirm.
sleep .5
nmcli con show "static-eth0"|grep ipv4
echo 
sleep 2
read -p "Press [Enter] to return to Main Menu. Reboot for changes to take effect."
jumpto $start

: option3:
echo 
echo "This function will disable and delete an existing 'static-eth0' profile, then enable DHCP."
echo "It will attempt to activate the DHCP NIC immediately, but a reboot may be required to get a lease."
echo 
sleep 2
sudo nmcli con mod "static-eth0" connection.interface-name -
sudo nmcli con mod "dhcp-eth0" connection.interface-name eth0
echo 
echo "Connection is configured."
echo 
sleep 1
echo "The DHCP profile will be enabled and the static profile will be deleted."
echo "This means you will lose your current SSH session under this IP. The session will appear to freeze."
echo "Close this SSH session and reconnect with the DHCP address that is leased."
sudo nmcli con up "dhcp-eth0" && sudo nmcli con delete "static-eth0"
#echo "Please wait for IP lease..."
#sleep 5
#nmcli con show "dhcp-eth0"|grep ipv4.method
#nmcli con show "dhcp-eth0"|grep IP4.ADDRESS
#echo "Now deleting static-eth0 profile. Connection will close."
#sleep 3
logout

: option4auto:
clear
echo "Current date is:"
date
echo 
sleep .5
echo 
echo "Trying to update via NTP.org first. Please wait..."
sudo htpdate -t -s 0.pool.ntp.org
echo 
echo "New date and time is:"
date
echo 
echo 
read -n1 -p "Did it work? Is the time correct? [y,n]" dateresp
echo 
case $dateresp in
	y|Y) echo "Great! Returning to main menu."; sleep 1; jumpto $start;;
	n|N) echo "Okay. Enter date manually."; sleep .5; jumpto option4manual;;
	*) echo "Enter y or n.";;
esac

: option4manual:
echo "Enter year"
read year
echo "Enter month in two digits (ex. February is 02)"
read month
echo "Enter day in two digits"
read day
sudo date +%Y%m%d -s "$year$month$day"
echo 
echo "Enter time in military time. (ex. 5:35PM should be entered as 17:35:00)"
read usertime
sudo date +%T -s "$usertime"
echo 
echo "New date and time is:"
date
read -p "Press [Enter] to return to the Main Menu."
jumpto $start

: option5:
clear
echo 
echo This function will rotate the screen for a vertically mounted display.
read -n1 -p "Are you sure you want to continue? This can't be reversed. [y,n]" rotateresp
echo 
echo 
case $rotateresp in
	y|Y) echo "OK. Rotating now."; sleep 1;;
	n|N) echo "Returning to Main Menu."; sleep 1; jumpto $start;;
	*) echo "Enter y or n.";;
esac
sudo sh -c "echo display_rotate=3 >> /boot/config.txt"
echo 
echo ${bold}Confirm the output below now contains the line "display_rotate=3".${normal}
echo Reboot for changes to take effect.
echo 
sleep .5
tail -n 5 /boot/config.txt
read -p "Press [Enter] to return to Main Menu."
jumpto $start

: reboot:
echo 
echo Rebooting now.
sleep 1
sudo reboot now



: exit:
exit
