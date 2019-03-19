//
//  HeaderData.swift
//  ProtonMail - Created on 08/03/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import Foundation

/// Incapsulates data we need for filling in the EmailHeaderView. Will not be needed once we deprecate that view.
class HeaderData: NSObject {
    let title: String
    let sender: ContactVO
    let to: [ContactVO]?
    let cc: [ContactVO]?
    let bcc: [ContactVO]?
    let isStarred: Bool
    let time: Date?
    let labels: [Label]?
    let expiration: Date?
    let score: Message.SpamScore
    let isSent: Bool
    
    init(message: Message) {
        self.title = message.subject
        self.sender = message.senderContactVO
        self.to = message.toList.toContacts()
        self.cc = message.ccList.toContacts()
        self.bcc = message.bccList.toContacts()
        self.isStarred = message.starred
        self.time = message.time
        self.labels = message.labels.allObjects as? [Label]
        self.expiration = message.expirationTime
        self.score = message.getScore()
        self.isSent = message.contains(label: .sent)
    }
}

extension EmailHeaderView {
    func updateHeaderData(_ headerData: HeaderData) {
        self.updateHeaderData(headerData.title,
                              sender: headerData.sender,
                              to: headerData.to,
                              cc: headerData.cc,
                              bcc: headerData.bcc,
                              isStarred: headerData.isStarred,
                              time: headerData.time,
                              labels: headerData.labels,
                              showShowImages: false,
                              expiration: headerData.expiration,
                              score: headerData.score,
                              isSent: headerData.isSent)
    }
}
