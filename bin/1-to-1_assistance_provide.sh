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
Starts SSVNC Viewer in reverse listening mode awaiting a connection 
request from an X11VNC Server. 

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

   # Title in the titlebar of YAD window
   WINDOW_TITLE="1-to-1 Assistance"

   # Location of icons
   ICONS=/usr/share/pixmaps
   
   # Message to display in error window
   ERROR_MSG_1="\n This script must be started from \
                \n 1-to-1_assistance.sh \
                \n \
                \n Exiting..."

   # Display an error message
   yad                      \
   --button="OK:1"          \
   --title="$WINDOW_TITLE"  \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_1"

   # Exit the script
   clear
   exit 1
fi



# -----------------------------------------------------------------------------
# Ensure provide mode configuration files exist in the user home file structure
# -----------------------------------------------------------------------------

# When the profile is not present
if [ ! -f $HOME/.vnc/profiles/$PROFILE ]; then
   
   # Ensure the destination directory is present
   mkdir --parents  $HOME/.vnc/profiles
   
   # Put a copy of the profile in place
   cp /etc/skel/.vnc/profiles/$PROFILE  $HOME/.vnc/profiles/$PROFILE
fi

 
yad --title ' Vinagre warning ' \
--window-icon=gtk-about --width=700 --button=gtk-close \
--text ' WARNING: \
 Vinagre forwarded keyboard shortcuts by default to the remote computer \
 and local keyboard shortcuts are deactivated. \
 Closing Vinagre fullscreen mode with F11 only works \
 if under View local keyboard shortcuts are activated. \
\
 IMPORTANT: \
 Please use the key combination "Ctrl+Alt+Backspace", if you are trapped in full screen mode. \
\
 INFO: \
 For a successful vnc reverse connection, “Reverse Connection” must be activated in Vinagre. \
 Under "Removed -> Reversed connections -> Connection" \
 you will also find your public IP for the assistance receiver. \
\ '


# ----------------------------------------------------
# Listen for incoming connection request from a server
# ----------------------------------------------------

# Launch in listening mode
vinagre
