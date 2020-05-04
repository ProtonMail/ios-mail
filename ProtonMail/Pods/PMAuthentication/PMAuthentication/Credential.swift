//
//  AuthCredential.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

/// Blind object to returned to clients in order to continue authentication upon 2FA code input
public typealias TwoFactorContext = (credential: Credential, passwordMode: PasswordMode)

/// Credential to be used across all authenticated API calls
public struct Credential {
    typealias BackendScope = CredentialConvertible.Scope
    public typealias Scope = [String]
    
    public var UID: String
    public var accessToken: String
    public var refreshToken: String
    public var expiration: Date
    public var scope: Scope
    
    public init(UID: String, accessToken: String, refreshToken: String, expiration: Date, scope: Credential.Scope) {
        self.UID = UID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiration = expiration
        self.scope = scope
    }
    
    init(res: CredentialConvertible, UID: String = "") {
        self.UID = res.UID ?? UID
        self.accessToken = res.accessToken
        self.refreshToken = res.refreshToken
        self.expiration = Date(timeIntervalSinceNow: res.expiresIn)
        self.scope = res.scope.components(separatedBy: " ")
    }
    
    mutating func updateScope(_ newScope: BackendScope) {
        self.scope = newScope.components(separatedBy: " ")
    }
}

@dynamicMemberLookup
protocol CredentialConvertible {
    typealias Scope = String
    
    var code: Int { get }
    var accessToken: String { get }
    var expiresIn: TimeInterval { get }
    var tokenType: String { get }
    var scope: Scope { get }
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
