import ProtonCore_Networking

public extension Credential {
    static var dummy: Credential {
        Credential(UID: .empty, accessToken: .empty, refreshToken: .empty, expiration: .distantFuture, scope: [])
    }

    func updated(
        UID: String? = nil, accessToken: String? = nil, refreshToken: String? = nil, expiration: Date? = nil, scope: Credential.Scope? = nil
    ) -> Credential {
        Credential(UID: UID ?? self.UID,
                   accessToken: accessToken ?? self.accessToken,
                   refreshToken: refreshToken ?? self.refreshToken,
                   expiration: expiration ?? self.expiration,
                   scope: scope ?? self.scope)
    }
}
