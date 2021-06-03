import ProtonCore_Networking
import ProtonCore_Services

public final class HumanVerifyDelegateMock: HumanVerifyDelegate {

    public init() {}

    @FuncStub(HumanVerifyDelegateMock.onHumanVerify) public var onHumanVerifyStub
    public func onHumanVerify(methods: [VerifyMethod],
                              startToken: String?,
                              completion: @escaping ((HumanVerifyHeader, HumanVerifyIsClosed, SendVerificationCodeBlock?) -> Void)) {
        onHumanVerifyStub(methods, startToken, completion)
    }

    @FuncStub(HumanVerifyDelegateMock.getSupportURL, initialReturn: URL(string: "https://protoncore.unittest")!) public var getSupportURLStub
    public func getSupportURL() -> URL {
        getSupportURLStub()
    }
}
