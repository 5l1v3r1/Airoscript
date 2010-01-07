#!/bin/bash
# Unstable functions file for airoscript.
# Requires: wlandecrypter 

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


doitwld(){
	$WLD $Host_MAC $Host_SSID $DUMP_PATH/wlddic 
	$AIRCRACKOLD $FORCEWEPKOREK -b $Host_MAC -w $DUMP_PATH/wlddic $DUMP_PATH/$Host_MAC-01.cap
}

doitjt(){
	$JTD $Host_MAC $Host_SSID $DUMP_PATH/jtddic
	$AIRCRACKOLD $FORCEWEPKOREK -b $Host_MAC -w $DUMP_PATH/jtddic $DUMP_PATH/$Host_MAC-01.cap
}

wld(){
    if [ "$Host_MAC" == "" ]; then clear; echo -e "gettext `'Error: You must select a client before performing this attack'`\n"; fi
    if [[ "$Host_MAC" =~ "WLAN(.*)" ]]; then
        if [ -e $DUMP_PATH/$Host_MAC-01.cap ]; then doitjtd
        else echo "`gettext 'No capture file. Capture some ivs'`"; fi
    fi
}
jtd(){
    if [ "$Host_MAC" == "" ]; then clear; echo -e "gettext `'Error: You must select a client before performing this attack'`\n"; fi
    if [[ "$Host_MAC" =~ "JAZZTEL(.*)" ]]; then
        if [ -e $DUMP_PATH/$Host_MAC-01.cap ]; then doitjtd
        else echo "`gettext 'No capture file. Capture some ivs'`"; fi
    fi
}

auto(){
    $AIROSCWORDLIST --filename $DUMP_PATH/$Host_MAC.dic -cf $CMPFILE -e $Host_SSID -m $Host_MAC;
    if [ $? =! "404" ]; then $AIRCRACK -b $Host_MAC -w $DUMP_PATH/$Host_MAC.dic $DUMP_PATH/$Host_MAC-01.cap; fi
        if [ $? == "404" ]; then crack; fi
}
