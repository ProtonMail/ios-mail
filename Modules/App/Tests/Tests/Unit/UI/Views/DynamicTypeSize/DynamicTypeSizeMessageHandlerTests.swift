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

import Testing
import WebKit

@testable import ProtonMail

@MainActor
struct DynamicTypeSizeMessageHandlerTests {
    private let sut = DynamicTypeSizeMessageHandler()

    @Test
    func scalesFontSizeAndLineHeightSpecifiedInAbsoluteUnitsByApplyingScaleFactor() {
        let incomingStyle = "font-size: 13px; line-height: 14px"

        let expectedStyle =
            "--dts-font-size-scale-factor: 1.0;--dts-line-height-scale-factor: 1.0;font-size: calc(13px * var(--dts-font-size-scale-factor)) !important;line-height: calc(14px * var(--dts-line-height-scale-factor)) !important;overflow-wrap: anywhere !important;text-wrap-mode: wrap !important"

        #expect(sut.applyScaling(to: incomingStyle) == expectedStyle)
    }

    @Test
    func doesNotModifyPropertiesWithRelativeUnits() {
        let incomingStyle = "font-family: Roboto-Regular, Helvetica, Arial, sans-serif; font-size: 13px; color: #000000de; line-height: 1.6"

        let expectedStyle =
            "--dts-font-size-scale-factor: 1.0;color: #000000de;font-family: Roboto-Regular, Helvetica, Arial, sans-serif;font-size: calc(13px * var(--dts-font-size-scale-factor)) !important;line-height: 1.6;overflow-wrap: anywhere !important;text-wrap-mode: wrap !important"

        #expect(sut.applyScaling(to: incomingStyle) == expectedStyle)
    }
}
