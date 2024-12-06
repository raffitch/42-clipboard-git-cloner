# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    42-lazy-dev-butler.sh                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: rtchaker <rtchaker@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2024/12/06 11:54:30 by rtchaker          #+#    #+#              #
#    Updated: 2024/12/06 11:55:51 by rtchaker         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# Lazy Dev's Clipboard Butler: 
# Why do boring manual work when you can automate it?
# This script listens to your clipboard for Git URLs, clones them, opens them in VS Code,
# and even cleans up after itself when you're done. All you need to do is sit back, copy, and quit!

#!/bin/bash

# Clear the clipboard
echo -n "" | pbcopy
echo "Clipboard cleared."

# Define the folder name
FOLDER_NAME="NEWEVAL"

# Delete the folder if it exists
if [ -d "$FOLDER_NAME" ]; then
    echo "Deleting existing folder '$FOLDER_NAME'..."
    rm -rf "$FOLDER_NAME"
    echo "Folder deleted."
fi

# Launch Chrome in incognito mode and open the specified link
echo "Launching Chrome in incognito mode..."
open -na "Google Chrome" --args --incognito "https://profile.intra.42.fr/"

# Initialize last clipboard content
last_clipboard=""

# Print initial messages
echo "Listening for clipboard changes. Copy a Git clone URL to execute..."
echo "Type 'q' and press Enter at any time to quit."

# Handle graceful exit and cleanup
cleanup() {
    if [ -d "$FOLDER_NAME" ]; then
        echo "Deleting the folder '$FOLDER_NAME' created during the session..."
        rm -rf "$FOLDER_NAME"
        echo "Folder deleted."
    fi
    echo "Exiting the script..."
    exit 0
}
trap cleanup SIGINT

while true; do
    # Get the current clipboard content
    clipboard=$(pbpaste)

    # Check if clipboard content has changed and starts with 'git'
    if [[ "$clipboard" != "$last_clipboard" ]] && [[ "$clipboard" =~ ^git ]]; then
        echo "Detected new Git URL: $clipboard"
        
        # Attempt to clone the repository
        if git clone "$clipboard" "$FOLDER_NAME"; then
            echo "Clone successful. Opening folder in Visual Studio Code..."
            
            # Open the folder in Visual Studio Code
            /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code "$FOLDER_NAME"
            echo "Waiting for new clipboard content. Type 'q' to quit."
        else
            echo "Failed to clone repository."
            while true; do
                read -p "Do you want to retry or quit? (r/q): " choice
                if [[ "$choice" == "q" ]]; then
                    cleanup
                elif [[ "$choice" == "r" ]]; then
                    echo "Retrying... Copy a new Git URL."
                    break
                else
                    echo "Invalid input. Please type 'r' to retry or 'q' to quit."
                fi
            done
        fi

        last_clipboard="$clipboard"
    fi

    # Listen for quit input only once
    read -t 5 -n 1 user_input
    if [[ "$user_input" == "q" ]]; then
        cleanup
    fi

    # Sleep to avoid excessive CPU usage
    sleep 1
done
