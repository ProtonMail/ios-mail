import ProtonCore_TestingToolkit
import ProtonCore_Login

public extension LoginData {
    static var dummy: LoginData {
        .init(credential: .dummy, user: .dummy, salts: [], passphrases: [:], addresses: [], scopes: [])
    }
}
