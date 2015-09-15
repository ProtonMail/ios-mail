#!/bin/sh
set -e

mkdir -p "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

RESOURCES_TO_COPY=${PODS_ROOT}/resources-to-copy-${TARGETNAME}.txt
> "$RESOURCES_TO_COPY"

XCASSET_FILES=()

realpath() {
  DIRECTORY="$(cd "${1%/*}" && pwd)"
  FILENAME="${1##*/}"
  echo "$DIRECTORY/$FILENAME"
}

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
      echo "ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --reference-external-strings-file --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename \"$1\" .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.framework)
      echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      echo "rsync -av ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      rsync -av "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
      ;;
    *.xcdatamodel)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1"`.mom\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodel`.mom"
      ;;
    *.xcdatamodeld)
      echo "xcrun momc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd\""
      xcrun momc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcdatamodeld`.momd"
      ;;
    *.xcmappingmodel)
      echo "xcrun mapc \"${PODS_ROOT}/$1\" \"${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcmappingmodel`.cdm\""
      xcrun mapc "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename "$1" .xcmappingmodel`.cdm"
      ;;
    *.xcassets)
      ABSOLUTE_XCASSET_FILE=$(realpath "${PODS_ROOT}/$1")
      XCASSET_FILES+=("$ABSOLUTE_XCASSET_FILE")
      ;;
    /*)
      echo "$1"
      echo "$1" >> "$RESOURCES_TO_COPY"
      ;;
    *)
      echo "${PODS_ROOT}/$1"
      echo "${PODS_ROOT}/$1" >> "$RESOURCES_TO_COPY"
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

mkdir -p "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
if [[ "${ACTION}" == "install" ]]; then
  mkdir -p "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  rsync -avr --copy-links --no-relative --exclude '*/.svn/*' --files-from="$RESOURCES_TO_COPY" / "${INSTALL_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
rm -f "$RESOURCES_TO_COPY"

if [[ -n "${WRAPPER_EXTENSION}" ]] && [ "`xcrun --find actool`" ] && [ -n "$XCASSET_FILES" ]
then
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

  # Find all other xcassets (this unfortunately includes those of path pods and other targets).
  OTHER_XCASSETS=$(find "$PWD" -iname "*.xcassets" -type d)
  while read line; do
    if [[ $line != "`realpath $PODS_ROOT`*" ]]; then
      XCASSET_FILES+=("$line")
    fi
  done <<<"$OTHER_XCASSETS"

  printf "%s\0" "${XCASSET_FILES[@]}" | xargs -0 xcrun actool --output-format human-readable-text --notices --warnings --platform "${PLATFORM_NAME}" --minimum-deployment-target "${IPHONEOS_DEPLOYMENT_TARGET}" ${TARGET_DEVICE_ARGS} --compress-pngs --compile "${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
fi
