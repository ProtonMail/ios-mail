//
//  Localization.swift
//  ProtonCore-CoreTranslation - Created on 07.11.2020
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

// swiftlint:disable line_length identifier_name

import Foundation

public var CoreString = LocalizedString()

public class LocalizedString {

    // Human verification

    /// Title
    public lazy var _hv_title = NSLocalizedString("Human Verification", bundle: Common.bundle, comment: "Title")

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

    /// Sign in button
    public lazy var _ls_sign_in_button = NSLocalizedString("Sign in", bundle: Common.bundle, comment: "Sign in button")

    /// Sign up button
    public lazy var _ls_create_account_button = NSLocalizedString("Create an account", bundle: Common.bundle, comment: "Create account button")

    // Login welcome screen

    public lazy var _ls_welcome_footer = NSLocalizedString("One account for all Proton services.", bundle: Common.bundle, comment: "Welcome screen footer label")

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

    /// Screen title for picking Proton mail username
    public lazy var _ls_username_screen_title = NSLocalizedString("Create Proton Mail address", bundle: Common.bundle, comment: "Screen title for creating Proton Mail address")

    /// Info about existing external Proton Mail address
    public lazy var _ls_username_screen_info = NSLocalizedString("Your Proton Account is associated with %@. To use %@, please create an address.", bundle: Common.bundle, comment: "Info about existing external Proton Mail address")

    /// Username field title
    public lazy var _ls_username_username_title = NSLocalizedString("Username", bundle: Common.bundle, comment: "Username field title")

    /// Action button title for picking Proton Mail username
    public lazy var _ls_username_button_title = NSLocalizedString("Next", bundle: Common.bundle, comment: "Action button title for picking Proton Mail username")

    /// Username field error message
    public lazy var _ls_username_username_error = NSLocalizedString("Please enter a username.", bundle: Common.bundle, comment: "Username field error message")

    // Login create address

    /// Action button title for creating Proton Mail address
    public lazy var _ls_create_address_button_title = NSLocalizedString("Create address", bundle: Common.bundle, comment: "Action button title for creating Proton Mail address")

    /// Info about Proton Mail address usage
    public lazy var _ls_create_address_info = NSLocalizedString("You will use this email address to log into all Proton services.", bundle: Common.bundle, comment: "Info about Proton Mail address usage")

    /// Recovery address label title
    public lazy var _ls_create_address_recovery_title = NSLocalizedString("Your recovery email address:", bundle: Common.bundle, comment: "Recovery address label title")

    /// Terms and conditions note
    public lazy var _ls_create_address_terms_full = NSLocalizedString("By clicking Create address, you agree with Proton's Terms and Conditions.", bundle: Common.bundle, comment: "Terms and conditions note")

    /// Terms and conditions link in the note
    public lazy var _ls_create_address_terms_link = NSLocalizedString("Terms and Conditions", bundle: Common.bundle, comment: "Terms and conditions link in the note")

    /// Proton Mail address availability
    public lazy var _ls_create_address_available = NSLocalizedString("%@ is available", bundle: Common.bundle, comment: "Proton Mail address availability")

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

    public lazy var _no_dont_bypass_validation = NSLocalizedString("No, for another Proton Mail account", bundle: Common.bundle, comment: "Warning message option when user want to relogin to another account")
    
    public lazy var _popup_credits_applied_message = NSLocalizedString("We were unable to upgrade your account to the plan you selected, so we added your payment as credits to your account. For more information and to complete your upgrade, please contact Support.", comment: "Message shown to the user if we had to top up the account with credits instead of purchasing a plan")
    
    public lazy var _popup_credits_applied_confirmation = NSLocalizedString("Contact Support", comment: "Confirmation for the credits applied popup, will result in showing customer support contact form")
    
    public lazy var _popup_credits_applied_cancellation = NSLocalizedString("Dismiss", comment: "Cancellation for the credits applied popup")

    public lazy var _error_apply_payment_on_registration_title = NSLocalizedString("Payment failed", bundle: Common.bundle, comment: "Error applying credit after registration alert")

    public lazy var _error_apply_payment_on_registration_message = NSLocalizedString("You have successfully registered but your payment was not processed. To resend your payment information, click Retry. You will only be charged once. If the problem persists, please contact customer support.", bundle: Common.bundle, comment: "Error applying credit after registration alert")

    public lazy var _retry = NSLocalizedString("Retry", bundle: Common.bundle, comment: "Button in some alerts")

    public lazy var _error_apply_payment_on_registration_support = NSLocalizedString("Contact customer support", bundle: Common.bundle, comment: "Error applying credit after registration alert")

    /// Errors
    public lazy var _error_unavailable_product = NSLocalizedString("Failed to get list of available products from App Store.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_invalid_purchase = NSLocalizedString("Purchase is not possible.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_reciept_lost = NSLocalizedString("Apple informed us you've upgraded the service plan, but some technical data was missing. Please fill in the bug report and our customer support team will contact you.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_another_user_transaction = NSLocalizedString("Apple informed us you've upgraded the service plan, but we detected you have logged out of the account since then.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_backend_mismatch = NSLocalizedString("It wasn't possible to match your purchased App Store product to any products on our server. Please fill in the bug report and our customer support team will contact you.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_sandbox_receipt = NSLocalizedString("Sorry, we cannot process purchases in the beta version of the iOS app. Thank you for participating in our public beta!", bundle: Common.bundle, comment: "Error message for beta users")

    public lazy var _error_no_hashed_username_arrived_in_transaction = NSLocalizedString("We have been notified of an App Store purchase but cannot match the purchase with an account of yours.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_no_active_username_in_user_data_service = NSLocalizedString("Please log in to the Proton Mail account you're upgrading the service plan for so we can complete the purchase.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_transaction_failed_by_unknown_reason = NSLocalizedString("Apple informed us they could not process the purchase.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_no_new_subscription_in_response = NSLocalizedString("We have successfully activated your subscription. Please relaunch the app to start using your new service plan.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_unlock_to_proceed_with_iap = NSLocalizedString("Please unlock the app to proceed with your service plan activation", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_please_sign_in_iap = NSLocalizedString("Please log in to the Proton Mail account you're upgrading the service plan for so we can complete the service plan activation.", bundle: Common.bundle, comment: "Error message")

    public lazy var _error_credits_applied = NSLocalizedString("Contact support@protonvpn.com to complete your purchase.", bundle: Common.bundle, comment: "In App Purchase error")

    public lazy var _error_wrong_token_status = NSLocalizedString("Wrong payment token status. Please relaunch the app. If error persists, contact support.", bundle: Common.bundle, comment: "In App Purchase error")

    //  Login upgrade username-only account

    /// Dialog title for organization user first login
    public lazy var _login_username_org_dialog_title = NSLocalizedString("Change your password", bundle: Common.bundle, comment: "Dialog title for organization user first login")

    /// Dialog action button title for organization user first login
    public lazy var _login_username_org_dialog_action_button = NSLocalizedString("Change password", bundle: Common.bundle, comment: "Dialog action button title for organization user first login")

    /// Dialog message for organization user first login
    public lazy var _login_username_org_dialog_message = NSLocalizedString("To use the Proton app as a member of an organization, you first need to change your password by signing into Proton through a browser.", bundle: Common.bundle, comment: "Dialog message for organization user first login")
    
    /// Account deletion
    
    public lazy var _ad_delete_account_title = NSLocalizedString("Delete account", bundle: Common.bundle, comment: "Delete account screen title")
    
    public lazy var _ad_delete_account_button = NSLocalizedString("Delete account", bundle: Common.bundle, comment: "Delete account button title")
    
    public lazy var _ad_delete_account_message = NSLocalizedString("This will permanently delete your account and all of its data. You will not be able to reactivate this account.", bundle: Common.bundle, comment: "Delete account explaination under button")
    
    public lazy var _ad_delete_account_success = NSLocalizedString("Account deleted.\nLogging out...", bundle: Common.bundle, comment: "Delete account success")
    
    public lazy var _ad_delete_network_error = NSLocalizedString("A networking error has occured", bundle: Common.bundle, comment: "A generic error message when we have no better message from the backend")
    
    public lazy var _ad_delete_close_button = NSLocalizedString("Close", bundle: Common.bundle, comment: "Button title shown when a error has occured, causes the screen to close")

    /// Account switcher

    public lazy var _as_switch_to_title = NSLocalizedString("switch to", bundle: Common.bundle, comment: "Section title of account switcher")

    public lazy var _as_accounts = NSLocalizedString("Accounts", bundle: Common.bundle, comment: "Title of account switcher")

    public lazy var _as_manage_accounts = NSLocalizedString("Manage accounts", bundle: Common.bundle, comment: "Manage accounts button")

    public lazy var _as_signed_in_to_protonmail = NSLocalizedString("Signed in to Proton Mail", bundle: Common.bundle, comment: "Section title of account manager")

    public lazy var _as_signed_out_of_protonmail = NSLocalizedString("Signed out of Proton Mail", bundle: Common.bundle, comment: "Section title of account manager")

    public lazy var _as_signout = NSLocalizedString("Sign out", bundle: Common.bundle, comment: "Sign out button/ title")
    
    public lazy var _as_remove_button = NSLocalizedString("Remove", bundle: Common.bundle, comment: "Remove button")

    public lazy var _as_remove_account_from_this_device = NSLocalizedString(
        "Remove account from this device", bundle: Common.bundle, value: _as_remove_button, comment: "remove account button in account manager"
    )
    
    public lazy var _as_remove_account = NSLocalizedString("Remove account", bundle: Common.bundle, comment: "old value of remove account button in account manager")

    public lazy var _as_remove_account_alert_text = NSLocalizedString("You will be signed out and all the data associated with this account will be removed from this device.", bundle: Common.bundle, comment: "Alert message of remove account")

    public lazy var _as_signout_alert_text = NSLocalizedString("Are you sure you want to sign out %@?", bundle: Common.bundle, comment: "Alert message of sign out the email address")

    public lazy var _as_dismiss_button = NSLocalizedString("Dismiss account switcher", bundle: Common.bundle, comment: "Button for dismissing account switcher")
    
    public lazy var _as_sign_in_button = NSLocalizedString("Sign in to another account", bundle: Common.bundle, comment: "Button for signing into another account")

    // Signup

    /// Signup main view title
    public lazy var _su_main_view_title = NSLocalizedString("Create your Proton Account", bundle: Common.bundle, comment: "Signup main view title")

    /// Signup main view description
    public lazy var _su_main_view_desc = NSLocalizedString("One account for all Proton services.", bundle: Common.bundle, comment: "Signup main view description")

    /// Next button
    public lazy var _su_next_button = NSLocalizedString("Next", bundle: Common.bundle, comment: "Next button")

    /// Sign in button
    public lazy var _su_signin_button = NSLocalizedString("Sign in", bundle: Common.bundle, comment: "Sign in button")

    /// Email address button
    public lazy var _su_email_address_button = NSLocalizedString("Use your current email instead", bundle: Common.bundle, comment: "Email address button")

    /// Proton Mail address  button
    public lazy var _su_proton_address_button = NSLocalizedString("Create a secure Proton Mail address instead", bundle: Common.bundle, comment: "Proton Mail address button")

    /// Username field title
    public lazy var _su_username_field_title = NSLocalizedString("Username", bundle: Common.bundle, comment: "Username field title")

    /// Email field title
    public lazy var _su_email_field_title = NSLocalizedString("Email", bundle: Common.bundle, comment: "Email field title")

    /// Signup password proton view title
    public lazy var _su_password_proton_view_title = NSLocalizedString("Create your password", bundle: Common.bundle, comment: "Signup password proton view title")

    /// Signup password email view title
    public lazy var _su_password_email_view_title = NSLocalizedString("Create a Proton account with your current email", bundle: Common.bundle, comment: "Signup password email view title")

    /// Password field title
    public lazy var _su_password_field_title = NSLocalizedString("Password", bundle: Common.bundle, comment: "Password field title")

    public lazy var _su_password_field_hint = NSLocalizedString("Password must contain at least 8 characters", bundle: Common.bundle, comment: "Password field hint about minimum length")

    /// Repeat password field title
    public lazy var _su_repeat_password_field_title = NSLocalizedString("Repeat password", bundle: Common.bundle, comment: "Repeat password field title")
    
    public lazy var _su_domains_sheet_title = NSLocalizedString("Domain", bundle: Common.bundle, comment: "Title of domains bottom action sheet")

    // TODO: CP-2352 — remove the default value once the text is translated to all languages
    
    /// Signup recovery view title
    public lazy var _su_recovery_view_title = NSLocalizedString(
        "Set recovery method",
        tableName: nil,
        bundle: Common.bundle,
        value: _su_recovery_method_button,
        comment: "Recovery view title"
    )
    
    /// Signup recovery view title optional
    public lazy var _su_recovery_view_title_optional = NSLocalizedString(
        "Set recovery method (optional)",
        tableName: nil,
        bundle: Common.bundle,
        value: _su_recovery_method_button,
        comment: "Recovery view title optional"
    )

    // TODO: CP-2352 — remove the string once the new text (below) is translated to all languages
    /// Signup recovery view description — old string
    public lazy var _su_recovery_view_desc_old = NSLocalizedString("This will help you access your account in case you forget your password or get locked out of your account.", bundle: Common.bundle, comment: "Recovery view description (old string, replaced)")

    // TODO: CP-2352 — remove the default value once the text is translated to all languages
    /// Signup recovery view description
    public lazy var _su_recovery_view_desc = NSLocalizedString(
        "We will send recovery instructions to this email or phone number if you get locked out of your account.",
        tableName: nil,
        bundle: Common.bundle,
        value: _su_recovery_view_desc_old,
        comment: "Recovery view description"
    )
    
    public lazy var _su_recovery_email_only_view_desc = NSLocalizedString(
        "We will send recovery instructions to this email if you get locked out of your account.",
        tableName: nil,
        bundle: Common.bundle,
        value: _su_recovery_view_desc_old,
        comment: "Recovery view description"
    )

    /// Signup recovery segmented email
    public lazy var _su_recovery_seg_email = NSLocalizedString("Email", bundle: Common.bundle, comment: "Recovery segmenet email")

    /// Signup recovery segmented phone
    public lazy var _su_recovery_seg_phone = NSLocalizedString("Phone", bundle: Common.bundle, comment: "Recovery segmenet phone")

    /// Signup recovery email field title
    public lazy var _su_recovery_email_field_title = NSLocalizedString("Recovery email", bundle: Common.bundle, comment: "Recovery email field title")

    /// Signup recovery phone field title
    public lazy var _su_recovery_phone_field_title = NSLocalizedString("Recovery phone number", bundle: Common.bundle, comment: "Recovery phone field title")

    /// Signup recovery terms and conditions description
    public lazy var _su_recovery_t_c_desc = NSLocalizedString("By clicking Next, you agree with Proton's Terms and Conditions", bundle: Common.bundle, comment: "Recovery terms and conditions description")

    /// Signup recovery terms and conditions link
    public lazy var _su_recovery_t_c_link = NSLocalizedString("Terms and Conditions", bundle: Common.bundle, comment: "Recovery terms and conditions link")

    /// Skip button
    public lazy var _su_skip_button = NSLocalizedString("Skip", bundle: Common.bundle, comment: "Skip button")

    /// Recovery skip title
    public lazy var _su_recovery_skip_title = NSLocalizedString("Skip recovery method?", bundle: Common.bundle, comment: "Recovery skip title")

    /// Recovery skip description
    public lazy var _su_recovery_skip_desc = NSLocalizedString("A recovery method will help you access your account in case you forget your password or get locked out of your account.", bundle: Common.bundle, comment: "Recovery skip description")

    /// Recovery method button
    public lazy var _su_recovery_method_button = NSLocalizedString("Set recovery method", bundle: Common.bundle, comment: "Set recovery method button")

    /// Signup complete view title
    public lazy var _su_complete_view_title = NSLocalizedString("Your account is being created", bundle: Common.bundle, comment: "Complete view title")

    /// Signup complete view description
    public lazy var _su_complete_view_desc = NSLocalizedString("This should take no more than a minute.", bundle: Common.bundle, comment: "Complete view description")

    /// Signup complete progress step creation
    public lazy var _su_complete_step_creation = NSLocalizedString("Creating your account", bundle: Common.bundle, comment: "Signup complete progress step creation")
    
    /// Signup complete progress step address generation
    public lazy var _su_complete_step_address_generation = NSLocalizedString("Generating your address", bundle: Common.bundle, comment: "Signup complete progress step address generation")
    
    /// Signup complete progress step keys generation
    public lazy var _su_complete_step_keys_generation = NSLocalizedString("Securing your account", bundle: Common.bundle, comment: "Signup complete progress step keys generation")
    
    /// Signup complete progress step payment validation
    public lazy var _su_complete_step_payment_verification = NSLocalizedString("Verifying your payment", bundle: Common.bundle, comment: "Signup complete progress step payment verification")
    
    /// Signup complete progress step payment validated
    public lazy var _su_complete_step_payment_validated = NSLocalizedString("Payment validated", bundle: Common.bundle, comment: "Signup complete progress step payment validated")

    /// Signup email verification view title
    public lazy var _su_email_verification_view_title = NSLocalizedString("Account verification", bundle: Common.bundle, comment: "Email verification view title")

    /// Signup email verification view description
    public lazy var _su_email_verification_view_desc = NSLocalizedString("For your security, we must verify that the address you entered belongs to you. We sent a verification code to %@. Please enter the code below:", bundle: Common.bundle, comment: "Email verification view description")

    /// Signup email verification code name
    public lazy var _su_email_verification_code_name = NSLocalizedString("Verification code", bundle: Common.bundle, comment: "Email verification code name")

    /// Signup email verification code description
    public lazy var _su_email_verification_code_desc = NSLocalizedString("Enter the 6-digit code.", bundle: Common.bundle, comment: "Email verification code description")

    /// Did not receive code button
    public lazy var _su_did_not_receive_code_button = NSLocalizedString("Did not receive a code?", bundle: Common.bundle, comment: "Did not receive code button")

    /// Signup terms and conditions view title
    public lazy var _su_terms_conditions_view_title = NSLocalizedString("Terms and Conditions", bundle: Common.bundle, comment: "Terms and conditions view title")

    /// Signup error invalid token request
    public lazy var _su_error_invalid_token_request = NSLocalizedString("Invalid token request", bundle: Common.bundle, comment: "Invalid token request error")

    /// Signup error invalid token
    public lazy var _su_error_invalid_token = NSLocalizedString("Invalid token error", bundle: Common.bundle, comment: "Invalid token error")

    /// Signup error create user failed
    public lazy var _su_error_create_user_failed = NSLocalizedString("Create user failed", bundle: Common.bundle, comment: "Create user failed error")

    /// Signup error invalid hashed password
    public lazy var _su_error_invalid_hashed_password = NSLocalizedString("Invalid hashed password", bundle: Common.bundle, comment: "Invalid hashed password error")

    /// Signup error password empty
    public lazy var _su_error_password_empty = NSLocalizedString("Password can not be empty.\nPlease try again.", bundle: Common.bundle, comment: "Password empty error")

    public lazy var _su_error_password_too_short = NSLocalizedString("Password must contain at least %@ characters.", bundle: Common.bundle, comment: "Password too short error")

    /// Signup error password not equal
    public lazy var _su_error_password_not_equal = NSLocalizedString("Passwords do not match.\nPlease try again.", bundle: Common.bundle, comment: "Password not equal error")

    /// Signup error email address already used
    public lazy var _su_error_email_already_used = NSLocalizedString("Email address already used.", bundle: Common.bundle, comment: "Email address already used error")
    
    /// Signup error email address already used
    public lazy var _su_error_missing_sub_user_configuration = NSLocalizedString("Please ask your admin to configure your sub-user.", bundle: Common.bundle, comment: "Sub-user configuration error")

    /// Signup invalid verification alert message
    public lazy var _su_invalid_verification_alert_message = NSLocalizedString("Would you like to receive a new verification code or use an alternate email address?", bundle: Common.bundle, comment: "Invalid verification alert message")

    /// Signup invalid verification change email address button
    public lazy var _su_invalid_verification_change_email_button = NSLocalizedString("Change email address", bundle: Common.bundle, comment: "Change email address button")
    
    /// Signup summary title
    public lazy var _su_summary_title = NSLocalizedString("Congratulations", bundle: Common.bundle, comment: "Signup summary title")
    
    /// Signup summary free plan description
    public lazy var _su_summary_free_description = NSLocalizedString("Your Proton Free account was successfully created.", bundle: Common.bundle, comment: "Signup summary free plan description")
    
    /// Signup summary free plan description replacement
    public lazy var _su_summary_free_description_replacement = NSLocalizedString("Proton Free", bundle: Common.bundle, comment: "Signup summary free plan description replacement")
    
    /// Signup summary paid plan description
    public lazy var _su_summary_paid_description = NSLocalizedString("Your payment was confirmed and your %@ account successfully created.", bundle: Common.bundle, comment: "Signup summary paid plan description")
    
    /// Signup summary welcome text
    public lazy var _su_summary_welcome = NSLocalizedString("Enjoy the world of privacy.", bundle: Common.bundle, comment: "Signup summary welcome text")
    
    // Payments UI
    
    /// Select a plan title
    public lazy var _pu_select_plan_title = NSLocalizedString("Select a plan", bundle: Common.bundle, comment: "Plan selection title")

    /// Current plan title
    public lazy var _pu_current_plan_title = NSLocalizedString("Current plan", bundle: Common.bundle, comment: "Plan selection title")
    
    /// Subscription title
    public lazy var _pu_subscription_title = NSLocalizedString("Subscription", bundle: Common.bundle, comment: "Subscription title")
  
    /// Upgrade plan title
    public lazy var _pu_upgrade_plan_title = NSLocalizedString("Upgrade your plan", bundle: Common.bundle, comment: "Plan selection title")
    
    /// Plan footer description
    public lazy var _pu_plan_footer_desc = NSLocalizedString("Only annual subscriptions without auto-renewal are available inside the mobile app.", bundle: Common.bundle, comment: "Plan footer description")

    /// Plan footer description purchased
    public lazy var _pu_plan_footer_desc_purchased = NSLocalizedString("You cannot manage subscriptions inside the mobile application.", bundle: Common.bundle, comment: "Plan footer purchased description")
    
    /// Select plan button
    public lazy var _pu_select_plan_button = NSLocalizedString("Select", bundle: Common.bundle, comment: "Select plan button")
    
    /// Upgrade plan button
    public lazy var _pu_upgrade_plan_button = NSLocalizedString("Upgrade", bundle: Common.bundle, comment: "Upgrade plan button")
   
    /// Plan details renew automatically expired
    public lazy var _pu_plan_details_renew_auto_expired = NSLocalizedString("Your plan will automatically renew on %@", bundle: Common.bundle, comment: "Plan details renew automatically expired")
    
    /// Plan details renew expired
    public lazy var _pu_plan_details_renew_expired = NSLocalizedString("Current plan will expire on %@", bundle: Common.bundle, comment: "Plan details renew expired")

    /// Plan details unavailable contact administrator
    public lazy var _pu_plan_details_plan_details_unavailable_contact_administrator = NSLocalizedString("Contact an administrator to make changes to your Proton subscription.", bundle: Common.bundle, comment: "Plan details unavailable contact administrator")
    
    /// Plan details storage
    public lazy var _pu_plan_details_storage = NSLocalizedString("%@ storage", bundle: Common.bundle, comment: "Plan details storage")

    /// Plan details storage per user
    public lazy var _pu_plan_details_storage_per_user = NSLocalizedString("%@ storage / user", bundle: Common.bundle, comment: "Plan details storage per user")

    /// Plan details medium speed
    public lazy var _pu_plan_details_vpn_free_speed = NSLocalizedString("Medium speed", bundle: Common.bundle, comment: "Plan details medium speed")
    
    /// Plan details custom email addresses
    public lazy var _pu_plan_details_custom_email = NSLocalizedString("Custom email addresses", bundle: Common.bundle, comment: "Plan details custom email addresses")
    
    /// Plan details priority customer support
    public lazy var _pu_plan_details_priority_support = NSLocalizedString("Priority customer support", bundle: Common.bundle, comment: "Plan details priority customer support")
    
    /// Plan details adblocker
    public lazy var _pu_plan_details_adblocker = NSLocalizedString("Adblocker (NetShield)", bundle: Common.bundle, comment: "Plan details adblocker")
    
    /// Plan details adblocker
    public lazy var _pu_plan_details_streaming_service = NSLocalizedString("Streaming service support", bundle: Common.bundle, comment: "Plan details streaming service support")

    /// Plan details n uneven amount of addresses & calendars
    public lazy var _pu_plan_details_n_uneven_amounts_of_addresses_and_calendars = NSLocalizedString("%@ & %@", bundle: Common.bundle, comment: "Plan details n uneven amount of addresses & calendars, like: 1 address & 2 calendars")

    /// Plan details high speed message
    public lazy var _pu_plan_details_high_speed = NSLocalizedString("High speed", bundle: Common.bundle, comment: "Plan details high speed message")

    /// Plan details highest speed message
    public lazy var _pu_plan_details_highest_speed = NSLocalizedString("Highest speed", bundle: Common.bundle, comment: "Plan details highest speed message")

    /// Plan details high speed message
    public lazy var _pu_plan_details_multi_user_support = NSLocalizedString("Multi-user support", bundle: Common.bundle, comment: "Plan details multi-user support message")
    
    /// Plan details free description
    public lazy var _pu_plan_details_free_description = NSLocalizedString("The basic for private and secure communications.", bundle: Common.bundle, comment: "Plan details free description")
    
    /// Plan details plus description
    public lazy var _pu_plan_details_plus_description = NSLocalizedString("Full-featured mailbox with advanced protection.", bundle: Common.bundle, comment: "Plan details plus description")
    
    /// Plan details plus description
    public lazy var _pu_plan_details_pro_description = NSLocalizedString("Proton Mail for professionals and businesses", bundle: Common.bundle, comment: "Plan details pro description")
    
    /// Plan details visionary description
    public lazy var _pu_plan_details_visionary_description = NSLocalizedString("Mail + VPN bundle for families and small businesses", bundle: Common.bundle, comment: "Plan details visionary description")
    
    /// Unfinished operation error dialog title
    public lazy var _pu_plan_unfinished_error_title = NSLocalizedString("Complete payment?", bundle: Common.bundle, comment: "Unfinished operation error dialog title")
    
    /// Unfinished operation error dialog description
    public lazy var _pu_plan_unfinished_error_desc = NSLocalizedString("A purchase for a Proton Bundle plan has already been initiated. Press continue to complete the payment processing and create your account", bundle: Common.bundle, comment: "Unfinished operation error dialog description")
    
    /// Unfinished operation error dialog retry button
    public lazy var _pu_plan_unfinished_error_retry_button = NSLocalizedString("Complete payment", bundle: Common.bundle, comment: "Unfinished operation error dialog retry button")
    
    /// Unfinished operation dialog description
    public lazy var _pu_plan_unfinished_desc = NSLocalizedString("The account setup process could not be finalized due to an unexpected error.\nPlease try again.", bundle: Common.bundle, comment: "Unfinished operation dialog description")
    
    // IAP in progress banner message
    public lazy var _pu_iap_in_progress_banner = NSLocalizedString("The IAP purchase process has started. Please follow Apple's instructions to either complete or cancel the purchase.", bundle: Common.bundle, comment: "IAP in progress banner message")

// Splash

    /// Part of "Made by Proton" text at the bottom of the splash screen
    public lazy var _splash_made_by = NSLocalizedString("Made by", bundle: Common.bundle, comment: "Made by")

// Networking

    /// Networking connection error
    public lazy var _net_connection_error = NSLocalizedString("Network connection error", bundle: Common.bundle, comment: "Networking connection error")
    
    /// Networking connection error
    public lazy var _net_insecure_connection_error = NSLocalizedString("The TLS certificate validation failed when trying to connect to the Proton API. Your current Internet connection may be monitored. To keep your data secure, we are preventing the app from accessing the Proton API.\nTo log in or access your account, switch to a new network and try to connect again.", bundle: Common.bundle, comment: "Networking insecure connection error")
}
