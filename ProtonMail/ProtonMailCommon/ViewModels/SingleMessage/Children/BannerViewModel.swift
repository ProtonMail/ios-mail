//
//  BannerViewModel.swift
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

import Foundation

class BannerViewModel {

    var updateTableView: (() -> Void)?

    let shouldAutoLoadRemoteContent: Bool
    let shouldAutoLoadEmbeddedImage: Bool
    private(set) var expirationTime: Date = .distantFuture
    private var timer: Timer?
    private let unsubscribeService: UnsubscribeService
    private let markLegitimateService: MarkLegitimateService
    private let urlOpener: URLOpener

    var updateExpirationTime: ((Int) -> Void)?
    var messageExpired: (() -> Void)?
    var reloadBanners: (() -> Void)?

    var canUnsubscribe: Bool {
        let unsubscribeMethods = self.message.getUnsubscribeMethods
        let isAvailable = unsubscribeMethods?.oneClick != nil || unsubscribeMethods?.httpClient != nil
        return isAvailable && !message.flag.contains(.unsubscribed)
    }

    private(set) var message: Message {
        didSet {
            reloadBanners?()
        }
    }

    var spamType: SpamType? {
        message.spam
    }

    init(message: Message,
         shouldAutoLoadRemoteContent: Bool,
         expirationTime: Date?,
         shouldAutoLoadEmbeddedImage: Bool,
         unsubscribeService: UnsubscribeService,
         markLegitimateService: MarkLegitimateService,
         urlOpener: URLOpener = UIApplication.shared) {
        self.message = message
        self.shouldAutoLoadRemoteContent = shouldAutoLoadRemoteContent
        self.shouldAutoLoadEmbeddedImage = shouldAutoLoadEmbeddedImage
        self.unsubscribeService = unsubscribeService
        self.markLegitimateService = markLegitimateService
        self.urlOpener = urlOpener
        setUpTimer(expirationTime: expirationTime)
    }

    deinit {
        timer?.invalidate()
    }

    func setUpTimer(expirationTime: Date?) {
        if let time = expirationTime {
            self.expirationTime = time
            self.timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(self.timerUpdate),
                userInfo: nil,

                repeats: true
            )
        }
    }

    func getExpirationOffset() -> Int {
        return Int(self.expirationTime.timeIntervalSince(Date()))
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

    @objc
    func unsubscribe() {
        let unsubscribeMethods = message.getUnsubscribeMethods
        if unsubscribeMethods?.oneClick != nil {
            unsubscribeService.oneClickUnsubscribe(messageId: message.messageID)
        } else if let httpClient = unsubscribeMethods?.httpClient {
            open(url: httpClient)
        }
    }

    func markAsLegitimate() {
        markLegitimateService.markAsLegitimate(messageId: message.messageID)
    }

    private func open(url: String) {
        guard let url = URL(string: url), urlOpener.canOpenURL(url) else { return }
        urlOpener.open(url)
        _ = unsubscribeService.markAsUnsubscribed(messageId: message.messageID)
    }

    @objc
    private func timerUpdate() {
        let offset = getExpirationOffset()
        if offset <= 0 {
            messageExpired?()
        }
        updateExpirationTime?(offset)
    }
}
