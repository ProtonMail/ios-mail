//
//  BannerViewModel.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

class BannerViewModel {

    let shouldAutoLoadRemoteContent: Bool
    let shouldAutoLoadEmbeddedImage: Bool
    private(set) var expirationTime: Date = .distantFuture
    private var timer: Timer?
    private let unsubscribeService: UnsubscribeService
    private let markLegitimateService: MarkLegitimateService
    private let receiptService: ReceiptService
    private let urlOpener: URLOpener
    var shouldShowReceiptBanner: Bool {
        return message.hasReceiptRequest && !message.isSent
    }
    var hasSentReceipt: Bool {
        return message.hasSentReceipt
    }

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)?
    var resetLoadedHeight: (() -> Void)?
    var updateExpirationTime: ((Int) -> Void)?
    var messageExpired: (() -> Void)?
    var reloadBanners: (() -> Void)?

    var canUnsubscribe: Bool {
        let unsubscribeMethods = self.message.getUnsubscribeMethods
        let isAvailable = unsubscribeMethods?.oneClick != nil || unsubscribeMethods?.httpClient != nil
        return isAvailable && !message.flag.contains(.unsubscribed)
    }

    var isAutoReply: Bool {
        message.isAutoReply
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
         receiptService: ReceiptService,
         urlOpener: URLOpener = UIApplication.shared) {
        self.message = message
        self.shouldAutoLoadRemoteContent = shouldAutoLoadRemoteContent
        self.shouldAutoLoadEmbeddedImage = shouldAutoLoadEmbeddedImage
        self.unsubscribeService = unsubscribeService
        self.markLegitimateService = markLegitimateService
        self.receiptService = receiptService
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
        let referenceDate = Date.getReferenceDate(processInfo: userCachedStatus)
        return Int(self.expirationTime.timeIntervalSince(referenceDate))
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

    func sendReceipt() {
        self.receiptService.sendReceipt(messageID: self.message.messageID)
    }

    private func open(url: String) {
        guard let url = URL(string: url), urlOpener.canOpenURL(url) else { return }
        urlOpener.open(url)
        unsubscribeService.markAsUnsubscribed(messageId: message.messageID, finish: {})
    }

    @objc
    private func timerUpdate() {
        let offset = getExpirationOffset()
        if offset <= 0 {
            messageExpired?()
        }
        updateExpirationTime?(offset)
    }

    static func calculateExpirationTitle(of offset: Int) -> String {
        let (day, hour, min) = durationsBySecond(seconds: offset + 60)
        if offset <= 0 {
            return LocalString._message_expired
        } else {
            return String(format: LocalString._expires_in_days_hours_mins_seconds, day, hour, min)
        }
    }

    static func durationsBySecond(seconds: Int) -> (days: Int, hours: Int, minutes: Int) {
        return (seconds / (24 * 3_600), (seconds % (24 * 3_600)) / 3_600, seconds % 3_600 / 60)
    }
}
