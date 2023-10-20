#!/bin/bash

# Set source and destination folders
workdir="/app"
volumedir="/app-volume"

# maybe squip the syncronisation if the env var SKIP_SYNC is set to false
if [ "$SKIP_SYNC" = "true" ]; then
    echo "SKIP_SYNC is set to true, skipping syncronisation..."
    # Run the command
    exec "$@"
    exit 0
fi

starttime=$(date +%s)

# Copy files from the volume to the workdir
# Do not copy dependencies, node_modules, releases and vendor folders
echo "syncing files from $volumedir to $workdir..."
rsync -a --delete --exclude 'dependencies' --exclude 'node_modules' --exclude 'modules' --exclude 'packages' --exclude 'release' --exclude 'releases' --exclude 'vendor' "$volumedir/" "$workdir"

# Get the time difference in seconds
timediff=$(($(date +%s)-$starttime))

echo "Start completed in $timediff seconds"

# Run the command
exec "$@"