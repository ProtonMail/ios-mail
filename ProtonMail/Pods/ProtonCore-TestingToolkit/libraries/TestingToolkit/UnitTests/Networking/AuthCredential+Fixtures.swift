import ProtonCore_Networking

public extension AuthCredential {
    static var dummy: AuthCredential {
        .init(sessionID: .empty, accessToken: .empty, refreshToken: .empty, expiration: .distantFuture, privateKey: nil, passwordKeySalt: nil)
    }
}
