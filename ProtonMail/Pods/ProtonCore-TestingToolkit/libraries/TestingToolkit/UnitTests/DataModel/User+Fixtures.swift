import ProtonCore_DataModel

public extension User {
    static var dummy: User {
        .init(ID: .empty,
              name: nil,
              usedSpace: .zero,
              currency: .empty,
              credit: .zero,
              maxSpace: .zero,
              maxUpload: .zero,
              role: .zero,
              private: .zero,
              subscribed: .zero,
              services: .zero,
              delinquent: .zero,
              orgPrivateKey: nil,
              email: nil,
              displayName: nil,
              keys: [])
    }
}
