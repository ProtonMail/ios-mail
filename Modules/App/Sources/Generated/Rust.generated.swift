// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
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
