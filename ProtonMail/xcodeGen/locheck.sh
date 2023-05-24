#!/bin/bash

set -euo pipefail

function validateLocalizations {
    xcodeGen/run_with_mint.sh locheck discoverlproj --ignore-missing --treat-warnings-as-errors ProtonMail/Resource/Localization
}

if ! validateLocalizations; then
    echo "error: Some localizable strings are not correct. What locheck calls a warning can actually cause a crash in production, so please fix everything that is listed above."
    exit 1
fi
