//
//  MailboxViewModel+LabelAs.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import PMUIFoundations

// MARK: - Label as functinos
extension MailboxViewModel: LabelAsActionSheetProtocol {
    func handleLabelAsAction(shouldArchive: Bool, currentOptionsStatus: [MenuLabel: PMActionSheetPlainItem.MarkType]) {
        for (label, markType) in currentOptionsStatus {
            if selectedLabelAsLabels
                .contains(where: { $0.labelID == label.location.labelID}) {
                // Add to message which does not have this label
                let messageToApply = selectedMessages.filter({ !$0.contains(label: label.location.labelID )})
                messageService.label(messages: messageToApply,
                                     label: label.location.labelID,
                                     apply: true)
            } else if markType != .dash { // Ignore the option in dash
                let messageToRemove = selectedMessages.filter({ $0.contains(label: label.location.labelID )})
                messageService.label(messages: messageToRemove,
                                     label: label.location.labelID,
                                     apply: false)
            }
        }

        selectedLabelAsLabels.removeAll()

        if shouldArchive {
            var msgToArchive: [Message] = []
            var fromLabels: [String] = []
            for msg in selectedMessages {
                if let fLabel = msg.firstValidFolder() {
                    fromLabels.append(fLabel)
                    msgToArchive.append(msg)
                }
            }
            messageService.move(messages: msgToArchive,
                                from: fromLabels,
                                to: Message.Location.archive.rawValue)
        }
    }

    func updateSelectedLabelAsDestination(menuLabel: MenuLabel?, isOn: Bool) {
        if let label = menuLabel {
            if isOn {
                selectedLabelAsLabels.insert(label.location)
            } else {
                selectedLabelAsLabels.remove(label.location)
            }
        } else {
            selectedLabelAsLabels.removeAll()
        }
    }
}
