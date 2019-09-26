#!/usr/bin/env python

#
# xliff-export.py l10n-repository export-directory
#
# Convert the l10n repository from the following format:
#
#  en/firefox-ios.xliff
#  fr/firefox-ios.xliff
#
# To the following format:
#
#  Client/en-US.lproj/Localizable.strings
#  Client/fr.lproj/Localizable.strings
#  ShareTo/en-US.lproj/ShareTo.strings
#  ShareTo/fr.lproj/ShareTo.strings
#
# For any Info.plist file in the xliff, we generate a InfoPlist.strings.
#

#Credits: https://github.com/mozilla-mobile/ios-l10n-scripts

import argparse
import glob
import os
import sys

from lxml import etree

NS = {'x':'urn:oasis:names:tc:xliff:document:1.2'}

# Files we are interested in. It would be nice to not hardcode this but I'm not totally sure how yet.
FILES = [
    "ProtonMail/Localizable.strings",
    "ProtonMail/PasswordExtension.strings",
    "ProtonMail/InfoPlist.strings",
]

# Because Xcode is unpredictable. See bug 1162510 - Sync.strings are not imported
FILENAME_OVERRIDES = {
    "ProtonMail/Base.lproj/Localizable.strings" : "ProtonMail/Localizable.strings",
    "ProtonMail/en.lproj/Localizable.strings" : "ProtonMail/Localizable.strings",
    "ProtonMail/Base.lproj/InfoPlist.strings" : "ProtonMail/InfoPlist.strings",
    "ProtonMail/en.lproj/InfoPlist.strings" : "ProtonMail/InfoPlist.strings",
    "ProtonMail/Base.lproj/PasswordExtension.strings" : "ProtonMail/PasswordExtension.strings",
    "ProtonMail/en.lproj/PasswordExtension.strings" : "ProtonMail/PasswordExtension.strings",
}

# Because Xcode can't handle strings that need to live in two
# different bundles, we also duplicate some files.(For example
# SendTo.strings is needed both in the main app and in the SendTo
# extension.) See bug 1234322
#
# This is not ideal - but we currently have no good way to extract just the
# strings that these extensions need. This copies all strings from the main
# app's Localizable.strings into the extension bundles. This means the app
# will grow in size a few 100KB. We should really add a filter function to
# this list to limit the number of copied strings.

FILES_TO_DUPLICATE = {
    "Client/Localizable.strings": [
        "Extensions/ShareTo/Localizable.strings",
        "Extensions/NotificationService/Localizable.strings"
    ],
    "Client/3DTouchActions.strings": [
        "Extensions/ShareTo/3DTouchActions.strings"
    ]
}

def export_xliff_file(file_node, export_path, target_language):
    directory = os.path.dirname(export_path)
    if not os.path.exists(directory):
        os.makedirs(directory)
    with open(export_path, "wb") as fp:
        for trans_unit_node in file_node.xpath("x:body/x:trans-unit", namespaces=NS):
            trans_unit_id = trans_unit_node.get("id")
            targets = trans_unit_node.xpath("x:target", namespaces=NS)

            if trans_unit_id is not None and len(targets) == 1 and targets[0].text is not None:
                notes = trans_unit_node.xpath("x:note", namespaces=NS)
                if len(notes) == 1:
                    line = u"/* %s */\n" % notes[0].text
                    fp.write(line.encode("utf8"))
                source_text = trans_unit_id.replace('"', '\"')
                source_text = source_text.replace('\"', '\\"')
                target_text = targets[0].text.replace('"', '\"')
                target_text = target_text.replace('\"', '\\"')
                line = u"\"%s\" = \"%s\";\n\n" % (source_text, target_text)
                fp.write(line.encode("utf8"))

    # Export fails if the strings file is empty. Xcode probably checks
    # on file length vs read error.
    contents = open(export_path).read()
    if len(contents) == 0:
        os.remove(export_path)

def original_path(root, target, original):
    dir,file = os.path.split(original)
    if file == "Info.plist":
        file = "InfoPlist.strings"
    lproj = "%s.lproj" % target_language
    path = dir + "/" + lproj + "/" + file 
    return path

if __name__ == "__main__":

    # parser = argparse.ArgumentParser()
    # parser.add_argument("import_root", help="Path to folder including subfolders for all locales")
    # parser.add_argument("export_root", help="Path to folder used to export .strings files")
    # parser.add_argument("--ignore-errors", help="Ignore parsing errors in localized XLIFF files", action="store_true")
    # args = parser.parse_args()

    # if not os.path.isdir(args.import_root):
    #     print("import path does not exist or is not a directory")
    #     sys.exit(1)

    # if not os.path.isdir(args.export_root):
    #     print("export path does not exist or is not a directory")
    #     sys.exit(1)

    for xliff_path in glob.glob("/Users/Yanfeng/Documents/ProtonMailGit/protonmail_ios/Scripts/xliff/" + "*.xliff"):
        print("Exporting {}".format(xliff_path))
        with open(xliff_path) as fp:
            try:
                tree = etree.parse(fp)
                root = tree.getroot()
            except Exception as e:
                print("ERROR: Can't parse file %s" % xliff_path)
                print(e)
                if not args.ignore_errors:
                    sys.exit(1)

            # Make sure there are <file> nodes in this xliff file.
            file_nodes = root.xpath("//x:file", namespaces=NS)
            if len(file_nodes) == 0:
                print("  ERROR: No translated files. Skipping.")
                continue

            # Take the target language from the first <file>. Not sure if that
            # is a bug in the XLIFF, but in some files only the first node has
            # the target-language set.
            target_language = file_nodes[0].get('target-language')
            if not target_language:
                print("  ERROR: Missing target-language. Skipping.")
                continue

            # Export each <file> node as a separate strings file under the
            # export root.
            for file_node in file_nodes:
                original = file_node.get('original')
                original = FILENAME_OVERRIDES.get(original, original)
                if original in FILES:
                    # Because we have strings files that need to live in multiple bundles
                    # we build a list of export_paths. Start with the default.
                    export_paths = [original_path("", target_language, original)]
                    for extra_copy in FILES_TO_DUPLICATE.get(original, []):
                        export_path = original_path(args.export_root, target_language, extra_copy)
                        export_paths.append(export_path)
                    for export_path in export_paths:
                        export_path = "/Users/Yanfeng/Documents/ProtonMailGit/protonmail_ios/Scripts/out/" + export_path
                        print("  Writing {} to {}".format(original, export_path))
                        export_xliff_file(file_node, export_path, target_language)
