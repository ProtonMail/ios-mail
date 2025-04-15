//
// Copyright (c) 2025 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

enum L10n {
    static let openApp = LocalizedStringResource("Open Proton Mail", bundle: .module, comment: "Button to open the main app from the Share extension")
    static let needToSignIn = LocalizedStringResource("You need to sign-in to Proton Mail to share content.", bundle: .module, comment: "Error message when attempting to use the Share extension without being logged in")
}
