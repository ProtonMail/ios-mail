// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

protocol HasBiometricStatusProvider {
    var biometricStatusProvider: BiometricStatusProvider { get }
}

extension GlobalContainer: HasBiometricStatusProvider {
    var biometricStatusProvider: BiometricStatusProvider {
        biometricStatusProviderFactory()
    }
}

extension UserContainer: HasBiometricStatusProvider {
    var biometricStatusProvider: BiometricStatusProvider {
        globalContainer.biometricStatusProvider
    }
}

protocol HasCleanCache {
    var cleanCache: CleanCache { get }
}

extension GlobalContainer: HasCleanCache {
    var cleanCache: CleanCache {
        cleanCacheFactory()
    }
}

extension UserContainer: HasCleanCache {
    var cleanCache: CleanCache {
        globalContainer.cleanCache
    }
}

protocol HasSaveSwipeActionSettingForUsersUseCase {
    var saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase { get }
}

extension GlobalContainer: HasSaveSwipeActionSettingForUsersUseCase {
    var saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase {
        saveSwipeActionSettingFactory()
    }
}

extension UserContainer: HasSaveSwipeActionSettingForUsersUseCase {
    var saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase {
        globalContainer.saveSwipeActionSetting
    }
}

protocol HasSwipeActionCacheProtocol {
    var swipeActionCache: SwipeActionCacheProtocol { get }
}

extension GlobalContainer: HasSwipeActionCacheProtocol {
    var swipeActionCache: SwipeActionCacheProtocol {
        swipeActionCacheFactory()
    }
}

extension UserContainer: HasSwipeActionCacheProtocol {
    var swipeActionCache: SwipeActionCacheProtocol {
        globalContainer.swipeActionCache
    }
}

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

protocol HasSettingsViewsFactory {
    var settingsViewsFactory: SettingsViewsFactory { get }
}

extension UserContainer: HasSettingsViewsFactory {
    var settingsViewsFactory: SettingsViewsFactory {
        settingsViewsFactoryFactory()
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

