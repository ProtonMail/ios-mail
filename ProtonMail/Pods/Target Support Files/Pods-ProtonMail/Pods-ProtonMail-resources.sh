#!/bin/sh
set -e

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

case "${TARGETED_DEVICE_FAMILY}" in
  1,2)
    TARGET_DEVICE_ARGS="--target-device ipad --target-device iphone"
    ;;
  1)
    TARGET_DEVICE_ARGS="--target-device iphone"
    ;;
  2)
    TARGET_DEVICE_ARGS="--target-device ipad"
    ;;
  *)
    TARGET_DEVICE_ARGS="--target-device mac"
    ;;
esac

realpath() {
  DIRECTORY="$(cd "${1%/*}" && pwd)"
  FILENAME="${1##*/}"
  echo "$DIRECTORY/$FILENAME"
}

install_resource()
{
  if [[ "$1" = /* ]] ; then
    RESOURCE_PATH="$1"
  else
    RESOURCE_PATH="${PODS_ROOT}/$1"
  fi
  if [[ ! -e "$RESOURCE_PATH" ]] ; then
    cat << EOM
error: Resource "$RESOURCE_PATH" not found. Run 'pod install' to update the copy resources script.
EOM
    exit 1
  fi
  case $RESOURCE_PATH in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc $RESOURCE_PATH --sdk ${SDKROOT} ${TARGET_DEVICE_ARGS}"
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .storyboard`.storyboardc" "$RESOURCE_PATH" --sdk "${SDKROOT}" ${TARGET_DEVICE_ARGS}
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile ${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib $RESOURCE_PATH --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --minimum-deployment-target ${!DEPLOYMENT_TARGET_SETTING_NAME} --output-format human-readable-text --compile "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$RESOURCE_PATH\" .xib`.nib" "$RESOURCE_PATH" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av $RESOURCE_PATH ${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH"`.mom\""
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd\""
      xcrun momc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"$RESOURCE_PATH\" \"${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm\""
      xcrun mapc "$RESOURCE_PATH" "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$RESOURCE_PATH" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE=$(realpath "$RESOURCE_PATH")
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    *)
      echo "$RESOURCE_PATH"
      echo "$RESOURCE_PATH" >> "$RESOURCES_TO_COPY"
      ;;
  esac
}
if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbgcolor.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbgcolor@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbold.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbold@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSScenterjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSScenterjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSclearstyle.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSclearstyle@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSforcejustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSforcejustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh1.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh1@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh2.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh2@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh3.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh3@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh4.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh4@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh5.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh5@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh6.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh6@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSShorizontalrule.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSShorizontalrule@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSimage.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSimage@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSindent.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSindent@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSinsertkeyword.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSinsertkeyword@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSitalic.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSitalic@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSkeyboard.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSkeyboard@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSleftjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSleftjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSlink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSlink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSorderedlist.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSorderedlist@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSoutdent.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSoutdent@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSparagraph.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSparagraph@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSpicker.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSpicker@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSquicklink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSquicklink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSredo.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSredo@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSrightjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSrightjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSstrikethrough.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSstrikethrough@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsubscript.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsubscript@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsuperscript.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsuperscript@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStable.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStable@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStextcolor.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStextcolor@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunderline.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunderline@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSundo.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSundo@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunlink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunlink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunorderedlist.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunorderedlist@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSviewsource.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSviewsource@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/ZSSRichTextEditor.js"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/editor.html"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbgcolor.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbgcolor@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbold.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbold@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSScenterjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSScenterjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSclearstyle.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSclearstyle@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSforcejustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSforcejustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh1.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh1@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh2.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh2@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh3.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh3@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh4.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh4@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh5.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh5@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh6.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh6@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSShorizontalrule.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSShorizontalrule@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSimage.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSimage@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSindent.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSindent@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSinsertkeyword.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSinsertkeyword@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSitalic.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSitalic@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSkeyboard.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSkeyboard@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSleftjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSleftjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSlink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSlink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSorderedlist.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSorderedlist@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSoutdent.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSoutdent@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSparagraph.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSparagraph@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSpicker.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSpicker@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSquicklink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSquicklink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSredo.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSredo@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSrightjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSrightjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSstrikethrough.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSstrikethrough@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsubscript.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsubscript@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsuperscript.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsuperscript@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStable.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStable@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStextcolor.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStextcolor@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunderline.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunderline@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSundo.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSundo@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunlink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunlink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunorderedlist.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunorderedlist@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSviewsource.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSviewsource@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/ZSSRichTextEditor.js"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/editor.html"
fi
if [[ "$CONFIGURATION" == "Distribution" ]]; then
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbgcolor.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbgcolor@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbold.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSbold@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSScenterjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSScenterjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSclearstyle.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSclearstyle@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSforcejustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSforcejustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh1.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh1@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh2.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh2@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh3.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh3@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh4.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh4@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh5.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh5@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh6.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSh6@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSShorizontalrule.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSShorizontalrule@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSimage.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSimage@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSindent.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSindent@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSinsertkeyword.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSinsertkeyword@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSitalic.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSitalic@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSkeyboard.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSkeyboard@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSleftjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSleftjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSlink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSlink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSorderedlist.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSorderedlist@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSoutdent.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSoutdent@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSparagraph.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSparagraph@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSpicker.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSpicker@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSquicklink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSquicklink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSredo.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSredo@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSrightjustify.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSrightjustify@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSstrikethrough.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSstrikethrough@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsubscript.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsubscript@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsuperscript.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSsuperscript@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStable.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStable@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStextcolor.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSStextcolor@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunderline.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunderline@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSundo.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSundo@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunlink.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunlink@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunorderedlist.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSunorderedlist@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSviewsource.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/Images/ZSSviewsource@2x.png"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/ZSSRichTextEditor.js"
  install_resource "../../ZSSRichTextEditor/ZSSRichTextEditor/editor.html"
fi

mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]] && [[ "${SKIP_INSTALL}" == "NO" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "$XCASSET_FILES" ]
then
  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "`realpath $PODS_ROOT`*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${!DEPLOYMENT_TARGET_SETTING_NAME}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
