#!/bin/sh

# copy-firebase-config.sh
# This script copies the appropriate GoogleService-Info.plist based on the build configuration

echo "========================================"
echo "Firebase Configuration Copy Script"
echo "========================================"
echo "Current configuration: ${CONFIGURATION}"
echo "Current scheme: ${SCHEME_NAME}"
echo "Project directory: ${PROJECT_DIR}"
echo "Source root: ${SRCROOT}"

# Determine the flavor based on the configuration or scheme name
if [[ "${CONFIGURATION}" == *"Dev"* ]] || [[ "${SCHEME_NAME}" == *"dev"* ]] || [[ "${SCHEME_NAME}" == *"Dev"* ]]; then
    FLAVOR="Dev"
elif [[ "${CONFIGURATION}" == *"Prod"* ]] || [[ "${SCHEME_NAME}" == *"prod"* ]] || [[ "${SCHEME_NAME}" == *"Prod"* ]]; then
    FLAVOR="Prod"
else
    # Default to Dev for debug builds
    if [[ "${CONFIGURATION}" == "Debug" ]]; then
        FLAVOR="Dev"
        echo "No specific flavor found, defaulting to Dev for Debug build"
    else
        FLAVOR="Prod"
        echo "No specific flavor found, defaulting to Prod for Release build"
    fi
fi

echo "Selected flavor: ${FLAVOR}"

# Define source and destination paths
GOOGLE_SERVICE_INFO_SRC="${SRCROOT}/Runner/Firebase/${FLAVOR}/GoogleService-Info.plist"
GOOGLE_SERVICE_INFO_DEST="${SRCROOT}/Runner/GoogleService-Info.plist"

echo "Source file: ${GOOGLE_SERVICE_INFO_SRC}"
echo "Destination: ${GOOGLE_SERVICE_INFO_DEST}"

# Check if source file exists
if [ -f "${GOOGLE_SERVICE_INFO_SRC}" ]; then
    echo "✅ Source file found"
    
    # Remove existing file if it exists
    if [ -f "${GOOGLE_SERVICE_INFO_DEST}" ]; then
        echo "Removing existing GoogleService-Info.plist"
        rm "${GOOGLE_SERVICE_INFO_DEST}"
    fi
    
    # Copy the file
    cp "${GOOGLE_SERVICE_INFO_SRC}" "${GOOGLE_SERVICE_INFO_DEST}"
    
    if [ -f "${GOOGLE_SERVICE_INFO_DEST}" ]; then
        echo "✅ Successfully copied GoogleService-Info.plist for ${FLAVOR} environment"
    else
        echo "❌ Failed to copy GoogleService-Info.plist"
        exit 1
    fi
else
    echo "❌ Error: Source file not found at ${GOOGLE_SERVICE_INFO_SRC}"
    echo "Please ensure you have placed the GoogleService-Info.plist files at:"
    echo "  - ${SRCROOT}/Runner/Firebase/Dev/GoogleService-Info.plist"
    echo "  - ${SRCROOT}/Runner/Firebase/Prod/GoogleService-Info.plist"
    exit 1
fi

echo "========================================"