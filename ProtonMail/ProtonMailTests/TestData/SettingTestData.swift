// Copyright (c) 2023 Proton Technologies AG
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

enum SettingTestData {
    static let mailSettings: [String: Any] = [
        "Code": 1000,
        "MailSettings": [
            "HideRemoteImages": 1,
            "LastLoginTime": 1683709394,
            "DelaySendSeconds": 10,
            "AlsoArchive": 0,
            "Shortcuts": 1,
            "KT": 0,
            "SwipeLeft": 4,
            "RightToLeft": 0,
            "ShowImages": 2,
            "TLS": 0,
            "HideEmbeddedImages": 0,
            "ThemeType": 0,
            "AutoWildcardSearch": 1,
            "PGPScheme": 16,
            "AutoSaveContacts": 0,
            "MessageButtons": 0,
            "EnableFolderColor": 1,
            "ComposerMode": 0,
            "AttachPublicKey": 0,
            "StickyLabels": 0,
            "Autocrypt": 0,
            "Hotkeys": 0,
            "AlmostAllMail": 0,
            "ViewLayout": 0,
            "HideSenderImages": 0,
            "Signature": "",
            "ImageProxy": 0,
            "PromptPin": 0,
            "SwipeRight": 4,
            "InheritParentFolderColor": 0,
            "Sign": 0,
            "ExpandFolders": 0,
            "NextMessageOnMove": 0,
            "Theme": "",
            "PMSignature": 2,
            "ShowMoved": 0,
            "ViewMode": 1,
            "DisplayName": "",
            "ConfirmLink": 1,
            "MobileSettings": [
                "ListToolbar": [
                    "IsCustom": false,
                    "Actions": []
                ],
                "MessageToolbar": [
                    "IsCustom": true,
                    "Actions": [
                        "trash"
                    ]
                ] as [String : Any],
                "ConversationToolbar": [
                    "IsCustom": false,
                    "Actions": []
                ]
            ],
            "AutoResponder": [
                "StartTime": 0,
                "EndTime": 0,
                "DaysSelected": [],
                "Repeat": 0,
                "Subject": "Auto",
                "Message": "",
                "IsEnabled": false,
                "Zone": "Europe/Zurich"
            ] as [String : Any],
            "NumMessagePerPage": 50,
            "RecipientLimit": 100,
            "DraftMIMEType": "text/plain",
            "ReceiveMIMEType": "text/html",
            "ShowMIMEType": "text/html",
            "PMSignatureReferralLink": 0,
            "SubmissionAccess": 0
        ] as [String : Any]
    ]

    static let userSettings: [String: Any] = [
        "Code": 1000,
        "UserSettings": [
            "Email": [
                "Value": "test@pm.me",
                "Status": 1,
                "Notify": 0,
                "Reset": 1
            ] as [String : Any],
            "Phone": [
                "Status": 0,
                "Notify": 0,
                "Reset": 0
            ],
            "Password": [
                "Mode": 1,
            ],
            "PasswordMode": 1,
            "2FA": [
                "Enabled": 0,
                "Allowed": 3,
                "U2FKeys": [],
                "RegisteredKeys": []
            ] as [String : Any],
            "TOTP": 0,
            "News": 174,
            "Locale": "en_US",
            "LogAuth": 1,
            "InvoiceText": "",
            "Density": 0,
            "ThemeType": 1,
            "WeekStart": 0,
            "DateFormat": 0,
            "TimeFormat": 0,
            "Flags": [
                "Welcomed": 1,
                "InAppPromosHidden": 0
            ],
            "DeviceRecovery": 1,
            "Telemetry": 1,
            "CrashReports": 1,
            "HighSecurity": [
                "Eligible": 0,
                "Value": 0
            ],
            "Referral": [
                "Link": "https://pr.tn/ref/XXX",
                "Eligible": false
            ] as [String : Any],
            "HideSidePanel": 0,
            "TwoFactor": 0,
            "Welcome": 0,
            "WelcomeFlag": 0,
            "AppWelcome": [
                "Mail": [
                    "Web"
                ],
                "Calendar": [
                    "Web"
                ],
                "Drive": [
                    "Web"
                ],
                "Contacts": [
                    "Web"
                ],
                "Account": [
                    "Web",
                    "Web"
                ]
            ],
            "EarlyAccess": 0,
        ] as [String : Any]
    ]
}
