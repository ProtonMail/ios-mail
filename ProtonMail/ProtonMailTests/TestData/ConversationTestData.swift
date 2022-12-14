//
//  ConversationTestData.swift
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

let testConversationsData = """
{
"Code": 1000,
"Total": 8,
"Limit": 8,
"Conversations": [
    {
        "ID": "T84AbM3JlI2QtLr_8LjwZTTTTTTTT-UH7UMqoxs9yH7fZCVIlwJ8SsiaJLb0ha8RVOa2x7AzW-valZOR_sg==",
        "Order": 300634479085,
        "Subject": "TestT",
        "Senders": [
            {
                "Address": "test@gmail.com",
                "Name": "tester"
            },
            {
                "Address": "test@protonmail.ch",
                "Name": "Test"
            }
        ],
        "Recipients": [
            {
                "Address": "test1@gmail.com",
                "Name": "test1"
            },
            {
                "Address": "test@protonmail.ch",
                "Name": "Test"
            }
        ],
        "NumMessages": 2,
        "NumUnread": 0,
        "NumAttachments": 0,
        "ExpirationTime": 0,
        "Size": 792,
        "ContextSize": 280,
        "ContextTime": 1604543563,
        "Time": 1604543563,
        "ContextNumMessages": 1,
        "ContextNumUnread": 0,
        "ContextNumAttachments": 0,
        "LabelIDs": [
            "0",
            "2",
            "5",
            "7"
        ],
        "Labels": [
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1604543563,
                "ContextSize": 280,
                "ContextNumAttachments": 0,
                "ID": "0"
            },
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1604543515,
                "ContextSize": 512,
                "ContextNumAttachments": 0,
                "ID": "2"
            },
            {
                "ContextNumMessages": 2,
                "ContextNumUnread": 0,
                "ContextTime": 1604543563,
                "ContextSize": 792,
                "ContextNumAttachments": 0,
                "ID": "5"
            },
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1604543515,
                "ContextSize": 512,
                "ContextNumAttachments": 0,
                "ID": "7"
            }
        ]
    },
    {
        "ID": "y9m4m1QxAnhoOiBPFXbyke8OiITkaQDKamt-iCe4z5kedOH9nD1xc7ubSxKxWgyY1_dIVlXK0LtHLG7YK-W9qw==",
        "Order": 300462229414,
        "Subject": "ProtonDrive security, ProtonVPN server poll, and more",
        "Senders": [
            {
                "Address": "contact@proton.me",
                "Name": "Proton Newsletter"
            }
        ],
        "Recipients": [
            {
                "Address": "linquas@protonmail.ch",
                "Name": ""
            }
        ],
        "NumMessages": 1,
        "NumUnread": 0,
        "NumAttachments": 16,
        "ExpirationTime": 0,
        "Size": 1239883,
        "ContextSize": 1239883,
        "ContextTime": 1599241312,
        "Time": 1599241312,
        "ContextNumMessages": 1,
        "ContextNumUnread": 0,
        "ContextNumAttachments": 16,
        "LabelIDs": [
            "0",
            "5",
            "10"
        ],
        "Labels": [
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1599241312,
                "ContextSize": 1239883,
                "ContextNumAttachments": 16,
                "ID": "0"
            },
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1599241312,
                "ContextSize": 1239883,
                "ContextNumAttachments": 16,
                "ID": "5"
            },
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1599241312,
                "ContextSize": 1239883,
                "ContextNumAttachments": 16,
                "ID": "10"
            }
        ]
    }
]
}
"""
let testConversationDetailData = """
{
    "Code": 1000,
    "Conversation": {
        "ID": "T84AbM3JlI2QtLr_8LjwZTTTTTTTT-UH7UMqoxs9yH7fZCVIlwJ8SsiaJLb0ha8RVOa2x7AzW-valZOR_sg==",
        "Order": 300634479085,
        "Subject": "TestT",
        "Senders": [
            {
                "Address": "test@gmail.com",
                "Name": "tester"
            },
            {
                "Address": "test@protonmail.ch",
                "Name": "Test"
            }
        ],
        "Recipients": [
            {
                "Address": "test1@gmail.com",
                "Name": "test1"
            },
            {
                "Address": "test@protonmail.ch",
                "Name": "Test"
            }
        ],
        "NumMessages": 2,
        "NumUnread": 0,
        "NumAttachments": 0,
        "ExpirationTime": 0,
        "Size": 792,
        "LabelIDs": [],
        "Labels": [
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1604543563,
                "ContextSize": 280,
                "ContextNumAttachments": 0,
                "ID": "0"
            },
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1604543515,
                "ContextSize": 512,
                "ContextNumAttachments": 0,
                "ID": "2"
            },
            {
                "ContextNumMessages": 2,
                "ContextNumUnread": 0,
                "ContextTime": 1604543563,
                "ContextSize": 792,
                "ContextNumAttachments": 0,
                "ID": "5"
            },
            {
                "ContextNumMessages": 1,
                "ContextNumUnread": 0,
                "ContextTime": 1604543515,
                "ContextSize": 512,
                "ContextNumAttachments": 0,
                "ID": "7"
            }
        ]
    },
    "Messages": [
        {
            "ID": "uRA-Yxg_D1aU_WssF71zbN2Cd_FVkmhu2PdvNnt6Fz4fiMJhXTjTVqDJJBxcetoX8ja6qRCzRdMLw65AiPbgRA==",
            "ConversationID": "T84AbM3JlI2QtLr_8LjwZTTTTTTTT-UH7UMqoxs9yH7fZCVIlwJ8SsiaJLb0ha8RVOa2x7AzW-valZOR_sg==",
            "Subject": "TestT",
            "Unread": 0,
            "SenderAddress": "test1@gmail.com",
            "SenderName": "test1",
            "Sender": {
                "Address": "test1@gmail.com",
                "Name": "test1"
            },
            "Flags": 8206,
            "Type": 2,
            "IsEncrypted": 1,
            "IsReplied": 0,
            "IsRepliedAll": 0,
            "IsForwarded": 0,
            "ToList": [
                {
                    "Name": "test@gmail.com",
                    "Address": "test@gmail.com",
                    "Group": ""
                }
            ],
            "CCList": [],
            "BCCList": [],
            "Time": 1604543515,
            "Size": 512,
            "NumAttachments": 0,
            "ExpirationTime": 0,
            "AddressID": "JwUa_eV8uqbTqVertsFytegBnB_u4pCO-01Yy1QAp3stedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
            "LabelIDs": [
                "2",
                "5",
                "7"
            ]
        }
    ]
}
"""

let testConversationReadData = """
{
  "Code": 1001,
  "Responses": [
    {
      "ID": "KPlISx5MiML3XcSY-tfNw==",
      "Response": {
        "Code": 1000
      }
    }
  ]
}
"""

let testConversationDeleteData = """
{
  "Code": 1001,
  "Responses": [
    {
      "ID": "KPlISx5MiML3XcSY-tfNw==",
      "Response": {
        "Code": 1000
      }
    }
  ]
}
"""

let testConversationLabelData = """
{
  "Code": 1001,
  "Responses": [
    {
      "ID": "KPlISx5MiML3XcSY-tfNw==",
      "Response": {
        "Code": 1000
      }
    }
  ]
}
"""

let testConversationUnlabelData = """
{
  "Code": 1001,
  "Responses": [
    {
      "ID": "KPlISx5MiML3XcSY-tfNw==",
      "Response": {
        "Code": 1000
      }
    }
  ]
}
"""

let testConversationExpireData = """
{
  "Code": 1001,
  "Responses": [
    {
      "ID": "KPlISx5MiML3XcSY-tfNw==",
      "Response": {
        "Code": 1000
      }
    }
  ]
}
"""

let conversationObjetcTestData = """
                      {
                         "ID":"7roRxUKBEBHTl22o-47jRh4A6i_uR4UNUX_az_zCmFR10yw6Nu40z-Pl8QRm-dzoVb6OdQ==",
                         "Order":300704832180,
                         "Subject":"Fwd: Test photo",
                         "Senders":[
                            {
                               "Address":"test@proton.me",
                               "Name":"Steven Lin"
                            }
                         ],
                         "Recipients":[
                            {
                               "Address":"lll@protonmail.ch",
                               "Name":"lll@protonmail.ch"
                            }
                         ],
                         "NumMessages":1,
                         "NumUnread":0,
                         "NumAttachments":5,
                         "ExpirationTime":0,
                         "Size":17711047,
                         "ContextSize":17711047,
                         "ContextTime":1605861149,
                         "Time":1605861149,
                         "ContextNumMessages":1,
                         "ContextNumUnread":0,
                         "ContextNumAttachments":5,
                         "LabelIDs":[
                            "0",
                            "5"
                         ],
                         "Labels":[
                            {
                               "ContextNumMessages":1,
                               "ContextNumUnread":0,
                               "ContextTime":1605861149,
                               "ContextSize":17711047,
                               "ContextNumAttachments":5,
                               "ID":"0"
                            },
                            {
                               "ContextNumMessages":9,
                               "ContextNumUnread":2,
                               "ContextTime":1605861149,
                               "ContextSize":17711047,
                               "ContextNumAttachments":4,
                               "ID":"5"
                            }
                         ]
                      }
    """

let testConversationEvent = """
          {
             "ID":"7roRxUKBEBHTl22odgEWglj-47jRh4A6i_uR4UNfVCmu7c9JUX_az_zCmFR10yw6Nu40z-Pl8QRm-dzoVb6OdQ==",
             "Action":3,
             "Conversation":{
                "NumUnread":1,
                "Labels":[
                   {
                      "ContextNumMessages":1,
                      "ContextNumUnread":1,
                      "ContextTime":1605861149,
                      "ContextSize":17711047,
                      "ContextNumAttachments":5,
                      "ID":"0"
                   },
                   {
                      "ContextNumMessages":1,
                      "ContextNumUnread":1,
                      "ContextTime":1605861149,
                      "ContextSize":17711047,
                      "ContextNumAttachments":5,
                      "ID":"5"
                   }
                ]
             }
          }
"""
