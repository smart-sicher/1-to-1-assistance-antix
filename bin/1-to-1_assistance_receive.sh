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
if [[ "$0" = "$BASH_SOURCE" ]]; then

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
if [[ ! -f $HOME/.1-to-1_assistance_receive_rc ]]; then
   
   # Put a copy of the server settings in place
   cp /etc/skel/.1-to-1_assistance_receive_rc  $HOME/.1-to-1_assistance_receive_rc
fi



# ----------------------------
# Desktop geometry pre-session
# ----------------------------

# Question and guidance to display
MESSAGE_1="\n Which one? \
           \n \
           \n 1. Resize my desktop \
           \n     Your desktop will fit entirely in the Provider desktop. \
           \n     This automatically adjusts your screen resolution \
           \n     and restores it at the end of the 1-to-1 session. \
           \n \
           \n 2. Do not resize my desktop \
           \n     Your desktop might be too big for the Provider. \
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
   --button="Resize:0"                      \
   --button="Unchanged":3                   \
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


# Set selected desktop size mode indicator
case $ACTION in
   0)  # Resize was selected
       DESKTOP_SIZE_MODE=resize
       ;;
   3)  # Unchanged was selected
       DESKTOP_SIZE_MODE=unchanged
       ;;
   70) # Resize was selected via timeout 
       DESKTOP_SIZE_MODE=resize
       ;;
   *)  # Otherwise
       exit 1        
       ;;
esac


# When resize of desktop was requested
if [[ "$DESKTOP_SIZE_MODE" = "resize" ]]; then

   # Capture the current desktop settings
   DESKTOP_ANTE_SESSION=$(unxrandr 2>/dev/null)
   
   # Create from the captured settings those to use in the session
   SEARCH="--mode ????x????"
   SUBSTITUTE="--mode 800x600 "
   DESKTOP_IN_SESSION=${DESKTOP_ANTE_SESSION//$SEARCH/$SUBSTITUTE}
fi



# ---------------------------
# Connect to listening viewer
# ---------------------------

# Ensure an encryted tunnel is operating
while [[ "$SSL_CONNECTION_STATUS" = "" ]]
do
   # Message to display in the address input window
   LABEL_MSG_1=" IP Address of 1-to-1 Assistance Provider "
   
   # Display a window in which to input the address of the viewer system
   PROVIDER_ADDRESS=$(yad                          \
                      --center                     \
                      --entry                      \
                      --entry-label="$LABEL_MSG_1" \
                      --buttons-layout="center"    \
                      --title="$WINDOW_TITLE")
   
   # Capture which button was selected
   EXIT_STATUS=$?

   # Check whether user cancelled or closed the window and if so exit
   [[ "$EXIT_STATUS" = "1" ]] || [[ "$EXIT_STATUS" = "252" ]] && exit 1
                    
   # Request a connection to the viewer system
   x11vnc -connect_or_exit $PROVIDER_ADDRESS -rfbauth ~/.vnc/passwd -o $LOG
   
   # Pause to enable the log to be updated, then check whether connection was successfully established
   sleep 3
   SSL_CONNECTION_STATUS=$(grep "SSL_connect() succeeded" $LOG)
   
   # When the conection request was successful
   if [[ "$SSL_CONNECTION_STATUS" != "" ]] ; then
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
while [[ "$SESSION_STATUS_ACCEPTED" = "" ]] && [[ "$SESSION_STATUS_REFUSED" = "" ]]
do
   sleep 1

   # Increment the timeout counter and check if the limit is reached
   COUNTER_TIMEOUT=$(expr $COUNTER_TIMEOUT + 1)
   if [[ $COUNTER_TIMEOUT = 40 ]]; then
      break
   fi

   # Obtain the status of the session request
   SESSION_STATUS_ACCEPTED=$(grep 'accept_client: popup accepted:' $LOG)
   SESSION_STATUS_REFUSED=$(grep 'denying client: accept_cmd="popup"' $LOG)
done


# When the session was refused
if [[ "$SESSION_STATUS_REFUSED" != "" ]]; then
   exit 1
fi


# When the session was not accepted due to the timeout limit being reached
if [[ "$SESSION_STATUS_ACCEPTED" = "" ]]; then

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



# ---------------------------
# Desktop geometry in session
# ---------------------------

# When a resize of the desktop was requested
if [[ "$DESKTOP_SIZE_MODE" = "resize" ]]; then

   # Resize the desktop    
   $DESKTOP_IN_SESSION 2>/dev/null
fi
   


# -----------------------------
# Desktop geometry post session
# -----------------------------

# When the desktop was resized for the duration of the session
if [[ "$DESKTOP_SIZE_MODE" = "resize" ]]; then

   # Wait for the session to be closed
   while [[ "$SESSION_STATUS_CLOSED" = "" ]]
   do
         sleep 2
         
         # Check whether the session has finished
         SESSION_STATUS_CLOSED=$(tail $LOG | grep "killing gui_pid")
   done
   
   # Restore the pre-session desktop settings
   $DESKTOP_ANTE_SESSION 2>/dev/null
fi
