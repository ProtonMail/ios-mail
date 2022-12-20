if [ $CONFIGURATION = "Debug" ]; then
xcodeGen/run_with_mint.sh LicensePlist --output-path $PRODUCT_NAME/Supporting\ Files/Settings.bundle --prefix Acknowledgements
fi