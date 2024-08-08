//
//  URLOpener.swift
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

// sourcery: mock
protocol URLOpener {
    func canOpenURL(_ url: URL) -> Bool
    func open(_ url: URL)
    func openAsync(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any]) async -> Bool
}

extension UIApplication: URLOpener {
    func open(_ url: URL) {
        open(url, options: [:], completionHandler: nil)
    }

    func openAsync(_ url: URL, options: [OpenExternalURLOptionsKey: Any]) async -> Bool {
        await open(url, options: options)
    }
}
