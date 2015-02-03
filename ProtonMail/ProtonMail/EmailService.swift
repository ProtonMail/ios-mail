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

    class func retrieveInboxMessages() -> [EmailThread] {
        var messages: [EmailThread] = [
            // (title: String, sender:String, time: String, hasAttachments: Bool = false, isEncrypted: Bool = false, isFavorite: Bool = false)
            EmailThread(id: "1", title:"Inbox: Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "2", title:"Inbox: More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "3", title:"Inbox: Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm", isRead: true),
            EmailThread(id: "4", title:"Inbox: RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "5", title:"Inbox: Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true, isRead: true),
            EmailThread(id: "6", title:"Inbox: TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "7", title:"Inbox: Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true, isRead: true),
            EmailThread(id: "8", title:"Inbox: More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "9", title:"Inbox: Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm", isRead: true),
            EmailThread(id: "10", title:"Inbox: RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "11", title:"Inbox: Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(id: "12", title:"Inbox: TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "13", title:"Inbox: Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "14", title:"Inbox: More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "15", title:"Inbox: Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(id: "16", title:"Inbox: RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "17", title:"Inbox: Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(id: "18", title:"Inbox: TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "19", title:"Inbox: Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "20", title:"Inbox: More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "21", title:"Inbox: Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(id: "22", title:"Inbox: RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(id: "23", title:"Inbox: Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(id: "24", title:"Inbox: TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true)
        ]
        
        return messages
    }
    
    class func retrieveDraftMessages() -> [EmailThread] {
        var messages: [EmailThread] = [
            // (title: String, sender:String, time: String, hasAttachments: Bool = false, isEncrypted: Bool = false, isFavorite: Bool = false)
            EmailThread(id: "25", title:"Draft: Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(id: "26", title:"Draft: More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true),
            EmailThread(id: "27", title:"Draft: Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm", isRead: true),
            EmailThread(id: "28", title:"Draft: RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true, isRead: true)
        ]
        
        return messages
    }

}