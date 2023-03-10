# For DEBUG and ENTERPRISE configurations, we replace the settings bundle with one to be able to switch environments
if [[ "${CONFIGURATION}" = "Debug" ]]; then
    rm -r "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
    cp -r ${PROJECT_DIR}/ProtonMail/Supporting\ Files/debug/SettingsEnvironment.bundle "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
fi

if [[ "${CONFIGURATION}" = "Enterprise Debug" || "${CONFIGURATION}" = "Enterprise Release" ]]; then
    rm -r "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
    cp -r ${PROJECT_DIR}/ProtonMail/Supporting\ Files/enterprise/SettingsEnvironment.bundle "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Settings.bundle"
fi
