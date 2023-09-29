// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

protocol HasCoreDataContextProviderProtocol {
    var contextProvider: CoreDataContextProviderProtocol { get }
}

extension GlobalContainer: HasCoreDataContextProviderProtocol {
    var contextProvider: CoreDataContextProviderProtocol {
        contextProviderFactory()
    }
}

extension UserContainer: HasCoreDataContextProviderProtocol {
    var contextProvider: CoreDataContextProviderProtocol {
        globalContainer.contextProvider
    }
}

protocol HasInternetConnectionStatusProviderProtocol {
    var internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol { get }
}

extension GlobalContainer: HasInternetConnectionStatusProviderProtocol {
    var internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol {
        internetConnectionStatusProviderFactory()
    }
}

extension UserContainer: HasInternetConnectionStatusProviderProtocol {
    var internetConnectionStatusProvider: InternetConnectionStatusProviderProtocol {
        globalContainer.internetConnectionStatusProvider
    }
}

protocol HasKeyMakerProtocol {
    var keyMaker: KeyMakerProtocol { get }
}

extension GlobalContainer: HasKeyMakerProtocol {
    var keyMaker: KeyMakerProtocol {
        keyMakerFactory()
    }
}

extension UserContainer: HasKeyMakerProtocol {
    var keyMaker: KeyMakerProtocol {
        globalContainer.keyMaker
    }
}

protocol HasLockCacheStatus {
    var lockCacheStatus: LockCacheStatus { get }
}

extension GlobalContainer: HasLockCacheStatus {
    var lockCacheStatus: LockCacheStatus {
        lockCacheStatusFactory()
    }
}

extension UserContainer: HasLockCacheStatus {
    var lockCacheStatus: LockCacheStatus {
        globalContainer.lockCacheStatus
    }
}

protocol HasQueueManager {
    var queueManager: QueueManager { get }
}

extension GlobalContainer: HasQueueManager {
    var queueManager: QueueManager {
        queueManagerFactory()
    }
}

extension UserContainer: HasQueueManager {
    var queueManager: QueueManager {
        globalContainer.queueManager
    }
}

protocol HasUsersManager {
    var usersManager: UsersManager { get }
}

extension GlobalContainer: HasUsersManager {
    var usersManager: UsersManager {
        usersManagerFactory()
    }
}

extension UserContainer: HasUsersManager {
    var usersManager: UsersManager {
        globalContainer.usersManager
    }
}

protocol HasUserCachedStatus {
    var userCachedStatus: UserCachedStatus { get }
}

extension GlobalContainer: HasUserCachedStatus {
    var userCachedStatus: UserCachedStatus {
        userCachedStatusFactory()
    }
}

extension UserContainer: HasUserCachedStatus {
    var userCachedStatus: UserCachedStatus {
        globalContainer.userCachedStatus
    }
}

protocol HasUserManager {
    var user: UserManager { get }
}

extension UserContainer: HasUserManager {
    var user: UserManager {
        userFactory()
    }
}

