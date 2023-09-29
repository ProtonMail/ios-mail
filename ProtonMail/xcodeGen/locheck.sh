#!/bin/bash

set -uo pipefail

xcodeGen/run_with_mint.sh locheck discoverlproj --ignore-missing --treat-warnings-as-errors ProtonMail/Resource/Localization
locheck_exit_code=$?

if ! ( [ $locheck_exit_code == 0 ] || [ $locheck_exit_code == 127 ] ); then
    echo "error: Some localizable strings are not correct. What locheck calls a warning can actually cause a crash in production, so please fix everything that is listed above."
fi

exit $locheck_exit_code
