#!/bin/bash

set -euo pipefail

# Go through the en.lproj files and throw errors on any issues.
# This is so that we can spot problems early in the development.
function validateEnglishLocalization {
    # It seems that there are bugs in `lproj` command: it does not detect every issue that `discoverlproj` does.
    # This is unfortunate, because it can be run on a specific language.
    # For this reason we have to use `discoverlproj` but, we need to manually exclude all localizations other than Base and en (the latter is the default).
    ignoreLanguagesParameter=""

    for localizationIdentifier in $(find ProtonMail/Resource/Localization -name "*.lproj" | xargs basename -s .lproj | grep -v en); do
        ignoreLanguagesParameter="$ignoreLanguagesParameter --ignore-language $localizationIdentifier"
    done

    xcodeGen/run_with_mint.sh locheck discoverlproj --ignore-missing --treat-warnings-as-errors $ignoreLanguagesParameter ProtonMail/Resource/Localization
}

if ! validateEnglishLocalization; then
    echo "Warnings found in the English localization must be fixed immediately, so we treat them as errors, and fail the build. Please take a look at locheck output above."
    exit 1
fi
