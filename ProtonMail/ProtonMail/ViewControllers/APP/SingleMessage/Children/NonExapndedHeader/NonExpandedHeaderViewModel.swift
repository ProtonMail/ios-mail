//
//  NonExpandedHeaderViewModel.swift
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

import PromiseKit
import ProtonCore_UIFoundations
import Foundation

class NonExpandedHeaderViewModel {

    var reloadView: (() -> Void)?
    var updateTimeLabel: (() -> Void)?

    var shouldShowSentImage: Bool {
        guard let message = infoProvider?.message else { return false }
        return message.isSent && message.messageLocation != .sent
    }

    private(set) var infoProvider: MessageInfoProvider? {
        didSet { reloadView?() }
    }

    private var timer: Timer?
    private let isScheduledSend: Bool

    init(isScheduledSend: Bool) {
        self.isScheduledSend = isScheduledSend
    }

    deinit {
        timer?.invalidate()
    }

    func providerHasChanged(provider: MessageInfoProvider) {
        infoProvider = provider
    }

    func setupTimerIfNeeded() {
        guard isScheduledSend else {
            return
        }
        #if DEBUG
        let interval = 1.0
        #else
        let interval = 10.0
        #endif
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateTimeLabel?()
        }
    }
}
