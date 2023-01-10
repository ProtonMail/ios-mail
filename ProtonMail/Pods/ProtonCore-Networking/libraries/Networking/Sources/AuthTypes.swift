//
//  AuthCredential.swift
//  ProtonCore-Networking - Created on 03.06.2021
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public final class AuthCredential: NSObject, NSCoding {

    struct Key {
        static let keychainStore = "keychainStoreKeyProtectedWithMainKey"
    }

    struct CoderKey {
        static let accessToken   = "accessTokenCoderKey"
        static let refreshToken  = "refreshTokenCoderKey"
        static let sessionID     = "userIDCoderKey"
        static let key           = "privateKeyCoderKey"
        static let plainToken    = "plainCoderKey"
        static let pwd           = "pwdKey"
        static let salt          = "passwordKeySalt"

        static let userID        = "AuthCredential.UserID"
        static let password      = "AuthCredential.Password"
        static let userName      = "AuthCredential.UserName"
    }

    public static var none: AuthCredential = AuthCredential.init(res: AuthResponse(), userName: "" )

    // user session id, this change in every login
    public var sessionID: String
    // plain text accessToken
    public var accessToken: String
    // refresh token use to renew access token
    public var refreshToken: String
    // the expiration time
    @available(*, deprecated, message: "Please do not use expiration property")
    public var expiration: Date = .distantPast
    // user ID
    public var userID: String
    // user name
    public var userName: String

    // the login private key, ususally it is first userkey
    public var privateKey: String?
    public var passwordKeySalt: String?
    public var mailboxpassword: String = ""

    override public var description: String {
        return """
        AccessToken: \(accessToken)
        RefreshToken: \(refreshToken)
        SessionID: \(sessionID)
        UserName: \(userName)
        UserUD: \(userID)
        """
    }
    
    public init(sessionID: String,
                accessToken: String,
                refreshToken: String,
                userName: String,
                userID: String,
                privateKey: String?,
                passwordKeySalt: String?) {
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userName = userName
        self.userID = userID
        self.privateKey = privateKey
        self.passwordKeySalt = passwordKeySalt
    }
    
    @available(*, deprecated, message: "Please use the init method without expiration")
    public init(sessionID: String,
                accessToken: String,
                refreshToken: String,
                expiration: Date,
                userName: String,
                userID: String,
                privateKey: String?,
                passwordKeySalt: String?) {
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userName = userName
        self.userID = userID
        self.privateKey = privateKey
        self.passwordKeySalt = passwordKeySalt
    }
    
    public init(copying other: AuthCredential) {
        self.sessionID = other.sessionID
        self.accessToken = other.accessToken
        self.refreshToken = other.refreshToken
        self.userName = other.userName
        self.userID = other.userID
        self.privateKey = other.privateKey
        self.passwordKeySalt = other.passwordKeySalt
        self.mailboxpassword = other.mailboxpassword
    }

    @available(*, deprecated, message: "This method no longer does anything. Client apps should not depend on the expiration date, please don't use this for anything")
    public var isExpired: Bool {
        assertionFailure("This property should never be called")
        return Date().compare(expiration) != .orderedAscending
    }

    @available(*, deprecated, message: "This method no longer does anything. Client apps should not depend on the expiration date, please don't use this for anything")
    public func expire() {
        assertionFailure("This method should never be called")
    }

    public func update(salt: String?, privateKey: String?) {
        self.privateKey = privateKey
        self.passwordKeySalt = salt
    }

    public func udpate(password: String) {
        self.mailboxpassword = password
    }

    public func udpate(sessionID: String,
                       accessToken: String,
                       refreshToken: String) {
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    @available(*, deprecated, message: "Please use the update method without expiration")
    public func udpate(sessionID: String,
                       accessToken: String,
                       refreshToken: String,
                       expiration: Date) {
        self.sessionID = sessionID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    required init(res: AuthResponse, userName: String) {
        self.sessionID = res.sessionID ?? ""
        self.accessToken = res.accessToken
        self.refreshToken = res.refreshToken
        self.userName = userName
        self.userID = res.userID
    }

    public required init?(coder aDecoder: NSCoder) {
        guard
            let token = aDecoder.decodeObject(forKey: CoderKey.accessToken) as? String,
            let refreshToken = aDecoder.decodeObject(forKey: CoderKey.refreshToken) as? String,
            let sessionID = aDecoder.decodeObject(forKey: CoderKey.sessionID) as? String else
        {
                return nil
        }

        self.accessToken = token
        self.sessionID = sessionID
        self.refreshToken = refreshToken

        self.privateKey = aDecoder.decodeObject(forKey: CoderKey.key) as? String
        self.passwordKeySalt = aDecoder.decodeObject(forKey: CoderKey.salt) as? String
        self.mailboxpassword = aDecoder.decodeObject(forKey: CoderKey.password) as? String ?? ""
        self.userName = aDecoder.decodeObject(forKey: CoderKey.userName) as? String ?? ""
        self.userID = aDecoder.decodeObject(forKey: CoderKey.userID) as? String ?? ""
    }

    public class func unarchive(data: NSData?) -> AuthCredential? {
        guard let data = data as Data? else { return nil }

        // Looks like this is necessary for cases when AuthCredential was updated and saved by one target, and unarchived by another. For example, Share extension updates token from server, archives AuthCredential with its prefix, and after a while main target should unarchive it - and should know that prefix
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ProtonMail.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ProtonMailDev.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "Share.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "ShareDev.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "PushService.AuthCredential")
        NSKeyedUnarchiver.setClass(AuthCredential.classForKeyedUnarchiver(), forClassName: "PushServiceDev.AuthCredential")

        return NSKeyedUnarchiver.unarchiveObject(with: data) as? AuthCredential
    }

    // MARK: - Class methods

    public func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(sessionID, forKey: CoderKey.sessionID)
        aCoder.encode(accessToken, forKey: CoderKey.accessToken)
        aCoder.encode(refreshToken, forKey: CoderKey.refreshToken)
        aCoder.encode(privateKey, forKey: CoderKey.key)
        aCoder.encode(mailboxpassword, forKey: CoderKey.password)
        aCoder.encode(passwordKeySalt, forKey: CoderKey.salt)
        aCoder.encode(userName, forKey: CoderKey.userName)
        aCoder.encode(userID, forKey: CoderKey.userID)
    }
}

extension AuthCredential {
    public convenience init(_ credential: Credential) {
        self.init(sessionID: credential.UID,
                  accessToken: credential.accessToken,
                  refreshToken: credential.refreshToken,
                  userName: credential.userName,
                  userID: credential.userID,
                  privateKey: nil,
                  passwordKeySalt: nil)
    }
    
    public func updatedKeepingKeyAndPasswordDataIntact(credential: Credential) -> AuthCredential {
        self.sessionID = credential.UID
        self.accessToken = credential.accessToken
        self.refreshToken = credential.refreshToken
        self.userName = credential.userName
        self.userID = credential.userID
        // we deliberately not update nor nil out privateKey, passwordKeySalt and mailboxpassword here
        return self
    }
}

public struct Credential: Equatable {
    @available(*, deprecated, message: "Please use BackendScopes instead of BackendScope")
    public typealias BackendScope = CredentialConvertible.Scope
    public typealias BackendScopes = CredentialConvertible.Scopes
    public typealias Scopes = [String]

    public var UID: String
    public var accessToken: String
    public var refreshToken: String
    @available(*, deprecated, message: "Please do not use expiration property")
    public var expiration: Date = .distantPast
    public var userName: String
    public var userID: String
    @available(*, deprecated, renamed: "scopes")
    public var scope: Scopes { scopes }
    public var scopes: Scopes
    
    public var hasFullScope: Bool { scopes.contains("full") }

    public init(UID: String, accessToken: String, refreshToken: String, userName: String, userID: String, scopes: Scopes) {
        self.UID = UID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userName = userName
        self.userID = userID
        self.scopes = scopes
    }
    
    @available(*, deprecated, message: "Please use the init method without expiration and with scopes")
    public init(UID: String, accessToken: String, refreshToken: String, expiration: Date, userName: String, userID: String, scope: Scopes) {
        self.UID = UID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userName = userName
        self.userID = userID
        self.scopes = scope
    }

    public init(res: CredentialConvertible, UID: String = "", userName: String, userID: String) {
        self.UID = res.UID ?? res.sessionID ?? UID
        self.accessToken = res.accessToken
        self.refreshToken = res.refreshToken
        self.userName = userName
        self.userID = userID
        self.scopes = res.scopes
    }
    
    @available(*, deprecated, message: "Please update scopes property directly")
    public mutating func updateScope(_ newScope: BackendScope) {
        self.scopes = newScope.components(separatedBy: " ")
    }
}

@dynamicMemberLookup
public protocol CredentialConvertible {
    typealias Scopes = [String]
    typealias Scope = String

    var accessToken: String { get }
    var tokenType: String { get }
    var scopes: Scopes { get }
    var refreshToken: String { get }
}

// this will allow us to add UID dynamically when available
extension CredentialConvertible {
    subscript<T>(dynamicMember name: String) -> T? {
        let mirror = Mirror(reflecting: self)
        guard let child = mirror.children.first(where: { $0.label == name }) else { return nil }
        return child.value as? T
    }
}

extension Credential {
    public init(_ authCredential: AuthCredential) {
        self.init(UID: authCredential.sessionID,
                  accessToken: authCredential.accessToken,
                  refreshToken: authCredential.refreshToken,
                  userName: authCredential.userName,
                  userID: authCredential.userID,
                  scopes: [])
    }
    
    public init(_ authCredential: AuthCredential, scopes: Scopes) {
        self.init(UID: authCredential.sessionID,
                  accessToken: authCredential.accessToken,
                  refreshToken: authCredential.refreshToken,
                  userName: authCredential.userName,
                  userID: authCredential.userID,
                  scopes: scopes)
    }
    
    @available(*, deprecated, message: "Please use the init method with scopes")
    public init(_ authCredential: AuthCredential, scope: Scopes) {
        self.init(UID: authCredential.sessionID,
                  accessToken: authCredential.accessToken,
                  refreshToken: authCredential.refreshToken,
                  userName: authCredential.userName,
                  userID: authCredential.userID,
                  scopes: scope)
    }
}

public struct VerifyMethod: Equatable {
    
    public var method: String
    
    public init(string: String) {
        self.method = string
    }
}

// HV V2 compatibility
extension VerifyMethod {

    public enum PredefinedMethod: String {
        case captcha
        case sms
        case email
        case payment
    }
    
    public init(predefinedMethod: PredefinedMethod) {
        self.method = predefinedMethod.rawValue
    }
    
    public init?(predefinedString: String) {
        switch predefinedString {
        case PredefinedMethod.captcha.rawValue, PredefinedMethod.sms.rawValue,
            PredefinedMethod.email.rawValue:
            self.method = predefinedString
        default: return nil
        }
    }
    
    public var predefinedMethod: PredefinedMethod? {
        switch method {
        case PredefinedMethod.captcha.rawValue: return .captcha
        case PredefinedMethod.sms.rawValue: return .sms
        case PredefinedMethod.email.rawValue: return .email
        default: return nil
        }
    }
}

// MARK: Response part
public final class AuthResponse: Response, CredentialConvertible, Codable {
    public var accessToken: String = ""
    @available(*, deprecated, message: "Please do not use expiresIn property")
    public var expiresIn: TimeInterval = 0.0
    public var tokenType: String = ""
    public var userID: String = ""
    @available(*, deprecated, renamed: "scopes")
    public var scope: Scopes { scopes }
    public var scopes: Scopes = []
    public var refreshToken: String = ""

    override public func ParseResponse(_ response: [String: Any]!) -> Bool {
        return true
    }
}

public typealias SendVerificationCodeBlock = (Bool, ResponseError?, VerificationCodeBlockFinish?) -> Void
public typealias SendResultCodeBlock = (Bool, ResponseError?) -> Void
public typealias VerificationCodeBlockFinish = () -> Void

public struct HumanVerifyParameters {
    public var methods: [VerifyMethod] = []
    public var startToken: String?
    public var title: String?
    
    public init(methods: [VerifyMethod] = [], startToken: String? = nil, title: String? = nil) {
        self.methods = methods
        self.startToken = startToken
        self.title = title
    }
}

public class HumanVerificationResponse: Response {
    public var parameters = HumanVerifyParameters()

    override public func ParseResponse(_ response: [String: Any]) -> Bool {
        if let details = response["Details"] as? [String: Any] {
            parameters.startToken = details["HumanVerificationToken"] as? String
            parameters.title = details["Title"] as? String
            if let methods = details["HumanVerificationMethods"] as? [String] {
                parameters.methods = methods.map { VerifyMethod(string: $0) }
            }
        }
        return true
    }
}

public enum AuthErrors: Error {
    case emptyAuthInfoResponse
    case emptyAuthResponse
    case emptyServerSrpAuth
    case emptyClientSrpAuth
    case emptyUserInfoResponse
    case wrongServerProof
    case externalAccountsNotSupported(message: String, originalError: ResponseError)
    case addressKeySetupError(Error)
    case networkingError(ResponseError)
    case apiMightBeBlocked(message: String, originalError: ResponseError)
    case parsingError(Error)
    case notImplementedYet(String)

    // case serverError(NSError) <- This case was removed. Use networkingError instead. If you're logic depends on previously available NSError, use .underlyingError property.
    // In case you wonder why I'm writing a comment and not use @available(*, unavailable): it's because at the time of writing,
    // this bug is still open: https://bugs.swift.org/browse/SR-4079 and it renders availability mark for enum cases useless.

    public var underlyingError: NSError {
        switch self {
        case .emptyAuthResponse, .emptyAuthInfoResponse, .emptyServerSrpAuth,
             .emptyClientSrpAuth, .emptyUserInfoResponse, .wrongServerProof, .notImplementedYet:
            return self as NSError
        case .addressKeySetupError(let error), .parsingError(let error):
            return error as NSError
        case .networkingError(let error), .apiMightBeBlocked(_, let error), .externalAccountsNotSupported(_, let error):
            return error.underlyingError ?? error as NSError
        }
    }

    public var codeInNetworking: Int {
        switch self {
        case .emptyAuthResponse, .emptyAuthInfoResponse, .emptyServerSrpAuth,
             .emptyClientSrpAuth, .emptyUserInfoResponse, .wrongServerProof, .notImplementedYet:
            return (self as NSError).code
        case .addressKeySetupError(let error), .parsingError(let error):
            return (error as NSError).code
        case .networkingError(let error), .apiMightBeBlocked(_, let error), .externalAccountsNotSupported(_, let error):
            return error.bestShotAtReasonableErrorCode
        }
    }

    public var localizedDescription: String {
        switch self {
        case .emptyAuthResponse, .emptyAuthInfoResponse, .emptyServerSrpAuth, .emptyClientSrpAuth, .emptyUserInfoResponse, .wrongServerProof:
            return (self as NSError).localizedDescription
        case .addressKeySetupError(let error), .parsingError(let error):
            return error.localizedDescription
        case .networkingError(let error), .apiMightBeBlocked(_, let error):
            return error.localizedDescription
        case .externalAccountsNotSupported(let message, _), .notImplementedYet(let message):
            return message
        }
    }
    
    public var isInvalidAccessToken: Bool {
        if case .networkingError(let responseError) = self, responseError.httpCode == 401 {
            return true
        }
        return false
    }
}

public extension AuthErrors {
    var userFacingMessageInNetworking: String {
        return localizedDescription
    }
}
