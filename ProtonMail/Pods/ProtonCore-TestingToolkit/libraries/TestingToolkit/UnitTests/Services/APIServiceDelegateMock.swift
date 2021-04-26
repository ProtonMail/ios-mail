import ProtonCore_Services

public final class APIServiceDelegateMock: APIServiceDelegate {

    public init() {}

    @FuncStub(APIServiceDelegateMock.onUpdate) public var onUpdateStub
    public func onUpdate(serverTime: Int64) { onUpdateStub(serverTime) }

    @FuncStub(APIServiceDelegateMock.isReachable, initialReturn: false) public var isReachableStub
    public func isReachable() -> Bool { isReachableStub() }

    @PropertyStub(\APIServiceDelegateMock.appVersion, initialGet: .empty) public var appVersionStub
    public var appVersion: String { appVersionStub() }

    @PropertyStub(\APIServiceDelegateMock.userAgent, initialGet: nil) public var userAgentStub
    public var userAgent: String? { userAgentStub() }

    @FuncStub(APIServiceDelegateMock.onDohTroubleshot) public var onDohTroubleshotStub
    public func onDohTroubleshot() { onDohTroubleshotStub() }
}
