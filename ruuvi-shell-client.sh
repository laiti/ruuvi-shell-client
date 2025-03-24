#!/usr/bin/env bash

# Check if jq is installed.
if ! which jq &> /dev/null; then
	echo "jq is not installed. Exiting..."
	exit 1
fi

# Decimal separator must be a dot.
LC_NUMERIC=C

# Color output commands.
GREEN="$(tput bold)$(tput setaf 2)"
DIM="$(tput setaf 7)"
WHITE="$(tput bold)$(tput setaf 7)"
RED="$(tput bold)$(tput setaf 1)"
RESET="$(tput sgr0)"

# Load settings file if it exists.
[[ -f settings ]] && source settings

# Check if the specified formatter file exists.
if [[ -n "$FORMATTER" && -f "$FORMATTER" ]]; then
    source "$FORMATTER"
else
    echo "Error: Formatter file '$FORMATTER' not found!"
    exit 1
fi

# Define data variable outside of the main loop.
DATA=""

while true; do
	# Get a new payload into a separate variable.
	NEW_DATA=$(curl --silent --fail "$API_URL")
	CURL_EXIT_CODE=$?
	NETWORK_ERROR=0 # Reset network error flag.
	
	# Check if curl command exit code is 0. If not, there's an network error.
	if [ "$CURL_EXIT_CODE" -eq 0 ]; then
		# The reply needs to be non-empty and the data has changed compared to old data. If something isn't right, the old data is used.
		if [ -n "$NEW_DATA" ] && [ "$DATA" != "$NEW_DATA" ]; then
			DATA=$NEW_DATA
		fi
	else
		NETWORK_ERROR=1
	fi
	
	# Clear the screen.
	clear
	
	# Parse the JSON data an extract variables.
	echo "$DATA" | eval "parse_json" | while read -r SENSOR; do
		ID=$(echo "$SENSOR" | jq -r '.id')
		NAME=$(echo "$SENSOR" | jq -r '.tag_name')
		TEMPERATURE=$(echo "$SENSOR" | jq -r '.temperature')
		HUMIDITY=$(echo "$SENSOR" | jq -r '.humidity')
		DATETIME=$(echo "$SENSOR" | jq -r '.datetime')
		VOLTAGE=$(echo "$SENSOR" | jq -r '.voltage')
		BATTERY_LOW=$(echo "$SENSOR" | jq -r '.battery_low')
		
		# If we have an ID, let's try to look up a name from settings.
		NAME="${TAG_NAMES[$ID]:-$NAME}"
		
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
		
		# Handle low battery warning. Try BATTERY_LOW first, then VOLTAGE.
		if { [ "$BATTERY" != null ] && [ "$BATTERY_LOW" = true ]; } ||
			{ [ "$VOLTAGE" != null ] && [ "$(echo "$VOLTAGE < 2.5" | bc -l)" -eq 1 ]; }; then

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
	
	# If there was a network error while getting new data, print a warning.
	if [ "$NETWORK_ERROR" == 1 ]; then
		echo -e "${RED}Network error${RESET}"
	fi
	
	# Sleep.
	sleep $INTERVAL
done
