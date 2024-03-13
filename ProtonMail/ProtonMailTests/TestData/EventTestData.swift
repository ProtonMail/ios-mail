//
//  EventTestData.swift
//  Proton Mail
//
//
//  Copyright (c) 2020 Proton AG
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

import Foundation

let eventTestDatawithDeleteConversation = """
    {
       "Code":1000,
       "EventID":"YavOMCsY_G_OM2ti21cBlKbY-wVO-LaxvvLwGFM5duj3RpswhVBMFkepPg==",
       "Refresh":0,
       "More":0,
       "Messages":[
          {
             "ID":"yFB3cIZKN6v9Yi-U412pnXCihxjECML2y6AYQ9xlNw2cAoKJi03XoaK8-3kJBFqjkdWHyQ==",
             "Action":0
          },
          {
             "ID":"z07aOb878rT8DnonOxMQbUazrVyrpIsA9Jfo1sEeljwm_zUeEFhGvqLjcf1foaTolwJSDgqg==",
             "Action":0
          },
          {
             "ID":"uXLofJM80hmX60S-PvRP8WIxKfeRHmd416UqaT1Of8OHHKZzMy14drpv45EBpXOsIfd7VVA==",
             "Action":0
          }
       ],
       "Conversations":[
          {
             "ID":"sY1LHLrAfl0vL_mUE4meCEHQt3M5IRKUQRdQi_538-AZ-494hHfMs9RMpBw==",
             "Action":0
          }
       ],
       "Total":{
          "Locations":[
             {
                "Location":0,
                "Count":39
             },
             {
                "Location":1,
                "Count":26
             },
             {
                "Location":2,
                "Count":70
             },
             {
                "Location":3,
                "Count":15
             },
             {
                "Location":4,
                "Count":4
             },
             {
                "Location":5,
                "Count":129
             },
             {
                "Location":6,
                "Count":0
             },
             {
                "Location":7,
                "Count":66
             },
             {
                "Location":8,
                "Count":25
             },
             {
                "Location":9,
                "Count":0
             }
          ],
          "Labels":[

          ],
          "Starred":5
       },
       "Unread":{
          "Locations":[
             {
                "Location":0,
                "Count":0
             },
             {
                "Location":1,
                "Count":0
             },
             {
                "Location":2,
                "Count":0
             },
             {
                "Location":3,
                "Count":0
             },
             {
                "Location":4,
                "Count":0
             },
             {
                "Location":5,
                "Count":0
             },
             {
                "Location":6,
                "Count":0
             },
             {
                "Location":7,
                "Count":0
             },
             {
                "Location":8,
                "Count":0
             },
             {
                "Location":9,
                "Count":0
             }
          ],
          "Labels":[

          ],
          "Starred":0
       },
       "MessageCounts":[
          {
             "LabelID":"0",
             "Total":39,
             "Unread":0
          },
          {
             "LabelID":"1",
             "Total":26,
             "Unread":0
          },
          {
             "LabelID":"2",
             "Total":70,
             "Unread":0
          },
          {
             "LabelID":"3",
             "Total":15,
             "Unread":0
          },
          {
             "LabelID":"4",
             "Total":4,
             "Unread":0
          },
          {
             "LabelID":"5",
             "Total":129,
             "Unread":0
          },
          {
             "LabelID":"6",
             "Total":0,
             "Unread":0
          },
          {
             "LabelID":"7",
             "Total":66,
             "Unread":0
          },
          {
             "LabelID":"8",
             "Total":25,
             "Unread":0
          },
          {
             "LabelID":"9",
             "Total":0,
             "Unread":0
          },
          {
             "LabelID":"10",
             "Total":5,
             "Unread":0
          }
       ],
       "ConversationCounts":[
          {
             "LabelID":"0",
             "Total":36,
             "Unread":0
          },
          {
             "LabelID":"1",
             "Total":23,
             "Unread":0
          },
          {
             "LabelID":"2",
             "Total":69,
             "Unread":0
          },
          {
             "LabelID":"3",
             "Total":13,
             "Unread":0
          },
          {
             "LabelID":"4",
             "Total":4,
             "Unread":0
          },
          {
             "LabelID":"5",
             "Total":116,
             "Unread":0
          },
          {
             "LabelID":"6",
             "Total":0,
             "Unread":0
          },
          {
             "LabelID":"7",
             "Total":65,
             "Unread":0
          },
          {
             "LabelID":"8",
             "Total":22,
             "Unread":0
          },
          {
             "LabelID":"9",
             "Total":0,
             "Unread":0
          },
          {
             "LabelID":"10",
             "Total":5,
             "Unread":0
          }
       ],
       "UsedSpace":157621062,
       "Notices":[

       ]
    }
"""

enum EventTestData {
    static let userSettings = """
{
    "Code": 1000,
    "EventID": "AhD-_rGuAsCLTde62U5nKnxpY9xboU6rx_13d94CNXncuXFr13se0weeE-DqRq",
    "Refresh": 0,
    "More": 0,
    "UserSettings": {
        "Email": {
            "Value": "test@pm.me",
            "Status": 1,
            "Notify": 0,
            "Reset": 1
        },
        "Phone": {
            "Value": null,
            "Status": 0,
            "Notify": 0,
            "Reset": 0
        },
        "Password": {
            "Mode": 1,
            "ExpirationTime": null
        },
        "PasswordMode": 1,
        "2FA": {
            "Enabled": 0,
            "Allowed": 3,
            "ExpirationTime": null,
            "U2FKeys": [],
            "RegisteredKeys": []
        },
        "TOTP": 0,
        "News": 64430,
        "Locale": "en_US",
        "LogAuth": 1,
        "InvoiceText": "",
        "Density": 0,
        "Theme": null,
        "ThemeType": 3,
        "WeekStart": 0,
        "DateFormat": 0,
        "TimeFormat": 0,
        "Flags": {
            "Welcomed": 1,
            "InAppPromosHidden": 0
        },
        "DeviceRecovery": 1,
        "Telemetry": 0,
        "CrashReports": 1,
        "HighSecurity": {
            "Eligible": 0,
            "Value": 0
        },
        "SessionAccountRecovery": 1,
        "Referral": {
            "Link": "https://pr.tn/ref/xxxx",
            "Eligible": false
        },
        "HideSidePanel": 0,
        "TwoFactor": 0,
        "Welcome": 1,
        "WelcomeFlag": 1,
        "AppWelcome": {
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
        },
        "EarlyAccess": 1,
        "Checklists": []
    },
    "Notifications": [],
    "Notices": [],
    "UsedSpace": 553769095
}
"""

    static let mailSettings = """
{
    "Code": 1000,
    "EventID": "F43Ne8bTojs3YG6h6P3M9kJmY4mqJCkmt3sugqeRJwNmr7QG_",
    "Refresh": 0,
    "More": 0,
    "MailSettings": {
        "HideRemoteImages": 1,
        "LastLoginTime": 1699324602,
        "DelaySendSeconds": 10,
        "AlsoArchive": 0,
        "Shortcuts": 1,
        "KT": 0,
        "SwipeLeft": 0,
        "FontSize": null,
        "RightToLeft": 0,
        "ShowImages": 2,
        "TLS": 0,
        "HideEmbeddedImages": 1,
        "FontFace": null,
        "ThemeType": 0,
        "AutoWildcardSearch": 1,
        "PGPScheme": 16,
        "AutoSaveContacts": 0,
        "MessageButtons": 0,
        "ThemeVersion": null,
        "EnableFolderColor": 1,
        "ComposerMode": 0,
        "AttachPublicKey": 0,
        "StickyLabels": 0,
        "Autocrypt": 0,
        "Hotkeys": 0,
        "PageSize": 50,
        "AlmostAllMail": 1,
        "ViewLayout": 0,
        "SpamAction": null,
        "HideSenderImages": 0,
        "Signature": "",
        "UnreadFavicon": 0,
        "ImageProxy": 2,
        "PromptPin": 0,
        "SwipeRight": 4,
        "BlockSenderConfirmation": null,
        "InheritParentFolderColor": 0,
        "Sign": 1,
        "ExpandFolders": 0,
        "NextMessageOnMove": 0,
        "Theme": "",
        "PMSignature": 2,
        "ShowMoved": 0,
        "ViewMode": 0,
        "DisplayName": "TestName",
        "ConfirmLink": 1,
        "AutoDeleteSpamAndTrashDays": null,
        "AutoResponder": {
            "StartTime": 0,
            "EndTime": 0,
            "DaysSelected": [],
            "Repeat": 0,
            "Subject": "Auto",
            "Message": "",
            "IsEnabled": false,
            "Zone": "Europe/Zurich"
        },
        "NumMessagePerPage": 50,
        "RecipientLimit": 100,
        "DraftMIMEType": "text/plain",
        "ReceiveMIMEType": "text/html",
        "ShowMIMEType": "text/html",
        "PMSignatureReferralLink": 0,
        "SubmissionAccess": 0,
        "MobileSettings": {
            "ListToolbar": {
                "IsCustom": false,
                "Actions": []
            },
            "MessageToolbar": {
                "IsCustom": true,
                "Actions": [
                    "trash",
                    "toggle_read"
                ]
            },
            "ConversationToolbar": {
                "IsCustom": false,
                "Actions": []
            }
        },
    },
    "Notifications": [],
    "Notices": []
}
"""

    static let incomingDefaults = """
{
    "Code": 1000,
    "EventID": "4qiqO1xxL-t14SXMWbJQB3PDw==",
    "Refresh": 0,
    "More": 0,
    "IncomingDefaults": [
        {
            "ID": "NuYq04-jVQL6dd4w1NatTSaDDRIXxlRSpYZQq_GeRI0Nsx94GA==",
            "Action": 1,
            "IncomingDefault": {
                "ID": "NuYq04-jVQL6dd4w1NatTSaDDRIXxlRSpYZQq_GeRI0Nsx94GA==",
                "Location": 14,
                "Type": 1,
                "Time": 1699507315,
                "Email": "test1@proton.me"
            }
        },
        {
            "ID": "q04-jVQL6dd4w1NatTSaDDRIXxlRSpYZQq_GeR",
            "Action": 1,
            "IncomingDefault": {
                "ID": "q04-jVQL6dd4w1NatTSaDDRIXxlRSpYZQq_GeR",
                "Location": 14,
                "Type": 1,
                "Time": 1699507115,
                "Email": "test2@proton.me"
            }
        },
        {
            "ID": "w1NatTSaDDRIXxlRSpY",
            "Action": 0
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let user = """
{
    "Code": 1000,
    "EventID": "xqxYAgtqxSzj6akDD2ksEAmXeI=",
    "Refresh": 0,
    "More": 0,
    "User": {
        "ID": "Rbfvlksgs11Q==",
        "Name": "TestingName",
        "Currency": "USD",
        "Credit": 0,
        "Type": 1,
        "CreateTime": 1588054886,
        "MaxSpace": 1073741824,
        "MaxUpload": 26214400,
        "UsedSpace": 553769095,
        "ProductUsedSpace": {
            "Calendar": 5114,
            "Contact": 2919,
            "Drive": 147920756,
            "Mail": 405840306,
            "Pass": 0
        },
        "Subscribed": 0,
        "Services": 1,
        "MnemonicStatus": 4,
        "Role": 0,
        "Private": 1,
        "Delinquent": 0,
        "Keys": [
            {
                "ID": "18LqT9H5Rxz2pjYYtIFk_4K8AHU1Wmfh6kAOUcm0XGbSRA==",
                "Version": 3,
                "Primary": 1,
                "RecoverySecret": "8xUobmbCcJU947bXBvfKg=",
                "RecoverySecretSignature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKAAYFAmNClJ4IQT5guksoDFantnTh+Eyf189\\nGB7Wa9exAPwI62wD/Z4bG\\nHhycsEO0biDKVvmRctfMSUp2SbXtpq9M6g92PwI=\\n=Ff2w\\n-----END PGP SIGNATURE-----\\n",
                "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: GopenPGP 2.7.3\\nComment: https://gopenpgp.org\\n\\nxYYEZVRT4hYJKwYBBAHaRw8BAQdA5zeaaqDXZHASWQq+dFZ9AhK51DY5QhQw7bpc\\nJfKAG8H+CQMIPM5gDwDkswdgA5kOowfjOKfX5KjxyG5npR1OuCe9bxl0cLxoBp0L\\nRWCtNbkdU0+tmu2VulKp+JDrNFxsTy+d4ymZObssTq84KmbNL6Y85M1aRjdBNTg3\\nODYtMzU2MS00NEQ2LUE0MjktNEMwNEI4OEUyRkNGIDxGN0E1ODc4Ni0zNTYxLTQ0\\nRDYtQTQyOS00QzA0Qjg4RTJGQ0ZAcHJvdG9ubWFpbC5jb20+wo8EExYIAEEFAmVU\\nU+IJEP1N/9d+WklgFiEE9LaW08SydK5gSDSm/U3/135aSWACGwMCHgECGQEDCwkH\\nAhUIAxYAAgUnCQIHAgAAxHkBAKH5SO21v+J/mjAGy4CYdQ7h9FVyEGzeVbPwri2L\\nfXM/AP0UCaK3JSHhpUoTkOQYptw8RAk+wpIaSPEKUZitITGwCceLBGVUU+ISCisG\\nAQQBl1UBBQEBB0DRCu+Vwb028XTnZouaeXLeshk8ohrn6KX9H9nebjKdOgMBCgn+\\nCQMIx+QBI+HjclhgOKcal9ZA5lLC6mLoxwbOaerhR2GZ8UKODp2dVJfCQgDE6lPH\\nlnsx38P12bJU/mXTqukh1gLOvvSaZTi9kRjo+SKI9U1n+sJ3BBgWCAAqBQJlVFPi\\nCRD9Tf/XflpJYBYhBPS2ltPEsnSuYEg0pv1N/9d+WklgAhsMAABnRgD3ehppTpZO\\nLtT4dLzKaouqdt+m0vITFNmigr8tBNyceAEA1nKYMuxHUizpHv1NzNkxFXUN+aJ+\\nC+tKzt+POd2kOQc=\\n=JaHu\\n-----END PGP PRIVATE KEY BLOCK-----",
                "Fingerprint": "f4b696d3c4b274ae604834a6fd4dffd77e5a4960",
                "Active": 1
            },
            {
                "ID": "Y0AUSJZReSj1ug==",
                "Version": 3,
                "Primary": 0,
                "RecoverySecret": null,
                "RecoverySecretSignature": null,
                "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: GopenPGP 2.7.3\\nComment: https://gopenpgp.org\\n\\nxYYEZVRUWBYJKwYBBAHaRw8BAQdA37qpqg8LELjaUfQQGFJv9jrnLykT93qUwlKb\\nK+Ix0DH+CQMIqeuP+0jT3pVg+lgXF71ibZ0VGwl/HJdp8/vszQBwBb0uLVlkbyRj\\neGk/XG+psmttgnsIP26EH/Y5WtUyNWuyu+wLjR2WTWYDM6Y2b46wi81aQzVBMTdB\\nREUtRkU3My00MTlCLTlCNkYtMUU1N0Q1RkFGNUNGIDxDNUExN0FERS1GRTczLTQx\\nOUItOUI2Ri0xRTU3RDVGQUY1Q0ZAcHJvdG9ubWFpbC5jb20+wo8EExYIAEEFAmVU\\nVFgJELATbCHfKMDrFiEEw8H2LFHvwZyAYPZHsBNsId8owOsCGwMCHgECGQEDCwkH\\nAhUIAxYAAgUnCQIHAgAAQXQBAOVKu1PCeq3BlxMyv7FMorGyLTdWaIJqqyJKtmZP\\nmzTvAQCcsqt3zM8aE0x4t2QOOdMLmYgdC5SnRAbkKmJcSi9xAseLBGVUVFgSCisG\\nAQQBl1UBBQEBB0AIURdvuUsKE4yR81DUQuiKzTSHGRQ/JNgbWGQZ+RJwUAMBCgn+\\nCQMIfYaA9O3CgNFgBqE2rBi0PV6iOnYVnbfuQs2/NOWc7MnyLz2z4dN39qkOlUN0\\nJ9vplE0/ZM0jZQCczgirQKMsEn83/vSEg91kRtVm5vUK2MJ4BBgWCAAqBQJlVFRY\\nCRCwE2wh3yjA6xYhBMPB9ixR78GcgGD2R7ATbCHfKMDrAhsMAADYhQD/Q6mljhO+\\nLJrfnsBoT5faMC+gA1gj5ZAHk+vuDH8GCx0BAKOSr/8OrVWCDfGSrQVpZZSu3Lrp\\nYJr0orR/xSWxZaIH\\n=3eAH\\n-----END PGP PRIVATE KEY BLOCK-----",
                "Fingerprint": "c3c1f62c51efc19c8060f647b0136c21df28c0eb",
                "Active": 1
            }
        ],
        "ToMigrate": 0,
        "Email": "test@protonmail.ch",
        "DisplayName": "DisplayName",
        "AccountRecovery": null,
        "Flags": {
            "protected": false,
            "drive-early-access": false,
            "onboard-checklist-storage-granted": true,
            "has-temporary-password": false,
            "test-account": false,
            "no-login": false,
            "recovery-attempt": false
        }
    },
    "Notifications": [],
    "Notices": []
}
"""

    static let addresses = """
{
    "Code": 1000,
    "EventID": "xqxYAgtqxSzj6ak5oufcFEm0gUsv4eo_0KSXKaePZgAYNX4ZQ==",
    "Refresh": 0,
    "More": 0,
    "Addresses": [
        {
            "ID": "1",
            "Action": 0
        },
        {
            "ID": "JwUa_eV8uqbTqVNeYtedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
            "Action": 2,
            "Address": {
                "ID": "JwUa_eV8uqbTqVNeYtedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
                "DomainID": "pIJGEYyNFsPEb61o2JrcdohiRuWSN2i1rgnkEnZmolVx4Np96IcwxJh1WNw==",
                "Email": "test@proton.me",
                "Status": 1,
                "Type": 1,
                "Receive": 1,
                "Send": 1,
                "DisplayName": "L",
                "Signature": "",
                "Order": 1,
                "Priority": 1,
                "CatchAll": false,
                "ProtonMX": true,
                "ConfirmationState": 1,
                "HasKeys": 1,
                "Flags": 0,
                "Keys": [
                    {
                        "ID": "4NjM11QwBRhJemHW4jEUA==",
                        "Primary": 1,
                        "Flags": 3,
                        "Fingerprint": "5d9a4103fb0fd83f604600bc4bbe389b7494b58d",
                        "Fingerprints": [
                            "1cb0d620dab69b13b8fc8baedda3d1ad05f",
                            "5d9a4103fb0fd83f604600bc4bbe389b7494b58d"
                        ],
                        "PublicKey": "-----BEGIN PGP PUBLIC KEY BLOCK-----\\nVersion: GopenPGP 2.7.3\\nComment: https://gopenpgp.org\\n\\nxjMEY+8x+hYJKwYBBAHaRw8BAQdAClNY5grIa+9A1yJUB+WEoa1YqHEv9Y9kY2Ye\\n9drO7FjNWjNGMzNEMzE4LTA4QkQtNEVGNS05QjE5LTM0MUNGNEQ2MDM0QyA8M0Yz\\nM0QzMTgtMDhCRC00RUY1LTlCMTktMzQxQ0Y0RDYwMzRDQHByb3Rvbm1haWwuY29t\\nPsKMBBMWCAA+BQJj7zH6CZBLvjibdJS1jRYhBF2aQQP7D9g/YEYAvEu+OJt0lLWN\\nAhsDAh4BAhkBAwsJBwIVCAMWAAICIgEAAB00AQDULi00/56I405uGvbzlJrieoBq\\n18L9y1F20na4g3zVTQEA/mM+iFfnHRX65zNkewpG94MxmRzj4m5kcgy2K/LLGQ3O\\nOARj7zH6EgorBgEEAZdVAQUBAQdAINcyx02bOvqIc7FQD7XlWnP0wAYMMllblIfW\\nQpyuRVgDAQoJwngEGBYIACoFAmPvMfoJkEu+OJt0lLWNFiEEXZpBA/sP2D9gRgC8\\nS744m3SUtY0CGwwAAK6aAQDRG9qAiztWy+3nBx4MetggBKlI/pgQLqkwdW8gsckS\\nHgD8CFBV7tRMec4VN+rrVIHTULmycgXhL2zy7zX4nOjjTwk=\\n=83Fw\\n-----END PGP PUBLIC KEY BLOCK-----",
                        "Active": 1,
                        "AddressForwardingID": null,
                        "Version": 3,
                        "Activation": null,
                        "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: GopenPGP 2.5.0\\nComment: https://gopenpgp.org\\n\\nxYYEY+8x+hYJKwYBBAHaRw8BAQdAClNY5grIa+9A1yJUB+WEoa1YqHEv9Y9kY2Ye\\n9drO7Fj+CQMI/6nqJsFlQyBgm8sfTguiRcyg155wS4f+iYrB8URfrTK04OZVmHFa\\nbfbbQvFo9YUwoI0W6V9+KOjh6SSuNt1oTna0eEMkSP2eMop1glGEQM1aM0YzM0Qz\\nMTgtMDhCRC00RUY1LTlCMTktMzQxQ0Y0RDYwMzRDIDwzRjMzRDMxOC0wOEJELTRF\\nRjUtOUIxOS0zNDFDRjRENjAzNENAcHJvdG9ubWFpbC5jb20+wowEExYIAD4FAmPv\\nMfoJkEu+OJt0lLWNFiEEXZpBA/sP2D9gRgC8S744m3SUtY0CGwMCHgECGQEDCwkH\\nAhUIAxYAAgIiAQAAHTQBANQuLTT/nojjTm4a9vOUmuJ6gGrXwv3LUXbSdriDfNVN\\nAQD+Yz6IV+cdFfrnM2R7Ckb3gzGZHOPibmRyDLYr8ssZDceLBGPvMfoSCisGAQQB\\nl1UBBQEBB0Ag1zLHTZs6+ohzsVAPteVac/TABgwyWVuUh9ZCnK5FWAMBCgn+CQMI\\nfKQAON4aJw5gUKI70IVWwX1k/jWRnvHcPgyEDstND10njVhKuMX51cciUiB7O7hq\\nD+QYf9fbus4qv1wEJxuZaGgaKdH05AyWvqUT7kZQKMJ4BBgWCAAqBQJj7zH6CZBL\\nvjibdJS1jRYhBF2aQQP7D9g/YEYAvEu+OJt0lLWNAhsMAACumgEA0RvagIs7Vsvt\\n5wceDHrYIASpSP6YEC6pMHVvILHJEh4A/AhQVe7UTHnOFTfq61SB01C5snIF4S9s\\n8u81+Jzo408J\\n=Yz3C\\n-----END PGP PRIVATE KEY BLOCK-----",
                        "Token": "-----BEGIN PGP MESSAGE-----\\nVersion: ProtonMail\\n\\nwV4D86C6JLhOkfkSAQdA6d/8geU5CFP2HQp7HhR9GI92liXoKMYaC2p0a/hHxCB/+A0lb8kb2Afr4BoC0yJ6uIqs4133dcPWpB+/IX6\\n1TRnIg5NDjDEJr4UOC+mJkd5ldEzR35nTtmmxpRFS6Pdlm3aR7o=\\n=dReU\\n-----END PGP MESSAGE-----\\n",
                        "Signature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKAAYFAmHuZ0kAIQkQMn9fPRge1msWIQT5guksoDFantnTh+Eyf189\\nGB7Wa1XViXZ1AA=\\n=HPz6\\n-----END PGP SIGNATURE-----\\n"
                    },
                    {
                        "ID": "o6MJHyu55uvLrikV6NOp9J7blBHC_C7xwjmiBRWQCL_xEbAazAv0A==",
                        "Primary": 0,
                        "Flags": 3,
                        "Fingerprint": "906e82d7262bec9fd7bc9b70440f664b75505bbb",
                        "Fingerprints": [
                            "1058c7378b77bf010c05458830d084118f1",
                            "f84a52102538ee4bb4a873327198a0aed"
                        ],
                        "PublicKey": "-----BEGIN PGP PUBLIC KEY BLOCK-----\\nVersion: GopenPGP 2.7.3\\nComment: https://gopenpgp.org\\n\\nxjMEZVRNhBYJKwYBBAHaRw8BAQdAdVG+SX8abqKeH2Nywq6EDz3GE5zi3Hs/THh3\\nnAsHBqPNWjVCQzQwQTRGLTQ0MDQtNEMxNy04RDdFLUM1QkU4MDE0NjBDQSA8NUJD\\nNDBBNEYtNDQwNC00QzE3LThEN0UtQzVCRTgwMTQ2MENBQHByb3Rvbm1haWwuY29t\\nPsKPBBMWCABBBQJlVE2ECRBED2ZLdVBbuxYhBJBugtcmK+yf17ybcEQPZkt1UFu7\\nAhsDAh4BAhkBAwsJBwIVCAMWAAIFJwkCBwIAAH15AQCFATOQCMVhfvfTVmX631+G\\n4wOIPQ70g1vMJIZSnGVksAEAhVDlxMDhtUVusutSF11r6KbjgEpFj8y6rkrntxCa\\nqQXOOARlVE2EEgorBgEEAZdVAQUBAQdA4iPoUWT3k8x1+WhPiYSnkR/iGqQuGhwq\\ngxO068KbITIDAQoJwngEGBYIACoFAmVUTYQJEEQPZkt1UFu7FiEEkG6C1yYr7J/X\\nvJtwRA9mS3VQW7sCGwwAAFG0AQCGgyTarszxl8aTxSQKlVZWMr3ZXW5GptUOJES2\\nE/4VbQEAiAyiYkXq/MwPCflaEw5Mh6ZXmc5QMg+0R1iiZms/SwA=\\n=blFn\\n-----END PGP PUBLIC KEY BLOCK-----",
                        "Active": 1,
                        "AddressForwardingID": null,
                        "Version": 3,
                        "Activation": null,
                        "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: GopenPGP 2.7.3\\nComment: https://gopenpgp.org\\n\\nxYYEZVRNhBYJKwYBBAHaRw8BAQdAdVG+SX8abqKeH2Nywq6EDz3GE5zi3Hs/THh3\\nnAsHBqP+CQMIcC9j7f6YZ6VgS+xkRxTfofZT6dlDaTMg2PlRGYWv6IR6YaAs+1tC\\nqdFx/O6hWFICE3zc5YZB8Gq4SeGm1DgePICVWJx+D36+8eOgeBkUkc1aNUJDNDBB\\nNEYtNDQwNC00QzE3LThEN0UtQzVCRTgwMTQ2MENBIDw1QkM0MEE0Ri00NDA0LTRD\\nMTctOEQ3RS1DNUJFODAxNDYwQ0FAcHJvdG9ubWFpbC5jb20+wo8EExYIAEEFAmVU\\nTYQJEEQPZkt1UFu7FiEEkG6C1yYr7J/XvJtwRA9mS3VQW7sCGwMCHgECGQEDCwkH\\nAhUIAxYAAgUnCQIHAgAAfXkBAIUBM5AIxWF+99NWZfrfX4bjA4g9DvSDW8wkhlKc\\nZWSwAQCFUOXEwOG1RW6y61IXXWvopuOASkWPzLquSue3EJqpBceLBGVUTYQSCisG\\nAQQBl1UBBQEBB0DiI+hRZPeTzHX5aE+JhKeRH+IapC4aHCqDE7TrwpshMgMBCgn+\\nCQMIWju2HIPIONNgxNR6gHcV/qCS7sa8Z4aavx1tP5FYQbYWtawAriJXy8zzo7qk\\nvFVvvBAgMNE/5TF7cL1NXAtUmTAOOe21yNhp838uZi311cJ4BBgWCAAqBQJlVE2E\\nCRBED2ZLdVBbuxYhBJBugtcmK+yf17ybcEQPZkt1UFu7AhsMAABRtAEAhoMk2q7M\\n8ZfGk8UkCpVWVjK92V1uRqbVDiREthP+FW0BAIgMomJF6vzMDwn5WhMOTIemV5nO\\nUDIPtEdYomZrP0sA\\n=UlWf\\n-----END PGP PRIVATE KEY BLOCK-----",
                        "Token": "-----BEGIN PGP MESSAGE-----\\nVersion: ProtonMail\\n\\nwV4DQg7fTNedqRMSAQdAg0LTE0H+evspZxj2+dQ/8CRKMMmJ00Ku7rR4XY6Y7XeBpbO+jGQVQ+XFGx1d2V2klwHzcOrYen9vY\\nlFDK58bu1pf6Cuat82fW68N57+P27yrTLZ0nb2ppZS7iNjcPlKU=\\n=3s0w\\n-----END PGP MESSAGE-----\\n",
                        "Signature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKAAYFAmGyvlsAIQkQUBJWQeVkjFUWIQSKTHKRHplL32DXq+xQElZBVmCkpK0HyTpQM=\\n=RCV9\\n-----END PGP SIGNATURE-----\\n"
                    }
                ],
                "SignedKeyList": {
                    "MinEpochID": 1,
                    "MaxEpochID": 839,
                    "ExpectedMinEpochID": null,
                    "Data": "",
                    "ObsolescenceToken": null,
                    "Revision": 1,
                    "Signature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKAAYFAmHuaNIAIQkQztcmSufiZKEWIQTbxTRYVFphLdPWaX3O1yZK\\n8mZ/xwM=\\n=yvQ8\\n-----END PGP SIGNATURE-----\\n"
                }
            }
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let messageCounts = """
{
    "Code": 1000,
    "EventID": "Sp6kNRu-mMkYSzq3xmfCUWCTbYdqh3Q==",
    "Refresh": 0,
    "More": 0,
    "MessageCounts": [
        {
            "LabelID": "0",
            "Total": 280,
            "Unread": 56
        },
        {
            "LabelID": "1",
            "Total": 44,
            "Unread": 0
        },
        {
            "LabelID": "2",
            "Total": 279,
            "Unread": 0
        },
        {
            "LabelID": "3",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "4",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "5",
            "Total": 735,
            "Unread": 56
        },
        {
            "LabelID": "15",
            "Total": 735,
            "Unread": 56
        },
        {
            "LabelID": "6",
            "Total": 169,
            "Unread": 0
        },
        {
            "LabelID": "7",
            "Total": 211,
            "Unread": 0
        },
        {
            "LabelID": "8",
            "Total": 19,
            "Unread": 0
        },
        {
            "LabelID": "9",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "12",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "10",
            "Total": 42,
            "Unread": 0
        },
        {
            "LabelID": "16",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g==",
            "Total": 9,
            "Unread": 9
        },
        {
            "LabelID": "Y7WZniLsZpKoozhCudxqGJJNWYAmFpzvfK9phOmApaUP1TJOoocri2IN7q9ljTR8_wAzB6GshCeb10_MCOq67A==",
            "Total": 3,
            "Unread": 0
        },
        {
            "LabelID": "y4979YHYB6C0Cc11RV84TociphRjY8EYHAHBmPvcYYoZ-goDI5bn8OtxZgTr58svKsijwMrG7qjnokpfykfqYQ==",
            "Total": 4,
            "Unread": 0
        },
        {
            "LabelID": "PYW3f9DGHAExMdOQMbmKN5lIDaUCu652_3BptaOWyOMWhFGvxgX9EOLW4G8kuvWFedDKFoTWpIuePVav1Vr21Q==",
            "Total": 2,
            "Unread": 0
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let conversationCounts = """
{
    "Code": 1000,
    "EventID": "Sp6kNRu-mMkYSzq3xmfCUWCTbYdqh3Q==",
    "Refresh": 0,
    "More": 0,
    "ConversationCounts": [
        {
            "LabelID": "0",
            "Total": 260,
            "Unread": 56
        },
        {
            "LabelID": "1",
            "Total": 22,
            "Unread": 0
        },
        {
            "LabelID": "2",
            "Total": 246,
            "Unread": 0
        },
        {
            "LabelID": "3",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "4",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "5",
            "Total": 565,
            "Unread": 56
        },
        {
            "LabelID": "15",
            "Total": 565,
            "Unread": 56
        },
        {
            "LabelID": "6",
            "Total": 107,
            "Unread": 0
        },
        {
            "LabelID": "7",
            "Total": 195,
            "Unread": 0
        },
        {
            "LabelID": "8",
            "Total": 19,
            "Unread": 0
        },
        {
            "LabelID": "9",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "12",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "10",
            "Total": 28,
            "Unread": 0
        },
        {
            "LabelID": "16",
            "Total": 0,
            "Unread": 0
        },
        {
            "LabelID": "_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g==",
            "Total": 8,
            "Unread": 9
        },
        {
            "LabelID": "Y7WZniLsZpKoozhCudxqGJJNWYAmFpzvfK9phOmApaUP1TJOoocri2IN7q9ljTR8_wAzB6GshCeb10_MCOq67A==",
            "Total": 2,
            "Unread": 0
        },
        {
            "LabelID": "y4979YHYB6C0Cc11RV84TociphRjY8EYHAHBmPvcYYoZ-goDI5bn8OtxZgTr58svKsijwMrG7qjnokpfykfqYQ==",
            "Total": 3,
            "Unread": 0
        },
        {
            "LabelID": "PYW3f9DGHAExMdOQMbmKN5lIDaUCu652_3BptaOWyOMWhFGvxgX9EOLW4G8kuvWFedDKFoTWpIuePVav1Vr21Q==",
            "Total": 2,
            "Unread": 0
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let newLabel = """
{
    "Code": 1000,
    "EventID": "tTYHB879QchPPy30KBgoHLtPTmDrCGy7LEpO_Ci_TcFw==",
    "Refresh": 0,
    "More": 0,
    "Labels": [
        {
            "ID": "e7vaVmdmUi4dVUP5PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==",
            "Action": 1,
            "Label": {
                "ID": "e7vaVmdmUi4dVUP5PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==",
                "Name": "testLabel",
                "Path": "testLabel",
                "Type": 1,
                "Color": "#c44800",
                "Order": 14,
                "Notify": 0,
                "Expanded": 0,
                "Sticky": 0,
                "Display": 1,
                "ParentID": "Y8EYHAHBmPvcYYoZ-goDI5bn8Ot"
            }
        },
        {
            "ID": "qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==",
            "Action": 2,
            "Label": {
                "ID": "qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==",
                "Name": "testLabel2",
                "Path": "testLabel2",
                "Type": 1,
                "Color": "#c44800",
                "Order": 15,
                "Notify": 1,
                "Expanded": 1,
                "Sticky": 1,
                "Display": 1
            }
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let deleteLabel = """
{
    "Code": 1000,
    "EventID": "ES9zFQ40gGZ2knm1BGQcbw-lxR41Bq49nsIALF88HKAWYZB1hyk24LHkXJvg==",
    "Refresh": 0,
    "More": 0,
    "Labels": [
        {
            "ID": "e7vaVmdmUi4dVUPEGeEoC65PXv-qQw9VzWcO1p_M0P57R8LmS4py95OBT_xKPoPA==",
            "Action": 0
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let deleteContact = """
{
    "Code": 1000,
    "EventID": "o7QmZ94HvYeaBwRz74c7C1Ji87qTWrvB9gNrPepjW0pWlDsrd8P6vo8Ow==",
    "Refresh": 0,
    "More": 0,
    "Contacts": [
        {
            "ID": "XVoMXk6t55XPh-OFw9lM3yLQKYxsuaA5-bN8RzyZKe3ym85iwwVVqZXyQ==",
            "Action": 0
        }
    ],
    "ContactEmails": [
        {
            "ID": "PybPhCZN7O5CEkxPCpJHX_5Dz-aF6HUQsP5E-OEfWST0gcCayq_lYehI8tZckqnCA==",
            "Action": 0
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let modifyContact = """
{
    "Code": 1000,
    "EventID": "oSXqIYm3WAwPlkyovdMWrKP5cGhT--TEgxkCnYkMdTbA6dmutxcQ==",
    "Refresh": 0,
    "More": 0,
    "Contacts": [
        {
            "ID": "upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==",
            "Action": 2,
            "Contact": {
                "ID": "upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==",
                "Name": "TestName",
                "UID": "F57C8277-585D-4327-88A6-B5689FF69DFE",
                "Size": 541,
                "CreateTime": 1696573579,
                "ModifyTime": 1699593228,
                "Cards": [
                    {
                        "Type": 3,
                        "Data": "-----BEGIN PGP MESSAGE-----\\nVersion: ProtonMail\\n\\nwV4D86C6JLhOkfkSAQdA23pYmicHS4Q4FAi+o8Ltj9mtcuBfv/6djt7EaL9h\\nwiMwVYHXmMZWlQN33TjH5Eq3iceQx9i0ASLo87lIRuYbMNka46PCwOUWBXiF\\n+Rtj8FDY0sCTAV8maG9q2ABmscwxGjrmhAiTlKGND+wpPhXS7+vDMR2qia6Z\\nsDiv3oGLhoxht6mbp7QiaLB\\nswyjyvYdv8Tu121UAsafJCr9mq7Tn+/QNVtMrLXwSu8b\\n=Mckd\\n-----END PGP MESSAGE-----\\n",
                        "Signature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKACcFgmVNvAcJkDJ/Xz0YHtZrFiEE+YLpLKAxWp7Z04fhMn9fPRge\\n1msAALlRA1CljeQM=\\n=PLH/\\n-----END PGP SIGNATURE-----\\n"
                    },
                    {
                        "Type": 2,
                        "Data": "BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID;VALUE=TEXT:pm-ez-vcard 0.0.1\\r\\nITEM0.EMAIL;TYPE=\\"INTERNET,HOME,pref\\";PREF=1:test@proton.me\\r\\nUID:F57C8277-585D-4327-88A6-B5689FF69DFE\\r\\nFN;PREF=1:TestName\\r\\nEND:VCARD",
                        "Signature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKACcFgmVNvAcJkDJ/Xz0YHtZrFiEE+YLpLKAxWp7Z04fhMn9fPRge\\n1msWiTzev+grFEi0DAY=\\n=o3zr\\n-----END PGP SIGNATURE-----\\n"
                    }
                ],
                "ContactEmails": [
                    {
                        "ID": "QfgmzQv9W8FyoeCKBaJXpWbUF0BTvKCm56eKQ==",
                        "Name": "Anna Haro",
                        "Email": "anna-haro@mac.com",
                        "IsProton": 0,
                        "Type": [
                            "internet",
                            "home",
                            "pref"
                        ],
                        "Defaults": 1,
                        "Order": 1,
                        "LastUsedTime": 0,
                        "ContactID": "upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==",
                        "LabelIDs": []
                    }
                ],
                "LabelIDs": []
            }
        }
    ],
    "ContactEmails": [
        {
            "ID": "saPUe0mny7kXL44_x8cbJZhBtUtEprh0Qvzb4kO28Ey-vM-R2gwxQ9KbGeLbIPMT2JQxQ==",
            "Action": 0
        },
        {
            "ID": "QfgmzQv9W8FyoeCKBaJXpWbUF0BTvKCm56eKQ==",
            "Action": 1,
            "ContactEmail": {
                "ID": "QfgmzQv9W8FyoeCKBaJXpWbUF0BTvKCm56eKQ==",
                "Name": "Anna Haro",
                "Email": "anna-haro@mac.com",
                "IsProton": 0,
                "Type": [
                    "internet",
                    "home",
                    "pref"
                ],
                "Defaults": 1,
                "Order": 1,
                "LastUsedTime": 0,
                "ContactID": "upBasrP-iFNnomTyeuXVw3n9-4uKoiATZbPPWaQ6F5D70oXIA==",
                "LabelIDs": []
            }
        },
        {
            "ID": "JXpWbUF0BTvKCm56eKQ==",
            "Action": 2,
            "ContactEmail": {
                "ID": "JXpWbUF0BTvKCm56eKQ==",
                "Name": "TestName",
                "Email": "testName@proton.me",
                "IsProton": 1,
                "Type": [
                    "internet",
                    "home",
                    "pref"
                ],
                "Defaults": 0,
                "Order": 2,
                "LastUsedTime": 0,
                "ContactID": "iFNnomTyeuXVw3n9",
                "LabelIDs": []
            }
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let conversationUpdate = """
{
    "Code": 1000,
    "EventID": "QnDTmbDIRcQQIGPjAIyDmCfS2Mk2FOSndZX99KfgBg==",
    "Refresh": 0,
    "More": 0,
    "Conversations": [
        {
            "ID": "ssd9ifpwenrpwjosdjfpwerq",
            "Action": 0
        },
        {
            "ID": "mjHxuuw06vSloSQwa4GLoQqwcyT4GJ4Bda2qtOWyQ==",
            "Action": 3,
            "Conversation": {
                "ID": "mjHxuuw06vSloSQwa4GLoQqwcyT4GJ4Bda2qtOWyQ==",
                "Order": 402171434036,
                "Subject": "Email Test 325878",
                "Senders": [
                    {
                        "Name": "name",
                        "Address": "sender@proton.me",
                        "IsProton": 0,
                        "DisplaySenderImage": 0,
                        "BimiSelector": null,
                        "IsSimpleLogin": 0
                    }
                ],
                "Recipients": [
                    {
                        "Name": "testMail",
                        "Address": "testMail@pm.me",
                        "IsProton": 0
                    }
                ],
                "NumMessages": 1,
                "NumUnread": 1,
                "NumAttachments": 2,
                "ExpirationTime": 0,
                "Size": 54679,
                "IsProton": 0,
                "DisplaySenderImage": 0,
                "DisplaySnoozedReminder": false,
                "BimiSelector": null,
                "Labels": [
                    {
                        "ContextNumMessages": 1,
                        "ContextNumUnread": 1,
                        "ContextTime": 1688439582,
                        "ContextExpirationTime": 0,
                        "ContextSize": 54679,
                        "ContextNumAttachments": 2,
                        "ContextSnoozeTime": 1688439582,
                        "ID": "0"
                    },
                    {
                        "ContextNumMessages": 1,
                        "ContextNumUnread": 1,
                        "ContextTime": 1688439582,
                        "ContextExpirationTime": 0,
                        "ContextSize": 54679,
                        "ContextNumAttachments": 2,
                        "ContextSnoozeTime": 1688439582,
                        "ID": "5"
                    },
                    {
                        "ContextNumMessages": 1,
                        "ContextNumUnread": 1,
                        "ContextTime": 1688439582,
                        "ContextExpirationTime": 0,
                        "ContextSize": 54679,
                        "ContextNumAttachments": 2,
                        "ContextSnoozeTime": 1688439582,
                        "ID": "15"
                    }
                ],
                "AttachmentInfo": {
                    "image/png": {
                        "attachment": 2
                    }
                },
                "AttachmentsMetadata": [
                    {
                        "ID": "V4WrbdOshmKMZnLJJyfqCWsuol9bV_NpSgNNMWjOE361FFec4aHkvX1Q==",
                        "Name": "moon.png",
                        "Size": 24437,
                        "MIMEType": "image/png",
                        "Disposition": "attachment"
                    },
                    {
                        "ID": "PttIO0lOXJDjVHumLu_zmYraomvXYDnbUuadmakHef9Vd58Inqg==",
                        "Name": "moon.png",
                        "Size": 18364,
                        "MIMEType": "image/png",
                        "Disposition": "attachment"
                    }
                ]
            }
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let messageDelete = """
{
    "Code": 1000,
    "EventID": "G7-h36BvxtTuPHUIYJLUxNFl_2UY8W2H_teyETChc5ZBCRQ==",
    "Refresh": 0,
    "More": 0,
    "Messages": [
        {
            "ID": "c1B3MfMAxkUfKfkwv9gE1qaWFG7p_4fBxF2XLefqwTYF1ejviu_KSfUvdg==",
            "Action": 0
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let messageUpdate = """
{
    "Code": 1000,
    "EventID": "G7-h36BvxtTuPHUIYJLUxNFl_2UY8W2H_teyETChc5ZBCRQ==",
    "Refresh": 0,
    "More": 0,
    "Messages": [
        {
            "ID": "c1B3MfMAxkUfKfkwv9gE1qaWFG7p_4fBxF2XLefqwTYF1ejviu_KSfUvdg==",
            "Action": 3,
            "Message": {
                "ID": "c1B3MfMAxkUfKfkwv9gE1qaWFG7p_4fBxF2XLefqwTYF1ejviu_KSfUvdg==",
                "Order": 403238854175,
                "ConversationID": "mjHxuuw06vSloSQwCBdLUyuzy9CrPrcpoQqwcyT4GJ4Bda2qtOWyQ==",
                "Subject": "TestEmail",
                "Unread": 0,
                "Sender": {
                    "Name": "name",
                    "Address": "sender@mail.me",
                    "IsProton": 0,
                    "DisplaySenderImage": 0,
                    "BimiSelector": null,
                    "IsSimpleLogin": 0
                },
                "SenderAddress": "sender@mail.me",
                "SenderName": "name",
                "Flags": 8397825,
                "Type": 0,
                "IsEncrypted": 2,
                "IsReplied": 0,
                "IsRepliedAll": 0,
                "IsForwarded": 0,
                "IsProton": 0,
                "DisplaySenderImage": 0,
                "BimiSelector": null,
                "SnoozeTime": 0,
                "ToList": [
                    {
                        "Name": "test",
                        "Address": "test@pm.me",
                        "Group": "",
                        "IsProton": 0
                    }
                ],
                "CCList": [],
                "BCCList": [],
                "Time": 1688439582,
                "Size": 54679,
                "NumAttachments": 2,
                "ExpirationTime": 0,
                "AddressID": "bHFOZeFQEQdJf862nqkDwMw1dzGWiyiM_rvkIMkZQJbHfzCX7n5j0w==",
                "ExternalID": "e5b44b97-e047-d312d9b02723@mail.com",
                "LabelIDs": [
                    "0",
                    "5",
                    "15",
                    "_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g=="
                ],
                "LabelIDsAdded": [
                    "_CnYJz7oOv1GTZ0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH84pvqQ6g86W-0Qd5o1Vk0x8WTOKq6g=="
                ],
                "LabelIDsRemoved": [
                    "Z0a2De-4IF7mOLzqcSDqdhiPWnBKbwJkaTowYWD78jH"
                ],
                "AttachmentInfo": {
                    "image/png": {
                        "attachment": 2
                    }
                },
                "AttachmentsMetadata": [
                    {
                        "ID": "V4WrbdOshmKMt9CRYCWsuol9bV_NpSgNNMWjOE361FFec4aHkvX1Q==",
                        "Name": "moon.png",
                        "Size": 24437,
                        "MIMEType": "image/png",
                        "Disposition": "attachment"
                    },
                    {
                        "ID": "PttIO0lOd4Z0oMAnVjVHumLu_zmYraomvXYDnbUuadmakHef9Vd58Inqg==",
                        "Name": "moon.png",
                        "Size": 18364,
                        "MIMEType": "image/png",
                        "Disposition": "attachment"
                    }
                ]
            }
        }
    ],
    "Notifications": [],
    "Notices": []
}
"""

    static let draftInsert = """
{
    "Code": 1000,
    "EventID": "F6SxA9Fhd4MbT5lJWOQms01EV-WBb5pe8j4YOjeHlyoGkUe7uGXQI0dQ==",
    "Refresh": 0,
    "More": 0,
    "Messages": [
        {
            "ID": "w3Xjn6rCOyTM2EFMWhgRpfeNujozP6u6PEYEpH2PW0M4qymA6OENDjRI1ymKA==",
            "Action": 1,
            "Message": {
                "ID": "w3Xjn6rCOyTM2EFMWhgRpfeNujozP6u6PEYEpH2PW0M4qymA6OENDjRI1ymKA==",
                "Order": 403343586214,
                "ConversationID": "RZX1jyBAYBRGzYOPRZ3B6rqg8N7r1sjuseJPml0H4p_LL9mhgFnHiClT7TNi_JA==",
                "Subject": "(No Subject)",
                "Unread": 0,
                "Sender": {
                    "Name": "L",
                    "Address": "ccList",
                    "IsProton": 0,
                    "DisplaySenderImage": 0,
                    "BimiSelector": null,
                    "IsSimpleLogin": 0
                },
                "SenderAddress": "test@protonmail.ch",
                "SenderName": "L",
                "Flags": 12,
                "Type": 1,
                "IsEncrypted": 5,
                "IsReplied": 0,
                "IsRepliedAll": 0,
                "IsForwarded": 0,
                "IsProton": 0,
                "DisplaySenderImage": 0,
                "BimiSelector": null,
                "SnoozeTime": 0,
                "ToList": [],
                "CCList": [],
                "BCCList": [
                    {
                        "Name": "test",
                        "Address": "test@pm.me",
                        "Group": "",
                        "IsProton": 0
                    }
                ],
                "Time": 1700191020,
                "Size": 231,
                "NumAttachments": 0,
                "ExpirationTime": 0,
                "AddressID": "JwUa_eV8uqbTqVNeYNEo5psVgBnB_u4pCO-01Yy1QAp3stedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
                "ExternalID": null,
                "LabelIDs": [
                    "1",
                    "5",
                    "8",
                    "15"
                ],
                "AttachmentInfo": {},
                "AttachmentsMetadata": [
                    {
                        "ID": "pNnebrcs9wmfCa7le_relCZVwAEnhToQ1Z-cWGbdEGWxZjLQ7DGRhV-Bc373AzmGTuiog4MCzH5J2qxT4-nw4w==",
                        "Name": "Test.pdf",
                        "Size": 434137,
                        "MIMEType": "application/pdf",
                        "Disposition": "attachment"
                    }
                ]
            }
        }
    ],
    "Notices": []
}
"""

    static let draftUpdate = """
{
    "Code": 1000,
    "EventID": "F6SxA9Fhd4MbT5lJWOQms01EV-WBb5pe8j4YOjeHlyoGkUe7uGXQI0dQ==",
    "Refresh": 0,
    "More": 0,
    "Messages": [
        {
            "ID": "w3Xjn6rCOyTM2EFMWhgRpfeNujozP6u6PEYEpH2PW0M4qymA6OENDjRI1ymKA==",
            "Action": 2,
            "Message": {
                "ID": "w3Xjn6rCOyTM2EFMWhgRpfeNujozP6u6PEYEpH2PW0M4qymA6OENDjRI1ymKA==",
                "Order": 403343586214,
                "ConversationID": "RZX1jyBAYBRGzYOPRZ3B6rqg8N7r1sjuseJPml0H4p_LL9mhgFnHiClT7TNi_JA==",
                "Subject": "(No Subject)",
                "Unread": 0,
                "Sender": {
                    "Name": "L",
                    "Address": "ccList",
                    "IsProton": 0,
                    "DisplaySenderImage": 0,
                    "BimiSelector": null,
                    "IsSimpleLogin": 0
                },
                "SenderAddress": "test@protonmail.ch",
                "SenderName": "L",
                "Flags": 12,
                "Type": 1,
                "IsEncrypted": 5,
                "IsReplied": 0,
                "IsRepliedAll": 0,
                "IsForwarded": 0,
                "IsProton": 0,
                "DisplaySenderImage": 0,
                "BimiSelector": null,
                "SnoozeTime": 0,
                "ToList": [],
                "CCList": [],
                "BCCList": [],
                "Time": 1700191020,
                "Size": 231,
                "NumAttachments": 0,
                "ExpirationTime": 0,
                "AddressID": "JwUa_eV8uqbTqVNeYNEo5psVgBnB_u4pCO-01Yy1QAp3stedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
                "ExternalID": null,
                "LabelIDs": [
                    "1",
                    "5",
                    "8",
                    "15"
                ],
                "AttachmentInfo": {},
                "AttachmentsMetadata": []
            }
        }
    ],
    "Notices": []
}
"""

    static let contactEvents_insertsAndUpdates_lessThan15 = """
{
          "Code": 1000,
          "EventID": "F5Lr-HwtHPeRwIgrzlR6r4i6t408b86KaY97AANQ2ybfOka2eGWNPvtibNB4Sz19OPb2JRJ6mX_xy1ay4354Tg==",
          "Refresh": 0,
          "More": 0,
          "Contacts": [
            {
              "ID": "FU3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "EK2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "PA9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "FU3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            }
          ],
          "UsedSpace": 77985967,
          "UsedBaseSpace": 77985967,
          "UsedDriveSpace": 0,
          "ProductUsedSpace": {
            "Calendar": 0,
            "Contact": 386903,
            "Drive": 0,
            "Mail": 77599064,
            "Pass": 0
          },
          "Notifications": [],
          "Notices": []
        }
"""

    static let contactEvents_insertsAndUpdates_moreThan15 = """
{
          "Code": 1000,
          "EventID": "F5Lr-HwtHPeRwIgrzlR6r4i6t408b86KaY97AANQ2ybfOka2eGWNPvtibNB4Sz19OPb2JRJ6mX_xy1ay4354Tg==",
          "Refresh": 0,
          "More": 0,
          "Contacts": [
            {
              "ID": "FU3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "EK2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "PA9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "FU3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "DD2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "RR9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "WW3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "HH2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "JJ9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "UU3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "TT2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "EP9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "TI3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "IW2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "SR9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "AB3sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "AC2sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 1
            },
            {
              "ID": "AD9sgyFSwzI_zid5ChG0_NKTsf1zfcc7YLw6YUBDOePKs5XavUQeb9TxFIlFpYxnPEzE4qmR3H1uD8lrKEahXQ==",
              "Action": 2
            },
            {
              "ID": "c4-E6qq6WXuDfn-5wwTmlGu6QZab3XicOGfrllraZT2jpt1zUB_UepxnBAYpET2q80LBOz1-kcDV9HAd2f9ZhA==",
              "Action": 2
            }
          ],
          "UsedSpace": 77985967,
          "UsedBaseSpace": 77985967,
          "UsedDriveSpace": 0,
          "ProductUsedSpace": {
            "Calendar": 0,
            "Contact": 386903,
            "Drive": 0,
            "Mail": 77599064,
            "Pass": 0
          },
          "Notifications": [],
          "Notices": []
        }

"""
}
