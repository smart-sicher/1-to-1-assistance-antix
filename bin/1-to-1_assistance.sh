#!/bin/bash


# Capture the name of the script
PROGNAME=${0##*/}

# Set the version number
PROGVERSION=1.2



# --------------------
# Help and Information
# --------------------

# When requested show information about script
if [[ "$1" = '-h' ]] || [[ "$1" = '--help' ]]; then

# Display the following block
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Creates an encrypted connection between two systems and enables the
desktop of one system to be controlled from the other one.

Usage: 
   $PROGNAME [options]

Options:
   -h  --help        Show this output

Summary:
   A system may perform either of two roles:
   * Receive assistance from someone else
   * Provide assistance to someone else
   The receiver allows their local desktop to be shared.  
   The provider is allowed to share the remote desktop.
   Both receiver and provider see the same desktop on their screens.
   
   Receiving assistance does not require any changes to be made to the
   firewall/router of the local network.
   
   Providing assistance across a local network does not require any 
   changes to be made to the firewall/router of the local network.
 
   Providing assistance across the internet requires two ports in the
   firewall/router of the local network to be forwarded to the provider
   system:
   * 5500 (listens for a connection request from the receiver system)
   * 5900 (conducts the desktop sharing session)

   If the provider system is also running an active local firewall it 
   must be configured to allow connections on the above ports.
   
   Reverse SSL is used to automatically establish an encrypted connection
   between the receiver and provider systems.  A desktop sharing (VNC)
   session is then automatically started with all traffic passing within
   the encrypted tunnel.
   
Configuration:
   In receive mode the configuration file is:
   /home/USERNAME/.1-to-1_assistance_receive_rc
   
   In provide mode the configuration files are:
   /home/USERNAME/.ssvnc
   /home/USERNAME/.vnc/profiles/1-to-1_assistance_provide.vnc
   
Environment:
   The script works in a GUI (X) environment. 
   
Requires:
   1-to-1_assistance_receive.sh, 1-to-1_assistance_provide.sh
   vinagre, x11vnc, bash, flock, grep, sleep, tail, unxrandr, xrandr, yad

References:
   Two excellent works by Karl J. Runge
   http://www.karlrunge.com/x11vnc/ssvnc.html
   http://www.karlrunge.com/x11vnc/

end-of-messageblock
   exit 0
fi



# ---------------
# Static settings
# ---------------

# Location of the lock file used to ensure only a single instance of the script is run
LOCK_FILE=/tmp/1-to-1_assistance.lock

# Title in the titlebar of YAD windows
WINDOW_TITLE="1-to-1 Assistance"

# Location of icons
ICONS=/usr/share/pixmaps

# Location of log file
LOG=$HOME/.1-to-1_assistance_receive.log

# Location of configuration file for x11vnc server
CONFIG=$HOME/.1-to-1_assistance_receive_rc

# Location of profile file for ssvnc viewer
PROFILE=1-to-1_assistance_provide.vnc




# --------------------
# Single instance lock
# --------------------

# Create the lock file and remove it when the script finishes
exec 9> $LOCK_FILE
trap "rm -f $LOCK_FILE" 0

# When a subsequent instance of the script is started
if ! flock -n 9 ; then

   # ----- Inform user script already running -----

   # Message to display in error window
   ERROR_MSG_1="\n $WINDOW_TITLE is already running. \
                \n Only one instance at a time is allowed. \
                \n \
                \n Exiting..."

   # Display error message
   yad                             \
   --button="OK:1"                 \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_1"
 
   # Exit the script
   clear
   exit 1     
fi


yad --html --browser --uri=http://aika.bplaced.net/1-to-1_vnc-help/ --width=780 --height=580 \
--window-icon=gtk-about \
--button=gtk-close \
--text ' Use 1-to-1 VNC online help ? '


# -----------------------------
# Selection of operational mode
# -----------------------------

# Question and guidance to display
MESSAGE_1="\n Which one? \
           \n \
           \n 1. Receive assistance from somone else \
           \n \
           \n 2. Provide assistance to someone else  \
           \n \
           \n \
           \n"


# Obtain desired mode of operation
   # Display the mode options
   yad                                      \
   --center                                 \
   --width=0                                \
   --height=0                               \
   --timeout-indicator="bottom"             \
   --timeout="10"                           \
   --buttons-layout=center                  \
   --button="Receive":0                     \
   --button="Provide":3                     \
   --button="gtk-cancel":1                  \
   --title="$WINDOW_TITLE"                  \
   --image="$ICONS/questionmark_yellow.png" \
   --text="$MESSAGE_1"      

   # Capture which button was selected
   EXIT_STATUS=$?

   # Check whether user cancelled or closed the window and if so exit
   [[ "$EXIT_STATUS" = "1" ]] || [[ "$EXIT_STATUS" = "252" ]] && exit 1
     
   # Capture which action was requested
   ACTION=$EXIT_STATUS


# Launch selected operational mode 
case $ACTION in
   0)  # Receive was selected
       # Start the required script
       . 1-to-1_assistance_receive.sh
       ;;
   3)  # Provide was selected
       # Start the required script
       . 1-to-1_assistance_provide.sh
       ;;
   70) # Receive was selected via timeout 
       # Start the required script
       . 1-to-1_assistance_receive.sh
       ;;
   *)  # Otherwise
       exit 1        
       ;;
esac

exit



