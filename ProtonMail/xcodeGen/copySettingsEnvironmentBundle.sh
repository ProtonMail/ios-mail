CopySettingsEnvironmentBundle

if [ "${CONFIGURATION}" = "Debug" ]; then
    cp -r ${PROJECT_DIR}/ProtonMail/Supporting\ Files/debug/SettingsEnvironment.bundle "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
fi