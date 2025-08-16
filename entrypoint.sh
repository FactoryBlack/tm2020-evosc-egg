#!/bin/bash
set -euo pipefail

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2); exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Set proper permissions
if [[ "${EUID}" -eq 0 ]]; then
    # Running as root, switch to container user
    exec su -c "$0 $*" container
fi

# Print Java version
echo "Running on Pterodactyl Wings"

# Replace Pterodactyl placeholders if they exist
if [[ -f ".pteroignore" ]]; then
    rm -f .pteroignore
fi

# Convert all of the "{{VARIABLE}}" parts of the command into the expected shell
# variable format of "${VARIABLE}" before evaluating the string and automatically
# replacing the values.
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | envsubst)

# Display the command we're running in the output, and then execute it with the env
# from the container itself.
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"

# Execute the startup command
exec env ${PARSED}
</merged_code>
