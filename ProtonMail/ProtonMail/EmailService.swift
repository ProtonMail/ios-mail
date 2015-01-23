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
            EmailThread(title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Happy Holidays!", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: true, isEncrypted: true, isFavorite: true),
            EmailThread(title:"More tips for hiring!", sender: "Rafael Corrales", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Re: ProtonMail iOS/Android, without using HTML", sender: "Riachard TETAZ", time: "7:36pm"),
            EmailThread(title:"RE: Front End - Stanford - Kilometers", sender: "Ryan Neely", time: "7:36pm", hasAttachments: true, isEncrypted: true),
            EmailThread(title:"Wireframe Status | Monday report", sender: "Elizabeth Kintzele (GF)", time: "7:36pm", hasAttachments: false, isEncrypted: true, isFavorite: true),
            EmailThread(title:"TriNet Notice: Important Information", sender: "TriNet Passport", time: "7:36pm", hasAttachments: true, isEncrypted: true)
        ]
        
        return messages
    }
}