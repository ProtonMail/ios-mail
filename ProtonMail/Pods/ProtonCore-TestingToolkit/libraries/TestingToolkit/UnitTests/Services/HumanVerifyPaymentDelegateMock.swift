import ProtonCore_Services

public final class HumanVerifyPaymentDelegateMock: HumanVerifyPaymentDelegate {

    public init() {}

    @PropertyStub(\HumanVerifyPaymentDelegateMock.paymentToken, initialGet: .crash) public var paymentTokenStub
    public var paymentToken: String? { paymentTokenStub() }

    @FuncStub(HumanVerifyPaymentDelegateMock.paymentTokenStatusChanged) public var paymentTokenStatusChangedStub
    public func paymentTokenStatusChanged(status: PaymentTokenStatusResult) { paymentTokenStatusChangedStub(status) }
}
