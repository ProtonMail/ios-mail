//
//  Localization.swift
//  PMCoreTranslation - Created on 07.11.2020
//
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

// swiftlint:disable line_length identifier_name

import Foundation

public var CoreString = LocalizedString()

public class LocalizedString {

    // Human verification

    /// Title
    public lazy var _hv_title = NSLocalizedString("Human verification", bundle: Common.bundle, comment: "Title")

    /// Captcha method name
    public lazy var _hv_captha_method_name = NSLocalizedString("CAPTCHA", bundle: Common.bundle, comment: "captha method name")

    /// sms method name
    public lazy var _hv_sms_method_name = NSLocalizedString("SMS", bundle: Common.bundle, comment: "SMS method name")

    /// email method name
    public lazy var _hv_email_method_name = NSLocalizedString("Email", bundle: Common.bundle, comment: "email method name")

    /// Help button
    public lazy var _hv_help_button = NSLocalizedString("Help", bundle: Common.bundle, comment: "Help button")

    /// OK button
    public lazy var _hv_ok_button = NSLocalizedString("OK", bundle: Common.bundle, comment: "OK button")

    /// Cancel button
    public lazy var _hv_cancel_button = NSLocalizedString("Cancel", bundle: Common.bundle, comment: "Cancel button")

    // Human verification - email method

    /// Email enter label
    public lazy var _hv_email_enter_label = NSLocalizedString("Your email will only be used for this one-time verification.", bundle: Common.bundle, comment: "Enter email label")

    /// Email  label
    public lazy var _hv_email_label = NSLocalizedString("Email", bundle: Common.bundle, comment: "Email label")

    /// Email  verification button
    public lazy var _hv_email_verification_button = NSLocalizedString("Get verification code", bundle: Common.bundle, comment: "Verification button")

    // Human verification - sms method

    /// SMS enter label
    public lazy var _hv_sms_enter_label = NSLocalizedString("Your phone number will only be used for this one-time verification.", bundle: Common.bundle, comment: "Enter SMS label")

    /// SMS  label
    public lazy var _hv_sms_label = NSLocalizedString("Phone number", bundle: Common.bundle, comment: "SMS label")

    /// Search country placeholder
    public lazy var _hv_sms_search_placeholder = NSLocalizedString("Search country", bundle: Common.bundle, comment: "Search country placeholder")

    // Human verification - verification

    /// Verification enter sms code label
    public lazy var _hv_verification_enter_sms_code = NSLocalizedString("Enter the verification code that was sent to %@", bundle: Common.bundle, comment: "Enter sms code label")

    /// Verification enter email code label
    public lazy var _hv_verification_enter_email_code = NSLocalizedString("Enter the verification code that was sent to %@. If you don't find the email in your inbox, please check your spam folder.", bundle: Common.bundle, comment: "Enter email code label")

    /// Verification code label
    public lazy var _hv_verification_code = NSLocalizedString("Verification code", bundle: Common.bundle, comment: "Verification code label")

    /// Verification code hint label
    public lazy var _hv_verification_code_hint = NSLocalizedString("Enter the 6-digit code.", bundle: Common.bundle, comment: "Verification code hint label")

    /// Verification code Verify button
    public lazy var _hv_verification_verify_button = NSLocalizedString("Verify", bundle: Common.bundle, comment: "Verify button")

    /// Verification code Verifying button
    public lazy var _hv_verification_verifying_button = NSLocalizedString("Verifying", bundle: Common.bundle, comment: "Verifying button")

    public lazy var _hv_verification_not_receive_code_button = NSLocalizedString("Did not receive the code?", bundle: Common.bundle, comment: "Not receive code button")

    /// Verification code error alert title
    public lazy var _hv_verification_error_alert_title = NSLocalizedString("Invalid verification code", bundle: Common.bundle, comment: "alert title")

    /// Verification code error alert message
    public lazy var _hv_verification_error_alert_message = NSLocalizedString("Would you like to receive a new verification code or use an alternative verification method?", bundle: Common.bundle, comment: "alert message")

    /// Verification code error alert resend button
    public lazy var _hv_verification_error_alert_resend = NSLocalizedString("Resend", bundle: Common.bundle, comment: "resend alert button")

    /// Verification code error alert try other method button
    public lazy var _hv_verification_error_alert_other_method = NSLocalizedString("Try other method", bundle: Common.bundle, comment: "other method alert button")

    /// Verification new code alert title
    public lazy var _hv_verification_new_alert_title = NSLocalizedString("Request new code?", bundle: Common.bundle, comment: "alert title")

    /// Verification new code alert message
    public lazy var _hv_verification_new_alert_message = NSLocalizedString("Get a replacement code sent to %@.", bundle: Common.bundle, comment: "alert message")

    /// Verification new code alert new code button
    public lazy var _hv_verification_new_alert_button = NSLocalizedString("Request new code", bundle: Common.bundle, comment: "new code alert button")

    /// Verification new code sent banner title
    public lazy var _hv_verification_sent_banner = NSLocalizedString("Code sent to %@", bundle: Common.bundle, comment: "sent baner title")

    // Human verification - help

    /// Verification help header title
    public lazy var _hv_help_header = NSLocalizedString("Need help with human verification?", bundle: Common.bundle, comment: "help header title")

    /// Verification help request item title
    public lazy var _hv_help_request_item_title = NSLocalizedString("Request an invite", bundle: Common.bundle, comment: "request item title")

    /// Verification help request item message
    public lazy var _hv_help_request_item_message = NSLocalizedString("If you are having trouble creating your account, please request an invitation and we will respond within 1 business day.", bundle: Common.bundle, comment: "request item message")

    /// Verification help visit item title
    public lazy var _hv_help_visit_item_title = NSLocalizedString("Visit our Help Center", bundle: Common.bundle, comment: "visit item title")

    /// Verification help visit item message
    public lazy var _hv_help_visit_item_message = NSLocalizedString("Learn more about human verification and why we ask for it.", bundle: Common.bundle, comment: "visit item message")

    // Force upgrade

    /// Force upgrade alert title
    public lazy var _fu_alert_title = NSLocalizedString("Update required", bundle: Common.bundle, comment: "alert title")

    /// Force upgrade alert leran more button
    public lazy var _fu_alert_learn_more_button = NSLocalizedString("Learn more", bundle: Common.bundle, comment: "learn more button")

    /// Force upgrade alert update button
    public lazy var _fu_alert_update_button = NSLocalizedString("Update", bundle: Common.bundle, comment: "update button")

    /// Force upgrade alert quit button
    public lazy var _fu_alert_quit_button = NSLocalizedString("Quit", bundle: Common.bundle, comment: "quit button")

    // Login screen

    /// Login screen title
    public lazy var _ls_screen_title = NSLocalizedString("Sign in", bundle: Common.bundle, comment: "Login screen title")

    /// Login screen subtitle
    public lazy var _ls_screen_subtitle = NSLocalizedString("Enter your Proton Account details.", bundle: Common.bundle, comment: "Login screen subtitle")

    /// Username field title
    public lazy var _ls_username_title = NSLocalizedString("Email or username", bundle: Common.bundle, comment: "Username field title")

    /// Password field title
    public lazy var _ls_password_title = NSLocalizedString("Password", bundle: Common.bundle, comment: "Password field title")

    /// Help button
    public lazy var _ls_help_button = NSLocalizedString("Need help?", bundle: Common.bundle, comment: "Help button")

    // Login help

    /// Login help screen title
    public lazy var _ls_help_screen_title = NSLocalizedString("How can we help?", bundle: Common.bundle, comment: "Login help screen title")

    /// Forgot username help button
    public lazy var _ls_help_forgot_username = NSLocalizedString("Forgot username", bundle: Common.bundle, comment: "Forgot username help button")

    /// Forgot password help button
    public lazy var _ls_help_forgot_password = NSLocalizedString("Forgot password", bundle: Common.bundle, comment: "Forgot password help button")

    /// Other sign-in issues help button
    public lazy var _ls_help_other_issues = NSLocalizedString("Other sign-in issues", bundle: Common.bundle, comment: "Other sign-in issues button")

    /// Customer support help button
    public lazy var _ls_help_customer_support = NSLocalizedString("Customer support", bundle: Common.bundle, comment: "Customer support button")

    /// More help button
    public lazy var _ls_help_more_help = NSLocalizedString("Still need help? Contact us directly.", bundle: Common.bundle, comment: "Customer support button")

    // Login validation

    /// Invalid username hint
    public lazy var _ls_validation_invalid_username = NSLocalizedString("Please enter your Proton Account email or username.", bundle: Common.bundle, comment: "Invalid username hint")

    /// Invalid password hint
    public lazy var _ls_validation_invalid_password = NSLocalizedString("Please enter your Proton Account password.", bundle: Common.bundle, comment: "Invalid password hint")

    // Login errors

    /// Dialog button for missing keys error
    public lazy var _ls_error_missing_keys_text_button = NSLocalizedString("Complete Setup", bundle: Common.bundle, comment: "Dialog button for missing keys error")

    /// Dialog text for missing keys error
    public lazy var _ls_error_missing_keys_text = NSLocalizedString("Your account is missing keys, please sign in on web to automatically generate required keys. Once you have signed in on web, please return to the app and sign in.", bundle: Common.bundle, comment: "Dialog text for missing keys error")

    /// Dialog title for missing keys error
    public lazy var _ls_error_missing_keys_title = NSLocalizedString("Account setup required", bundle: Common.bundle, comment: "Dialog title for missing keys error")

    /// Incorrect mailbox password error
    public lazy var _ls_error_invalid_mailbox_password = NSLocalizedString("Incorrect mailbox password", bundle: Common.bundle, comment: "Incorrect mailbox password error")

    /// Generic error message when no better error can be displayed
    public lazy var _ls_error_generic = NSLocalizedString("An error has occured", bundle: Common.bundle, comment: "Generic error message when no better error can be displayed")

    // Login choose username

    /// Screen title for picking Protonmail username
    public lazy var _ls_username_screen_title = NSLocalizedString("Create ProtonMail address", bundle: Common.bundle, comment: "Screen title for creating ProtonMail address")

    /// Info about existing external ProtonMail address
    public lazy var _ls_username_screen_info = NSLocalizedString("Your Proton Account is associated with %@. To use %@, please create an address.", bundle: Common.bundle, comment: "Info about existing external ProtonMail address")

    /// Username field title
    public lazy var _ls_username_username_title = NSLocalizedString("Username", bundle: Common.bundle, comment: "Username field title")

    /// Action button title for picking Protonmail username
    public lazy var _ls_username_button_title = NSLocalizedString("Next", bundle: Common.bundle, comment: "Action button title for picking Protonmail username")

    /// Username field error message
    public lazy var _ls_username_username_error = NSLocalizedString("Please enter a username.", bundle: Common.bundle, comment: "Username field error message")

    // Login create address

    /// Action button title for creating ProtonMail address
    public lazy var _ls_create_address_button_title = NSLocalizedString("Create address", bundle: Common.bundle, comment: "Action button title for creating ProtonMail address")

    /// Info about ProtonMail address usage
    public lazy var _ls_create_address_info = NSLocalizedString("You will use this email address to log in to all Proton services.", bundle: Common.bundle, comment: "Info about ProtonMail address usage")

    /// Recovery address label title
    public lazy var _ls_create_address_recovery_title = NSLocalizedString("Your recovery email address:", bundle: Common.bundle, comment: "Recovery address label title")

    /// Terms and conditions note
    public lazy var _ls_create_address_terms_full = NSLocalizedString("By clicking Create address, you agree with Proton's Terms and Conditions.", bundle: Common.bundle, comment: "Terms and conditions note")

    /// Terms and conditions link in the note
    public lazy var _ls_create_address_terms_link = NSLocalizedString("Terms and Conditions", bundle: Common.bundle, comment: "Terms and conditions link in the note")

    /// ProtonMail address availability
    public lazy var _ls_create_address_available = NSLocalizedString("%@ is available", bundle: Common.bundle, comment: "ProtonMail address availability")

    // Login unlock mailbox

    /// Mailbox unlock screen title
    public lazy var _ls_login_mailbox_screen_title = NSLocalizedString("Unlock your mailbox", bundle: Common.bundle, comment: "Mailbox unlock screen title")

    /// Mailbox password field title
    public lazy var _ls_login_mailbox_field_title = NSLocalizedString("Mailbox password", bundle: Common.bundle, comment: "Mailbox password field title")

    /// Mailbox unlock screen action button title
    public lazy var _ls_login_mailbox_button_title = NSLocalizedString("Unlock", bundle: Common.bundle, comment: "Mailbox unlock screen action button title")

    /// Forgot password button title
    public lazy var _ls_login_mailbox_forgot_password = NSLocalizedString("Forgot password", bundle: Common.bundle, comment: "Forgot password button title")

    // Login 2FA

    /// 2FA screen title
    public lazy var _ls_login_2fa_screen_title = NSLocalizedString("Two-factor authentication", bundle: Common.bundle, comment: "2FA screen title")

    /// 2FA screen action button title
    public lazy var _ls_login_2fa_action_button_title = NSLocalizedString("Authenticate", bundle: Common.bundle, comment: "2FA screen action button title")

    /// 2FA screen field title
    public lazy var _ls_login_2fa_field_title = NSLocalizedString("Two-factor code", bundle: Common.bundle, comment: "2FA screen field title")

    /// 2FA screen recovery field title
    public lazy var _ls_login_2fa_recovery_field_title = NSLocalizedString("Recovery code", bundle: Common.bundle, comment: "2FA screen recovery field title")

    /// 2FA screen recovery button title
    public lazy var _ls_login_2fa_recovery_button_title = NSLocalizedString("Use recovery code", bundle: Common.bundle, comment: "2FA screen recovery button title")

    /// 2FA screen 2FA button title
    public lazy var _ls_login_2fa_2fa_button_title = NSLocalizedString("Use two-factor code", bundle: Common.bundle, comment: "2FA screen 2FA button title")

    /// 2FA screen field info
    public lazy var _ls_login_2fa_field_info = NSLocalizedString("Enter the 6-digit code.", bundle: Common.bundle, comment: "2FA screen field info")

    /// 2FA screen recovery field info
    public lazy var _ls_login_2fa_recovery_field_info = NSLocalizedString("Enter an 8-character recovery code.", bundle: Common.bundle, comment: "2FA screen recovery field info")

    // Payments

    public lazy var _error_occured = NSLocalizedString("Error occured", bundle: Common.bundle, comment: "Error alert title")

    /// "OK"
    public lazy var _general_ok_action = NSLocalizedString("OK", bundle: Common.bundle, comment: "Action")

    /// "Warning"
    public lazy var _warning = NSLocalizedString("Warning", bundle: Common.bundle, comment: "Title")

    /// UIAlerts
    public lazy var _do_you_want_to_bypass_validation = NSLocalizedString("Do you want to activate the purchase for %@ address?", bundle: Common.bundle, comment: "Question is user wants to bypass username validation and activate plan for current username")

    public lazy var _yes_bypass_validation = NSLocalizedString("Yes, activate it for ", bundle: Common.bundle, comment: "Warning message option to bypass validation and activate plan for current username")

    public lazy var _no_dont_bypass_validation = NSLocalizedString("No, for another ProtonMail account", bundle: Common.bundle, comment: "Warning message option when user want to relogin to another account")

    public lazy var _error_apply_payment_on_registration_title = NSLocalizedString("Payment failed", bundle: Common.bundle, comment: "Error applying credit after registration alert")

    public lazy var _error_apply_payment_on_registration_message = NSLocalizedString("You have successfully registered but your payment was not processed. To resend your payment information, click Retry. You will only be charged once. If the problem persists, please contact customer support.", bundle: Common.bundle, comment: "Error applying credit after registration alert")

    public lazy var _retry = NSLocalizedString("Retry", bundle: Common.bundle, comment: "Button in some alerts")

    public lazy var _error_apply_payment_on_registration_support = NSLocalizedString("Contact customer support", bundle: Common.bundle, comment: "Error applying credit after registration alert")

    public lazy var _error_unknown_title = NSLocalizedString("Unknown error", bundle: Common.bundle, comment: "General title for several error alerts")

    /// Errors
    public lazy var _error_unavailable_product = NSLocalizedString("Failed to get list of available products from AppStore.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_invalid_purchase = NSLocalizedString("Purchase is not possible.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_reciept_lost = NSLocalizedString("Apple informed us you've upgraded the service plan, but some technical data was missing. Please fill in the bug report and our customer support team will contact you.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_another_user_transaction = NSLocalizedString("Apple informed us you've upgraded the service plan, but we detected you have logged out of the account since then.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_backend_mismatch = NSLocalizedString("It wasn't possible to match your purchased App Store product to any products on our server. Please fill in the bug report and our customer support team will contact you.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_sandbox_receipt = NSLocalizedString("Sorry, we cannot process purchases in the beta version of the iOS app. Thank you for participating in our public beta!", bundle: Common.bundle, comment: "Error message for beta users")

    public lazy var _error_no_hashed_username_arrived_in_transaction = NSLocalizedString("We have been notified of an App Store purchase but cannot match the purchase with an account of yours.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_no_active_username_in_user_data_service = NSLocalizedString("Please log in to the ProtonMail account you're upgrading the service plan for so we can complete the purchase.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_transaction_failed_by_unknown_reason = NSLocalizedString("Apple informed us they could not process the purchase.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_no_new_subscription_in_response = NSLocalizedString("We have successfully activated your subscription. Please relaunch the app to start using your new service plan.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_unlock_to_proceed_with_iap = NSLocalizedString("Please unlock the app to proceed with your service plan activation", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_please_sign_in_iap = NSLocalizedString("Please log in to the ProtonMail account you're upgrading the service plan for so we can complete the service plan activation.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_credits_applied = NSLocalizedString("Contact support@protonvpn.com to complete your purchase.", bundle: Common.bundle, comment: "In App Purchase error")

    public lazy var _error_wrong_token_status = NSLocalizedString("Wrong payment token status. Please relaunch the app. If error persists, contact support.", bundle: Common.bundle, comment: "In App Purchase error")

    //  Login upgrade username-only account

    /// Dialog title for organization user first login
    public lazy var _login_username_org_dialog_title = NSLocalizedString("Change your password", bundle: Common.bundle, comment: "Dialog title for organization user first login")

    /// Dialog action button title for organization user first login
    public lazy var _login_username_org_dialog_action_button = NSLocalizedString("Change password", bundle: Common.bundle, comment: "Dialog action button title for organization user first login")

    /// Dialog message for organization user first login
    public lazy var _login_username_org_dialog_message = NSLocalizedString("To use the Proton app as a member of an organization, you first need to change your password by signing into Proton through a browser.", bundle: Common.bundle, comment: "Dialog message for organization user first login")
    
    /// Account switcher
    
    public lazy var _as_switch_to_title = NSLocalizedString("switch to", bundle: Common.bundle, comment: "Section title of account switcher")
    
    public lazy var _as_manage_accounts = NSLocalizedString("Manage accounts", bundle: Common.bundle, comment: "Manage accounts button")
    
    public lazy var _as_signed_in_to_protonmail = NSLocalizedString("Signed in to ProtonMail", bundle: Common.bundle, comment: "Section title of account manager")
    
    public lazy var _as_signed_out_of_protonmail = NSLocalizedString("Signed out of Protonmail", bundle: Common.bundle, comment: "Section title of account manager")
    
    public lazy var _as_signout = NSLocalizedString("Sign out", bundle: Common.bundle, comment: "Sign out button/ title")
    
    public lazy var _as_remove_account = NSLocalizedString("Remove account", bundle: Common.bundle, comment: "remove account button")
    
    public lazy var _as_remove_account_alert_text = NSLocalizedString("You will be signed out and all the data associated with this account will be removed from this device.", bundle: Common.bundle, comment: "Alert message of remove account")
    
    public lazy var _as_remove_button = NSLocalizedString("Remove", bundle: Common.bundle, comment: "Remove button")
    
    public lazy var _as_signout_alert_text = NSLocalizedString("Are you sure you want to sign out %@?", bundle: Common.bundle, comment: "Alert message of sign out the email address")
}
