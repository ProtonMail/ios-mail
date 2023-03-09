# For DEBUG and ENTERPRISE configurations, we replace the settings bundle with one to be able to switch environments
if ! [[ "${CONFIGURATION}" = "Release" ]]; then
    groupContainerIdentifier="group.ch.protonmail.protonmail"
    if [[ "${CONFIGURATION}" = "Enterprise Debug" || "${CONFIGURATION}" = "Enterprise Release" ]]; then
        groupContainerIdentifier="group.com.protonmail.protonmail"
    fi

    rm -r "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
    /usr/libexec/PlistBuddy -c "Set :ApplicationGroupContainerIdentifier $groupContainerIdentifier" ${PROJECT_DIR}/ProtonMail/Supporting\ Files/debug/SettingsEnvironment.bundle/Root.plist
    cp -r ${PROJECT_DIR}/ProtonMail/Supporting\ Files/debug/SettingsEnvironment.bundle "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
fi
