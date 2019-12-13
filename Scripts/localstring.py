import fnmatch
import os
import sys
import re
import fileinput

regex = r"NSLocalizedString\(\"([^)\")]*)\", comment:\s*\"([^\"]*)\"\)"
# test_str = "NSLocalizedString(\"normal att3achments\", comment: \"Title\")NSLocalizedString(\"normal attachm2ents\", Comment: \"Title\")NSLocalizedString(\"normal attachmen1ts\", comment: \"Title\")"

cur_path = os.path.dirname(__file__) 

new_string_file = os.path.dirname(__file__) + "/strings.swift"

output_file = open(new_string_file, "w")
output_file.truncate()

header = "// \r\n \
//  Localization+Constants.swift \r\n\
//  ProtonMail \r\n\
// \r\n\
//  Copyright (c) 2019 Proton Technologies AG \r\n\
// \r\n\
 \r\n\
import Foundation \r\n\
 \r\n\
/// object for all the localization strings, this avoid some issues with xcode 9 import/export \r\n\
class LocalString { \r\n \
\r\n \
"

output_file.write(header)

output_file.write("\r\n")

def get_tree_size(path):
    """Return total size of files in path and subdirs. If
    is_dir() or stat() fails, print an error message to stderr
    and assume zero size (for example, file has been deleted).
    """
    for entry in os.scandir(path):
        try:
            is_dir = entry.is_dir(follow_symlinks=False)
        except OSError as error:
            print('Error calling is_dir():', error, file=sys.stderr)
            continue
        if is_dir:
            get_tree_size(entry.path)
        else:
            try:
                name, file_extension = os.path.splitext(entry.path)
                if file_extension == ".swift" and "Localization+Constants" not in name:
                    print(entry.path)
                    input_file = open(entry.path, "r")
                    for line in input_file:
                        matches = re.finditer(regex, line, re.IGNORECASE)
                        for matchNum, match in enumerate(matches):
                            group = match.groups()[0]
                            output_file.write("/// \"{group}\"\r\n".format(group = group))
                            key = group.lower().replace(" ", "_")

                            # re.sub(match, 'T!!!!!!', line)

                            output_file.write("static let {key} = {matches}\r\n".format(key = key, matches = match.group()))
                            output_file.write("\r\n")
                            # print ("Match {matchNum} was found at {start}-{end}: {match}".format(matchNum = matchNum, start = match.start(), end = match.end(), match = match.group()))
                            # print ("Group {groupNum} found at {start}-{end}: {group}".format(groupNum = groupNum, start = match.start(groupNum), end = match.end(groupNum), group = match.group(groupNum)))
                    entry.stat(follow_symlinks=False).st_size
            except UnicodeDecodeError as error:
                output_file.write(entry.path)
                print('Error calling stat():', error, file=sys.stderr)
            except OSError as error:
                print('Error calling stat():', error, file=sys.stderr)

try:
    get_tree_size(cur_path)
except OSError as error:
    print('Error calling stat():', error, file=sys.stderr)




output_file.write("\r\n")
output_file.write("\r\n")
output_file.write("\r\n")
output_file.write("}")
output_file.close()
