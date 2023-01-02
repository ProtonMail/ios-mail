// Generated using Sourcery 1.9.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
@testable import ProtonMail


extension AttachmentEntity {
    static func make(
        headerInfo: String? = nil,
        id: AttachmentID = .init(rawValue: .init()),
        keyPacket: String? = nil,
        rawMimeType: String = .init(),
        attachmentType: AttachmentType = .audio,
        name: String = .init(),
        userID: UserID = .init(rawValue: .init()),
        messageID: MessageID = .init(rawValue: .init()),
        isSoftDeleted: Bool = .init(),
        fileData: Data? = nil,
        fileSize: NSNumber = .init(),
        localURL: URL? = nil,
        isTemp: Bool = .init(),
        keyChanged: Bool = .init(),
        objectID: ObjectID = .init(rawValue: .init()),
        order: Int = .init(),
        contentId: String? = nil
    ) -> Self {
        AttachmentEntity(
            headerInfo: headerInfo,
            id: id,
            keyPacket: keyPacket,
            rawMimeType: rawMimeType,
            attachmentType: attachmentType,
            name: name,
            userID: userID,
            messageID: messageID,
            isSoftDeleted: isSoftDeleted,
            fileData: fileData,
            fileSize: fileSize,
            localURL: localURL,
            isTemp: isTemp,
            keyChanged: keyChanged,
            objectID: objectID,
            order: order,
            contentId: contentId
        )
    }
}
extension ContactEntity {
    static func make(
        objectID: ObjectID = .init(rawValue: .init()),
        contactID: ContactID = .init(rawValue: .init()),
        name: String = .init(),
        cardData: String = .init(),
        uuid: String = .init(),
        createTime: Date = .init(),
        isDownloaded: Bool = .init(),
        isCorrected: Bool = .init(),
        needsRebuild: Bool = .init(),
        isSoftDeleted: Bool = .init(),
        emailRelations: [EmailEntity] = .init()
    ) -> Self {
        ContactEntity(
            objectID: objectID,
            contactID: contactID,
            name: name,
            cardData: cardData,
            uuid: uuid,
            createTime: createTime,
            isDownloaded: isDownloaded,
            isCorrected: isCorrected,
            needsRebuild: needsRebuild,
            isSoftDeleted: isSoftDeleted,
            emailRelations: emailRelations
        )
    }
}
extension ContextLabelEntity {
    static func make(
        messageCount: Int = .init(),
        unreadCount: Int = .init(),
        time: Date? = nil,
        size: Int = .init(),
        attachmentCount: Int = .init(),
        conversationID: ConversationID = .init(rawValue: .init()),
        labelID: LabelID = .init(rawValue: .init()),
        userID: UserID = .init(rawValue: .init()),
        order: Int = .init(),
        isSoftDeleted: Bool = .init()
    ) -> Self {
        ContextLabelEntity(
            messageCount: messageCount,
            unreadCount: unreadCount,
            time: time,
            size: size,
            attachmentCount: attachmentCount,
            conversationID: conversationID,
            labelID: labelID,
            userID: userID,
            order: order,
            isSoftDeleted: isSoftDeleted
        )
    }
}
extension ConversationEntity {
    static func make(
        objectID: ObjectID = .init(rawValue: .init()),
        conversationID: ConversationID = .init(rawValue: .init()),
        expirationTime: Date? = nil,
        attachmentCount: Int = .init(),
        messageCount: Int = .init(),
        order: Int = .init(),
        senders: String = .init(),
        recipients: String = .init(),
        size: Int? = nil,
        subject: String = .init(),
        userID: UserID = .init(rawValue: .init()),
        contextLabelRelations: [ContextLabelEntity] = .init(),
        isSoftDeleted: Bool = .init()
    ) -> Self {
        ConversationEntity(
            objectID: objectID,
            conversationID: conversationID,
            expirationTime: expirationTime,
            attachmentCount: attachmentCount,
            messageCount: messageCount,
            order: order,
            senders: senders,
            recipients: recipients,
            size: size,
            subject: subject,
            userID: userID,
            contextLabelRelations: contextLabelRelations,
            isSoftDeleted: isSoftDeleted
        )
    }
}
extension EmailEntity {
    static func make(
        objectID: ObjectID = .init(rawValue: .init()),
        contactID: ContactID = .init(rawValue: .init()),
        isContactDownloaded: Bool = .init(),
        userID: UserID = .init(rawValue: .init()),
        emailID: EmailID = .init(rawValue: .init()),
        email: String = .init(),
        name: String = .init(),
        defaults: Bool = .init(),
        order: Int = .init(),
        type: String = .init(),
        lastUsedTime: Date? = nil,
        contactCreateTime: Date? = nil,
        contactName: String = .init()
    ) -> Self {
        EmailEntity(
            objectID: objectID,
            contactID: contactID,
            isContactDownloaded: isContactDownloaded,
            userID: userID,
            emailID: emailID,
            email: email,
            name: name,
            defaults: defaults,
            order: order,
            type: type,
            lastUsedTime: lastUsedTime,
            contactCreateTime: contactCreateTime,
            contactName: contactName
        )
    }
}
extension LabelCountEntity {
    static func make(
        start: Date? = nil,
        end: Date? = nil,
        update: Date? = nil,
        unreadStart: Date? = nil,
        unreadEnd: Date? = nil,
        unreadUpdate: Date? = nil,
        total: Int = .init(),
        unread: Int = .init(),
        viewMode: ViewMode = .conversation
    ) -> Self {
        LabelCountEntity(
            start: start,
            end: end,
            update: update,
            unreadStart: unreadStart,
            unreadEnd: unreadEnd,
            unreadUpdate: unreadUpdate,
            total: total,
            unread: unread,
            viewMode: viewMode
        )
    }
}
extension LabelEntity {
    static func make(
        userID: UserID = .init(rawValue: .init()),
        labelID: LabelID = .init(rawValue: .init()),
        parentID: LabelID = .init(rawValue: .init()),
        objectID: ObjectID = .init(rawValue: .init()),
        name: String = .init(),
        color: String = .init(),
        type: LabelType = .messageLabel,
        sticky: Bool = .init(),
        order: Int = .init(),
        path: String = .init(),
        notify: Bool = .init(),
        emailRelations: [EmailEntity] = .init(),
        isSoftDeleted: Bool = .init()
    ) -> Self {
        LabelEntity(
            userID: userID,
            labelID: labelID,
            parentID: parentID,
            objectID: objectID,
            name: name,
            color: color,
            type: type,
            sticky: sticky,
            order: order,
            path: path,
            notify: notify,
            emailRelations: emailRelations,
            isSoftDeleted: isSoftDeleted
        )
    }
}
extension MessageEntity {
    static func make(
        messageID: MessageID = .init(rawValue: .init()),
        addressID: AddressID = .init(rawValue: .init()),
        conversationID: ConversationID = .init(rawValue: .init()),
        userID: UserID = .init(rawValue: .init()),
        action: NSNumber? = nil,
        numAttachments: Int = .init(),
        size: Int = .init(),
        spamScore: SpamScore = .pmSpoof,
        rawHeader: String? = nil,
        rawParsedHeaders: String? = nil,
        rawFlag: Int = .init(),
        time: Date? = nil,
        expirationTime: Date? = nil,
        order: Int = .init(),
        unRead: Bool = .init(),
        unsubscribeMethods: UnsubscribeMethods? = nil,
        title: String = .init(),
        rawSender: String? = nil,
        rawTOList: String = .init(),
        rawCCList: String = .init(),
        rawBCCList: String = .init(),
        rawReplyTos: String = .init(),
        recipientsTo: [String] = .init(),
        recipientsCc: [String] = .init(),
        recipientsBcc: [String] = .init(),
        replyTo: [String] = .init(),
        mimeType: String? = nil,
        body: String = .init(),
        attachments: [AttachmentEntity] = .init(),
        labels: [LabelEntity] = .init(),
        nextAddressID: AddressID? = nil,
        expirationOffset: Int = .init(),
        isSoftDeleted: Bool = .init(),
        isDetailDownloaded: Bool = .init(),
        hasMetaData: Bool = .init(),
        lastModified: Date? = nil,
        originalMessageID: MessageID? = nil,
        originalTime: Date? = nil,
        passwordEncryptedBody: String = .init(),
        password: String = .init(),
        passwordHint: String = .init(),
        objectID: ObjectID = .init(rawValue: .init())
    ) -> Self {
        MessageEntity(
            messageID: messageID,
            addressID: addressID,
            conversationID: conversationID,
            userID: userID,
            action: action,
            numAttachments: numAttachments,
            size: size,
            spamScore: spamScore,
            rawHeader: rawHeader,
            rawParsedHeaders: rawParsedHeaders,
            rawFlag: rawFlag,
            time: time,
            expirationTime: expirationTime,
            order: order,
            unRead: unRead,
            unsubscribeMethods: unsubscribeMethods,
            title: title,
            rawSender: rawSender,
            rawTOList: rawTOList,
            rawCCList: rawCCList,
            rawBCCList: rawBCCList,
            rawReplyTos: rawReplyTos,
            recipientsTo: recipientsTo,
            recipientsCc: recipientsCc,
            recipientsBcc: recipientsBcc,
            replyTo: replyTo,
            mimeType: mimeType,
            body: body,
            attachments: attachments,
            labels: labels,
            nextAddressID: nextAddressID,
            expirationOffset: expirationOffset,
            isSoftDeleted: isSoftDeleted,
            isDetailDownloaded: isDetailDownloaded,
            hasMetaData: hasMetaData,
            lastModified: lastModified,
            originalMessageID: originalMessageID,
            originalTime: originalTime,
            passwordEncryptedBody: passwordEncryptedBody,
            password: password,
            passwordHint: passwordHint,
            objectID: objectID
        )
    }
}
