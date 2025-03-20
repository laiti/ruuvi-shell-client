#!/usr/bin/env bash

# Check if jq is installed.
if ! which jq &> /dev/null; then
	echo "jq is not installed. Exiting..."
	exit 1
fi

# Color output commands.
GREEN="$(tput bold)$(tput setaf 2)"
DIM="$(tput setaf 7)"
WHITE="$(tput bold)$(tput setaf 7)"
RED="$(tput bold)$(tput setaf 1)"
RESET="$(tput sgr0)"

# Load settings file
source settings

# Do initial request.
DATA=$(curl -s "$API_URL")

while true; do
	# Clear the screen.
	clear
	
	# Parse the JSON data an extract variables.
	echo "$DATA" | jq -c '.[]' | while read -r SENSOR; do
		NAME=$(echo "$SENSOR" | jq -r '.tag_name')
		TEMPERATURE=$(echo "$SENSOR" | jq -r '.temperature')
		HUMIDITY=$(echo "$SENSOR" | jq -r '.humidity')
		DATETIME=$(echo "$SENSOR" | jq -r '.datetime')
		BATTERY_LOW=$(echo "$SENSOR" | jq -r '.battery_low') # For future.
		
		# Round values to 2 decimals
		TEMPERATURE=$(printf "%.2f" $TEMPERATURE)
		HUMIDITY=$(printf "%.2f" $HUMIDITY)
		
		# Calculate time difference.
		CURRENT_TIME=$(date -u +%s)
		SENSOR_TIME=$(date -d "$DATETIME" +%s)
		
		# Calculate time difference.
		SECONDS_AGO=$((CURRENT_TIME - SENSOR_TIME))
		
		# Hacky "Updated N ago".
		if [[ SECONDS_AGO -lt 60 ]]; then
			UPDATED="${SECONDS_AGO} seconds ago"
		elif [[ SECONDS_AGO -lt 3600 ]]; then
			UPDATED="$((SECONDS_AGO / 60)) minutes ago"
		elif [[ SECONDS_AGO -lt 86400 ]]; then
			UPDATED="$((SECONDS_AGO / 3600)) hours ago"
		else
			UPDATED="$((SECONDS_AGO / 86400)) days ago"
		fi
		
		# --- Displaying ---
		
		# Handle low battery warning.
		if [[ $BATTERY_LOW = "true" ]]; then
			NAME="${NAME} ${RESET}${RED}Battery low${RESET}"
		fi
		
		# Add "+" into positive temperature.
		if [ "$(echo "$TEMPERATURE > 0" | bc -l)" -eq 1 ]; then
			TEMPERATURE="+${TEMPERATURE}"
		fi
		
		# Display the stuff.
		echo -e "${GREEN}${NAME}${RESET}"
		echo -e "${WHITE}${TEMPERATURE}°C ${WHITE}${HUMIDITY}%${RESET}"
		echo -e "${DIM}Updated: ${UPDATED}${RESET}"
		echo ""
	done
	
	# Sleep.
	sleep $INTERVAL
	
	# Get a new payload into a separate variable.
	NEW_DATA=$(curl -s "$API_URL")
	
	# Check if curl command exit code is 0 and reply non-empty.
	if [ $? -eq 0 ] && [ -n $NEW_DATA ]; then
		# Update original variable so that we don't overwrite it with empty, thus keeping the original data until new one comes in.
		DATA=$NEW_DATA
	fi
done
