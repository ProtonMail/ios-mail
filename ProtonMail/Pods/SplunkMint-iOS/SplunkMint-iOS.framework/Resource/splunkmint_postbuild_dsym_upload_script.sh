#!/bin/bash

# Copyright 2015 Splunk, Inc.

# Licensed under the Apache License, Version 2.0 (the "License"): you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.


if [[ -z $2 ]]; then
echo "Usage: $0 <API KEY> <API TOKEN>"
exit -1
fi

if [[ ! "${DWARF_DSYM_FOLDER_PATH}" ]]; then
echo "$0 Not in XCode build"
exit -2
fi

if [[ "${EFFECTIVE_PLATFORM_NAME}" == "-iphonesimulator" ]] && [[ "${CONFIGURATION}" == "Debug" ]]; then
echo "Splunk Mint: Skipping upload, simulator or Debug build symbols found"
exit 0
fi

API_KEY=$1
API_TOKEN=$2

TEMP_ZIP_PATH="/tmp/splunk-mint-dsyms"

DSYM_UUIDS=$(xcrun dwarfdump --uuid "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}" | awk '{print $2}' | tr -d '[()]' | tr "\n" "," | sed 's/,$//')

if [[ "${DSYM_UUIDS}" =~ "unsupported" ]]; then
echo "Splunk Mint: Unsupported UUID found. Exiting..."
exit -2
fi;

mkdir -p "${TEMP_ZIP_PATH}"

/bin/rm -f "${TEMP_ZIP_PATH}/*.zip"

# add one more field for primary file ${DWARF_DSYM_FILE_NAME}

cd ${DWARF_DSYM_FOLDER_PATH}

for DIR in $(find . -name "*.dSYM" -maxdepth 1 -type d); do
APPNAME=$(ls -1 ${DIR}/Contents/Resources/DWARF/* | awk -F/ '{print $NF}')
echo "Splunk Mint: Archiving \"${APPNAME}\" to \"${TEMP_ZIP_PATH}/${APPNAME}.zip\""
/usr/bin/zip -j "${TEMP_ZIP_PATH}/${APPNAME}.zip" "${DWARF_DSYM_FOLDER_PATH}/${DIR}/Contents/Resources/DWARF/"*
if [[ ! -f "${TEMP_ZIP_PATH}/${APPNAME}.zip" ]]; then
echo "Splunk Mint: Failed to archive dSYMs for \"${APPNAME}\" to \"${TEMP_ZIP_PATH}\""
/bin/rm -f "${TEMP_ZIP_PATH}/*.zip"
exit -3
fi
CURL_OPTIONS="$CURL_OPTIONS -F ${APPNAME}-file=@\"${TEMP_ZIP_PATH}/${APPNAME}.zip\""
done

APPNAME=$(ls -1 ${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/* | awk -F/ '{print $NF}')
CURL_OPTIONS="$CURL_OPTIONS -F ${APPNAME}-uuids=${DSYM_UUIDS}"

HTTP_RESPONSE=$(echo `curl -w %{http_code} -s --output /dev/null ${CURL_OPTIONS[@]} -H "X-Splunk-Mint-apikey: ${API_KEY}" -H "X-Splunk-Mint-Auth-Token: ${API_TOKEN}" -XPOST https://ios.splkmobile.com/api/v1/upload/symbols`)

if (( ${HTTP_RESPONSE} > 199 )) && (( $HTTP_RESPONSE < 400 )); then
echo "Splunk Mint: Successfully uploaded debug symbols"
else
echo "Splunk Mint: ERROR \"${HTTP_RESPONSE}\" while uploading \"${TEMP_ZIP_PATH}/${APPNAME}.zip\""
/bin/rm -f "${TEMP_ZIP_PATH}/*.zip"
exit -4
fi

/bin/rm -f "${TEMP_ZIP_PATH}/*.zip"

exit 0
