//
//  AppVersion.swift
//  ProtonMail
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import PMKeymaker
import Crypto
import CoreData

struct AppVersion {
    typealias MigrationBlock = ()->Void

    private(set) var string: String
    private var numbers: Array<Int>
    private var migration: MigrationBlock?
    private var model: NSManagedObjectModel?
    private var modelUrl: URL?
    private var modelName: String?
    
    // TODO: CAN WE IMPTOVE THIS API?
    init(_ string: String,
         modelName: String? = nil, // every known should have
         migration: MigrationBlock? = nil) // every known should have
    {
        self.numbers = string.components(separatedBy: CharacterSet.punctuationCharacters.union(CharacterSet.whitespaces)).compactMap { Int($0) }
        self.string = self.numbers.map(String.init).joined(separator: ".")
        self.migration = migration
        
        if let modelName = modelName,
            let modelUrl = CoreDataService.modelBundle.url(forResource: modelName, withExtension: "mom"),
            let model = NSManagedObjectModel(contentsOf: modelUrl)
        {
            self.modelName = modelName
            self.modelUrl = modelUrl
            self.model = model
        }
    }
}

extension AppVersion {
    static var current: AppVersion = {
        let filenames = CoreDataService.modelBundle.urls(forResourcesWithExtension: "mom", subdirectory: nil)
        let versionsWithChangesInModel = filenames?.compactMap { AppVersion($0.lastPathComponent) }.sorted()
        // by convention, model name corresponds with the version it was released in
        let latestVersionWithModelUpdate = versionsWithChangesInModel?.last?.string ?? AppVersion.firstVersionWithMigratorReleased.modelName!
        return AppVersion(Bundle.main.appVersion, modelName: latestVersionWithModelUpdate)
    }()
    static var firstVersionWithMigratorReleased = AppVersion("1.12.0", modelName: "1.12.0")
    static var lastVersionBeforeMigratorWasReleased = AppVersion("1.11.1", modelName: "ProtonMail")
    static var lastMigratedTo: AppVersion {
        get {
            // on first launch after install we're setting this value to .current
            // then if there is no value in UserDefaults means it's the first time user updated to a version with migrator implemented
            // and we should run all the migrations we have since first migrator
            guard !self.isFirstRun() else {
                return self.current
            }
            guard let string = UserDefaultsSaver<String>(key: Keys.lastMigratedToVersion).get(),
                let modelName = UserDefaultsSaver<String>(key: Keys.lastMigratedToModel).get() else
            {
                return AppVersion.lastVersionBeforeMigratorWasReleased
            }
            return AppVersion(string, modelName: modelName)
        }
        set {
            UserDefaultsSaver(key: Keys.lastMigratedToVersion).set(newValue: newValue.string)
            if let modelName = newValue.modelName {
                UserDefaultsSaver(key: Keys.lastMigratedToModel).set(newValue: modelName)
            }
        }
    }

    // methods
    
    static internal func migrate() {
        let knownVersions = [self.v1_12_0].sorted()
        let shouldMigrateTo = knownVersions.filter { $0 > self.lastMigratedTo && $0 <= self.current }
        
        var previousModel = self.lastMigratedTo.model!
        var previousUrl = CoreDataService.dbUrl
        
        shouldMigrateTo.forEach { nextKnownVersion in
            nextKnownVersion.migration?()
            
            // core data
            
            guard lastMigratedTo.modelName != nextKnownVersion.modelName,
                let nextModel = nextKnownVersion.model else
            {
                self.lastMigratedTo = nextKnownVersion
                return
            }
            
            guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                                                                              at: previousUrl,
                                                                                              options: nil),
                !nextModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else
            {
                previousModel = nextModel
                self.lastMigratedTo = nextKnownVersion
                return
            }
            
            let migrationManager = NSMigrationManager(sourceModel: previousModel, destinationModel: nextModel)
            guard let mappingModel = NSMappingModel(from: [Bundle.main], forSourceModel: previousModel, destinationModel: nextModel) else {
                assert(false, "No mapping model found but need one")
                previousModel = nextModel
                self.lastMigratedTo = nextKnownVersion
                return
            }
            
            let destUrl = FileManager.default.temporaryDirectoryUrl.appendingPathComponent(UUID().uuidString, isDirectory: false)
            try? migrationManager.migrateStore(from: previousUrl,
                                              sourceType: NSSQLiteStoreType,
                                              options: nil,
                                              with: mappingModel,
                                              toDestinationURL: destUrl,
                                              destinationType: NSSQLiteStoreType,
                                              destinationOptions: nil)
            previousUrl = destUrl
            previousModel = nextModel
            self.lastMigratedTo = nextKnownVersion
        }
        
        try? NSPersistentStoreCoordinator(managedObjectModel: previousModel).replacePersistentStore(at: CoreDataService.dbUrl,
                                                                                              destinationOptions: nil,
                                                                                              withPersistentStoreFrom: previousUrl,
                                                                                              sourceOptions: nil,
                                                                                              ofType: NSSQLiteStoreType)
    }
    
    static func isFirstRun() -> Bool {
        return SharedCacheBase.getDefault().object(forKey: UserDataService.Key.firstRunKey) == nil
    }
}

extension AppVersion {
    /*
     IMPORTANT: each of these migrations read legacy values and transform them into current ones, not passing thru middle version's migrators. Please mind that user can migrate from every one of prevoius version, not only from the latest!
    */
    static var v1_12_0 = AppVersion("1.12.0", modelName: "1.12.0") {
        // UserInfo
        if let userInfo = SharedCacheBase.getDefault().customObjectForKey(DeprecatedKeys.UserDataService.userInfo) as? UserInfo {
           // AppVersion.inject(userInfo: userInfo, into: sharedUserDataService)
        }
        if let username = SharedCacheBase.getDefault().string(forKey: DeprecatedKeys.UserDataService.username) {
            AppVersion.inject(username: username, into: sharedUserDataService)
        }
        if let mobileSignature = SharedCacheBase.getDefault().string(forKey: DeprecatedKeys.UserCachedStatus.lastLocalMobileSignature) {
            userCachedStatus.mobileSignature = mobileSignature
        }
        
        // mailboxPassword
        if let triviallyProtectedMailboxPassword = KeychainWrapper.keychain.string(forKey: DeprecatedKeys.UserDataService.mailboxPassword),
            let cleartextMailboxPassword = try? triviallyProtectedMailboxPassword.decrypt(withPwd: "$Proton$" + DeprecatedKeys.UserDataService.mailboxPassword)
        {
            sharedUserDataService.mailboxPassword = cleartextMailboxPassword
        }
        
        // AuthCredential
        if let credentialRaw = KeychainWrapper.keychain.data(forKey: DeprecatedKeys.AuthCredential.keychainStore),
            let credential = NSKeyedUnarchiver.unarchiveObject(with: credentialRaw) as? AuthCredential
        {
            credential.storeInKeychain()
        }
        
        // MainKey
        let appLockMigration = DispatchGroup()
        var appWasLocked = false
        
        // via touch id
        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled) {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(BioProtection()) { _ in appLockMigration.leave() }
        }
        
        // via pin
        if userCachedStatus.getShared().bool(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled),
            let pin = KeychainWrapper.keychain.string(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        {
            appWasLocked = true
            appLockMigration.enter()
            keymaker.activate(PinProtection(pin: pin)) { _ in appLockMigration.leave() }
        }
        
        // and lock the app afterwards
        if appWasLocked {
            appLockMigration.notify(queue: .main) { keymaker.lockTheApp() }
        }
        
        // Clear up the old stuff on fresh installs also
        KeychainWrapper.keychain.removeItem(forKey: DeprecatedKeys.UserDataService.password)
        KeychainWrapper.keychain.removeItem(forKey: DeprecatedKeys.UserDataService.mailboxPassword)
        KeychainWrapper.keychain.removeItem(forKey: DeprecatedKeys.UserCachedStatus.pinCodeCache)
        KeychainWrapper.keychain.removeItem(forKey: DeprecatedKeys.AuthCredential.keychainStore)
        KeychainWrapper.keychain.removeItem(forKey: DeprecatedKeys.UserCachedStatus.enterBackgroundTime)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isTouchIDEnabled)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isPinCodeEnabled)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.isManuallyLockApp)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.touchIDEmail)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserCachedStatus.lastLocalMobileSignature)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.isRememberUser)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.userInfo)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.username)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.UserDataService.isRememberMailboxPassword)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.token)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.UID)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.badToken)
        userCachedStatus.getShared().removeObject(forKey: DeprecatedKeys.PushNotificationService.badUID)
        
        try? FileManager.default.removeItem(at: FileManager.default.applicationSupportDirectoryURL.appendingPathComponent("com.crashlytics"))
        try? FileManager.default.removeItem(at: FileManager.default.cachesDirectoryURL.appendingPathComponent("com.crashlytics.data"))
        try? FileManager.default.removeItem(at: FileManager.default.cachesDirectoryURL.appendingPathComponent("io.fabric.sdk.ios.data"))
    }
}


extension AppVersion {
    enum Keys {
        static let lastMigratedToVersion = "lastMigratedToVersion"
        static let lastMigratedToModel = "lastMigratedToModel"
    }
    
    enum DeprecatedKeys {
        enum AuthCredential {
            static let keychainStore = "keychainStoreKey"
        }
        enum UserCachedStatus {
            static let pinCodeCache         = "pinCodeCache"
            static let enterBackgroundTime  = "enterBackgroundTime"
            static let isManuallyLockApp    = "isManuallyLockApp"
            static let isPinCodeEnabled     = "isPinCodeEnabled"
            static let isTouchIDEnabled     = "isTouchIDEnabled"
            static let touchIDEmail         = "touchIDEmail"
            static let lastLocalMobileSignature = "last_local_mobile_signature"
        }
        enum UserDataService {
            static let password                  = "passwordKey"
            static let mailboxPassword           = "mailboxPasswordKey"
            static let isRememberUser            = "isRememberUserKey"
            static let userInfo                  = "userInfoKey"
            static let isRememberMailboxPassword = "isRememberMailboxPasswordKey"
            static let username                  = "usernameKey"
        }
        enum PushNotificationService {
            static let token    = "DeviceTokenKey"
            static let UID      = "DeviceUID"
            
            static let badToken = "DeviceBadToken"
            static let badUID   = "DeviceBadUID"
        }
    }
}


extension AppVersion: Comparable, Equatable {
    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        return lhs.numbers == rhs.numbers
    }
    
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let maxCount: Int = max(lhs.numbers.count, rhs.numbers.count)
        
        func normalizer(_ input: Array<Int>) -> Array<Int> {
            var norm = input
            let zeros = Array<Int>(repeating: 0, count: maxCount - input.count)
            norm.append(contentsOf: zeros)
            return norm
        }
        
        let pairs = zip(normalizer(lhs.numbers), normalizer(rhs.numbers))
        for (l, r) in pairs {
            if l < r {
                return true
            } else if l > r {
                return false
            }
        }
        return false
    }
}
