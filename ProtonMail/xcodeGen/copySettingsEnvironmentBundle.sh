# For DEBUG and Adhoc configurations, we replace the settings bundle with one to be able to switch environments
if [[ "${CONFIGURATION}" = "Debug" || "${CONFIGURATION}" = "Adhoc" ]]; then
    rm -r "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
    cp -r ${PROJECT_DIR}/ProtonMail/Supporting\ Files/debug/SettingsEnvironment.bundle "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
fi
