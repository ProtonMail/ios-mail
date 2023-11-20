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
    "Notices": []
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
        "DisplayName": "",
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
        "SubmissionAccess": 0
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
            "ID": "1",
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
            "ID": "2",
            "Action": 1,
            "IncomingDefault": {
                "ID": "x94GA==",
                "Location": 14,
                "Type": 1,
                "Time": 1699507115,
                "Email": "test2@proton.me"
            }
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
                "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: ProtonMail\\n\\nxYYEYe5nDRYJKwYBBAHaRw8BAQdAHlJ2eejYqLzlcNin33bg\\n-----END PGP PRIVATE KEY BLOCK-----\\n",
                "Fingerprint": "f982e92ca0315a93d181ed66b",
                "Active": 1
            },
            {
                "ID": "Y0AUSJZReSj1ug==",
                "Version": 3,
                "Primary": 0,
                "RecoverySecret": null,
                "RecoverySecretSignature": null,
                "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: ProtonMail\\n\\nxYYEYbK+HxYJKwYBBAHa\\n-----END PGP PRIVATE KEY BLOCK-----\\n",
                "Fingerprint": "8a4c729117abec50125641e5648c55",
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
            "ID": "JwUa_eV8uqbTqVNeYNEo5AXpwLU4I6D0YIz9Z_97hCySg==",
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
                        "Fingerprint": "dbc534585d6697dced7264ae7e264a1",
                        "Fingerprints": [
                            "1cb0d620dab69b13b8fc8baedda3d1ad05f",
                            "dbc5345852dd3d6697dced7264ae7e264a1"
                        ],
                        "PublicKey": "-----BEGIN PGP PUBLIC KEY BLOCK-----\\nVersion: ProtonMail\\n\\nxjMEYe5nDRYJKwYBBAHaRw8BAQdAQ8764WfHxH/cU5O7Zbu6c+oi1DRf7MQX\\nTe29Fewf5ibNLWxpbnF1YXNAcHJvdG9ubWFpbC5jaCA8bGlucXVhc0Bwcm90\\nb25tYWlsLmNFNFhUWmEt09Zpfc7XJkrn4mShSj4BAJ6qOGzAo5sRmSMb\\nbAwhZm7zs1yzWloBBdKPUxmPkbXJAP9kFELRBdYRUjMn+7JYlZl2MMt6aVyT\\nicnPqCz0u/oKCQ==\\n=JMMi\\n-----END PGP PUBLIC KEY BLOCK-----\\n",
                        "Active": 1,
                        "AddressForwardingID": null,
                        "Version": 3,
                        "Activation": null,
                        "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: ProtonMail\\n\\nxYYEYe5nDRYJKwYBBAHaRw8BAQdAQ8764WfHxH/cU5O7Zbu6c+oi1DRf7MQXS3T1ml9ztcmSufiZKFKPgEAnqo4bMCjmxGZIxtsDCFm\\nbvOzXLNaWgEF0o9TGY+RtckA/2QUQtEF1hFSMyf7sliVmXYwy3ppXJOJyc+o\\nLPS7+goJ\\n=8Vkx\\n-----END PGP PRIVATE KEY BLOCK-----\\n",
                        "Token": "-----BEGIN PGP MESSAGE-----\\nVersion: ProtonMail\\n\\nwV4D86C6JLhOkfkSAQdA6d/8geU5CFP2HQp7HhR9GI92liXoKMYaC2p0a/hHxCB/+A0lb8kb2Afr4BoC0yJ6uIqs4133dcPWpB+/IX6\\n1TRnIg5NDjDEJr4UOC+mJkd5ldEzR35nTtmmxpRFS6Pdlm3aR7o=\\n=dReU\\n-----END PGP MESSAGE-----\\n",
                        "Signature": "-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKAAYFAmHuZ0kAIQkQMn9fPRge1msWIQT5guksoDFantnTh+Eyf189\\nGB7Wa1XViXZ1AA=\\n=HPz6\\n-----END PGP SIGNATURE-----\\n"
                    },
                    {
                        "ID": "o6MJHyu55uvLrikV6NOp9J7blBHC_C7xwjmiBRWQCL_xEbAazAv0A==",
                        "Primary": 0,
                        "Flags": 3,
                        "Fingerprint": "1058c7378b77bfd61c8030d084118f1",
                        "Fingerprints": [
                            "1058c7378b77bf010c05458830d084118f1",
                            "f84a52102538ee4bb4a873327198a0aed"
                        ],
                        "PublicKey": "-----BEGIN PGP PUBLIC KEY BLOCK-----\\nVersion: ProtonMail\\n\\nxjMEYbK+HxYJKwYBBAHaRw8BAQdA3GW+kcULmO3LRFlmJ2HesJdocYlInrqs\\nTGS22HnarIzNLWxpbnF1YXNAcHJvdG9ubWFpbC5jaCA8bGlucXVhc0Bwcm90\\nb25tYWlsLmNoPsKPBBAWCgAgBQJhsr4fBgsJBwgDAgQVCAoCBBYCAQACGQEC\\nGwMCgACQUCYbK+HwIbDAAhCRBU\\nWIMNCEEY8RYhBBBYxzeLd7/WHIAQwFRYgw0IQRjxr+4BAJwi/gcSO9T+4Kw7\\n38IKReN02Mc6oDrALwCI9gX6LObgAQDFw5XFOZFB8fA23Y78++eyqOlO4d+l\\nW3ZOR32Di3omDQ==\\n=Ya7r\\n-----END PGP PUBLIC KEY BLOCK-----\\n",
                        "Active": 1,
                        "AddressForwardingID": null,
                        "Version": 3,
                        "Activation": null,
                        "PrivateKey": "-----BEGIN PGP PRIVATE KEY BLOCK-----\\nVersion: ProtonMail\\n\\nxYYEYbK+HxYJKwYBBAHaRw8BAQdA3GW+kcULmO3LRFlmJ2HesJdocYlInrqs\\nTGS22HnarIz+CQMIA3WgVBfHJbhgHvLEe4Bqm02VRHevLhJ98I8iRSvjWwWn\\n/V0gEAnCL+BxI71P7grDvfwgpF\\n43TYxzqgOsAvAIj2Bfos5uABAMXDlcU5kUHx8Dbdjvz757Ko6U7h36Vbdk5H\\nfYOLeiYN\\n=sNZ/\\n-----END PGP PRIVATE KEY BLOCK-----\\n",
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
            "Unread": 0
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
            "Unread": 0
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
            "ID": "mjHxuuw06vSloSQwa4GLoQqwcyT4GJ4Bda2qtOWyQ==",
            "Action": 3,
            "Conversation": {
                "ID": "mjHxuuw06vSloSQwa4GLoQqwcyT4GJ4Bda2qtOWyQ==",
                "Order": 402171434036,
                "Subject": "Dark Mode Email Test 325878",
                "Senders": [
                    {
                        "Name": "name",
                        "Address": "0911324@gmail.com",
                        "IsProton": 0,
                        "DisplaySenderImage": 0,
                        "BimiSelector": null,
                        "IsSimpleLogin": 0
                    }
                ],
                "Recipients": [
                    {
                        "Name": "linquas",
                        "Address": "linquas@pm.me",
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
                    "15"
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
}
