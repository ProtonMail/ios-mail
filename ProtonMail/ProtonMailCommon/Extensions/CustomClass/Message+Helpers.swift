//
//  Message+Helpers.swift
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
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

extension Message {

    func senderName(replacingEmails: [Email], groupContacts: [ContactGroupVO]) -> String {
        if isSent || draft {
            return allEmailAddresses(replacingEmails, groupContacts: groupContacts)
        } else {
            return displaySender(replacingEmails)
        }
    }

    func displaySender(_ replacingEmails: [Email]) -> String {
        guard let sender = senderContactVO else {
            assert(false, "Sender with no name or address")
            return ""
        }

        // will this be deadly slow?
        let mails = replacingEmails.filter({ $0.email == sender.email })
            .sorted { mail1, mail2 in
                guard let time1 = mail1.contact.createTime,
                      let time2 = mail2.contact.createTime else {
                          return true
                      }
                return time1 < time2
            }
        if mails.isEmpty {
            return sender.name.isEmpty ? sender.email : sender.name
        }
        let contact = mails[0].contact
        return contact.name.isEmpty ? mails[0].name: contact.name
    }

    // Although the time complexity of high order function is O(N)
    // But keep in mind that tiny O(n) can add up to bigger blockers if you accumulate them
    // Do async approach when there is a performance issue
    func allEmailAddresses(_ replacingEmails: [Email],
                           groupContacts: [ContactGroupVO]) -> String {
        var recipientLists = self.recipients
        let groups = recipientLists.filter { !(($0["Group"] as? String) ?? "").isEmpty }
        var groupList: [String] = []
        if !groups.isEmpty {
            groupList = self.getGroupNameLists(groupDict: groups,
                                               groupContacts: groupContacts)
        }
        recipientLists = recipientLists.filter { (($0["Group"] as? String) ?? "").isEmpty }

        let lists: [String] = recipientLists.map { jsonDict in
            let address = (jsonDict["Address"] as? String) ?? ""
            let name = (jsonDict["Name"] as? String) ?? ""
            let email = replacingEmails.first(where: { $0.email == address })
            let emailName = email?.name ?? ""
            let displayName = emailName.isEmpty ? name: emailName
            return displayName.isEmpty ? address: displayName
        }
        let result = groupList + lists
        return result.isEmpty ? "": result.asCommaSeparatedList(trailingSpace: true)
    }

    private func getGroupNameLists(groupDict: [[String: Any]], groupContacts: [ContactGroupVO]) -> [String] {
        var groupDict = groupDict
        var nameList: [String] = []
        while !groupDict.isEmpty {
            let groupName = (groupDict[0]["Group"] as? String) ?? ""
            let group = groupDict.filter { ($0["Group"] as? String) == groupName }
            let groupLabel = groupContacts.first(where: { $0.contactTitle == groupName })
            let count = groupLabel?.contactCount ?? 0
            let name = "\(groupName) (\(group.count)/\(count))"
            nameList.append(name)
            groupDict = groupDict.filter { ($0["Group"] as? String) != groupName }
        }
        return nameList
    }
}
