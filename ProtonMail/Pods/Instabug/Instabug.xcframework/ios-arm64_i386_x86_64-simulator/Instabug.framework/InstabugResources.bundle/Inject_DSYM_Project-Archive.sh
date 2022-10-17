echo "Instabug: Started inject dSYM and bcsymbolmap inside project archive."

Instabug_DSYM_PATH=($(find "${PROJECT_DIR}" -name 'Instabug.framework.dSYM'))
if [ ! "${Instabug_DSYM_PATH}" ]; then
    echo "Instabug: can not find Instabug.framework.dSYM in project directory."
else 
    cp -r "${Instabug_DSYM_PATH}" "${ARCHIVE_DSYMS_PATH}"
    echo "Instabug: Instabug.framework.dSYM successfully copied in project directory."
fi

InstabugCore_DSYM_PATH=($(find "${PROJECT_DIR}" -name 'InstabugCore.framework.dSYM'))
if [ ! "${InstabugCore_DSYM_PATH}" ]; then
echo "Instabug: can not find InstabugCore.framework.dSYM in project directory."
else
cp -r "${InstabugCore_DSYM_PATH}" "${ARCHIVE_DSYMS_PATH}"
echo "Instabug: InstabugCore.framework.dSYM successfully copied in project directory."
fi

find "${PROJECT_DIR}" -name "*.bcsymbolmap" | (while read -r file
do
    cp -r "${file}" "${ARCHIVE_DSYMS_PATH}/../BCSymbolMaps"
done
)
echo "Instabug: Injecting dSYM and bcsymbolmap inside project archive complete."

