//
//  MailboxViewModel+MoveTo.swift
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

// MARK: - Move to functions
extension MailboxViewModel: MoveToActionSheetProtocol {
    var labelId: String {
        return labelID
    }

    func handleMoveToAction() {
        guard let destination = selectedMoveToFolder else { return }
        let msgs = selectedMessages.filter { $0.firstValidFolder() != nil }

        var fLabels = [String]()
        for msg in msgs {
            let flable = msg.firstValidFolder() ?? Message.Location.inbox.rawValue
            let id = msg.selfSent(labelID: flable) ?? flable
            fLabels.append(id)
        }

        messageService.move(messages: msgs,
                            from: fLabels,
                            to: destination.location.labelID,
                            queue: true)
        selectedMoveToFolder = nil
    }

    func updateSelectedMoveToDestination(menuLabel: MenuLabel?, isOn: Bool) {
        selectedMoveToFolder = isOn ? menuLabel : nil
    }
}
