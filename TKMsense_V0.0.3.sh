#!/bin/sh

#TKMsense_V0.0.3
#Author Tyler K Monroe aka tman904 started on Saturday June 9th 2018

#main control dashboard
maincontrol() {

              #Are we root
              usr=`whoami`
              #check output
              if [ "$usr" == "root" ] ; then
                echo ""

              else

                  echo "TKMsense can only be run as root"
                  exit 0

              fi

              #remove any user added interfaces from installation
              tkmhk=`grep -m 1 -i tkmsense /etc/pf.conf |awk '{print $3}' |cut -d '_' -f1`

                if [ "$tkmhk" == "" ] ; then

                  rm /etc/hostname.*
                fi

             #grab interface information
             #get current LAN and WAN and DMZ interfaces
             curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
             curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
             curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
             #get current LAN and WAN and DMZ interface IP's
             curlanip=`ifconfig $curlanint |grep inet |awk ' { print $2 }'`
             curwanip=`ifconfig $curwanint |grep inet |awk ' { print $2 }'`
             curdmzip=`ifconfig $curdmzint |grep inet |awk ' { print $2 }'`
             #get current LAN and WAN and DMZ netmask/cidr
             curlanmask=`pfctl -vnf /etc/pf.conf |grep -m 1 "$curlanint inet from" |awk ' { print $7 } ' |cut -d / -f2`
             curwanmask=`pfctl -vnf /etc/pf.conf |grep -m 1 "nat-to" |awk ' { print $7 } ' |cut -d / -f2`
             curdmzmask=`pfctl -vnf /etc/pf.conf |grep -m 1 "$curdmzint inet from" |awk ' { print $7 } ' |cut -d / -f2`

             #services info
             #sshd status
             #check if sshd is disabled
             sshdstat=`rcctl check sshd`
             if [ "$sshdstat" == "sshd(failed)" ] ; then

                sshdstat="Disabled"
            else

                sshdstat="Enabled"
            fi

             if [ -f /etc/pf.conf ] ; then

               #check if dmz is not set
               if [ "$curdmzint" == "" ] ; then
                  #set everything about to dmz to null
                  unset curdmzint
                  unset curdmzip
                  unset curdmzmask
              fi

             fi


             if [ -f /etc/sysctl.conf ] ; then
                  #Is ip routing enabled?
                  iprouting=`grep net.inet.ip.forwarding /etc/sysctl.conf |cut -d = -f2`
                  #check iprouting
                  if [ "$iprouting" == "1" ] ; then
                    iproutingstatus=Enabled

                  else
                    iproutingstatus=Disabled

                  fi

              else

                iproutingstatus=Disabled
           fi

            #get pf status
            pfstatus=`pfctl -si |grep -i status |awk ' { print $2 }'`
            #check pfstatus
            if [ "$pfstatus" == "Enabled" ] ; then
              pfstate="Enabled"

            else

              pfstate="Disabled"

            fi

            #get dhcpd status
            dhcpdstat=`rcctl check dhcpd`
            if [ "$dhcpdstat" == "dhcpd(ok)" ] ; then
                dhcpdstate="Enabled"

            else
                dhcpdstate="Disabled"
            fi

            #make users aware of possible ssh breakins
            sshusrip=`w |grep p |grep root |awk '{print $3}'`
            sshusrtime=`date`


            #check to see if someone is logged in over ssh
            if [ "$sshusrip" != "" ] ; then
               #set the warning message and that will be displayed
              sshloginmsg="WARNING!!!!root ssh login from $sshusrip WARNING!!!!"

           else
              #no ssh logins found
              unset sshusrip
              unset sshusrtime
              unset sshloginmsg

            fi

            #set services info varible
            srvsinfo="Firewall=$pfstate|Routing=$iproutingstatus|DHCP=$dhcpdstate|SSH=$sshdstat"


             #has tkmsense been configured?
             tkmcfg=`grep -m 1 -i tkmsense /etc/pf.conf |awk '{print $3}' |cut -d '_' -f1`
             #check tkmcfg
             if [ "$tkmcfg" == "TKMsense" ] ; then
                #set status to configured
                tkmcfg="TKMsense_V0.0.3 Configured"
                autoinfo="0=automatic setup"

             else
                #set status to unconfigured
                tkmcfg="TKMsense_V0.0.3 Unconfigured"
                autoinfo="0=automatic setup (Start Here)"

             fi

             #check if lan interface is configured
             if [ "$curlanint" == "" ] ; then
                 #set lan status to not configured
                 lanintinfo="LAN not configured"

             else
                 lanintinfo="LAN IP $curlanip/$curlanmask"

             fi


             #check if wan interface is configured
             if [ "$curwanint" == "" ] ; then
                 #set wan status to not configured
                 wanintinfo="WAN not configured"

             else
                 wanintinfo="WAN IP $curwanip/$curwanmask"

             fi


             #check if dmz interface is configured
             if [ "$curdmzint" == "" ] ; then
                 #set dmz status to not configured
                 dmzintinfo="DMZ not configured"

             else
                 dmzintinfo="DMZ IP $curdmzip/$curdmzmask"

             fi


             clear
             echo "$sshloginmsg"
             echo "                   $tkmcfg"
             echo "###############################################################################"
             echo "$lanintinfo|$wanintinfo|$dmzintinfo"
             echo "$srvsinfo"
             echo "###############################################################################"
             echo "$autoinfo"
             echo "1=assign LAN and WAN interfaces"
             echo "2=enable/disable DHCP server"
             echo "3=set LAN DHCP server settings"
             echo "4=factory reset"
             echo "5=logout"
             echo "6=reboot/shutdown"
             echo "7=change root password"
             echo "8=advanced menu"
             echo "9=ping host"
             echo "10=traceroute to host"
             echo "#####################Menu Usage#################################################"
             echo "type desired option number and hit enter/return"
             echo -n "=>"

              read cpsetting


             #Check what the user picked
             if [ "$cpsetting" == "0" ] ; then
                  #Run auto setup wizard
                  autosetup
             fi

             if [ "$cpsetting" == "1" ] ; then
                  #Run LAN and WAN Interfaces wizard
                  LWINT
             fi

            if [ "$cpsetting" == "2" ] ; then
                 #Run Disable/Enable DHCP Server
                  DEDHCPSERV
            fi
            if [ "$cpsetting" == "3" ] ; then
                 #Run DHCP Server Settings wizard
                 DHCPSERVSET
            fi

            if [ "$cpsetting" == "4" ] ; then
                 #Run Factory reset
                 FACTORYRESET
            fi

            if [ "$cpsetting" == "5" ] ; then
                #Run logout wizard
                LOGOUT
            fi

            if [ "$cpsetting" == "6" ] ; then
                #Run restart wizard
                RESTART
            fi


            if [ "$cpsetting" == "7" ] ; then
                #run passwd wizard
                PASSWD
            fi

            if [ "$cpsetting" == "8" ] ; then
                #run advanced menu
                ADVMEN
            fi

            if [ "$cpsetting" == "9" ] ; then
                #run ping wizard
                pinghost
            fi

            if [ "$cpsetting" == "10" ] ; then
                #run traceroute wizard
                tracehost
            fi

            #user typed wrong number
            #return to main control
            maincontrol

}

#Interfaces wizard
LWINT() {

          #get LAN and WAN Interfaces
          curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
          curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`

          #disable LAN and WAN Interfaces
          ifconfig $curlanint -inet 1>&2 > /dev/null
          ifconfig $curwanint -inet 1>&2 > /dev/null
          ifconfig $curlanint down 1>&2 > /dev/null
          ifconfig $curwanint down 1>&2 > /dev/null
          #remove any interface configs
          rm /etc/hostname.*

      #make note of changes
      LWINT_confdate=`date`
      echo "Please enter WAN Interface\n"
      #get list of interfaces
      netifs=`ifconfig |egrep '(^[a-z\d:])' |awk '{ print $1 }' |sed 's/://g'`
      echo $netifs
      read WANIF
      echo "Is your WAN Connection dhcp or static?"
      echo "1=dhcp"
      echo "2=static"
      read WANCONTYPE

      #check WANCONTYPE
      if [ "$WANCONTYPE" == "1" ] ; then
        echo "#Created by TKMsense_V0.0.3 on $LWINT_confdate" >/etc/hostname.$WANIF
        echo "" >>/etc/hostname.$WANIF
        echo "dhcp" >>/etc/hostname.$WANIF

      elif [ "$WANCONTYPE" == "2" ] ; then
        echo "Please enter $WANIF IP Address\n"
        read WANIFIP
        echo "Please enter $WANIF NETMASK eg 255.255.255.0\n"
        read WANIFMASK
        echo "Please enter WAN gateway/default router\n"
        read WANIFGW

        #configure WAN settings
        echo "#Created by TKMsense_V0.0.3 on $LWINT_confdate" >/etc/hostname.$WANIF
        echo "" >>/etc/hostname.$WANIF
        echo "inet $WANIFIP $WANIFMASK" >/etc/hostname.$WANIF
        echo "" >>/etc/hostname.$WANIF
        echo "!route add default $WANIFGW" >>/etc/hostname.$WANIF
      fi

      echo ""

      echo "Please enter LAN Interface\n"
      #don't show user interface that has been picked for WAN
      newnetifs=`echo $netifs |sed s/$WANIF//g`
      echo "$newnetifs"
      read LANIF
      echo "Please enter $LANIF IP Address\n"
      read LANIFIP
      echo "Please enter $LANIF NETMASK eg 255.255.255.0\n"
      read LANIFMASK

      #configure LAN Settings
      echo "#Created by TKMsense_V0.0.3 on $LWINT_confdate" >/etc/hostname.$LANIF
      echo "" >>/etc/hostname.$LANIF
      echo "inet $LANIFIP $LANIFMASK" >>/etc/hostname.$LANIF



      #configure pf.conf
      echo "#Created by TKMsense_V0.0.3 on $LWINT_confdate" >/etc/pf.conf
      echo "" >>/etc/hostname.$WANIF
     echo "lan=\"$LANIF\"\n" >>/etc/pf.conf
     echo "wan=\"$WANIF\"\n" >>/etc/pf.conf
     echo "#dmz=\n" >> /etc/pf.conf
     echo "" >>/etc/pf.conf
     echo "set skip on lo0\n" >>/etc/pf.conf
    echo "set block-policy drop\n" >>/etc/pf.conf
    echo "" >>/etc/pf.conf
    echo "block drop all\n" >>/etc/pf.conf
    echo "pass in on \$lan from \$lan:network to any keep state" >>/etc/pf.conf
    echo "pass out on \$wan from \$lan:network to any nat-to (\$wan) keep state" >>/etc/pf.conf
    echo "pass out on \$wan from \$wan:network to any keep state" >>/etc/pf.conf

    #enable ip routing
    echo "#Created by TKMsense_V0.0.3 on $LWINT_confdate" >/etc/sysctl.conf
    echo "" >>/etc/sysctl.conf
    echo "net.inet.ip.forwarding=1" >>/etc/sysctl.conf
    sysctl net.inet.ip.forwarding=1

    #start Interfaces
    #chmod u+x /etc/netstart
    sh /etc/netstart

    #enable pf
    pfctl -f /etc/pf.conf
    pfctl -e

    #disable smtpd and sndiod
    rcctl disable smtpd
    rcctl disable sndiod
    rcctl stop smtpd
    rcctl stop sndiod


    #bootstrap needed programs
    #check if pftop is installed
    if [ ! -f /usr/local/sbin/pftop ] ; then
    pkg_add pftop
    fi
    #check if iftop is installed
    if [ ! -f /usr/local/sbin/iftop ] ; then
    pkg_add iftop
    fi
    #check if iperf3 is installed
    if [ ! -f /usr/local/bin/iperf3 ] ; then
    pkg_add iperf3
    fi

    echo ""
    echo "all done enjoy TKMsense"
     #return to control Panel
     maincontrol
   }

#Port forward wizard
WTOLPF() {


  #make note of changes
  WTOLPF_confdate=`date`

        echo "WARNING THIS WILL OPEN A PORT FROM THE INTERNET TO YOUR LAN"
        echo "Are you sure about this? yes or no"
        echo "1=no"
        echo "2=yes"
        read pfans

        #check pfans
        if [ "$pfans" == "1" ] ; then
            #return to control panel
            echo "Returning to control panel"
            ADVMEN
        fi

        if [ "$pfans" == "2" ] ; then
            echo "Ok then here we go"
            #get LAN and WAN interfaces
            curlanint=`grep lan /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
            curwanint=`grep wan /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
            #ask for protocol
            echo "what protocol do you want to forward?"
            echo "1=TCP"
            echo "2=UDP"
            read proans
        fi
            #check proans
            if [ "$proans" == "1" ] ; then
                PROTO="tcp"

            elif [ "$proans" == "2" ] ; then

                PROTO="udp"

                #if we get to the else the user mistyped
            else
              echo "Please make sure to type correct number"
              echo "Returning to control panel"
              maincontrol

            fi

            #ask for destination port number
            echo "what port number?"
            read PORT

            #ask for destination LAN IP
            echo "what LAN IP do you want this port forwarded to?"
            read LANIP

            #add port forwarding rule in /etc/pf.conf
            echo "" >>/etc/pf.conf
            echo "#WAN to LAN port forward created by TKMsense_V0.0.3 on $WTOLPF_confdate" >>/etc/pf.conf
            echo "" >>/etc/pf.conf
            echo "pass in on \$wan inet proto $PROTO from any to any port $PORT rdr-to $LANIP port $PORT keep state" >>/etc/pf.conf
            echo "pass out on \$lan inet proto $PROTO from any to $LANIP port $PORT keep state" >>/etc/pf.conf

            #reload pf ruleset
            pfctl -F rules
            pfctl -f /etc/pf.conf

            #return to control panel
            ADVMEN
}

#Enable/Disable pf wizard
DISPF() {


  echo "Do you want to enable or disable pf?"
  echo "1=disable"
  echo "2=enable"
  read anspf
  #check anspf
  if [ "$anspf" == "2" ] ; then
      pfctl -f /etc/pf.conf
      pfctl -e
      #return to control panel
      ADVMEN
  fi

  if [ "$anspf" == "1" ] ; then

        echo "WARNING!!!!!!!!"
        echo "This will stop all connections through this firewall."
        echo "Are you absolutely sure about this? yes or no"
        echo "1=yes"
        echo "2=no"
        read ans
  fi

        #check ans
          if [ "$ans" == "1" ] ; then
                pfctl -F all
                pfctl -d

          elif [ "$ans" == "2" ] ; then
                echo "Returning to control panel."
                ADVMEN
        fi

}

#Enable/Disable DHCP Wizard
DEDHCPSERV() {


        if [ ! -f /etc/dhcpd.conf ] ; then

          echo "Please run the DHCP Server wizard first"
          echo "Returning to control panel"
          #return to control panel
          maincontrol
        fi

        echo "Do you want to enable or disable the dhcp server?"
        echo "1=disable"
        echo "2=enable"
        read dhcpans

        #check if dhcpans is enable and dhcpd is configured
        if [ "$dhcpans" == "2" ] && [ -f /etc/dhcpd.conf ] ; then

            rcctl start dhcpd

        #check if dhcpans is disable and dhcpd is configured
      elif [ "$dhcpans" == "1" ] && [ -f /etc/dhcpd.conf ] ; then

            rcctl stop dhcpd

        #if we get here dhcpd must not be configured or user mistyped
        else

            echo "Please run the DHCP setup wizard fist"
            echo "Returning to control panel"
            #return to control panel
            maincontrol

        fi

}

#DHCP Server Setup Wizard
DHCPSERVSET() {


          #make note of changes
          DHCPSERVSET_confdate=`date`

          echo "Please enter domain name for local subnet"
          read dhcpdomainname

          echo "Enter primary dns server for client dns queries to WAN"
          read dhcpdnspri

          echo "Enter secondary dns server for client dns queries to WAN"
          read dhcpdnssec

          echo "Please enter your network id/subnet id eg 192.168.1.0"
          read dhcpnetid

          echo "Please enter your network LAN netmask eg 255.255.255.0"
          read dhcpnetmask

          echo "Please enter first IP in dhcp lease range"
          read dhcpstart

          echo "Please enter last IP in dhcp lease range"
          read dhcpend


          echo "Please enter default gateway for your LAN eg LAN IP"
          read dhcpgw

          #put all dhcp settings into /etc/dhcpd.conf
          echo "#Created by TKMsense_V0.0.3 on $DHCPSERVSET_confdate" >/etc/dhcpd.conf
          echo "" >>/etc/dhcpd.conf
          echo "option domain-name \"$dhcpdomainname\";" >>/etc/dhcpd.conf
          echo "option domain-name-servers $dhcpdnspri, $dhcpdnssec;" >>/etc/dhcpd.conf
          echo "" >>/etc/dhcpd.conf
          echo "subnet $dhcpnetid netmask $dhcpnetmask {" >>/etc/dhcpd.conf
          echo "" >>/etc/dhcpd.conf
          echo "range $dhcpstart $dhcpend;" >>/etc/dhcpd.conf
          echo "" >>/etc/dhcpd.conf
          echo "option routers $dhcpgw;" >>/etc/dhcpd.conf
          echo "" >>/etc/dhcpd.conf
          echo "}" >>/etc/dhcpd.conf


          echo "The DHCP Server has been fully configured"
          echo "Starting the DHCP Server"

          rcctl enable dhcpd
          rcctl start dhcpd

          #return to control panel

          echo "Returning to control panel"
          maincontrol

}


#guide me wizard
autosetup() {

                #has tkmsense been configured?
                tkmcfg=`grep -m 1 -i tkmsense /etc/pf.conf |awk '{print $3}' |cut -d '_' -f1`
                #check tkmcfg
                if [ "$tkmcfg" == "TKMsense" ] ; then
                  #tell user they need to factory reset first if system is configured
                  echo "Please do a factory reset before running automatic setup again."
                  sleep 4
                  #return to main menu
                  maincontrol

                fi

                  #start from a factory state


                  GUIDEME_confdate=`date`
                  #get LAN and WAN Interfaces
                  curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
                  curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`

                  #disable LAN and WAN Interfaces
                  ifconfig $curlanint -inet 1>&2 > /dev/null
                  ifconfig $curwanint -inet 1>&2 > /dev/null
                  ifconfig $curlanint down 1>&2 > /dev/null
                  ifconfig $curwanint down 1>&2 > /dev/null

                  #disable pf
                  pfctl -F all 1>&2 > /dev/null
                  pfctl -d 1>&2 > /dev/null
                  rm /etc/hostname.* 1>&2 > /dev/null
                  rm /etc/pf.conf 1>&2 > /dev/null
                  rm /etc/sysctl.conf 1>&2 > /dev/null
                  rm /etc/dhcpd.conf 1>&2 > /dev/null
                  rcctl disable dhcpd 1>&2 > /dev/null
                  rcctl stop dhcpd 1>&2 > /dev/null
                  rcctl enable smtpd 1>&2 > /dev/null
                  rcctl enable sndiod 1>&2 > /dev/null
                  rcctl start smtpd 1>&2 > /dev/null
                  rcctl start sndiod 1>&2 > /dev/null
                  sysctl net.inet.ip.forwarding=0 1>&2 > /dev/null
                  unset curlanint
                  unset curwanint
                  unset curlanip
                  unset curwanip
                  unset curlanmask
                  unset curwanmask


            echo ""
            echo "Welcome to the TKMsense automatic setup wizard."
            echo ""
            echo "Please unplug all network cables except power from this machine."
            echo "Careful if you have POE."
            sleep 5
            echo "Are all the network ports unplugged?"
            echo "1=yes"
            echo "2=no"
            read gmans
            #check gmans
            if [ "$gmans" == "2" ] ; then
               echo "Returning to control panel."
               maincontrol
            fi

            if [ "$gmans" == "1" ] ; then

                #this while loop runs until interfaces are configured
                  while [ ! -f /etc/hostname* ]
                  do

            	         #ask user to plug in desired LAN port
            	         echo "Please plug in your desired LAN port"
            	         sleep 3

            	         #find which interface they plugged in
            	         #get all interfaces in the system first
             	         allints=`ifconfig |egrep '(^[a-z\d])' |cut -d : -f1`

            	         #now remove lo0 pflog0 and enc0 from $allints
            	         cleanints=`echo $allints |sed 's/lo0//g;s/pflog0//g;s/enc0//g'`

                       #check each interface in $cleanints for which one is up and set as LAN
                       for t in $cleanints
                       do
                          #get current interfaces status
                          intstat=`ifconfig $t |grep status |cut -d : -f2 |sed s/" "//g`
                          #check current interface status
            	             if [ "$intstat" == "active" ] ; then
                               #if the interface status was active set it as the aclanint
                               aclanint="$t"
                               #configure lan interface
                                 echo "#Created by TKMsense_V0.0.3 on $GUIDEME_confdate" >/etc/hostname.$aclanint
                                 echo "" >>/etc/hostname.$aclanint
                                 echo "inet 192.168.240.1 255.255.255.0" >>/etc/hostname.$aclanint
            		                 echo "LAN interface is configured! in /etc/hostname.$aclanint"
                                 echo "With IP Address 192.168.240.1 and netmask 255.255.255.0"

            	             fi
                        done


        done

            #this while loop runs until the wan interface is configured
            while [ ! -f /etc/hostname.$acwanint ]
            do

                      sleep 3
            	        #ask user to plug in desired WAN port
            	         echo "Please plug in desired WAN port"

                       #remove the previous selected LAN interface from $cleanints
                       cleanintswolan=`echo $cleanints |sed s/$aclanint//g`
                       #check each interface in $cleanintswolan for which one is up and set as WAN
                       for t in $cleanintswolan
                       do
                          #get current interfaces status
                          intstat=`ifconfig $t |grep status |cut -d : -f2 |sed s/" "//g`
                          #check current interface status
                          if [ "$intstat" == "active" ] ; then
                            #if the interface status was active set it as the acwanint
                            acwanint="$t"

                            echo "Is your WAN Connection dhcp or static?"
                            echo "1=dhcp"
                            echo "2=static"
                            read WANCONTYPE

                            #check WANCONTYPE
                            if [ "$WANCONTYPE" == "1" ] ; then
                              #configure DHCP WAN settings
                              echo "#Created by TKMsense_V0.0.3 on $GUIDEME_confdate" >/etc/hostname.$acwanint
                              echo "" >>/etc/hostname.$acwanint
                              echo "dhcp" >>/etc/hostname.$acwanint
                              echo "WAN interface is configured! in /etc/hostname.$acwanint"
                              echo "Using DHCP"

                            elif [ "$WANCONTYPE" == "2" ] ; then
                              #configure static WAN settings
                              echo "Please enter $acwanint IP Address\n"
                              read WANIFIP
                              echo "Please enter $acwanint NETMASK eg 255.255.255.0\n"
                              read WANIFMASK
                              echo "Please enter WAN gateway/default router\n"
                              read WANIFGW

                              echo "#Created by TKMsense_V0.0.3 on $GUIDEME_confdate" >/etc/hostname.$acwanint
                              echo "" >>/etc/hostname.$acwanint
                              echo "inet $WANIFIP $WANIFMASK" >/etc/hostname.$acwanint
                              echo "" >>/etc/hostname.$acwanint
                              echo "!route add default $WANIFGW" >>/etc/hostname.$acwanint
                            fi

                     fi
                  done

            done


            echo "Please type the new root/admin password for management of TKMsense"
            passwd root
            echo "Password successfully changed!"
            echo ""

            echo ""
            echo "configuring ip routing in /etc/sysctl.conf\n"
            sleep 2
            echo "#Created by TKMsense_V0.0.3 on $GUIDEME_confdate" >/etc/sysctl.conf
            echo "" >>/etc/sysctl.conf
            echo "net.inet.ip.forwarding=1" >>/etc/sysctl.conf

            echo "configuring firewalling in /etc/pf.conf\n"
            sleep 2
            echo "#Created by TKMsense_V0.0.3 on $GUIDEME_confdate" >/etc/pf.conf
            echo "" >>/etc/pf.conf
            echo "lan=$aclanint" >>/etc/pf.conf
            echo "wan=$acwanint" >>/etc/pf.conf
            echo "#dmz=\n" >> /etc/pf.conf
            echo "" >>/etc/pf.conf
            echo "set skip on lo0" >>/etc/pf.conf
            echo "set block-policy drop" >>/etc/pf.conf
            echo "" >>/etc/pf.conf
            echo "block drop all" >>/etc/pf.conf
            echo "" >>/etc/pf.conf
            echo "pass in on \$lan from \$lan:network to any keep state" >>/etc/pf.conf
            echo "pass out on \$wan from \$lan:network to any nat-to (\$wan) keep state" >>/etc/pf.conf
            echo "pass out on \$wan from \$wan:network to any keep state" >>/etc/pf.conf

            echo "configuring the dhcp server in /etc/dhcpd.conf\n"
            sleep 2
            echo "#Created by TKMsense_V0.0.3 on $GUIDEME_confdate" >/etc/dhcpd.conf
            echo "" >>/etc/dhcpd.conf
            echo "option domain-name \"tkmsense\";" >>/etc/dhcpd.conf
            echo "option domain-name-servers 4.2.2.1, 4.2.2.2;" >>/etc/dhcpd.conf
            echo "subnet 192.168.240.0 netmask 255.255.255.0 {\n" >>/etc/dhcpd.conf
            echo "range 192.168.240.100 192.168.240.200;" >>/etc/dhcpd.conf
            echo "option routers 192.168.240.1;" >> /etc/dhcpd.conf
            echo "}\n" >> /etc/dhcpd.conf

            #turn all those services on and enable them.
            chmod u+x /etc/netstart
            /etc/netstart
            pfctl -F all
            pfctl -f /etc/pf.conf
            pfctl -e
            sysctl net.inet.ip.forwarding=1
            rcctl enable dhcpd
            rcctl start dhcpd
            rcctl stop smtpd
            rcctl disable smtpd
            rcctl stop sndiod
            rcctl disable sndiod
            rcctl stop sshd
            rcctl disable sshd

            #bootstrap needed programs
            #check if pftop is installed
            if [ ! -f /usr/local/sbin/pftop ] ; then
            pkg_add pftop
            fi
            #check if iftop is installed
            if [ ! -f /usr/local/sbin/iftop ] ; then
            pkg_add iftop
            fi
            #check if iperf3 is installed
            if [ ! -f /usr/local/bin/iperf3 ] ; then
            pkg_add iperf3
            fi

            echo "all done enjoy TKMsense."
            echo "Returing to control panel"
            maincontrol
        fi
}

#factory reset wizard
FACTORYRESET() {


            echo "This will reset this firewall to defaults all connectivity will break!!!!"
            echo "Are you sure about this? yes or no"
            echo "1=yes"
            echo "2=no"
            read resetans
            if [ "$resetans" == "2" ] ; then


                echo "Returning to control panel"

                #Return to control panel
                maincontrol

           elif [ "$resetans" == "1" ] ; then

              echo "Here we go!!!!!!!!"


                #get LAN and WAN Interfaces
                curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
                curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
                curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
                #disable LAN and WAN Interfaces
                ifconfig $curlanint -inet
                ifconfig $curwanint -inet
                ifconfig $curdmzint -inet
                ifconfig $curlanint down
                ifconfig $curwanint down
                ifconfig $curdmzint down

                #disable pf
                pfctl -F all
                pfctl -d
                rm /etc/hostname.*
                rm /etc/pf.conf
                rm /etc/sysctl.conf
                rm /etc/dhcpd.conf
                rcctl disable dhcpd
                rcctl stop dhcpd
                rcctl enable smtpd
                rcctl enable sndiod
                rcctl start smtpd
                rcctl start sndiod
                sysctl net.inet.ip.forwarding=0
                unset curlanint
                unset curwanint
                unset curlanip
                unset curwanip
                unset curlanmask
                unset curwanmask
                unset curdmzint
                unset curdmzip
                unset curdmzmask

                echo "Please reset password for root/admin to know value"
                passwd root
                echo "Password successfully changed!"
                echo "all done!!!!!!!!"
                echo "Rebooting"
                reboot

                #if we get to the else the user mistyped
            else

              echo "Please make sure to type correct number"
              echo "Returning to control panel"
              maincontrol


            fi
}

#logout wizard
LOGOUT() {

  #kill all ksh so we logout
  kl=`ps aux |grep ksh |awk '{print $2}'`
  #kill every ksh pid we found
  for t in $kl
  do
      #clear screen
      clear
      kill -9 $t
  done

}

#restart wizard
RESTART() {


  echo "WARNING this will stop all connectivity in your network."
  echo "Are you sure?"
  echo "1=yes"
  echo "2=no"
  read rebshans
  #check $rebshans
  if [ "$rebshans" == "2" ] ; then
        echo "Returning to control panel"
        maincontrol
  fi

  if [ "$rebshans" == "1" ] ; then
        echo "Do you want to reboot or shutdown?"
        echo "1=reboot"
        echo "2=shutdown"
        read rebshaction
                      #check $rebshaction
                    if [ "$rebshaction" == "1" ] ; then
                          echo "rebooting!"
                          reboot
                    fi

                    if [ "$rebshaction" == "2" ] ; then
                          echo "shutting down!"
                          shutdown -p now
                    fi

    else
      echo "Please type correct number"
      echo "Returning to control panel"
      maincontrol
    fi

}

#change password wizard
PASSWD() {


      echo "This will change the root/admin password"
      echo "Are you sure?"
      echo "1=no"
      echo "2=yes"
      read passwdans
      #check $passwdans
      if [ "$passwdans" == "1" ] ; then
        #return to control panel
        echo "Returning to control panel"
        maincontrol
      fi

      if [ "$passwdans" == "2" ] ; then
          #change root password
          echo "changing root/admin password"
          passwd root
          echo "All done returning to control panel"
          maincontrol
      fi

}

#ping host wizard
pinghost() {

  echo "Do you want to ping an IPV4 or IPV6 host?"
  echo "1=IPV4"
  echo "2=IPV6"
  read ptans
  #check rtans
  if [ "$ptans" == "1" ] ; then

    echo "Please enter either hostname or IPV4 Address to ping"
    read phost
    echo "Pinging $phost"
    #ping host
    ping -c 5 $phost
    echo "Ping to $phost complete"
    sleep 5
    #return to main menu
    maincontrol

 fi

  if [ "$ptans" == "2" ] ; then

  echo "Please enter either hostname or IPV6 Address to ping"
  read phost
  echo "Pinging $phost"
  #ping host
  ping6 -c 5 $phost
  echo "Ping to $phost complete"
  sleep 5
  #return to main menu
  maincontrol

fi


}


#ping host wizard
tracehost() {

  echo "Do you want to traceroute to an IPV4 or IPV6 host?"
  echo "1=IPV4"
  echo "2=IPV6"
  read ptans
  #check rtans
  if [ "$ptans" == "1" ] ; then

    echo "Please enter either hostname or IPV4 Address to traceroute to"
    read trhost
    echo "Tracing route to $trhost"
    sleep 2
    #traceroute to host
    traceroute -w 2 -n $trhost
    echo "Traceroute to $trhost complete"
    sleep 5
    #return to main menu
    maincontrol

 fi

  if [ "$ptans" == "2" ] ; then

  echo "Please enter either hostname or IPV6 Address to traceroute to"
  read trhost
  echo "Tracing route to $trhost"
  #traceroute to host
  traceroute6 -w 2 -n $trhost
  echo "Traceroute to $trhost complete"
  sleep 5
  #return to main menu
  maincontrol

fi

}


#advanced menu
ADVMEN() {

  clear

  #services info
  #sshd status
  #check if sshd is disabled
  sshdstat=`rcctl check sshd`
  if [ "$sshdstat" == "sshd(failed)" ] ; then

     sshdstat="Disabled"
  else

     sshdstat="Enabled"
  fi

  if [ -f /etc/pf.conf ] ; then

    #check if dmz is not set
    if [ "$curdmzint" == "" ] ; then
       #set everything about to dmz to null
       unset curdmzint
       unset curdmzip
       unset curdmzmask
   fi

  fi


  if [ -f /etc/sysctl.conf ] ; then
       #Is ip routing enabled?
       iprouting=`grep net.inet.ip.forwarding /etc/sysctl.conf |cut -d = -f2`
       #check iprouting
       if [ "$iprouting" == "1" ] ; then
         iproutingstatus=Enabled

       else
         iproutingstatus=Disabled

       fi

   else

     iproutingstatus=Disabled
  fi

  #get pf status
  pfstatus=`pfctl -si |grep -i status |awk ' { print $2 }'`
  #check pfstatus
  if [ "$pfstatus" == "Enabled" ] ; then
   pfstate="Enabled"

  else

   pfstate="Disabled"

  fi

  #get dhcpd status
  dhcpdstat=`rcctl check dhcpd`
  if [ "$dhcpdstat" == "dhcpd(ok)" ] ; then
     dhcpdstate="Enabled"

  else
     dhcpdstate="Disabled"
  fi


  #make users aware of possible ssh breakins
  sshusrip=`w |grep p |grep root |awk '{print $3}'`
  sshusrtime=`date`


  #check to see if someone is logged in over ssh
  if [ "$sshusrip" != "" ] ; then
     #set the warning message and that will be displayed
    sshloginmsg="WARNING!!!!root ssh login from $sshusrip WARNING!!!!"

  else
    #no ssh logins found
    unset sshusrip
    unset sshusrtime
    unset sshloginmsg

  fi

  #set services info varible
  srvsinfo="Firewall=$pfstate|Routing=$iproutingstatus|DHCP=$dhcpdstate|SSH=$sshdstat"

  clear
  echo  "$sshloginmsg"
  echo "                   $tkmcfg"
  echo "###############################################################################"
  echo "$lanintinfo|$wanintinfo|$dmzintinfo"
  echo "$srvsinfo"
  echo "###############################################################################"
  echo "0=return to main menu"
  echo "1=add port forward for WAN to LAN traffic"
  echo "2=enable/disable PF warning also disables NAT"
  echo "3=current network connections going through firewall"
  echo "4=real time DNS queries"
  echo "5=current connections using bandwidth"
  echo "6=run WAN speedtest"
  echo "7=bandwidth usage per interface"
  echo "8=enable SSH management"
  echo "9=current system status"
  echo "10=run top system monitor"
  echo "11=run tcpdump"
  echo "12=show arp cache"
  echo "13=show routing table"
  echo "14=assign DMZ interface"
  echo "15=add port forward for WAN to DMZ traffic"
  echo "#####################Menu Usage#################################################"
  echo "type desired option number and hit enter/return"
  echo -n "=>"

   read advsetting
   #check $advsetting

   if [ "$advsetting" == "1" ] ; then
        #Run Port Forward wizard
        WTOLPF
   fi

   if [ "$advsetting" == "2" ] ; then
       #Run enable/disable PF
        DISPF
   fi

  if [ "$advsetting" == "3" ] ; then
      #start pftop
      moncon
  fi

  if [ "$advsetting" == "4" ] ; then
        #start tcpdump
        mondns
  fi

  if [ "$advsetting" == "5" ] ; then
        #start iftop
        monconband
  fi

  if [ "$advsetting" == "6" ] ; then
        #start iperf3
        wansptst
  fi

  if [ "$advsetting" == "7" ] ; then
        #start systat ifstat
        intusage
  fi

  if [ "$advsetting" == "8" ] ; then
        #start ssh on LAN and WAN
        sshendis
  fi

  if [ "$advsetting" == "9" ] ; then
        #start current system status
        cursysstat
  fi

  if [ "$advsetting" == "10" ] ; then
        #start top system monitor
        runtop
  fi

  if [ "$advsetting" == "11" ] ; then
       #start tcpdump
       runtcpdump
  fi

  if [ "$advsetting" == "14" ] ; then
      #start dmz interface setup
       dmzint
  fi

  if [ "$advsetting" == "12" ] ; then
        #start show arp cache
        arpcache
  fi

  if [ "$advsetting" == "13" ] ; then
       #start show routing table
       routingtable
  fi

  if [ "$advsetting" == "15" ] ; then
        #start dmz port forward wizard
        dmzptfw
  fi

  if [ "$advsetting" == "0" ] ; then
      #return to main menu
      maincontrol
  fi

#user typed wrong number
#return to main control
ADVMEN

}

#connection monitor
moncon() {


    #start pftop
    echo "type q to exit"
    sleep 3
    pftop
    #return to advanced menu
    ADVMEN

}

#dns monitor
mondns() {

  #grab active interfaces
  #get current LAN and WAN interfaces
  curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  echo "Please enter the desired interface to listen on"
  echo "Current available interfaces"
  echo "1=LAN"
  echo "2=WAN"
  echo "3=DMZ"
  read tcpdpint
  #check interface chosen to capture on
  if [ "$tcpdpint" == "1" ] ; then
        #set tcpdpinfo to lan
        tcpdpinfo="$curlanint"
        echo "Capturing DNS queries on LAN"
        sleep 3
  fi

  if [ "$tcpdpint" == "2" ] ; then
        #set tcpdpinfo to wan
        tcpdpinfo="$curwanint"
        echo "Capturing DNS queries on WAN"
        sleep 3
  fi

  if [ "$tcpdpint" == "3" ] ; then
        #set iftopinfo to dmz
        tcpdpinfo="$curdmzint"
        echo "Capturing DNS queries on DMZ"
        sleep 3
  fi

    #start tcpdump to look for dns queries
    echo "how long do you want to monitor for in seconds?"
    echo "Careful this will run untill chosen time has expired"
    echo "Press enter/return for default of 5 seconds"
    read tpdpto
    sleep 3

    #if user pressed enter run with defaults
    if [ "$tpdpto" == "" ] ; then

        tcpdump -ni $tcpdpinfo udp port 53 & sleep 5; kill $!
        echo "Real time capture complete"
        sleep 5

    else
    #if user entered a timeout use it
        tcpdump -ni $tcpdpinfo udp port 53 & sleep $tpdpto; kill $!
        echo "Real time capture complete"
        sleep 5
    fi

    #return to advanced menu
    ADVMEN
}

#connection bandwidth usage
monconband() {

  #grab active interfaces
  #get current LAN and WAN interfaces
  curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  echo "Please enter the desired interface to listen on"
  echo "Current available interfaces"
  echo "1=LAN"
  echo "2=WAN"
  echo "3=DMZ"
  read iftopint
  #check interface chosen to capture on
  if [ "$iftopint" == "1" ] ; then
        #set iftopinfo to lan
        iftopinfo="$curlanint"
        echo "Running iftop on LAN"
        echo "type q to quit"
        sleep 3
        #run iftop on LAN
        iftop -nNPi $iftopinfo
  fi

  if [ "$iftopint" == "2" ] ; then
        #set iftopinfo to wan
        iftopinfo="$curwanint"
        echo "Running iftop on WAN"
        echo "type q to quit"
        sleep 3
        #run iftop on WAN
        iftop -nNPi $iftopinfo
  fi

  if [ "$iftopint" == "3" ] ; then
        #set iftopinfo to dmz
        iftopinfo="$curdmzint"
        echo "Running iftop on DMZ"
        echo "type q to quit"
        sleep 3
        #run iftop on DMZ
        iftop -nNPi $iftopinfo
  fi

    #return to advanced menu
    ADVMEN
}

#wan speed test
wansptst() {

    echo "This speedtest uses iperf3"
    sleep 2
    echo "How long do you want to test for in seconds?"
    echo "press enter/return for default of 10 seconds"
    read sttime

    echo "What server do you want to test with?"
    echo "If you use a server on your local network you can test LAN speed as well"
    echo "If the test server chosen is invalid or busy this will have to timeout"
    echo "press enter/return for default of iperf.he.net"
    read stserv

    #see if user typed any options
    if [ "$sttime" == "" ] && [ "$stserv" == "" ] ; then
       #run iperf with defaults
       iperf3 -t 10 -R -c iperf.he.net
       sleep 5

       #otherwise run with user's options
    else

    iperf3 -t $sttime -R -c $stserv
    sleep 5

    fi

    #return to advanced menu
    ADVMEN
}

#interface usage
intusage() {

    echo "How long do you want this to run for in seconds?"
    echo "Press enter/return for default"
    read sysifstime

    #see if user typed any options
    if [ "$sysifstime" == "" ] ; then
       #run systat ifstat with defaults
       systat ifstat 1 & sleep 5; kill $!
       clear

       #otherwise run with users options
    else

    systat ifstat 1 & sleep $sysifstime; kill $!
    clear

  fi

    #return to advanced menu
    ADVMEN
}

sshendis() {

        #enable sshd
        echo "Do you want to enable or disable ssh management of TKMsense?"
        echo "1=disable"
        echo "2=enable"
        read sshans
        #check sshans
        if [ "$sshans" == "2" ] ; then

        echo "Enabling SSH"
        sleep 3
        #enable root logins
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
        rcctl enable sshd
        rcctl start sshd

        #accept ssh traffic on WAN and reload pf
        echo "pass in on \$wan inet proto tcp from any to any port = 22 keep state" >> /etc/pf.conf
        pfctl -F all
        pfctl -f /etc/pf.conf

        #return to advanced menu
        ADVMEN

      #otherwise disable sshd
      else
        echo "Disabling SSH"
        sleep 3
        rcctl stop sshd
        rcctl disable sshd
        #remove ssh access on WAN
        sed -i '/pass in on \$wan inet proto tcp from any to any port = 22 keep state/d' /etc/pf.conf
        sed -i '/PermitRootLogin yes/d' /etc/ssh/sshd_config
        #reload pf
        pfctl -F all
        pfctl -f /etc/pf.conf

      fi

}

cursysstat() {
echo "This will return to the advanced menu within 10 seconds"

sleep 4

  x="0"
  while [ $x -le 1 ]

  do

  	     clear

               #grab hardware stats and info
               curdate=`date`
               lastboot=`sysctl kern.boottime |cut -d = -f2`
               uptime=`top -b -d 1 |grep "up" |awk ' { print $11 }' |head -1`
               curconnum=`pfctl -si |grep "current entries" |awk ' { print $3 }'`
               hwmod=`sysctl hw.model |cut -d = -f2`
               hwmach=`sysctl hw.machine |cut -d = -f2`
               hwmem=`dmesg |grep "real mem" |awk ' { print $5 } ' |sed 's/[()]//g' `
               usedmem=`top -b |grep -m 1 -i memory |awk '{print $3}' |cut -d '/' -f1`


               #sshd status
               #check if sshd is disabled
               sshdstat=`rcctl check sshd`
               if [ "$sshdstat" == "sshd(failed)" ] ; then

                  sshdstat="Disabled"
              else

                  sshdstat="Enabled"
              fi

              #show active admin logins
              acadm=`last |grep still`

               if [ -f /etc/pf.conf ] ; then

                 #check if dmz is not set
                 if [ "$curdmzint" == "" ] ; then
                    #set everything about to dmz to null
                    unset curdmzint
                    unset curdmzip
                    unset curdmzmask
                fi

               fi


               if [ -f /etc/sysctl.conf ] ; then
                    #Is ip routing enabled?
                    iprouting=`grep net.inet.ip.forwarding /etc/sysctl.conf |cut -d = -f2`
                    #check iprouting
                    if [ "$iprouting" == "1" ] ; then
                      iproutingstatus=Enabled

                    else
                      iproutingstatus=Disabled

                    fi

                else

                  iproutingstatus=Disabled
             fi

              #get pf status
              pfstatus=`pfctl -si |grep -i status |awk ' { print $2 }'`
              #check pfstatus
              if [ "$pfstatus" == "Enabled" ] ; then
                pfstate="Enabled"

              else

                pfstate="Disabled"

              fi

              #get dhcpd status
              dhcpdstat=`rcctl check dhcpd`
              if [ "$dhcpdstat" == "dhcpd(ok)" ] ; then
                  dhcpdstate="Enabled"

              else
                  dhcpdstate="Disabled"
              fi

              #count number of LAN and WAN port forwards
              curlanpf=`pfctl -sr |grep "pass out on $curlanint inet proto" |wc -l |sed -e 's/^[ \t]*//'`
              curdmzpf=`pfctl -sr |grep "pass out on $curdmzint inet proto" |wc -l |sed -e 's/^[ \t]*//'`



               echo "###############Logged In Admins#################################################"
               echo "$acadm"
               echo "################################################################################"
               echo "###############Hardware Specs###################################################"
  	     echo "Time is $curdate/Last boot $lastboot"
               echo "This firewall has been up for $uptime"
               echo "CPU=$hwmach/$hwmod"
               echo "Total RAM=$hwmem RAM Usage=$usedmem of $hwmem"
  	     echo "################################################################################"
               echo "###############Network Status###################################################"
  	     echo "There are currently $curconnum active connections"
         echo "There are currently $curlanpf LAN port forwards"
         echo "There are currently $curdmzpf DMZ port forwards"
               echo "$lanintinfo"
               echo "$wanintinfo"
               echo "$dmzintinfo"
  	     echo "################################################################################"
               echo "################Services Status#################################################"
  	     echo "SSH=$sshdstat"
               echo "ROUTING=$iproutingstatus"
               echo "PF=$pfstate"
               echo "DHCPD=$dhcpdstate"
  	     echo "################################################################################"

  	#don't overload the cpu
  	sleep 5
  	clear

  	#increment counter
  	x="$x+1"

  done

  #return to advanced menu
  ADVMEN

}


runtop() {

  echo "Starting top system monitor type q to exit"
  sleep 3
  top

  #return to advanced menu
  ADVMEN

}

runtcpdump() {

  #grab active interfaces
  #get current LAN, WAN and DMZ interfaces
  curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  echo "Please enter the desired interface to listen on"
  echo "Current available interfaces"
  echo "1=LAN"
  echo "2=WAN"
  echo "3=DMZ"
  read tcpdpint
  #check interface chosen to capture on
  if [ "$tcpdpint" == "1" ] ; then
        #set tcpdpint to lan
        tcpdpint="$curlanint"
        tcpdpinfo="LAN"
  fi

  if [ "$tcpdpint" == "2" ] ; then
        #set tcpdpint to wan
        tcpdpint="$curwanint"
        tcpdpinfo="WAN"
  fi

  if [ "$tcpdpint" == "3" ] ; then
        #set tcpdpint to dmz
        tcpdpint="$curdmzint"
        tcpdpinfo="DMZ"
  fi

  echo "Please enter number of desired interface and press enter"
  echo "How long do want this capture to run for in seconds default is 10 seconds?"
  read tpdpto
  #check tpdpto
  if [ "$tpdpto" == "" ] ; then
      #set tpdpto to 10 seconds
      tpdpto="10"
  fi

  echo "Starting tcpdump on $tcpdpinfo"
  sleep 3
  tcpdump -ni $tcpdpint & sleep $tpdpto; kill $!

#return to advmen
ADVMEN

}

dmzint() {

  #check if system is configured yet
  if [ ! -f /etc/pf.conf ] ; then
      #tell user to configure system first
      echo "Please either run automatic setup from main menu"
      echo "and or assign LAN and WAN interfaces prior to configuring a DMZ"
      sleep 8
      #return to advanced menu
      ADVMEN
  fi

  #check if dmz interface has already been configured
  curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  dmzrlchk=`grep -m 1 '$dmz:network' /etc/pf.conf`
  if [ "$curdmzint" != "" ] || [ "$dmzrlchk" != "" ] ; then
        #tell user dmz has been configured
        echo "A DMZ interface has already been configured"
        echo "Please factory reset from the main menu first to assign a new one"
        sleep 6
        #return to advanced menu
        ADVMEN
  fi

  #make note of our changes
  DMZINT_confdate=`date`
  #get list of interfaces
  curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  echo "Please enter desired DMZ interface"
  allints=`ifconfig |egrep '(^[a-z])' |cut -d : -f1`
  #now remove lo0 pflog0 and enc0 from $allints and configured LAN and WAN interfaces
  cleanints=`echo $allints |sed "s/lo0//g;s/pflog0//g;s/enc0//g;s/$curlanint//g;s/$curwanint//g"`

  echo "############################################################"
  echo $cleanints
  echo "############################################################"
  read DMZIF
  echo "Please enter $DMZIF IP Address"
  read DMZIFIP
  echo "Please enter $DMZIF NETMASK eg 255.255.255.0"
  read DMZIFMASK

  #configure DMZ Settings
  echo "#Created by TKMsense_V0.0.3 on $DMZINT_confdate" >/etc/hostname.$DMZIF
  echo "" >>/etc/hostname.$DMZIF
  echo "inet $DMZIFIP $DMZIFMASK" >>/etc/hostname.$DMZIF


  #configure DMZ firewall rules
  #sed -i '5i\dmz="$DMZIF"\' /etc/pf.conf
  sed -i "s/#dmz=/dmz=$DMZIF/" /etc/pf.conf
  echo "block in quick on \$dmz inet proto tcp from \$dmz:network to self port 22" >>/etc/pf.conf
  echo "pass in on \$dmz from \$dmz:network to any keep state" >>/etc/pf.conf
  echo "pass out on \$wan from \$dmz:network to any nat-to (\$wan) keep state" >>/etc/pf.conf

  #restart interfaces
  sh /etc/netstart

  #update dashboard
  #grab interface information
  #get current LAN and WAN and DMZ interfaces
  curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  #get current LAN and WAN and DMZ interface IP's
  curdmzip=`ifconfig $curdmzint |grep inet |awk ' { print $2 }'`
  #get current LAN and WAN and DMZ netmask/cidr
  curdmzmask=`pfctl -vnf /etc/pf.conf |grep -m 1 "$curdmzint inet from" |awk ' { print $7 } ' |cut -d / -f2`


  #check if dmz interface is configured
  if [ "$curdmzint" == "" ] ; then
      #set dmz status to not configured
      dmzintinfo="DMZ not configured"

  else
      dmzintinfo="DMZ IP $curdmzip/$curdmzmask"

  fi
  #return to ADVMEN
  ADVMEN

}


#show arp cache
arpcache() {

  #get interfaces
  curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`

  echo "What interface do you want to see the arp cache for?"
  echo "1=LAN"
  echo "2=WAN"
  echo "3=DMZ"
  echo "Press enter for all interfaces"
  read arpint
  #check arpint
  if [ "$arpint" == "1" ] ; then
      #show arp cache for selected interface
      #set to LAN interface
      echo "Showing arp cache for LAN"
      arp -an |grep $curlanint
      sleep 5

  elif [ "$arpint" == "2" ] ; then
        #set to WAN interface
        echo "Showing arp cache for WAN"
        arp -an |grep $curwanint
        sleep 5

  elif [ "$arpint" == "3" ] ; then
        #set to DMZ interface
        echo "Showing arp cache for DMZ"
        arp -an |grep $curdmzint
        sleep 5

 else
      #show all interfaces
      echo "Showing arp cache for all interfaces"
      arp -an
      sleep 5
  fi

  #return to advanced menu
  ADVMEN

}

routingtable() {

    echo "Do you want to show the IPV4 or IPV6 routing table?"
    echo "1=IPV4"
    echo "2=IPV6"
    read rtans
    #check rtans
    if [ "$rtans" == "1" ] ; then

        #get interfaces
        curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
        curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
        curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`

        echo "What interface do you want to see the routing table for?"
        echo "1=LAN"
        echo "2=WAN"
        echo "3=DMZ"
        echo "Press enter for all interfaces"
        read rtint
        #check arpint
        if [ "$rtint" == "1" ] ; then
            #show routing for selected interface
            #set to LAN interface
            echo "Showing routing table for LAN"
            netstat -rn -f inet |grep $curlanint
            sleep 5

        elif [ "$rtint" == "2" ] ; then
              #set to WAN interface
              echo "Showing routing table for WAN"
              netstat -rn -f inet |grep $curwanint
              sleep 5

        elif [ "$rtint" == "3" ] ; then
              #set to DMZ interface
              echo "Showing routing table for DMZ"
              netstat -rn -f inet |grep $curdmzint
              sleep 5

       else
            #show all interfaces
            echo "Showing routing table for all interfaces"
            netstat -rn -f inet
            sleep 5
        fi

    fi

        #show ipv6 routing table
        if [ "$rtans" == "2" ] ; then

            #get interfaces
            curlanint=`grep lan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
            curwanint=`grep wan= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
            curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`

            echo "What interface do you want to see the routing table for?"
            echo "1=LAN"
            echo "2=WAN"
            echo "3=DMZ"
            echo "Press enter for all interfaces"
            read rtint
            #check rtint
            if [ "$rtint" == "1" ] ; then
                #show routing table for selected interface
                #set to LAN interface
                echo "Showing routing table for LAN"
                netstat -rn -f inet6 |grep $curlanint
                sleep 5

            elif [ "$rtint" == "2" ] ; then
                  #set to WAN interface
                  echo "Showing routing table for WAN"
                  netstat -rn -f inet6 |grep $curwanint
                  sleep 5

            elif [ "$rtint" == "3" ] ; then
                  #set to DMZ interface
                  echo "Showing routing table for DMZ"
                  netstat -rn -f inet6 |grep $curdmzint
                  sleep 5

            else
                  #show all interfaces
                  echo "Showing routing table for all interfaces"
                  netstat -rn -f inet6
                  sleep 5

            fi

        fi

    #return to advanced menu
    ADVMEN

}

#dmz port forward wizard
dmzptfw() {


  #check if system is configured yet
  if [ ! -f /etc/pf.conf ] ; then
      #tell user to configure system first
      echo "Please either run automatic setup from main menu"
      echo "and or assign LAN and WAN interfaces prior to configuring a DMZ"
      sleep 8
      #return to advanced menu
      ADVMEN
  fi

  #check if DMZ interface is already configured
  curdmzint=`grep dmz= /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
  #check curdmzint
  if [ "$curdmzint" == "" ] ; then
        #tell user to setup dmz interface first
        echo "Please configure a DMZ interface first"
        sleep 3
        #return to advanced menu
        ADVMEN
  fi

    #make note of changes
    DMZINT_confdate=`date`

          echo "WARNING THIS WILL OPEN A PORT FROM THE INTERNET TO YOUR DMZ"
          echo "Are you sure about this? yes or no"
          echo "1=no"
          echo "2=yes"
          read pfans

          #check pfans
          if [ "$pfans" == "1" ] ; then
              #return to control panel
              echo "Returning to control panel"
              ADVMEN
          fi

          if [ "$pfans" == "2" ] ; then
              echo "Ok then here we go"
              #get DMZ and WAN interfaces
              curdmzint=`grep dmz /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
              curwanint=`grep wan /etc/pf.conf |sed 's/"//g' |cut -d = -f2`
              #ask for protocol
              echo "what protocol do you want to forward?"
              echo "1=TCP"
              echo "2=UDP"
              read proans
          fi
              #check proans
              if [ "$proans" == "1" ] ; then
                  PROTO="tcp"

              elif [ "$proans" == "2" ] ; then

                  PROTO="udp"

                  #if we get to the else the user mistyped
              else
                echo "Please make sure to type correct number"
                echo "Returning to control panel"
                ADVMEN

              fi

              #ask for destination port number
              echo "what port number?"
              read PORT

              #ask for destination LAN IP
              echo "what DMZ IP do you want this port forwarded to?"
              read DMZIP

              #add port forwarding rule in /etc/pf.conf
              echo "" >>/etc/pf.conf
              echo "#WAN to DMZ port forward created by TKMsense_V0.0.3 on $DMZINT_confdate" >>/etc/pf.conf
              echo "" >>/etc/pf.conf
              echo "pass in on \$wan inet proto $PROTO from any to any port $PORT rdr-to $DMZIP port $PORT keep state" >>/etc/pf.conf
              echo "pass out on \$dmz inet proto $PROTO from any to $DMZIP port $PORT keep state" >>/etc/pf.conf

              #reload pf ruleset
              pfctl -F rules
              pfctl -f /etc/pf.conf

              #return to control panel
              ADVMEN

}
#run dashboard
maincontrol
