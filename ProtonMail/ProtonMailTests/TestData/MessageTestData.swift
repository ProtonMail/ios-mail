//
//  MessageTestData.swift
//  ProtonMailTests
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

import Foundation

let testMessageMetaData = """
{
"IsForwarded" : 0,
"IsEncrypted" : 1,
"ExpirationTime" : 0,
"ReplyTo" : {
"Address" : "contact@protonmail.ch",
"Name" : "ProtonMail"
},
"Subject" : "Important phishing warning for all ProtonMail users",
"BCCList" : [
],
"Size" : 2217,
"ToList" : [
{
"Address" : "feng88@protonmail.com",
"Name" : "",
"Group" : ""
}
],
"Order" : 200441873160,
"IsRepliedAll" : 0,
"ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
"AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
"Location" : 0,
"LabelIDs" : [
"0",
"5",
"10"
],
"Time" : 1525279399,
"NumAttachments" : 0,
"SenderAddress" : "contact@protonmail.ch",
"MIMEType" : "texthtml",
"Starred" : 1,
"Unread" : 0,
"ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
"ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
"Flags" : 13,
"SenderName" : "ProtonMail",
"SpamScore" : 0,
"Type" : 0,
"CCList" : [
],
"Sender" : {
"Address" : "contact@protonmail.ch",
"Name" : "ProtonMail"
},
"IsReplied" : 0
}
"""

let testMessageDetailData = """
{
"IsForwarded" : 0,
"IsEncrypted" : 1,
"ExpirationTime" : 0,
"ReplyTo" : {
"Address" : "contact@protonmail.ch",
"Name" : "ProtonMail"
},
"Subject" : "Important phishing warning for all ProtonMail users",
"BCCList" : [
],
"Size" : 2217,
"ParsedHeaders" : {
"Subject" : "Important phishing warning for all ProtonMail users",
"X-Pm-Content-Encryption" : "end-to-end",
"To" : "feng88@protonmail.com",
"X-Auto-Response-Suppress" : "OOF",
"Precedence" : "bulk",
"X-Original-To" : "feng88@protonmail.com",
"Mime-Version" : "1.0",
"Return-Path" : "<contact@protonmail.ch>",
"Content-Type" : "texthtml",
"Delivered-To" : "feng88@protonmail.com",
"From" : "ProtonMail <contact@protonmail.ch>",
"Received" : "from mail.protonmail.ch by mail.protonmail.ch; Wed, 02 May 2018 12:43:19 -0400",
"Message-Id" : "<MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch>",
"Date" : "Wed, 02 May 2018 12:43:19 -0400",
"X-Pm-Origin" : "internal"
},
"ToList" : [
{
"Address" : "feng88@protonmail.com",
"Name" : "",
"Group" : ""
}
],
"Order" : 200441873160,
"IsRepliedAll" : 0,
"ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
"AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
"Location" : 0,
"LabelIDs" : [
"0",
"5",
"10"
],
"Time" : 1525279399,
"ReplyTos" : [
{
"Address" : "contact@protonmail.ch",
"Name" : "ProtonMail"
}
],
"NumAttachments" : 0,
"SenderAddress" : "contact@protonmail.ch",
"MIMEType" : "texthtml11111",
"Starred" : 1,
"Unread" : 0,
"ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
"ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
"Body" : "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----",
"Flags" : 13,
"Header" : "Date: Wed, 02 May 2018 12:43:19 this is a header",
"SenderName" : "ProtonMail",
"SpamScore" : 0,
"Attachments" : [
],
"Type" : 0,
"CCList" : [
],
"Sender" : {
"Address" : "contact@protonmail.ch",
"Name" : "ProtonMail"
},
"IsReplied" : 0
}
"""

let testMessageDetailDataWithAutoReply = #"{"ID":"qeSnADkutDnf_mhEI_vJjoEkCt2YMVbxpnX4EF9qm6uTheLp2DDOYx2VHznNYYTbePG0-pCEoBt0xhAXOpmZgw==","Order":401434236846,"ConversationID":"9kzxIsU-SR-MJltgHqSehY5_WfIwyBUDQHtQ6VbMk33XgrHuCDhY8i6seQmvG-rir_u7F7B8akuhrKG4vM0itw==","Subject":"Auto: Test","Unread":0,"SenderAddress":"mt.benlechhab@protonmail.com","SenderName":"Mustapha Tarek BEN LECHHAB","Sender":{"Address":"mt.benlechhab@protonmail.com","Name":"Mustapha Tarek BEN LECHHAB"},"Flags":9237,"Type":0,"IsEncrypted":10,"IsReplied":0,"IsRepliedAll":0,"IsForwarded":0,"ToList":[{"Name":"","Address":"mousstest@protonmail.com","Group":""}],"CCList":[],"BCCList":[],"Time":1629097440,"Size":112,"NumAttachments":0,"ExpirationTime":0,"SpamScore":0,"AddressID":"SPhI2s8Fux2i2eX9BaV8IOyjqifE_mbs_Eh-34Hav6lnLvBis97jAKyMjvLALbMMUe0a-iNTLsI_GI_s9Qb17Q==","ExternalID":"WemzDJo9Oic4MwZPlsbWNOiNAJTBvH71NnrTsuksluYVL1v0mGuzbmKpGdGz8ob1ObcmsVjMrdPM_kxieuTohsguSbgTanl6G_zcmLP7Nao=@protonmail.com","Body":"-----BEGIN PGP MESSAGE-----\nVersion: ProtonMail\n\nwcBMA3bnQeSvZMOdAQgArtCoRcgXOx7duZFGJJVE2XgBOt9ed58Z9k507RBp\nKrCCWQtwRAuMf8fTImEQGTpE0kX1EiujvvPeWPPgwd3OIEKPNcY/iTwTexuR\nZ1zStaVjnJpis98w7zUmly0RDY+9EavivImCUwBkkpz2xy2OJ9DBr6A+dUbD\nJDG6KF56rQBmZzIjfQ4Q4kVKsK3gFrBqjDgigL7WNzvjhHNPLLZtWbrXT7AM\nJ+uDs+057+F4widQf0AmW+0WPFFD9PJJfyY+IC1rKSTxRBNirJsWHljI6Q0Q\nUf/RaHCziaOn7Culnk4UDAqwqFoAQO9sQcMreSxMORqUGg0zZGfCAdOUB8iw\nnNJuAY9UCFY4UdZV36p+gPAmtP/rOqg7v/dt0JPcMdZ3X54ydS/Hn/vzKaHd\nh9cIW/OpplQiGMDnapbz93Wo/QFu3vmmHB0GtTYKbtm+IBJgiU8okGii7T1O\nlG8XXLp8oRbWjRkRxqjXWxDsA2jEiHA=\n=uog7\n-----END PGP MESSAGE-----\n","MIMEType":"text/html","Header":"In-Reply-To: <7bMpq4BTX2dHPPbeidrilXh9iEThQUdRLUg-DNDp6dtE1yENT8nTHJbTIhgVbSiiWurZlepKOPrWnkfzKHWlKBIo_c_KQKmFDYhkRlU79dE=@protonmail.com>\r\nReferences: <7bMpq4BTX2dHPPbeidrilXh9iEThQUdRLUg-DNDp6dtE1yENT8nTHJbTIhgVbSiiWurZlepKOPrWnkfzKHWlKBIo_c_KQKmFDYhkRlU79dE=@protonmail.com>\r\nAuto-Submitted: auto-replied\r\nX-Auto-Response-Suppress: OOF\r\nX-Autoreply: yes\r\nPrecedence: bulk\r\nX-Pm-Origin: internal\r\nX-Pm-Content-Encryption: on-delivery\r\nSubject: Auto: Test\r\nTo: mousstest@protonmail.com\r\nFrom: Mustapha Tarek BEN LECHHAB <mt.benlechhab@protonmail.com>\r\nDate: Mon, 16 Aug 2021 07:04:00 +0000\r\nMime-Version: 1.0\r\nContent-Type: text/html\r\nMessage-Id: <WemzDJo9Oic4MwZPlsbWNOiNAJTBvH71NnrTsuksluYVL1v0mGuzbmKpGdGz8ob1ObcmsVjMrdPM_kxieuTohsguSbgTanl6G_zcmLP7Nao=@protonmail.com>\r\nX-Pm-Spamscore: 0\r\nReceived: from mail.protonmail.ch by mail.protonmail.ch; Mon, 16 Aug 2021 07:04:05 +0000\r\nX-Original-To: mousstest@protonmail.com\r\nReturn-Path: <mt.benlechhab@protonmail.com>\r\nDelivered-To: mousstest@protonmail.com\r\n","ParsedHeaders":{"In-Reply-To":"<7bMpq4BTX2dHPPbeidrilXh9iEThQUdRLUg-DNDp6dtE1yENT8nTHJbTIhgVbSiiWurZlepKOPrWnkfzKHWlKBIo_c_KQKmFDYhkRlU79dE=@protonmail.com>","References":"<7bMpq4BTX2dHPPbeidrilXh9iEThQUdRLUg-DNDp6dtE1yENT8nTHJbTIhgVbSiiWurZlepKOPrWnkfzKHWlKBIo_c_KQKmFDYhkRlU79dE=@protonmail.com>","Auto-Submitted":"auto-replied","X-Auto-Response-Suppress":"OOF","X-Autoreply":"yes","Precedence":"bulk","X-Pm-Origin":"internal","X-Pm-Content-Encryption":"on-delivery","Subject":"Auto: Test","To":"mousstest@protonmail.com","From":"Mustapha Tarek BEN LECHHAB <mt.benlechhab@protonmail.com>","Date":"Mon, 16 Aug 2021 07:04:00 +0000","Mime-Version":"1.0","Content-Type":"text/html","Message-Id":"<WemzDJo9Oic4MwZPlsbWNOiNAJTBvH71NnrTsuksluYVL1v0mGuzbmKpGdGz8ob1ObcmsVjMrdPM_kxieuTohsguSbgTanl6G_zcmLP7Nao=@protonmail.com>","X-Pm-Spamscore":"0","Received":"from mail.protonmail.ch by mail.protonmail.ch; Mon, 16 Aug 2021 07:04:05 +0000","X-Original-To":"mousstest@protonmail.com","Return-Path":"<mt.benlechhab@protonmail.com>","Delivered-To":"mousstest@protonmail.com"},"ReplyTo":{"Address":"mt.benlechhab@protonmail.com","Name":"Mustapha Tarek BEN LECHHAB"},"ReplyTos":[{"Address":"mt.benlechhab@protonmail.com","Name":"Mustapha Tarek BEN LECHHAB"}],"Attachments":[],"LabelIDs":["0","5","o5ET9fo8-AkcIrLv8fcd_-Ql0p7ae6-YmXHc29C7ZxawOOu8zRLuSjHr2WcDkGHraF0AqHEiqOjAUGCKypVpBw==","SI4NoIQm96O22oThdXunloRQn-9FJIA_dt1GIyvRZLhNxepWCWREdlsFGnRfCPJanegU-fnQ68oZnv7v3XheAw=="]}"#

let testFetchingMessagesDataInInbox = """
{
    "Code": 1000,
    "Total": 614,
    "Limit": 614,
    "Messages": [{
        "ID": "Wv3p2AFdMVM-4SLmbVTC1ibPp0a4cfD4phT3rYshtMm5C-ZryQcomqBgie-JWH1pZFWszFrq52cQtIMX4KA38w==",
        "Order": 301829216480,
        "ConversationID": "F_hktP2Sc76az5j2Onj-F99B7rSGtIVwHDrEKEMNmO4IyHq5RUUN8b8WLAagjsgfZZImW-EGa0WW7prceOzaRg==",
        "Subject": "Toned arms. Healthier hair. Better sleep with magnesium.",
        "Unread": 1,
        "SenderAddress": "newsletter@newsletter.healthline.com",
        "SenderName": "Healthline: Wellness Wire",
        "Sender": {
            "Address": "newsletter@newsletter.healthline.com",
            "Name": "Healthline: Wellness Wire"
        },
        "Flags": 1,
        "Type": 0,
        "IsEncrypted": 2,
        "IsReplied": 0,
        "IsRepliedAll": 0,
        "IsForwarded": 0,
        "ToList": [{
            "Name": "",
            "Address": "gocesim@protonmail.com",
            "Group": ""
        }],
        "CCList": [],
        "BCCList": [],
        "Time": 1614266155,
        "Size": 6754,
        "NumAttachments": 0,
        "ExpirationTime": 0,
        "AddressID": "AJIr9-obxp13KC6I-QfDmg97p0ZQ6pLC8IB-guiq5vpg1Iv-bc5yAT-cXspACnvWRhsb7FPf572ed10hhih1ww==",
        "ExternalID": "20210225101555.23037758.1927984@sailthru.com",
        "LabelIDs": ["0", "5"]
    }, {
        "ID": "bzW4_jl_7LfKJCWmE8C0kKgA8XfZ9aGEiXiat3h3XKz9A-9KJ1MYLgBDpYWWDkOiC0EtlzWFSDcp6vL24W_C_w==",
        "Order": 301827873537,
        "ConversationID": "ha35uME9M6ocbySbBNSqvMtd-wSwxt77oQXqA08m3oomG7uyiTHgEhtlkA9N3t5wPcyWRjOz3TdDRcSeSKVB9w==",
        "Subject": "send encrypted message to check iOS and Bridge",
        "Unread": 0,
        "SenderAddress": "goce.testpm@gmail.com",
        "SenderName": "",
        "Sender": {
            "Address": "goce.testpm@gmail.com",
            "Name": ""
        },
        "Flags": 9225,
        "Type": 0,
        "IsEncrypted": 7,
        "IsReplied": 0,
        "IsRepliedAll": 0,
        "IsForwarded": 0,
        "ToList": [{
            "Name": "",
            "Address": "gocesim@protonmail.com",
            "Group": ""
        }],
        "CCList": [],
        "BCCList": [],
        "Time": 1614254413,
        "Size": 51798,
        "NumAttachments": 1,
        "ExpirationTime": 0,
        "AddressID": "AJIr9-obxp13KC6I-QfDmg97p0ZQ6pLC8IB-guiq5vpg1Iv-bc5yAT-cXspACnvWRhsb7FPf572ed10hhih1ww==",
        "ExternalID": "CAOVuwZdfzRxs2JCycrKQ91Zjute2_4DsMVzv4c+xOm2rTNX+8Q@mail.gmail.com",
        "LabelIDs": ["0", "5"]
    }, {
        "ID": "3oGie5p95xf4he7137pkQpuXEdY0cDfDWQuC2japrDWHUoc1DyFAh54HvW9chauqNKHcO7KT48ETNJvc7KakUA==",
        "Order": 301820880231,
        "ConversationID": "fcbec1xHYjchBzX-FvS3g4DulNhXart_oTspksGLq9C7eMTGG_fN1CVQiJEg9O8J_uB9Xdp78_RC8YnCnQYjgw==",
        "Subject": "Testing cross-platform operability",
        "Unread": 0,
        "SenderAddress": "testios12@protonmail.com",
        "SenderName": "Filip Testira",
        "Sender": {
            "Address": "testios12@protonmail.com",
            "Name": "Filip Testira"
        },
        "Flags": 9229,
        "Type": 0,
        "IsEncrypted": 1,
        "IsReplied": 0,
        "IsRepliedAll": 0,
        "IsForwarded": 0,
        "ToList": [{
            "Name": "gocesim@protonmail.com",
            "Address": "gocesim@protonmail.com",
            "Group": ""
        }],
        "CCList": [],
        "BCCList": [],
        "Time": 1614180325,
        "Size": 21321,
        "NumAttachments": 8,
        "ExpirationTime": 0,
        "AddressID": "AJIr9-obxp13KC6I-QfDmg97p0ZQ6pLC8IB-guiq5vpg1Iv-bc5yAT-cXspACnvWRhsb7FPf572ed10hhih1ww==",
        "ExternalID": "gzZjBltAdvXB1l6h_iXhWvpCqgfzJ4AKPV2AkO5ElOgT5rjJvVRDq5BIuYLH8AY2Urmr3m7T57_DPPcEH2cXuOXNxwFla5bAq5YxlIXsWH8=@protonmail.com",
        "LabelIDs": ["0", "5"]
    }, {
        "ID": "ylgAmW17HJcRJSj5FFx5XILy0WmIqXEXzNfqoR_UO1hqkeemUhN7gbGwF8-2OfFMAdJnT5MFopsMeJKG7XN2gg==",
        "Order": 301812473186,
        "ConversationID": "LLYtAG5I8UKFwsAi6DXDmmToXe3_sGebY-m3Kgu2wCWrCg8ocwEiEXm-3ZQPsTSXmWfUlYkYYmPWGmGjQCKtqQ==",
        "Subject": "Eat dark chocolate \\ud83c\\udf6b. Walking workout. Therapy FAQs.",
        "Unread": 1,
        "SenderAddress": "newsletter@newsletter.healthline.com",
        "SenderName": "Healthline: Wellness Wire",
        "Sender": {
            "Address": "newsletter@newsletter.healthline.com",
            "Name": "Healthline: Wellness Wire"
        },
        "Flags": 268444673,
        "Type": 0,
        "IsEncrypted": 2,
        "IsReplied": 0,
        "IsRepliedAll": 0,
        "IsForwarded": 0,
        "ToList": [{
            "Name": "",
            "Address": "gocesim@protonmail.com",
            "Group": ""
        }],
        "CCList": [],
        "BCCList": [],
        "Time": 1614093303,
        "Size": 5655,
        "NumAttachments": 0,
        "ExpirationTime": 0,
        "AddressID": "AJIr9-obxp13KC6I-QfDmg97p0ZQ6pLC8IB-guiq5vpg1Iv-bc5yAT-cXspACnvWRhsb7FPf572ed10hhih1ww==",
        "ExternalID": "20210223101503.23017497.1949007@sailthru.com",
        "LabelIDs": ["0", "5"]
    }]
}
"""

// typo in key "Messages"
let testBadFormatedFetchingMessagesDataInInbox = """
{
    "Code": 1000,
    "Total": 614,
    "Limit": 614,
    "Messaages": [{
        "ID": "Wv3p2AFdMVM-4SLmbVTC1ibPp0a4cfD4phT3rYshtMm5C-ZryQcomqBgie-JWH1pZFWszFrq52cQtIMX4KA38w==",
        "Order": 301829216480,
        "ConversationID": "F_hktP2Sc76az5j2Onj-F99B7rSGtIVwHDrEKEMNmO4IyHq5RUUN8b8WLAagjsgfZZImW-EGa0WW7prceOzaRg==",
        "Subject": "Toned arms. Healthier hair. Better sleep with magnesium.",
        "Unread": 1,
        "SenderAddress": "newsletter@newsletter.healthline.com",
        "SenderName": "Healthline: Wellness Wire",
        "Sender": {
            "Address": "newsletter@newsletter.healthline.com",
            "Name": "Healthline: Wellness Wire"
        },
        "Flags": 1,
        "Type": 0,
        "IsEncrypted": 2,
        "IsReplied": 0,
        "IsRepliedAll": 0,
        "IsForwarded": 0,
        "ToList": [{
            "Name": "",
            "Address": "gocesim@protonmail.com",
            "Group": ""
        }],
        "CCList": [],
        "BCCList": [],
        "Time": 1614266155,
        "Size": 6754,
        "NumAttachments": 0,
        "ExpirationTime": 0,
        "AddressID": "AJIr9-obxp13KC6I-QfDmg97p0ZQ6pLC8IB-guiq5vpg1Iv-bc5yAT-cXspACnvWRhsb7FPf572ed10hhih1ww==",
        "ExternalID": "20210225101555.23037758.1927984@sailthru.com",
        "LabelIDs": ["0", "5"]
    }]
}
"""

let testFetchingMessagesDataInDraft = """
    {
        "Code": 1000,
        "Total": 16,
        "Limit": 16,
        "Messages": [{
            "ID": "7JU0HG2gpOMhk9dL65NWkF0y0os0WKf03vkDpLig_rAv-MOR5CgowrEUgJ8GBKypj5Aw65mT2A4ryFTmH1HOEA==",
            "Order": 301827940682,
            "ConversationID": "6grZuQtkw6if3OSVnks8I_vaa6_gF661tvKC7udySt78olxLdhVzLzsIZmnh20K_01Pp5a4N0p28RcvGW9_aMg==",
            "Subject": "(No Subject)",
            "Unread": 0,
            "SenderAddress": "linquas@protonmail.ch",
            "SenderName": "Linquas",
            "Sender": {
                "Address": "linquas@protonmail.ch",
                "Name": "Linquas"
            },
            "Flags": 12,
            "Type": 1,
            "IsEncrypted": 5,
            "IsReplied": 0,
            "IsRepliedAll": 0,
            "IsForwarded": 0,
            "ToList": [],
            "CCList": [],
            "BCCList": [],
            "Time": 1614223091,
            "Size": 23069303,
            "NumAttachments": 1,
            "ExpirationTime": 0,
            "AddressID": "JwUa_eV8uqbTqVNeYNEo5psVgBnB_u4pCO-01Yy1QAp3stedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
            "ExternalID": null,
            "LabelIDs": ["1", "5", "8"]
        }, {
            "ID": "sbx3fNgrU4CgoUVAKDyC3P5QJ7-ykSOgUWsaPh9eznz8shN-M6X3H_0U95vEHLyVNuIN5YiZ207vkrADJmIP7g==",
            "Order": 301827939135,
            "ConversationID": "Y2z1D55eBKufbgtKK7Wd_4lBIAcAXDX1ZHPQD0036KAZ1Agqk6LErM-d-47GMcj9Y-tD7eqNH3hhR2JLqMuR7g==",
            "Subject": "(No Subject)",
            "Unread": 0,
            "SenderAddress": "linquas@protonmail.ch",
            "SenderName": "Linquas",
            "Sender": {
                "Address": "linquas@protonmail.ch",
                "Name": "Linquas"
            },
            "Flags": 12,
            "Type": 1,
            "IsEncrypted": 5,
            "IsReplied": 0,
            "IsRepliedAll": 0,
            "IsForwarded": 0,
            "ToList": [],
            "CCList": [],
            "BCCList": [],
            "Time": 1614222951,
            "Size": 497,
            "NumAttachments": 0,
            "ExpirationTime": 0,
            "AddressID": "JwUa_eV8uqbTqVNeYNEo5psVgBnB_u4pCO-01Yy1QAp3stedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
            "ExternalID": null,
            "LabelIDs": ["1", "5", "8"]
        }]
    }
"""

let testDraftMessageMetaData = """
            {
                "ID": "7JU0HG2gpOMhk9dL65NWkF0y0os0WKf03vkDpLig_rAv-MOR5CgowrEUgJ8GBKypj5Aw65mT2A4ryFTmH1HOEA==",
                "Order": 301827940682,
                "ConversationID": "6grZuQtkw6if3OSVnks8I_vaa6_gF661tvKC7udySt78olxLdhVzLzsIZmnh20K_01Pp5a4N0p28RcvGW9_aMg==",
                "Subject": "(No Subject) Before Update",
                "Unread": 0,
                "SenderAddress": "linquas@protonmail.ch",
                "SenderName": "Linquas",
                "Sender": {
                    "Address": "linquas@protonmail.ch",
                    "Name": "Linquas"
                },
                "Flags": 12,
                "Type": 1,
                "IsEncrypted": 5,
                "IsReplied": 0,
                "IsRepliedAll": 0,
                "IsForwarded": 0,
                "ToList": [],
                "CCList": [],
                "BCCList": [],
                "Time": 1614223091,
                "Size": 23069303,
                "NumAttachments": 1,
                "ExpirationTime": 0,
                "AddressID": "JwUa_eV8uqbTqVNeYNEo5psVgBnB_u4pCO-01Yy1QAp3stedgACzpoI9d0f9K9AXpwLU4I6D0YIz9Z_97hCySg==",
                "ExternalID": null,
                "LabelIDs": ["1", "5", "8"]
            }
"""

let testSentMessageWithGroupToAndCC = """
{
  "ID": "wOudvz8rC6CDzuZ",
  "Order": 103822924506,
  "ConversationID": "W8F_XgflBkb-",
  "Subject": "Test cc",
  "Unread": 0,
  "SenderAddress": "testSender@protonmail.com",
  "SenderName": "test sender",
  "Sender": {
    "Address": "testSender@protonmail.com",
    "Name": "test sender"
  },
  "Flags": 8198,
  "Type": 2,
  "IsEncrypted": 5,
  "IsReplied": 0,
  "IsRepliedAll": 0,
  "IsForwarded": 0,
  "ToList": [
    {
      "Name": "test0",
      "Address": "aaa@gmail.com",
      "Group": "groupA"
    },
    {
      "Name": "test1",
      "Address": "test1@protonmail.com",
      "Group": "groupA"
    },
    {
      "Name": "test2",
      "Address": "test2@gmail.com",
      "Group": "groupA"
    },
    {
      "Name": "test3",
      "Address": "test3@gmail.com",
      "Group": "groupA"
    },
    {
      "Name": "test4",
      "Address": "test4@protonmail.com",
      "Group": "groupA"
    }
  ],
  "CCList": [
    {
      "Name": "test5",
      "Address": "bbb@gmail.com",
      "Group": ""
    }
  ],
  "BCCList": [

  ],
  "Time": 1637048593,
  "Size": 2373,
  "NumAttachments": 1,
  "ExpirationTime": 0,
  "AddressID": "B8Ne3BCYiq",
  "ExternalID": "_3xsb_c05b-OvEG8JwJCt2K-hs0Zvbl4yxKxx",
  "LabelIDs": [
    "2",
    "5",
    "7"
  ]
}
"""

let testSentMessageWithToAndCC = """
{
  "ID": "wOudvz8rC6CDzuZ",
  "Order": 103822924506,
  "ConversationID": "W8F_XgflBkb-",
  "Subject": "Test cc",
  "Unread": 0,
  "SenderAddress": "testSender@protonmail.com",
  "SenderName": "test sender",
  "Sender": {
    "Address": "testSender@protonmail.com",
    "Name": "test sender"
  },
  "Flags": 8198,
  "Type": 2,
  "IsEncrypted": 5,
  "IsReplied": 0,
  "IsRepliedAll": 0,
  "IsForwarded": 0,
  "ToList": [
    {
      "Name": "test0",
      "Address": "aaa@gmail.com",
      "Group": ""
    },
    {
      "Name": "test1",
      "Address": "test1@protonmail.com",
      "Group": ""
    },
    {
      "Name": "test2",
      "Address": "test2@gmail.com",
      "Group": ""
    },
    {
      "Name": "test3",
      "Address": "test3@gmail.com",
      "Group": ""
    },
    {
      "Name": "test4",
      "Address": "test4@protonmail.com",
      "Group": ""
    }
  ],
  "CCList": [
    {
      "Name": "test5",
      "Address": "bbb@gmail.com",
      "Group": ""
    }
  ],
  "BCCList": [

  ],
  "Time": 1637048593,
  "Size": 2373,
  "NumAttachments": 1,
  "ExpirationTime": 0,
  "AddressID": "B8Ne3BCYiq",
  "ExternalID": "_3xsb_c05b-OvEG8JwJCt2K-hs0Zvbl4yxKxx",
  "LabelIDs": [
    "2",
    "5",
    "7"
  ]
}
"""

let testSentMessageWithToCCAndBCC = """
{
  "ID": "wOudvz8rC6CDzuZ",
  "Order": 103822924506,
  "ConversationID": "W8F_XgflBkb-",
  "Subject": "Test cc",
  "Unread": 0,
  "SenderAddress": "testSender@protonmail.com",
  "SenderName": "test sender",
  "Sender": {
    "Address": "testSender@protonmail.com",
    "Name": "test sender"
  },
  "Flags": 8198,
  "Type": 2,
  "IsEncrypted": 5,
  "IsReplied": 0,
  "IsRepliedAll": 0,
  "IsForwarded": 0,
  "ToList": [
    {
      "Name": "test0",
      "Address": "aaa@gmail.com",
      "Group": ""
    },
    {
      "Name": "test1",
      "Address": "test1@protonmail.com",
      "Group": ""
    },
    {
      "Name": "test2",
      "Address": "test2@gmail.com",
      "Group": ""
    }
  ],
  "CCList": [
    {
      "Name": "test5",
      "Address": "bbb@gmail.com",
      "Group": ""
    }
  ],
  "BCCList": [
        {
          "Name": "test3",
          "Address": "test3@gmail.com",
          "Group": ""
        },
        {
          "Name": "test4",
          "Address": "test4@protonmail.com",
          "Group": ""
        }
  ],
  "Time": 1637048593,
  "Size": 2373,
  "NumAttachments": 1,
  "ExpirationTime": 0,
  "AddressID": "B8Ne3BCYiq",
  "ExternalID": "_3xsb_c05b-OvEG8JwJCt2K-hs0Zvbl4yxKxx",
  "LabelIDs": [
    "2",
    "5",
    "7"
  ]
}
"""
