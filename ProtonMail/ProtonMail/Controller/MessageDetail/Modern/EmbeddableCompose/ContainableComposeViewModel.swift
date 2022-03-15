//
//  EditorViewModel.swift
//  ProtonMail - Created on 19/04/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import UIKit

class ContainableComposeViewModel: ComposeViewModelImpl {
    @objc internal dynamic var contentHeight: CGFloat = 0.1
    private let kDefaultAttachmentFileSize: Int = 25 * 1000 * 1000 // 25 mb

    func parse(mailToURL: URL) {
        guard let mailToData = mailToURL.parseMailtoLink() else { return }

        mailToData.to.forEach { (recipient) in
            self.addToContacts(ContactVO(name: recipient, email: recipient))
        }

        mailToData.cc.forEach { (recipient) in
            self.addCcContacts(ContactVO(name: recipient, email: recipient))
        }

        mailToData.bcc.forEach { (recipient) in
            self.addBccContacts(ContactVO(name: recipient, email: recipient))
        }

        if let subject = mailToData.subject {
            self.setSubject(subject)
        }

        if let body = mailToData.body {
            self.setBody(body)
        }
    }
}

extension ContainableComposeViewModel {
    internal var currentAttachmentsSize: Int {
        guard let message = self.message else { return 0}
        return message.attachments.reduce(into: 0) {
            $0 += ($1 as? Attachment)?.fileSize.intValue ?? 0
        }
    }

    internal func validateAttachmentsSize(withNew data: Data) -> Bool {
        return self.currentAttachmentsSize + data.dataSize < self.kDefaultAttachmentFileSize
    }
}
