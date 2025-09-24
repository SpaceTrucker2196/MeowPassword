#!/bin/bash
# MeowPassword launcher script

# Change to the directory containing this script
cd "$(dirname "$0")"

# Run the Swift package
swift run meowpass "$@"