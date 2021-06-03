import ProtonCore_Services

public final class HumanVerifyResponseDelegateMock: HumanVerifyResponseDelegate {

    public init() {}

    @FuncStub(HumanVerifyResponseDelegateMock.onHumanVerifyStart) public var onHumanVerifyStartStub
    public func onHumanVerifyStart() {
        onHumanVerifyStartStub()
    }

    @FuncStub(HumanVerifyResponseDelegateMock.onHumanVerifyEnd) public var onHumanVerifyEndStub
    public func onHumanVerifyEnd(result: HumanVerifyEndResult) {
        onHumanVerifyEndStub(result)
    }
}
