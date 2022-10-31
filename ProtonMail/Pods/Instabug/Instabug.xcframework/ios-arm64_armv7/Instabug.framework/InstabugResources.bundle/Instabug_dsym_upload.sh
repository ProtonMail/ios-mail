#!/bin/bash
# Copyright 2014 Instabug, Inc. All rights reserved.
#
# Usage:
#   * In the project editor, select your target.
#   * Click "Build Phases" at the top of the project editor.
#   * Click "+" button in the top left corner.
#   * Choose "New Run Script Build Phase."
#   * Uncomment and paste the following script.
#
# --- INVOCATION SCRIPT BEGIN ---
# # SKIP_SIMULATOR_BUILDS=1
# SCRIPT_SRC=$(find "$PROJECT_DIR" -name 'Instabug_dsym_upload.sh' | head -1)
# if [ ! "${SCRIPT_SRC}" ]; then
#   echo "Instabug: Error: script not found. Make sure that you're including Instabug.bundle in your project directory"
#   exit 1
# fi
# source "${SCRIPT_SRC}"
# --- INVOCATION SCRIPT END ---

echo "Instabug: Started uploading dSYM"

# Check for simulator builds
if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" ]; then
  if [ "${SKIP_SIMULATOR_BUILDS}" ] && [ "${SKIP_SIMULATOR_BUILDS}" -eq 1 ]; then
    echo "Instabug: Skipping simulator build"
    exit 0
  fi
fi

# Check if another `ENDPOINT` is provided
if [ ! "${ENDPOINT}" ]; then
    ENDPOINT="https://api.instabug.com/api/sdk/v3/symbols_files"
fi
echo "Instabug: using ENDPOINT=${ENDPOINT}"

# Check to make sure the app token exists
# Objective-C
if [ ! "${APP_TOKEN}" ]; then
    APP_TOKEN=$(grep -r 'Instabug startWithToken:@\"[0-9a-zA-Z]*\"' ./ --include="AppDelegate.m" -m 1 | grep -o '\"[0-9a-zA-Z]*\"' | cut -d "\"" -f 2)
fi
if [ ! "${APP_TOKEN}" ]; then
    APP_TOKEN=$(grep -r 'Instabug startWithToken:@\"[0-9a-zA-Z]*\"' ./ --include=*.{m,h,c,mm} -m 1 | grep -o '\"[0-9a-zA-Z]*\"' | cut -d "\"" -f 2)
fi

# Swift - Instabug.startWithToken(
if [ ! "${APP_TOKEN}" ]; then
    APP_TOKEN=$(grep -r 'Instabug.startWithToken([ ]*\"[0-9a-zA-Z]*\"' ./ -m 1 --include="AppDelegate.swift" | grep -o '\"[0-9a-zA-Z]*\"' | cut -d "\"" -f 2)
fi
if [ ! "${APP_TOKEN}" ]; then
    APP_TOKEN=$(grep -r 'Instabug.startWithToken([ ]*\"[0-9a-zA-Z]*\"' ./ -m 1 --include="*.swift"} | grep -o '\"[0-9a-zA-Z]*\"' | cut -d "\"" -f 2)
fi

# Swift - Instabug.start(withToken:
if [ ! "${APP_TOKEN}" ]; then
    APP_TOKEN=$(grep -r 'Instabug.start(withToken:[ ]*\"[0-9a-zA-Z]*\"' ./ -m 1  --include="AppDelegate.swift" | grep -o '\"[0-9a-zA-Z]*\"' | cut -d "\"" -f 2)
fi
if [ ! "${APP_TOKEN}" ]; then
    APP_TOKEN=$(grep -r 'Instabug.start(withToken:[ ]*\"[0-9a-zA-Z]*\"' ./ -m 1  --include="*.swift" | grep -o '\"[0-9a-zA-Z]*\"' | cut -d "\"" -f 2)
fi

if [ ! "${APP_TOKEN}" ] || [ -z "${APP_TOKEN}" ];then
  echo "Instabug: Error: APP_TOKEN not found. Make sure you've added the SDK initialization line [Instabug startWithToken: invocationEvent:]"
  exit 1
fi
echo "Instabug: found APP_TOKEN=${APP_TOKEN}"

# Check internet connection

echo "Instabug: Checking internet connection.."

CURL_RESPONSE=$(curl 'https://api.instabug.com')

if [[ $CURL_RESPONSE != *"OK"* ]]; then
    echo "Instabug: Error: Failed to connect to api.instabug.com."
    echo "${CURL_RESPONSE}"
    exit 1
else
    echo "Instabug: Device online."
fi

# Create temp directory if not exists
CURRENT_USER=$(whoami| tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]')
TEMP_ROOT="/tmp/Instabug-${CURRENT_USER}"
if [ ! -d "${TEMP_ROOT}" ]; then
mkdir "${TEMP_ROOT}"
fi
TEMP_DIRECTORY="${TEMP_ROOT}/$EXECUTABLE_NAME"
if [ ! -d "${TEMP_DIRECTORY}" ]; then
mkdir "${TEMP_DIRECTORY}"
fi

# Check dSYM file
if [ ! "${DSYM_PATH}" ]; then
  if [ ! "${DWARF_DSYM_FOLDER_PATH}" ] || [ ! "${DWARF_DSYM_FILE_NAME}" ]; then
    echo "Instabug: Error: DWARF_DSYM_FOLDER_PATH or DWARF_DSYM_FILE_NAME not defined"
    exit 1
  fi
  DSYM_PATH=${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
fi
echo "Instabug: found DSYM_PATH=${DSYM_PATH}"

# Check if UUIDs exists
DSYMS_DIR="${TEMP_DIRECTORY}/dSYM"

if [ -d "${DSYMS_DIR}" ]; then
    rm -rf "${DSYMS_DIR}"
fi

mkdir "$DSYMS_DIR"
DSYM_UUIDs_PATH="${TEMP_DIRECTORY}/UUIDs.dat"

# Create temp .dat file to save the output to it
DSYM_UUIDs_TMP_PATH="${TEMP_DIRECTORY}/UUIDs.dat.tmp"
rm -f "${DSYM_UUIDs_TMP_PATH}"

process_dsym_file() {
    file=$1
    UUIDs=$(dwarfdump --uuid "${file}" | cut -d ' ' -f2)
    if [ -f "${DSYM_UUIDs_PATH}" ]; then
        for uuid in $UUIDs
            do
                UUIDTOKEN="${uuid}"-"${APP_TOKEN}"
                if ! grep -w "${UUIDTOKEN}" "${DSYM_UUIDs_PATH}" ; then
                    echo "Instabug: Sending dSYM with UUID: ${uuid}"
                    cp -r "${file}" "${DSYMS_DIR}"
                    echo "${UUIDTOKEN}" >> "${DSYM_UUIDs_TMP_PATH}"
                else
                    echo "Instabug: ${uuid} already uploaded."
                fi
        done
    else
        cp -r "${file}" "${DSYMS_DIR}"
        echo "${UUIDs}$SEPARATOR" >> "${DSYM_UUIDs_TMP_PATH}"
    fi
}

# 1. Process app `.dSYM`
process_dsym_file "$DSYM_PATH"

# 2. Process app's frameworks' `.dSYMs`
if [ ! "${FRAMEWORKS_FOLDER_PATH}" ]; then
    find "${DWARF_DSYM_FOLDER_PATH}" -name "*.dSYM" | while read -r file
    do
        process_dsym_file "$file"
    done
 else
     find "${DWARF_DSYM_FOLDER_PATH}/${FRAMEWORKS_FOLDER_PATH}" -name "*.framework" | while read -r framework
     do
         framework_name="$(basename -- "$framework")"
         framework_dsym="$(find "${DWARF_DSYM_FOLDER_PATH}" -name "${framework_name}.dSYM")"
          if [ ! "${framework_dsym}" ]; then
             echo "Instabug: Cannot find ${framework_name}.dSYM"
          else
              echo "Instabug: found DSYM_PATH=${framework_dsym}"
              process_dsym_file "$framework_dsym"
          fi
     done

fi

DSYM_UUIDs=$(cat "${DSYM_UUIDs_TMP_PATH}")
if [ -z "$DSYM_UUIDs" ]; then
    rm -rf "${DSYMS_DIR}"
    echo "Instabug: No new dSYMs to upload."
    exit 0
fi

# Create dSYM .zip file
DSYM_PATH_ZIP="${TEMP_DIRECTORY}/$DWARF_DSYM_FILE_NAME.zip"
if [ ! -d "$DSYM_PATH" ]; then
  echo "Instabug: Error: dSYM not found: ${DSYM_PATH}"
  exit 1
fi
echo "Instabug: Compressing dSYM file..."
(/usr/bin/zip --recurse-paths --quiet "${DSYM_PATH_ZIP}" "${DSYMS_DIR}") || exit 1

# Upload dSYM
echo "Instabug: Uploading dSYM file..."
STATUS=$(curl -X POST "${ENDPOINT}" --write-out %{http_code} --silent --output /dev/null -F os=iOS -F symbols_file=@"${DSYM_PATH_ZIP}" -F application_token="${APP_TOKEN}")
if [ $STATUS -ne 200 ]; then
  echo "Instabug: Error: dSYM archive not succesfully uploaded with status code: ${STATUS}"
  echo "Instabug: deleting temporary dSYM archive..."
  rm -f "${DSYM_PATH_ZIP}"
  exit 1
fi

# Save UUIDs
echo "${DSYM_UUIDs}" >> "${DSYM_UUIDs_PATH}"

# Remove temp dSYM archive and dSYM DIR
echo "Instabug: deleting temporary dSYM archive..."
rm -f "${DSYM_PATH_ZIP}"
rm -rf "${DSYMS_DIR}"
rm -f "${DSYM_UUIDs_TMP_PATH}"

# Finalize
echo "Instabug: dSYM upload complete."
if [ "$?" -ne 0 ]; then
  echo "Instabug: Error: an error was encountered uploading dSYM"
  exit 1
fi
