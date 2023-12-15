//
//  LoginAndSignup+DataTypes.swift
//  ProtonCore-Login - Created on 27/05/2021.
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

import Foundation
import ProtonCoreUtilities

private class Handler {}

public enum LUITranslation: TranslationsExposing {

    public static var bundle: Bundle {
        #if SPM
        return Bundle.module
        #else
        return Bundle(path: Bundle(for: Handler.self).path(forResource: "Translations-LoginUI", ofType: "bundle")!)!
        #endif
    }

    public static var prefixForMissingValue: String = ""

    case _ls_welcome_footer
    case _core_external_accounts_address_required_popup_title
    case _core_external_accounts_update_required_popup_title
    case _core_validation_invalid_password
    case _core_ok_button
    case _core_help_button
    case _core_create_address_button_title
    case _core_password_field_title
    case _core_api_might_be_blocked_message
    case sms_search_placeholder
    case verification_sent_banner
    case verification_new_alert_title
    case verification_error_alert_resend
    case verification_new_alert_message
    case verification_new_alert_button
    case screen_subtitle
    case username_title
    case password_title
    case sign_in_button
    case sign_in_button_with_password
    case sign_in_with_sso_button
    case sign_in_with_sso_title
    case create_account_button
    case help_screen_title
    case help_forgot_username
    case help_forgot_password
    case help_other_issues
    case help_customer_support
    case help_more_help
    case validation_invalid_username
    case error_missing_keys_text_button
    case error_missing_keys_text
    case error_missing_keys_title
    case error_invalid_mailbox_password
    case info_session_expired
    case create_address_screen_title
    case create_address_screen_info
    case create_address_username_title
    case username_username_error
    case login_mailbox_screen_title
    case login_mailbox_field_title
    case login_mailbox_button_title
    case login_mailbox_forgot_password
    case login_2fa_screen_title
    case login_2fa_action_button_title
    case login_2fa_field_title
    case login_2fa_recovery_field_title
    case login_2fa_recovery_button_title
    case login_2fa_2fa_button_title
    case login_2fa_field_info
    case login_2fa_recovery_field_info
    case external_accounts_not_supported_popup_action_button
    case username_org_dialog_title
    case username_org_dialog_action_button
    case username_org_dialog_message
    case error_occured
    case main_view_title
    case main_view_desc
    case next_button
    case signin_button
    case email_address_button
    case proton_address_button
    case username_field_title
    case email_field_title
    case password_view_title
    case password_field_minimum_length_hint
    case repeat_password_field_title
    case domains_sheet_title
    case recovery_view_title
    case recovery_view_title_optional
    case recovery_view_desc
    case recovery_seg_email
    case recovery_seg_phone
    case recovery_email_field_title
    case recovery_phone_field_title
    case recovery_t_c_desc
    case recovery_t_c_link
    case skip_button
    case recovery_skip_title
    case recovery_skip_desc
    case recovery_method_button
    case complete_view_title
    case complete_view_desc
    case complete_step_creation
    case complete_step_address_generation
    case complete_step_keys_generation
    case complete_step_payment_verification
    case email_verification_view_title
    case email_verification_view_desc
    case email_verification_code_name
    case email_verification_code_desc
    case did_not_receive_code_button
    case terms_conditions_view_title
    case error_invalid_token_request
    case error_invalid_token
    case error_create_user_failed
    case error_invalid_hashed_password
    case error_password_empty
    case error_password_not_equal
    case error_email_already_used
    case error_missing_sub_user_configuration
    case invalid_verification_alert_message
    case invalid_verification_change_email_button
    case summary_title
    case summary_free_description
    case summary_free_description_replacement
    case summary_paid_description
    case summary_no_plan_description
    case summary_welcome
    case _core_cancel_button
    case _core_sign_in_screen_title
    case _core_api_might_be_blocked_button

    public var l10n: String {
        switch self {
        case ._ls_welcome_footer:
            return localized(key: "Privacy by default", comment: "Welcome screen footer label")
        case ._core_external_accounts_address_required_popup_title:
            return localized(key: "Proton address required", comment: "External accounts address required popup title")
        case ._core_external_accounts_update_required_popup_title:
            return localized(key: "Update required", comment: "External accounts update required popup title")
        case ._core_validation_invalid_password:
            return localized(key: "Please enter your Proton Account password.", comment: "Invalid password hint")
        case ._core_ok_button:
            return localized(key: "OK", comment: "OK button")
        case ._core_help_button:
            return localized(key: "Help", comment: "Help button")
        case ._core_create_address_button_title:
            return localized(key: "Continue", comment: "Action button title for picking Proton Mail username")
        case ._core_password_field_title:
            return localized(key: "Password", comment: "Password field title")
        case ._core_api_might_be_blocked_message:
            return localized(key: "The Proton servers are unreachable. It might be caused by wrong network configuration, Proton servers not working or Proton servers being blocked", comment: "Message shown when we suspect that the Proton servers are blocked")
        case .sms_search_placeholder:
            return localized(key: "Search country", comment: "Search country placeholder")
        case .verification_sent_banner:
            return localized(key: "Code sent to %@", comment: "sent baner title")
        case .verification_new_alert_title:
            return localized(key: "Request new code?", comment: "alert title")
        case .verification_error_alert_resend:
            return localized(key: "Resend", comment: "resend alert button")
        case .verification_new_alert_message:
            return localized(key: "Get a replacement code sent to %@.", comment: "alert message")
        case .verification_new_alert_button:
            return localized(key: "Request new code", comment: "new code alert button")
        case .screen_subtitle:
            return localized(key: "Enter your Proton Account details.", comment: "Login screen subtitle")
        case .username_title:
            return localized(key: "Email or username", comment: "Username field title")
        case .password_title:
            return localized(key: "Password", comment: "Password field title")
        case .sign_in_button:
            return localized(key: "Sign in", comment: "Sign in button")
        case .sign_in_button_with_password:
            return localized(key: "Sign in with password", comment: "Sign in button when in SSO mode")
        case .sign_in_with_sso_button:
            return localized(key: "Sign in with SSO", comment: "Sign in with SSO button")
        case .sign_in_with_sso_title:
            return localized(key: "Sign in to your organization", comment: "Sign in with SSO screen title")
        case .create_account_button:
            return localized(key: "Create an account", comment: "Create account button")
        case .help_screen_title:
            return localized(key: "How can we help?", comment: "Login help screen title")
        case .help_forgot_username:
            return localized(key: "Forgot username", comment: "Forgot username help button")
        case .help_forgot_password:
            return localized(key: "Forgot password", comment: "Forgot password help button")
        case .help_other_issues:
            return localized(key: "Other sign-in issues", comment: "Other sign-in issues button")
        case .help_customer_support:
            return localized(key: "Customer support", comment: "Customer support button")
        case .help_more_help:
            return localized(key: "Still need help? Contact us directly.", comment: "Customer support button")
        case .validation_invalid_username:
            return localized(key: "Please enter your Proton Account email or username.", comment: "Invalid username hint")
        case .error_missing_keys_text_button:
            return localized(key: "Complete Setup", comment: "Dialog button for missing keys error")
        case .error_missing_keys_text:
            return localized(key: "Your account is missing keys, please sign in on web to automatically generate required keys. Once you have signed in on web, please return to the app and sign in.", comment: "Dialog text for missing keys error")
        case .error_missing_keys_title:
            return localized(key: "Account setup required", comment: "Dialog title for missing keys error")
        case .error_invalid_mailbox_password:
            return localized(key: "Incorrect mailbox password", comment: "Incorrect mailbox password error")
        case .info_session_expired:
            return localized(key: "Your session has expired. Please log in again.", comment: "Session expired info")
        case .create_address_screen_title:
            return localized(key: "Proton address required", comment: "Screen title for creating Proton Mail address")
        case .create_address_screen_info:
            return localized(key: "You need a Proton email address to use Proton Mail and Proton Calendar.\nYou’ll still be able to use %@ to sign in, and to recover your account.", comment: "Info about existing external Proton Mail address")
        case .create_address_username_title:
            return localized(key: "Username", comment: "Username field title")
        case .username_username_error:
            return localized(key: "Please enter a username.", comment: "Username field error message")
        case .login_mailbox_screen_title:
            return localized(key: "Unlock your mailbox", comment: "Mailbox unlock screen title")
        case .login_mailbox_field_title:
            return localized(key: "Mailbox password", comment: "Mailbox password field title")
        case .login_mailbox_button_title:
            return localized(key: "Unlock", comment: "Mailbox unlock screen action button title")
        case .login_mailbox_forgot_password:
            return localized(key: "Forgot password", comment: "Forgot password button title")
        case .login_2fa_screen_title:
            return localized(key: "Two-factor authentication", comment: "2FA screen title")
        case .login_2fa_action_button_title:
            return localized(key: "Authenticate", comment: "2FA screen action button title")
        case .login_2fa_field_title:
            return localized(key: "Two-factor code", comment: "2FA screen field title")
        case .login_2fa_recovery_field_title:
            return localized(key: "Recovery code", comment: "2FA screen recovery field title")
        case .login_2fa_recovery_button_title:
            return localized(key: "Use recovery code", comment: "2FA screen recovery button title")
        case .login_2fa_2fa_button_title:
            return localized(key: "Use two-factor code", comment: "2FA screen 2FA button title")
        case .login_2fa_field_info:
            return localized(key: "Enter the 6-digit code.", comment: "2FA screen field info")
        case .login_2fa_recovery_field_info:
            return localized(key: "Enter an 8-character recovery code.", comment: "2FA screen recovery field info")
        case .external_accounts_not_supported_popup_action_button:
            return localized(key: "Learn more", comment: "External accounts not supported popup learn more button")
        case .username_org_dialog_title:
            return localized(key: "Change your password", comment: "Dialog title for organization user first login")
        case .username_org_dialog_action_button:
            return localized(key: "Change password", comment: "Dialog action button title for organization user first login")
        case .username_org_dialog_message:
            return localized(key: "To use the Proton app as a member of an organization, you first need to change your password by signing into Proton through a browser.", comment: "Dialog message for organization user first login")
        case .error_occured:
            return localized(key: "Error occured", comment: "Error alert title")
        case .main_view_title:
            return localized(key: "Create your Proton Account", comment: "Signup main view title")
        case .main_view_desc:
            return localized(key: "One account for all Proton services.", comment: "Signup main view description")
        case .next_button:
            return localized(key: "Next", comment: "Next button")
        case .signin_button:
            return localized(key: "Sign in", comment: "Sign in button")
        case .email_address_button:
            return localized(key: "Use your current email instead", comment: "Email address button")
        case .proton_address_button:
            return localized(key: "Create a secure Proton Mail address instead", comment: "Proton Mail address button")
        case .username_field_title:
            return localized(key: "Username", comment: "Username field title")
        case .email_field_title:
            return localized(key: "Email", comment: "Email field title")
        case .password_view_title:
            return localized(key: "Create your password", comment: "Signup password view title")
        case .password_field_minimum_length_hint:
            return localized(key: "Password must contain at least 8 characters", comment: "Password field hint about minimum length")
        case .repeat_password_field_title:
            return localized(key: "Repeat password", comment: "Repeat password field title")
        case .domains_sheet_title:
            return localized(key: "Domain", comment: "Title of domains bottom action sheet")
        case .recovery_view_title:
            return localized(key: "Set recovery method", value: LUITranslation.recovery_method_button.l10n, comment: "Recovery view title")
        case .recovery_view_title_optional:
            return localized(key: "Set recovery method (optional)", comment: "Recovery view title optional")
        case .recovery_view_desc:
            return localized(key: "We will send recovery instructions to this email or phone number if you get locked out of your account.", comment: "Recovery view description")
        case .recovery_seg_email:
            return localized(key: "Email", comment: "Recovery segmenet email")
        case .recovery_seg_phone:
            return localized(key: "Phone", comment: "Recovery segmenet phone")
        case .recovery_email_field_title:
            return localized(key: "Recovery email", comment: "Recovery email field title")
        case .recovery_phone_field_title:
            return localized(key: "Recovery phone number", comment: "Recovery phone field title")
        case .recovery_t_c_desc:
            return localized(key: "By clicking Next, you agree with Proton's Terms and Conditions", comment: "Recovery terms and conditions description")
        case .recovery_t_c_link:
            return localized(key: "Terms and Conditions", comment: "Recovery terms and conditions link")
        case .skip_button:
            return localized(key: "Skip", comment: "Skip button")
        case .recovery_skip_title:
            return localized(key: "Skip recovery method?", comment: "Recovery skip title")
        case .recovery_skip_desc:
            return localized(key: "A recovery method will help you access your account in case you forget your password or get locked out of your account.", comment: "Recovery skip description")
        case .recovery_method_button:
            return localized(key: "Set recovery method", comment: "Set recovery method button")
        case .complete_view_title:
            return localized(key: "Your account is being created", comment: "Complete view title")
        case .complete_view_desc:
            return localized(key: "This should take no more than a minute.", comment: "Complete view description")
        case .complete_step_creation:
            return localized(key: "Creating your account", comment: "Signup complete progress step creation")
        case .complete_step_address_generation:
            return localized(key: "Generating your address", comment: "Signup complete progress step address generation")
        case .complete_step_keys_generation:
            return localized(key: "Securing your account", comment: "Signup complete progress step keys generation")
        case .complete_step_payment_verification:
            return localized(key: "Verifying your payment", comment: "Signup complete progress step payment verification")
        case .email_verification_view_title:
            return localized(key: "Account verification", comment: "Email verification view title")
        case .email_verification_view_desc:
            return localized(key: "For your security, we must verify that the address you entered belongs to you. We sent a verification code to %@. Please enter the code below:", comment: "Email verification view description")
        case .email_verification_code_name:
            return localized(key: "Verification code", comment: "Email verification code name")
        case .email_verification_code_desc:
            return localized(key: "Enter the 6-digit code.", comment: "Email verification code description")
        case .did_not_receive_code_button:
            return localized(key: "Did not receive a code?", comment: "Did not receive code button")
        case .terms_conditions_view_title:
            return localized(key: "Terms and Conditions", comment: "Terms and conditions view title")
        case .error_invalid_token_request:
            return localized(key: "Invalid token request", comment: "Invalid token request error")
        case .error_invalid_token:
            return localized(key: "Invalid token error", comment: "Invalid token error")
        case .error_create_user_failed:
            return localized(key: "Create user failed", comment: "Create user failed error")
        case .error_invalid_hashed_password:
            return localized(key: "Invalid hashed password", comment: "Invalid hashed password error")
        case .error_password_empty:
            return localized(key: "Password can not be empty.\nPlease try again.", comment: "Password empty error")
        case .error_password_not_equal:
            return localized(key: "Passwords do not match.\nPlease try again.", comment: "Password not equal error")
        case .error_email_already_used:
            return localized(key: "Email address already used.", comment: "Email address already used error")
        case .error_missing_sub_user_configuration:
            return localized(key: "Please ask your admin to configure your sub-user.", comment: "Sub-user configuration error")
        case .invalid_verification_alert_message:
            return localized(key: "Would you like to receive a new verification code or use an alternate email address?", comment: "Invalid verification alert message")
        case .invalid_verification_change_email_button:
            return localized(key: "Change email address", comment: "Change email address button")
        case .summary_title:
            return localized(key: "Congratulations", comment: "Signup summary title")
        case .summary_free_description:
            return localized(key: "Your Proton Free account was successfully created.", comment: "Signup summary free plan description")
        case .summary_free_description_replacement:
            return localized(key: "Proton Free", comment: "Signup summary free plan description replacement")
        case .summary_paid_description:
            return localized(key: "Your payment was confirmed and your %@ account successfully created.", comment: "Signup summary paid plan description")
        case .summary_no_plan_description:
            return localized(key: "Your Proton account was successfully created.", comment: "Signup summary no plan description")
        case .summary_welcome:
            return localized(key: "Enjoy the world of privacy.", comment: "Signup summary welcome text")
        case ._core_cancel_button:
            return localized(key: "Cancel", comment: "Cancel button")
        case ._core_sign_in_screen_title:
            return localized(key: "Sign in", comment: "Login screen title")
        case ._core_api_might_be_blocked_button:
            return localized(key: "Troubleshoot", comment: "Button for the error banner shown when we suspect that the Proton servers are blocked")
        }
    }
}
