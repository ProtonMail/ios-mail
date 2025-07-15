// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all
import Foundation
import proton_app_uniffi

public extension DraftCancelScheduleSendResult {
    func get() throws(DraftCancelScheduleSendError) -> DraftCancelScheduledSendInfo {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionDeletePinCodeResult {
    func get() throws(PinAuthError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionSetPinCodeResult {
    func get() throws(PinSetError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailSessionVerifyPinCodeResult {
    func get() throws(PinAuthError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension MailUserSessionObserveEventLoopErrorsResult {
    func get() throws(EventError) -> EventLoopErrorObserverHandle {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowAvailableCountriesResult {
    func get() throws(SignupError) -> Countries {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowAvailableDomainsResult {
    func get() throws(SignupError) -> [String] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowCompleteResult {
    func get() throws(SignupError) -> UserAddrId {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowCreateResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSkipRecoveryResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowStepBackResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitExternalUsernameResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitInternalUsernameResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitPasswordResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitRecoveryEmailResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitRecoveryPhoneResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension SignupFlowSubmitValidatedPasswordResult {
    func get() throws(SignupError) -> SimpleSignupState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftUndoSendResult {
    func get() throws(DraftUndoSendError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidEventResult {
    func get() throws(EventError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
