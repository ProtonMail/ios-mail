import ProtonCore_DataModel

public extension User {

    static var dummy: User {
        User(ID: .empty,
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
             keys: .empty)
    }
    
    func updated(ID: String? = nil,
                 name: String? = nil,
                 usedSpace: Double? = nil ,
                 currency: String? = nil,
                 credit: Int? = nil,
                 maxSpace: Double? = nil,
                 maxUpload: Double? = nil,
                 role: Int? = nil,
                 private: Int? = nil,
                 subscribed: Int? = nil,
                 services: Int? = nil,
                 delinquent: Int? = nil,
                 orgPrivateKey: String? = nil,
                 email: String? = nil,
                 displayName: String? = nil,
                 keys: [Key]? = nil) -> User {
        User(ID: ID ?? self.ID,
             name: name ?? self.name,
             usedSpace: usedSpace ?? self.usedSpace,
             currency: currency ?? self.currency,
             credit: credit ?? self.credit,
             maxSpace: maxSpace ?? self.maxSpace,
             maxUpload: maxUpload ?? self.maxUpload,
             role: role ?? self.role,
             private: `private` ?? self.private,
             subscribed: subscribed ?? self.subscribed,
             services: services ?? self.services,
             delinquent: delinquent ?? self.delinquent,
             orgPrivateKey: orgPrivateKey ?? self.orgPrivateKey,
             email: email ?? self.email,
             displayName: displayName ?? self.displayName,
             keys: keys ?? self.keys)
    }
}
