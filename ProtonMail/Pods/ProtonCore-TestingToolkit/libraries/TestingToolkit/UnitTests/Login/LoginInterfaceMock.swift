import UIKit
import ProtonCore_Login

public class LoginInterfaceMock: LoginInterface {

    public init() {}

    @FuncStub(LoginInterfaceMock.presentLoginFlow) public var presentLoginFlowStub
    public func presentLoginFlow(over viewController: UIViewController,
                                 username: String?,
                                 completion: @escaping (LoginResult) -> Void) {
        presentLoginFlowStub(viewController, username, completion)
    }

    @FuncStub(LoginInterfaceMock.presentSignupFlow) public var presentSignupFlowStub
    public func presentSignupFlow(over viewController: UIViewController,
                                  receipt: String?,
                                  completion: @escaping (LoginResult) -> Void) {
        presentSignupFlowStub(viewController, receipt, completion)
    }

    @FuncStub(LoginInterfaceMock.presentMailboxPasswordFlow) public var presentMailboxPasswordFlowStub
    public func presentMailboxPasswordFlow(over viewController: UIViewController,
                                           completion: @escaping (String) -> Void) {
        presentMailboxPasswordFlowStub(viewController, completion)
    }

    @FuncStub(LoginInterfaceMock.presentFlowFromWelcomeScreen) public var presentFlowFromWelcomeScreenStub
    public func presentFlowFromWelcomeScreen(over viewController: UIViewController,
                                             welcomeScreen: WelcomeScreenVariant,
                                             username: String?,
                                             completion: @escaping (LoginResult) -> Void) {
        presentFlowFromWelcomeScreenStub(viewController, welcomeScreen, username, completion)
    }
}
