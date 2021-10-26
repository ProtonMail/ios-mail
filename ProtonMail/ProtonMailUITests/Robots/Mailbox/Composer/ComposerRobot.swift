//
//  ComposerRobot.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 24.07.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import XCTest
import pmtest

fileprivate struct id {
    /// Composer identifiers.
    static let sendButtonIdentifier = "ComposeContainerViewController.sendButton"
    static let sendButtonLabel = LocalString._general_send_action
    static let toTextFieldIdentifier = "To:TextField"
    static let ccTextFieldIdentifier = "ccTextField"
    static let bccTextFieldIdentifier = "bccTextField"
    static let composerWebViewIdentifier = "ComposerBody"
    static let subjectTextFieldIdentifier = "ComposeHeaderViewController.subject"
    static let pasteMenuItem = app.menuItems.staticTexts.element(boundBy: 0)
    static let popoverDismissRegionOtherIdentifier = "PopoverDismissRegion"
    static let expirationButtonIdentifier = "ComposeHeaderViewController.expirationButton"
    static let passwordButtonIdentifier = "ComposeHeaderViewController.encryptedButton"
    static let attachmentButtonIdentifier = "ComposeHeaderViewController.attachmentButton"
    static let showCcBccButtonIdentifier = "ComposeHeaderViewController.showCcBccButton"
    static let cancelNavBarButtonIdentifier = "ComposeContainerViewController.cancelButton"
    static let fromStaticTextIdentifier = "ComposeHeaderViewController.fromAddress"
    static let fromPickerButtonIdentifier = "ComposeHeaderViewController.fromPickerButton"
    static func getContactCellIdentifier(_ email: String) -> String { return "ContactsTableViewCell.\(email)" }

    /// Set Password modal identifiers.
    static let messagePasswordSecureTextFieldIdentifier = "ComposePasswordViewController.passwordField"
    static let confirmPasswordSecureTextFieldIdentifier = "ComposePasswordViewController.confirmPasswordField"
    static let hintPasswordTextFieldIdentifier = "ComposePasswordViewController.hintField"
    static let cancelButtonIdentifier = "ComposePasswordViewController.cancelButton"
    static let applyButtonIdentifier = "ComposePasswordViewController.applyButton"

    /// Expiration picker identifiers.
    static let expirationPickerIdentifier = "ExpirationPickerCell.picker"
    static let expirationActionButtonIdentifier = "expirationActionButton"

    /// Expiration picker identifiers.
    static let saveDraftButtonText = "saveDraftButton"
    static let invalidAddressStaticTextIdentifier = LocalString._signle_address_invalid_error_content
    static let recipientNotFoundStaticTextIdentifier = LocalString._recipient_not_found
}

/**
 Represents Composer view.
*/
class ComposerRobot: CoreElements {
    
    var verify = Verify()
    
    func tapCancel() -> DraftConfirmationRobot {
        button(id.cancelNavBarButtonIdentifier).tap()
        return DraftConfirmationRobot()
    }
    
    func sendMessage(_ to: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .subject(subjectText)
            .send()
    }
    
    func draftToSubjectBody(_ to: String, _ subjectText: String, _ body: String) -> ComposerRobot {
        recipients(to)
            .subject(subjectText)
            .body(body)
        return self
    }
    
    func draftToBody(_ to: String, _ body: String) -> ComposerRobot {
        recipients(to)
            .subject("")
            .body(body)
        return self
    }
    
    func draftSubjectBody(_ subjectText: String, _ body: String) -> ComposerRobot {
        subject(subjectText)
            .body(body)
        return self
    }
    
    func draftToSubjectBodyAttachment(_ to: String, _ subjectText: String, _ body: String) -> ComposerRobot {
        return recipients(to)
            .subject(subjectText)
            .body(body)
            .addAttachment()
            .add()
            .photoLibrary()
            .pickImages(1)
            .done()
    }
    
    func sendMessageToContact(_ subjectText: String) -> ContactDetailsRobot {
        return subject(subjectText)
            .sendToContact()
    }
    
    func sendMessageToGroup(_ subjectText: String) -> ContactsRobot {
        return subject(subjectText)
            .sendToContactGroup()
    }
    
    func sendMessage(_ to: String, _ cc: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .cc(cc)
            .subject(subjectText)
            .send()
    }
    
    func sendMessage(_ to: String, _ cc: String, _ bcc: String, _ subjectText: String) -> InboxRobot {
        return recipients(to)
            .showCcBcc()
            .cc(cc)
            .bcc(bcc)
            .subject(subjectText)
            .send()
    }
    
    func sendMessageWithPassword(_ to: String, _ subjectText: String, _ body: String, _ password: String, _ hint: String) -> InboxRobot {
        return composeMessage(to, subjectText, body)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .send()
    }
    
    func sendMessageExpiryTimeInDays(_ to: String, _ subjectText: String, _ body: String, expireInDays: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .messageExpiration()
            .setExpirationInDays(expireInDays)
            .send()
        return InboxRobot()
    }
    
    func sendMessageEOAndExpiryTime(_ to: String, _ subjectText: String, _ password: String, _ hint: String, expireInDays: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .messageExpiration()
            .setExpirationInDays(expireInDays)
            .send()
        return InboxRobot()
    }
    
    func sendMessageWithAttachments(_ to: String, _ subjectText: String, attachmentsAmount: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .addAttachment()
            .add()
            .photoLibrary()
            .pickImages(attachmentsAmount)
            .done()
            .send()
        return InboxRobot()
    }
    
    func sendMessageEOAndExpiryTimeWithAttachment(_ to: String, _ subjectText: String, _ password: String, _ hint: String, attachmentsAmount: Int = 1, expireInDays: Int = 1) -> InboxRobot {
        recipients(to)
            .subject(subjectText)
            .addAttachment()
            .add()
            .photoLibrary()
            .pickImages(attachmentsAmount)
            .done()
            .setMessagePassword()
            .definePasswordWithHint(password, hint)
            .messageExpiration()
            .setExpirationInDays(expireInDays)
            .send()
        return InboxRobot()
    }
    
    @discardableResult
    func send() -> InboxRobot {
        button(id.sendButtonLabel).tap()
        return InboxRobot()
    }
    
    @discardableResult
    func sendReplyMessage() -> MessageRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return MessageRobot()
    }

    func recipients(_ email: String) -> ComposerRobot {
        textField(id.toTextFieldIdentifier).tap().typeText(email)
        Element.other.tapIfExists(id.popoverDismissRegionOtherIdentifier)
        return self
    }
    
    func typeAndSelectRecipients(_ email: String) -> ComposerRobot {
        textField(id.toTextFieldIdentifier).tap().typeText(email)
        cell(id.getContactCellIdentifier(email)).tap()
        return self
    }
    
    func editRecipients(_ email: String) -> ComposerRobot {
        textField(id.toTextFieldIdentifier).tap().typeText(email)
        Element.other.tapIfExists(id.popoverDismissRegionOtherIdentifier)
        return self
    }
    
    func changeFromAddressTo(_ email: String) -> ComposerRobot {
        button(id.fromPickerButtonIdentifier).tap()
        button(email).tap()
        return ComposerRobot()
    }
    
    func changeSubjectTo(_ subjectText: String) -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier).tap().clearText().typeText(subjectText)
        return ComposerRobot()
    }
    
    func changeBodyTo(_ body: String) -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier).clearText().typeText(body)
        return ComposerRobot()
    }
    
    private func sendToContact() -> ContactDetailsRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return ContactDetailsRobot()
    }
    
    private func sendToContactGroup() -> ContactsRobot {
        button(id.sendButtonIdentifier).waitForHittable().tap()
        return ContactsRobot()
    }
    
    private func cc(_ email: String) -> ComposerRobot {
        textField(id.ccTextFieldIdentifier).tap().typeText(email)
        Element.other.tapIfExists(id.popoverDismissRegionOtherIdentifier)
        return self
    }
    
    func typeAndSelectCC(_ email: String) -> ComposerRobot {
        textField(id.ccTextFieldIdentifier).tap().typeText(email)
        cell(id.getContactCellIdentifier(email)).tap()
        return self
    }
    
    private func bcc(_ email: String) -> ComposerRobot {
        textField(id.bccTextFieldIdentifier).tap().typeText(email)
        Element.other.tapIfExists(id.popoverDismissRegionOtherIdentifier)
        return self
    }
    
    func typeAndSelectBCC(_ email: String) -> ComposerRobot {
        textField(id.bccTextFieldIdentifier).tap().typeText(email)
        cell(id.getContactCellIdentifier(email)).tap()
        return self
    }
    
    func subject(_ subjectText: String) -> ComposerRobot {
        textField(id.subjectTextFieldIdentifier).tap().typeText(subjectText)
        return self
    }
    
    @discardableResult
    private func body(_ text: String) -> ComposerRobot {
        ///TODO: add body update when WebView field will be accessible.
        return self
    }
    
    func pasteSubject(_ subjectText: String) -> ComposerRobot {
        Element.system.saveToClipBoard(subjectText)
        textField(id.subjectTextFieldIdentifier).tap()
        textField(id.subjectTextFieldIdentifier).longPress()
        menuItem().byIndex(0).onChild(staticText().byIndex(0)).tap()
        return self
    }
    
    func backgroundApp() -> ComposerRobot {
        XCUIDevice.shared.press(.home)
        return ComposerRobot()
    }
    
    func foregroundApp() -> ComposerRobot {
        XCUIApplication().activate()
        return ComposerRobot()
    }
    
    private func composeMessage(_ to: String, _ subject: String, _ body: String) -> ComposerRobot {
        return recipients(to)
            .subject(subject)
            .body(body)
    }
    
    private func setMessagePassword() -> MessagePasswordRobot  {
        button(id.passwordButtonIdentifier).tap()
        return MessagePasswordRobot()
    }
    
    private func addAttachment() -> MessageAttachmentsRobot  {
        button(id.attachmentButtonIdentifier).tap()
        return MessageAttachmentsRobot()
    }
    
    func showCcBcc() -> ComposerRobot {
        button(id.showCcBccButtonIdentifier).tap()
        return self
    }
    
    private func messageExpiration() -> MessageExpirationRobot {
        button(id.expirationButtonIdentifier).tap()
        return MessageExpirationRobot()
    }
    
    /**
     Class represents Message Password dialog.
     */
    class MessagePasswordRobot: CoreElements {
        func definePasswordWithHint(_ password: String, _ hint: String) -> ComposerRobot {
            return definePassword(password)
                .confirmPassword(password)
                .defineHint(hint)
                .applyPassword()
        }

        private func definePassword(_ password: String) -> MessagePasswordRobot {
            secureTextField(id.messagePasswordSecureTextFieldIdentifier).tap().typeText(password)
            return self
        }

        private func confirmPassword(_ password: String) -> MessagePasswordRobot {
            secureTextField(id.confirmPasswordSecureTextFieldIdentifier).tap().typeText(password)
            return self
        }

        private func defineHint(_ hint: String) -> MessagePasswordRobot {
            textField(id.hintPasswordTextFieldIdentifier).tap().typeText(hint)
            return self
        }

        private func applyPassword() -> ComposerRobot {
            button(id.applyButtonIdentifier).tap()
            return ComposerRobot()
        }
    }
    
    /**
     Class represents Message Expiration dialog.
     */
    class MessageExpirationRobot: CoreElements {
        @discardableResult
        func setExpirationInDays(_ days: Int) -> ComposerRobot {
            return expirationDays(days)
                .confirmMessageExpiration()
        }

        private func expirationDays(_ days: Int) -> MessageExpirationRobot {
            Element.pickerWheel.setPickerWheelValue(pickerWheelIndex: 0, value: days, dimension: "Days")
            return self
        }
        
        private func expirationHours(_ hours: Int) -> MessageExpirationRobot {
            Element.pickerWheel.setPickerWheelValue(pickerWheelIndex: 1, value: hours, dimension: "Hours")
            return self
        }

        private func confirmMessageExpiration() -> ComposerRobot {
            //Element.button.tapByIdentifier(expirationActionButtonIdentifier)
            return ComposerRobot()
        }
    }
    
    /**
     Class represents Message Expiration dialog.
     */
    class DraftConfirmationRobot: CoreElements {
        func confirmDraftSaving() -> InboxRobot {
            button(id.saveDraftButtonText).tap()
            return InboxRobot()
        }
        
        func confirmDraftSavingFromDrafts() -> DraftsRobot {
            button(id.saveDraftButtonText).tap()
            return DraftsRobot()
        }
    }
    
    /**
     Contains all the validations that can be performed by ComposerRobot.
    */
    class Verify: CoreElements {

        func fromEmailIs(_ email: String) {
            staticText(id.fromStaticTextIdentifier).checkHasLabel(email)
        }
        
        func messageWithSubjectOpened(_ subject: String) {
            textField(id.subjectTextFieldIdentifier).checkHasValue(subject)
        }
        
        @discardableResult
        func invalidAddressToastIsShown() -> ComposerRobot {
            staticText(id.invalidAddressStaticTextIdentifier).wait().checkExists()
            return ComposerRobot()
        }
        
        @discardableResult
        func invalidAddressToastIsNotShown() -> ComposerRobot {
            staticText(id.invalidAddressStaticTextIdentifier).waitUntilGone()
            return ComposerRobot()
        }
        
        @discardableResult
        func recipientNotFoundToastIsShown() -> ComposerRobot {
            staticText(id.recipientNotFoundStaticTextIdentifier).wait().checkExists()
            return ComposerRobot()
        }
        
        @discardableResult
        func ercipientNotFoundToastIsNotShown() -> ComposerRobot {
            staticText(id.recipientNotFoundStaticTextIdentifier).waitUntilGone()
            return ComposerRobot()
        }
    }
}
