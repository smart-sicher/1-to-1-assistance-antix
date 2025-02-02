#!/bin/bash

# Capture the name of the script
PROGNAME=${0##*/}

# Set the version number
PROGVERSION=1.3



# --------------------
# Help and Information
# --------------------

# When requested show information about script
if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then

# Display the following block
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Starts X11VNC Server in a mode prepared to make a connection request to
an SSVNC Viewer that is waiting in reverse listening mode.

Usage: 
   $PROGNAME [options]
   Note: must be sourced from 1-to-1_assistance.sh

Options:
   -h, --help     Show this output

Summary:
   Refer to 1-to-1_assistance.sh
   
Configuration:
   Refer to 1-to-1_assistance.sh
      
Environment:
   Refer to 1-to-1_assistance.sh
      
Requires:
   Refer to 1-to-1_assistance.sh

end-of-messageblock
   exit 0
fi



# ---------------------
# Inherit configuration
# ---------------------
   
# When this script is not being sourced
if [ "$0" = "$BASH_SOURCE" ]; then

   # Title in the titlebar of Dialog/YAD window
   WINDOW_TITLE="1-to-1 Assistance"
   
   # Location of icons
   ICONS=/usr/share/pixmaps
   
   # Message to display in error window
   ERROR_MSG_1="\n This script must be started from \
                \n 1-to-1_assistance.sh \
                \n \
                \n Exiting..."

   # Display an error message
   yad                             \
   --button="OK:1"                 \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_1"

   # Exit the script
   clear
   exit 1
fi



# -----------------------------------------------------------------------------
# Ensure receive mode configuration file exists in the user home file structure
# -----------------------------------------------------------------------------

# When the settings for the X11VNC Server is not present
if [ ! -f $HOME/.1-to-1_assistance_receive_rc ]; then
   
   # Put a copy of the server settings in place
   cp /etc/skel/.1-to-1_assistance_receive_rc  $HOME/.1-to-1_assistance_receive_rc
   
   else
   
   cp /etc/skel/.1-to-1_assistance_receive_rc_  $HOME/.1-to-1_assistance_receive_rc
fi



# ----------------------------
# Desktop geometry pre-session
# ----------------------------

# Question and guidance to display
MESSAGE_1="\n X11VNC-server screen resolution? \
           \n This will not change your own screen resolution. \
           \n \
           \n 1. 1280x720 \
           \n 1280x720 fits completely on the provider desktop. \
           \n \
           \n 2. 1360x768 \
           \n 1360x768 might be too big for the provider. \
           \n \
           \n 3. screen resolution not adjusted \
           \n 1280x720 is selected via timeout. \
           \n \
           \n"


# Obtain desired desktop size mode for the session
   # Display the size mode options
   yad                                      \
   --center                                 \
   --width=0                                \
   --height=0                               \
   --timeout-indicator="bottom"             \
   --timeout="30"                           \
   --buttons-layout=center                  \
   --button="1280x720":0                    \
   --button="1360x768":3                    \
   --button="gtk-cancel":1                  \
   --title="$WINDOW_TITLE"                  \
   --image="$ICONS/questionmark_yellow.png" \
   --text="$MESSAGE_1"      

   # Capture which button was selected
   EXIT_STATUS=$?

   # Check whether user cancelled or closed the window and if so exit
   [ "$EXIT_STATUS" = "1" ] || [ "$EXIT_STATUS" = "252" ] && exit 1
     
   # Capture which action was requested
   ACTION=$EXIT_STATUS


# Set selected desktop size mode indicator
case $ACTION in
   0)  # 1280x720 was selected
       DESKTOP_SIZE_MODE=1280x720
       ;;
   3)  # 1360x768 was selected
       DESKTOP_SIZE_MODE=1360x768
       ;;
   70) # 1280x720 was selected via timeout 
       DESKTOP_SIZE_MODE=1280x720
       ;;
   *)  # Otherwise
       exit 1        
       ;;
esac


# ---------------------------
# Desktop geometry in session
# ---------------------------

if [ "$DESKTOP_SIZE_MODE" = "1280x720" ]; then

   # set X11VNC_GEOMETRY settings
   X11VNC_GEOMETRY="-geometry 1280x720"
   else
   X11VNC_GEOMETRY="-geometry 1360x768"
fi


# ---------------------------
# Connect to listening viewer
# ---------------------------

# Create reverse vnc connection with password
while [ "$VNC_CONNECTION_STATUS" = "" ]
do
   # Message to display in the password input window
   LABEL_MSG_1=" Insert the vnc password "
   
   # Display a window in which to input the address of the viewer system
   VNC_PASSWORD=$(yad                          \
                      --center                     \
                      --entry                      \
                      --entry-label="$LABEL_MSG_1" \
                      --buttons-layout="center"    \
                      --title="$WINDOW_TITLE")
   
   # Capture which button was selected
   EXIT_STATUS=$?

   # Check whether user cancelled or closed the window and if so exit
   [ "$EXIT_STATUS" = "1" ] || [ "$EXIT_STATUS" = "252" ] && exit 1
                    
   # Request a password for x11vnc server
   x11vnc -storepasswd $VNC_PASSWORD ~/.vnc/passwd
   
   # Message to display in the address input window
   LABEL_MSG_2=" IP Address of 1-to-1 Assistance Provider "
   
   # Display a window in which to input the address of the viewer system
   PROVIDER_ADDRESS=$(yad                          \
                      --center                     \
                      --entry                      \
                      --entry-label="$LABEL_MSG_2" \
                      --buttons-layout="center"    \
                      --title="$WINDOW_TITLE")
   
   # Capture which button was selected
   EXIT_STATUS=$?

   # Check whether user cancelled or closed the window and if so exit
   [ "$EXIT_STATUS" = "1" ] || [ "$EXIT_STATUS" = "252" ] && exit 1
                    
   # Request a connection to the viewer system
   x11vnc -rc $CONFIG -connect_or_exit $PROVIDER_ADDRESS $X11VNC_GEOMETRY -rfbauth ~/.vnc/passwd -o $LOG
   
   # Pause to enable the log to be updated, then check whether connection was successfully established
   sleep 30
   VNC_CONNECTION_STATUS=$(grep "reverse_connect: turning on" $LOG)
   
   # When the conection request was successful
   if [ "$VNC_CONNECTION_STATUS" != "" ] ; then
      break
      
      # When the conection request was unsuccessful
      else
         # Message to display in error window
         ERROR_MSG_2="\n Unable to make a connection to \
                      \n $PROVIDER_ADDRESS \
                      \n "
      
         # Display an error message
         yad                             \
         --center                        \
         --timeout-indicator="bottom"    \
         --timeout="5"                   \
         --buttons-layout=center         \
         --button="OK:1"                 \
         --title="$WINDOW_TITLE"         \
         --image="$ICONS/cross_red.png"  \
         --text="$ERROR_MSG_2"
   fi
done

   
# ---------------------------------------
# Acceptance of connected session request
# ---------------------------------------

# Wait until the user accepts or refuses the session request or it is timed out
while [ "$SESSION_STATUS_ACCEPTED" = "" ] && [ "$SESSION_STATUS_REFUSED" = "" ]
do
   sleep 1

   # Increment the timeout counter and check if the limit is reached
   COUNTER_TIMEOUT=$(expr $COUNTER_TIMEOUT + 1)
   if [ $COUNTER_TIMEOUT = 40 ]; then
      break
   fi

   # Obtain the status of the session request
   SESSION_STATUS_ACCEPTED=$(grep 'accept_client: popup accepted:' $LOG)
   SESSION_STATUS_REFUSED=$(grep 'denying client: accept_cmd="popup"' $LOG)
done


# When the session was refused
if [ "$SESSION_STATUS_REFUSED" != "" ]; then
   exit 1
fi


# When the session was not accepted due to the timeout limit being reached
if [ "$SESSION_STATUS_ACCEPTED" = "" ]; then

   # Message to display in error window
   ERROR_MSG_3="\n Timeout limit reached \
                \n Session was not accepted in time \
                \n \
                \n Exiting..."

   # Display an error message
   yad                             \
   --center                        \
   --buttons-layout=center         \
   --button="OK:1"                 \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_3"
       
   exit 1
fi


# Wait for the session to be closed
while [ "$SESSION_STATUS_CLOSED" = "" ]
   do
   sleep 3
         
   # Check whether the session has finished
   SESSION_STATUS_CLOSED=$(tail $LOG | grep "viewer exited")
   done
   
yad --title ' Session closed ' \
--window-icon=gtk-about --width=700 --button=gtk-close \
--text ' INFO: \
 The VNC session was disconnected because the VNC viewer was closed. \
\ '

