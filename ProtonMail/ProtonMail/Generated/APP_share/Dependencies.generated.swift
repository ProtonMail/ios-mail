// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

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

protocol HasUserManager {
    var user: UserManager { get }
}

extension UserContainer: HasUserManager {
    var user: UserManager {
        userFactory()
    }
}

