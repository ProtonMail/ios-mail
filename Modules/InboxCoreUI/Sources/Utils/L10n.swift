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
    enum BiometricLock {
        static let biometricUnlockRationale = LocalizedStringResource(
            "Please authenticate to unlock your screen.",
            comment: "Displayed in the system PIN pop-up when FaceID for this app is disabled."
        )
        static let unlockButtonTitle = LocalizedStringResource(
            "Unlock Proton Mail",
            comment: "Title of a button that triggers biometric authorization on the lock screen."
        )
        enum BiometricsNotAvailableAlert {
            static let signInAgainAction = LocalizedStringResource(
                "Sign in again",
                comment: "Alert action title. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let title = LocalizedStringResource(
                "Enable access",
                comment: "Alert title. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let messageFaceID = LocalizedStringResource(
                "PIN and Face ID are disabled on your device. Enable them in Settings or sign in to unlock this app.",
                comment: "Face ID version alert message. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let messageTouchID = LocalizedStringResource(
                "PIN and Touch ID are disabled on your device. Enable them in Settings or sign in to unlock this app.",
                comment: "Touch ID version alert message. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
            static let defaultMessage = LocalizedStringResource(
                "PIN and Biometry are disabled on your device. Enable them in Settings or sign in to unlock this app.",
                comment: "Default version alert message. The alert is dispalyed when biometric is set as lock protection method, but it's not configured on the device."
            )
        }
    }

    enum ImageProxy {
        static let proxyFailed = LocalizedStringResource(
            "Some images failed to load with tracker protection.",
            comment: "Banner informing the user about an error."
        )
    }

    enum PINLock {
        static let title = LocalizedStringResource(
            "Enter PIN",
            comment: "Title of the pin lock screen."
        )
        static let subtitle = LocalizedStringResource(
            "Confirm it's you to continue.",
            comment: "Subtitle of PIN lock screen."
        )
        static let pinInputPlaceholder = LocalizedStringResource(
            "PIN Code",
            comment: "PIN input placeholder."
        )
        static let invalidPIN = LocalizedStringResource(
            "Incorrect PIN. Please try again.",
            comment: "Error message when a user enters an invalid PIN"
        )
        static let tooFrequentAttempts = LocalizedStringResource(
            "Too many attempts too quickly. Please wait before trying again.",
            comment: "Displayed when the user tries to validate their PIN too frequently."
        )
        static let signOut = LocalizedStringResource(
            "Sign out",
            comment: "Title of the sign out button."
        )
        static let signOutConfirmationTitle = LocalizedStringResource(
            "Sign Out of All Accounts",
            comment: "Title of the sign out confirmation alert."
        )
        static let signOutConfirmationMessage = LocalizedStringResource(
            "You're about to be signed out of all your accounts on this device. Do you want to continue?",
            comment: "Message of the sign out confirmation alert."
        )
        static func remainingAttemptsWarning(_ number: Int) -> LocalizedStringResource {
            LocalizedStringResource(
                "\(number) attempts remaining before sign-out.",
                comment: "Remaining attempts after a user has entered a wrong PIN a few times."
            )
        }
    }
}
