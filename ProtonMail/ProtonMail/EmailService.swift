//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

class EmailService {

    class func retrieveMessages() -> [EmailThread] {
        var messages: [EmailThread] = [
            // (title: String, sender:String, time: String, hasAttachments: Bool = false, isEncrypted: Bool = false, isFavorite: Bool = false)
            EmailThread(id: "1", title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "2", title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "3", title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm", isRead: true),
            EmailThread(id: "4", title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "5", title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true, isRead: true),
            EmailThread(id: "6", title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "7", title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true, isRead: true),
            EmailThread(id: "8", title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "9", title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm", isRead: true),
            EmailThread(id: "10", title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "11", title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(id: "12", title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "13", title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "14", title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "15", title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(id: "16", title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "17", title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(id: "18", title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "19", title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "20", title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "21", title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(id: "22", title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "23", title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(id: "24", title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true)
        ]
        
        sharedAPIService.messageList(.inbox, page: 1, sortedColumn: .date, order: .ascending, filter: .noFilter, failure: { error in
            NSLog("error: \(error)")
            })
        return messages
    }
}