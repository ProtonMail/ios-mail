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
    let shouldAutoLoadRemoteContent: Bool
    let shouldAutoLoadEmbeddedImage: Bool
    private(set) var expirationTime: Date = .distantFuture
    private var timer: Timer?

    var updateExpirationTime: ((Int) -> Void)?
    var messageExpired: (() -> Void)?

    init(shouldAutoLoadRemoteContent: Bool,
         expirationTime: Date?,
         shouldAutoLoadEmbeddedImage: Bool) {
        self.shouldAutoLoadRemoteContent = shouldAutoLoadRemoteContent
        self.shouldAutoLoadEmbeddedImage = shouldAutoLoadEmbeddedImage
        if let time = expirationTime {
            self.expirationTime = time
            self.timer = Timer.scheduledTimer(timeInterval: 1,
                                              target: self,
                                              selector: #selector(self.timerUpdate),
                                              userInfo: nil,
                                              repeats: true)
        }
    }

    deinit {
        timer?.invalidate()
    }

    func getExpirationOffset() -> Int {
        return Int(self.expirationTime.timeIntervalSince(Date()))
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
