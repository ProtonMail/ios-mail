// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// periphery:ignore:all
import Foundation
import proton_app_uniffi

public extension AttachmentListAddInlineResult {
    func get() throws(DraftAttachmentUploadError) -> String {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListAddResult {
    func get() throws(DraftAttachmentUploadError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListAttachmentsResult {
    func get() throws(DraftAttachmentUploadError) -> [DraftAttachment] {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListRemoveWithCidResult {
    func get() throws(DraftAttachmentUploadError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListRetryResult {
    func get() throws(DraftAttachmentUploadError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension AttachmentListWatcherResult {
    func get() throws(DraftAttachmentUploadError) -> DraftAttachmentWatcher {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension DraftChangeSenderAddressResult {
    func get() throws(DraftSenderAddressChangeError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension NewDraftResult {
    func get() throws(DraftOpenError) -> Draft {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension OpenDraftResult {
    func get() throws(DraftOpenError) -> OpenDraft {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowChangeMboxPassResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowChangePassResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowHasFidoResult {
    func get() throws(PasswordError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowHasMbpResult {
    func get() throws(PasswordError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowHasTotpResult {
    func get() throws(PasswordError) -> Bool {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowStepBackResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowSubmitPassResult {
    func get() throws(PasswordError) -> SimplePasswordState {
        switch self {
        case .ok(let value):
            value
        case .error(let error):
            throw error
        }
    }
}
public extension PasswordFlowSubmitTotpResult {
    func get() throws(PasswordError) -> SimplePasswordState {
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
public extension VoidDraftDiscardResult {
    func get() throws(DraftDiscardError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftSaveResult {
    func get() throws(DraftSaveError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
public extension VoidDraftSendResult {
    func get() throws(DraftSendError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }
}
