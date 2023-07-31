// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

protocol HasBlockedSenderCacheUpdater {
    var blockedSenderCacheUpdater: BlockedSenderCacheUpdater { get }
}

extension UserContainer: HasBlockedSenderCacheUpdater {
    var blockedSenderCacheUpdater: BlockedSenderCacheUpdater {
        blockedSenderCacheUpdaterFactory()
    }
}

protocol HasBlockedSendersPublisher {
    var blockedSendersPublisher: BlockedSendersPublisher { get }
}

extension UserContainer: HasBlockedSendersPublisher {
    var blockedSendersPublisher: BlockedSendersPublisher {
        blockedSendersPublisherFactory()
    }
}

protocol HasUnblockSender {
    var unblockSender: UnblockSender { get }
}

extension UserContainer: HasUnblockSender {
    var unblockSender: UnblockSender {
        unblockSenderFactory()
    }
}

