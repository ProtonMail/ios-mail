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

// swiftlint:disable line_length identifier_name cyclomatic_complexity function_body_length

import Foundation

@dynamicMemberLookup
public struct CoreString {
    
    private static var localizedStringInstance = LocalizedString()
    
    public static func reset() {
        localizedStringInstance = LocalizedString()
    }
    
    public static subscript(dynamicMember keyPath: KeyPath<LocalizedStringAccessors, LocalizedStringAccessors>) -> String {
        // it doesn't matter which instance/case we'll use to access keyPath, __general_ok_action is just a random choice
        // and the only reason we need to use the instance at all is that dynamic member lookup doesn't support static members (including enum cases)
        LocalizedStringAccessors.__general_ok_action[keyPath: keyPath].localizedString(from: localizedStringInstance)
    }
}

public enum LocalizedStringAccessors: CaseIterable {
    
    case __hv_title
    public var _hv_title: LocalizedStringAccessors { .__hv_title }

    case __hv_captha_method_name
    public var _hv_captha_method_name: LocalizedStringAccessors { .__hv_captha_method_name }

    case __hv_sms_method_name
    public var _hv_sms_method_name: LocalizedStringAccessors { .__hv_sms_method_name }

    case __hv_email_method_name
    public var _hv_email_method_name: LocalizedStringAccessors { .__hv_email_method_name }

    case __hv_help_button
    public var _hv_help_button: LocalizedStringAccessors { .__hv_help_button }

    case __hv_ok_button
    public var _hv_ok_button: LocalizedStringAccessors { .__hv_ok_button }

    case __hv_cancel_button
    public var _hv_cancel_button: LocalizedStringAccessors { .__hv_cancel_button }

    case __hv_email_enter_label
    public var _hv_email_enter_label: LocalizedStringAccessors { .__hv_email_enter_label }

    case __hv_email_label
    public var _hv_email_label: LocalizedStringAccessors { .__hv_email_label }

    case __hv_email_verification_button
    public var _hv_email_verification_button: LocalizedStringAccessors { .__hv_email_verification_button }

    case __hv_sms_enter_label
    public var _hv_sms_enter_label: LocalizedStringAccessors { .__hv_sms_enter_label }

    case __hv_sms_label
    public var _hv_sms_label: LocalizedStringAccessors { .__hv_sms_label }

    case __hv_sms_search_placeholder
    public var _hv_sms_search_placeholder: LocalizedStringAccessors { .__hv_sms_search_placeholder }

    case __hv_verification_enter_sms_code
    public var _hv_verification_enter_sms_code: LocalizedStringAccessors { .__hv_verification_enter_sms_code }

    case __hv_verification_enter_email_code
    public var _hv_verification_enter_email_code: LocalizedStringAccessors { .__hv_verification_enter_email_code }

    case __hv_verification_code
    public var _hv_verification_code: LocalizedStringAccessors { .__hv_verification_code }

    case __hv_verification_code_hint
    public var _hv_verification_code_hint: LocalizedStringAccessors { .__hv_verification_code_hint }

    case __hv_verification_verify_button
    public var _hv_verification_verify_button: LocalizedStringAccessors { .__hv_verification_verify_button }

    case __hv_verification_verifying_button
    public var _hv_verification_verifying_button: LocalizedStringAccessors { .__hv_verification_verifying_button }

    case __hv_verification_not_receive_code_button
    public var _hv_verification_not_receive_code_button: LocalizedStringAccessors { .__hv_verification_not_receive_code_button }

    case __hv_verification_error_alert_title
    public var _hv_verification_error_alert_title: LocalizedStringAccessors { .__hv_verification_error_alert_title }

    case __hv_verification_error_alert_message
    public var _hv_verification_error_alert_message: LocalizedStringAccessors { .__hv_verification_error_alert_message }

    case __hv_verification_error_alert_resend
    public var _hv_verification_error_alert_resend: LocalizedStringAccessors { .__hv_verification_error_alert_resend }

    case __hv_verification_error_alert_other_method
    public var _hv_verification_error_alert_other_method: LocalizedStringAccessors { .__hv_verification_error_alert_other_method }

    case __hv_verification_new_alert_title
    public var _hv_verification_new_alert_title: LocalizedStringAccessors { .__hv_verification_new_alert_title }

    case __hv_verification_new_alert_message
    public var _hv_verification_new_alert_message: LocalizedStringAccessors { .__hv_verification_new_alert_message }

    case __hv_verification_new_alert_button
    public var _hv_verification_new_alert_button: LocalizedStringAccessors { .__hv_verification_new_alert_button }

    case __hv_verification_sent_banner
    public var _hv_verification_sent_banner: LocalizedStringAccessors { .__hv_verification_sent_banner }

    case __hv_help_header
    public var _hv_help_header: LocalizedStringAccessors { .__hv_help_header }

    case __hv_help_request_item_title
    public var _hv_help_request_item_title: LocalizedStringAccessors { .__hv_help_request_item_title }

    case __hv_help_request_item_message
    public var _hv_help_request_item_message: LocalizedStringAccessors { .__hv_help_request_item_message }

    case __hv_help_visit_item_title
    public var _hv_help_visit_item_title: LocalizedStringAccessors { .__hv_help_visit_item_title }

    case __hv_help_visit_item_message
    public var _hv_help_visit_item_message: LocalizedStringAccessors { .__hv_help_visit_item_message }

    case __fu_alert_title
    public var _fu_alert_title: LocalizedStringAccessors { .__fu_alert_title }

    case __fu_alert_learn_more_button
    public var _fu_alert_learn_more_button: LocalizedStringAccessors { .__fu_alert_learn_more_button }

    case __fu_alert_update_button
    public var _fu_alert_update_button: LocalizedStringAccessors { .__fu_alert_update_button }

    case __fu_alert_quit_button
    public var _fu_alert_quit_button: LocalizedStringAccessors { .__fu_alert_quit_button }

    case __ls_screen_title
    public var _ls_screen_title: LocalizedStringAccessors { .__ls_screen_title }

    case __ls_screen_subtitle
    public var _ls_screen_subtitle: LocalizedStringAccessors { .__ls_screen_subtitle }

    case __ls_username_title
    public var _ls_username_title: LocalizedStringAccessors { .__ls_username_title }

    case __ls_password_title
    public var _ls_password_title: LocalizedStringAccessors { .__ls_password_title }

    case __ls_help_button
    public var _ls_help_button: LocalizedStringAccessors { .__ls_help_button }

    case __ls_sign_in_button
    public var _ls_sign_in_button: LocalizedStringAccessors { .__ls_sign_in_button }

    case __ls_create_account_button
    public var _ls_create_account_button: LocalizedStringAccessors { .__ls_create_account_button }

    case __ls_welcome_footer
    public var _ls_welcome_footer: LocalizedStringAccessors { .__ls_welcome_footer }

    case __ls_help_screen_title
    public var _ls_help_screen_title: LocalizedStringAccessors { .__ls_help_screen_title }

    case __ls_help_forgot_username
    public var _ls_help_forgot_username: LocalizedStringAccessors { .__ls_help_forgot_username }

    case __ls_help_forgot_password
    public var _ls_help_forgot_password: LocalizedStringAccessors { .__ls_help_forgot_password }

    case __ls_help_other_issues
    public var _ls_help_other_issues: LocalizedStringAccessors { .__ls_help_other_issues }

    case __ls_help_customer_support
    public var _ls_help_customer_support: LocalizedStringAccessors { .__ls_help_customer_support }

    case __ls_help_more_help
    public var _ls_help_more_help: LocalizedStringAccessors { .__ls_help_more_help }

    case __ls_validation_invalid_username
    public var _ls_validation_invalid_username: LocalizedStringAccessors { .__ls_validation_invalid_username }

    case __ls_validation_invalid_password
    public var _ls_validation_invalid_password: LocalizedStringAccessors { .__ls_validation_invalid_password }

    case __ls_error_missing_keys_text_button
    public var _ls_error_missing_keys_text_button: LocalizedStringAccessors { .__ls_error_missing_keys_text_button }

    case __ls_error_missing_keys_text
    public var _ls_error_missing_keys_text: LocalizedStringAccessors { .__ls_error_missing_keys_text }

    case __ls_error_missing_keys_title
    public var _ls_error_missing_keys_title: LocalizedStringAccessors { .__ls_error_missing_keys_title }

    case __ls_error_invalid_mailbox_password
    public var _ls_error_invalid_mailbox_password: LocalizedStringAccessors { .__ls_error_invalid_mailbox_password }

    case __ls_external_eccounts_not_supported_popup_title
    public var _ls_external_eccounts_not_supported_popup_title: LocalizedStringAccessors { .__ls_external_eccounts_not_supported_popup_title }

    case __ls_external_eccounts_not_supported_popup_local_desc
    public var _ls_external_eccounts_not_supported_popup_local_desc: LocalizedStringAccessors { .__ls_external_eccounts_not_supported_popup_local_desc }

    case __ls_external_eccounts_not_supported_popup_action_button
    public var _ls_external_eccounts_not_supported_popup_action_button: LocalizedStringAccessors { .__ls_external_eccounts_not_supported_popup_action_button }

    case __ls_info_session_expired
    public var _ls_info_session_expired: LocalizedStringAccessors { .__ls_info_session_expired }

    case __ls_error_generic
    public var _ls_error_generic: LocalizedStringAccessors { .__ls_error_generic }

    case __ls_create_address_screen_title
    public var _ls_create_address_screen_title: LocalizedStringAccessors { .__ls_create_address_screen_title }

    case __ls_create_address_screen_info
    public var _ls_create_address_screen_info: LocalizedStringAccessors { .__ls_create_address_screen_info }

    case __ls_create_address_username_title
    public var _ls_create_address_username_title: LocalizedStringAccessors { .__ls_create_address_username_title }

    case __ls_create_address_button_title
    public var _ls_create_address_button_title: LocalizedStringAccessors { .__ls_create_address_button_title }

    case __ls_username_username_error
    public var _ls_username_username_error: LocalizedStringAccessors { .__ls_username_username_error }

    case __ls_login_mailbox_screen_title
    public var _ls_login_mailbox_screen_title: LocalizedStringAccessors { .__ls_login_mailbox_screen_title }

    case __ls_login_mailbox_field_title
    public var _ls_login_mailbox_field_title: LocalizedStringAccessors { .__ls_login_mailbox_field_title }

    case __ls_login_mailbox_button_title
    public var _ls_login_mailbox_button_title: LocalizedStringAccessors { .__ls_login_mailbox_button_title }

    case __ls_login_mailbox_forgot_password
    public var _ls_login_mailbox_forgot_password: LocalizedStringAccessors { .__ls_login_mailbox_forgot_password }

    case __ls_login_2fa_screen_title
    public var _ls_login_2fa_screen_title: LocalizedStringAccessors { .__ls_login_2fa_screen_title }

    case __ls_login_2fa_action_button_title
    public var _ls_login_2fa_action_button_title: LocalizedStringAccessors { .__ls_login_2fa_action_button_title }

    case __ls_login_2fa_field_title
    public var _ls_login_2fa_field_title: LocalizedStringAccessors { .__ls_login_2fa_field_title }

    case __ls_login_2fa_recovery_field_title
    public var _ls_login_2fa_recovery_field_title: LocalizedStringAccessors { .__ls_login_2fa_recovery_field_title }

    case __ls_login_2fa_recovery_button_title
    public var _ls_login_2fa_recovery_button_title: LocalizedStringAccessors { .__ls_login_2fa_recovery_button_title }

    case __ls_login_2fa_2fa_button_title
    public var _ls_login_2fa_2fa_button_title: LocalizedStringAccessors { .__ls_login_2fa_2fa_button_title }

    case __ls_login_2fa_field_info
    public var _ls_login_2fa_field_info: LocalizedStringAccessors { .__ls_login_2fa_field_info }

    case __ls_login_2fa_recovery_field_info
    public var _ls_login_2fa_recovery_field_info: LocalizedStringAccessors { .__ls_login_2fa_recovery_field_info }

    case __error_occured
    public var _error_occured: LocalizedStringAccessors { .__error_occured }

    case __general_ok_action
    public var _general_ok_action: LocalizedStringAccessors { .__general_ok_action }

    case __warning
    public var _warning: LocalizedStringAccessors { .__warning }

    case __do_you_want_to_bypass_validation
    public var _do_you_want_to_bypass_validation: LocalizedStringAccessors { .__do_you_want_to_bypass_validation }

    case __yes_bypass_validation
    public var _yes_bypass_validation: LocalizedStringAccessors { .__yes_bypass_validation }

    case __no_dont_bypass_validation
    public var _no_dont_bypass_validation: LocalizedStringAccessors { .__no_dont_bypass_validation }

    case __popup_credits_applied_message
    public var _popup_credits_applied_message: LocalizedStringAccessors { .__popup_credits_applied_message }

    case __popup_credits_applied_confirmation
    public var _popup_credits_applied_confirmation: LocalizedStringAccessors { .__popup_credits_applied_confirmation }

    case __popup_credits_applied_cancellation
    public var _popup_credits_applied_cancellation: LocalizedStringAccessors { .__popup_credits_applied_cancellation }

    case __error_apply_payment_on_registration_title
    public var _error_apply_payment_on_registration_title: LocalizedStringAccessors { .__error_apply_payment_on_registration_title }

    case __error_apply_payment_on_registration_message
    public var _error_apply_payment_on_registration_message: LocalizedStringAccessors { .__error_apply_payment_on_registration_message }

    case __retry
    public var _retry: LocalizedStringAccessors { .__retry }

    case __error_apply_payment_on_registration_support
    public var _error_apply_payment_on_registration_support: LocalizedStringAccessors { .__error_apply_payment_on_registration_support }

    case __error_unavailable_product
    public var _error_unavailable_product: LocalizedStringAccessors { .__error_unavailable_product }

    case __error_invalid_purchase
    public var _error_invalid_purchase: LocalizedStringAccessors { .__error_invalid_purchase }

    case __error_reciept_lost
    public var _error_reciept_lost: LocalizedStringAccessors { .__error_reciept_lost }

    case __error_another_user_transaction
    public var _error_another_user_transaction: LocalizedStringAccessors { .__error_another_user_transaction }

    case __error_backend_mismatch
    public var _error_backend_mismatch: LocalizedStringAccessors { .__error_backend_mismatch }

    case __error_sandbox_receipt
    public var _error_sandbox_receipt: LocalizedStringAccessors { .__error_sandbox_receipt }

    case __error_no_hashed_username_arrived_in_transaction
    public var _error_no_hashed_username_arrived_in_transaction: LocalizedStringAccessors { .__error_no_hashed_username_arrived_in_transaction }

    case __error_no_active_username_in_user_data_service
    public var _error_no_active_username_in_user_data_service: LocalizedStringAccessors { .__error_no_active_username_in_user_data_service }

    case __error_transaction_failed_by_unknown_reason
    public var _error_transaction_failed_by_unknown_reason: LocalizedStringAccessors { .__error_transaction_failed_by_unknown_reason }

    case __error_no_new_subscription_in_response
    public var _error_no_new_subscription_in_response: LocalizedStringAccessors { .__error_no_new_subscription_in_response }

    case __error_unlock_to_proceed_with_iap
    public var _error_unlock_to_proceed_with_iap: LocalizedStringAccessors { .__error_unlock_to_proceed_with_iap }

    case __error_please_sign_in_iap
    public var _error_please_sign_in_iap: LocalizedStringAccessors { .__error_please_sign_in_iap }

    case __error_credits_applied
    public var _error_credits_applied: LocalizedStringAccessors { .__error_credits_applied }

    case __error_wrong_token_status
    public var _error_wrong_token_status: LocalizedStringAccessors { .__error_wrong_token_status }

    case __login_username_org_dialog_title
    public var _login_username_org_dialog_title: LocalizedStringAccessors { .__login_username_org_dialog_title }

    case __login_username_org_dialog_action_button
    public var _login_username_org_dialog_action_button: LocalizedStringAccessors { .__login_username_org_dialog_action_button }

    case __login_username_org_dialog_message
    public var _login_username_org_dialog_message: LocalizedStringAccessors { .__login_username_org_dialog_message }

    case __ad_delete_account_title
    public var _ad_delete_account_title: LocalizedStringAccessors { .__ad_delete_account_title }

    case __ad_delete_account_button
    public var _ad_delete_account_button: LocalizedStringAccessors { .__ad_delete_account_button }

    case __ad_delete_account_message
    public var _ad_delete_account_message: LocalizedStringAccessors { .__ad_delete_account_message }

    case __ad_delete_account_success
    public var _ad_delete_account_success: LocalizedStringAccessors { .__ad_delete_account_success }

    case __ad_delete_network_error
    public var _ad_delete_network_error: LocalizedStringAccessors { .__ad_delete_network_error }

    case __ad_delete_close_button
    public var _ad_delete_close_button: LocalizedStringAccessors { .__ad_delete_close_button }

    case __as_switch_to_title
    public var _as_switch_to_title: LocalizedStringAccessors { .__as_switch_to_title }

    case __as_accounts
    public var _as_accounts: LocalizedStringAccessors { .__as_accounts }

    case __as_manage_accounts
    public var _as_manage_accounts: LocalizedStringAccessors { .__as_manage_accounts }

    case __as_signed_in_to_protonmail
    public var _as_signed_in_to_protonmail: LocalizedStringAccessors { .__as_signed_in_to_protonmail }

    case __as_signed_out_of_protonmail
    public var _as_signed_out_of_protonmail: LocalizedStringAccessors { .__as_signed_out_of_protonmail }

    case __as_signout
    public var _as_signout: LocalizedStringAccessors { .__as_signout }

    case __as_remove_button
    public var _as_remove_button: LocalizedStringAccessors { .__as_remove_button }

    case __as_remove_account_from_this_device
    public var _as_remove_account_from_this_device: LocalizedStringAccessors { .__as_remove_account_from_this_device }

    case __as_remove_account
    public var _as_remove_account: LocalizedStringAccessors { .__as_remove_account }

    case __as_remove_account_alert_text
    public var _as_remove_account_alert_text: LocalizedStringAccessors { .__as_remove_account_alert_text }

    case __as_signout_alert_text
    public var _as_signout_alert_text: LocalizedStringAccessors { .__as_signout_alert_text }

    case __as_dismiss_button
    public var _as_dismiss_button: LocalizedStringAccessors { .__as_dismiss_button }

    case __as_sign_in_button
    public var _as_sign_in_button: LocalizedStringAccessors { .__as_sign_in_button }

    case __su_main_view_title
    public var _su_main_view_title: LocalizedStringAccessors { .__su_main_view_title }

    case __su_main_view_desc
    public var _su_main_view_desc: LocalizedStringAccessors { .__su_main_view_desc }

    case __su_next_button
    public var _su_next_button: LocalizedStringAccessors { .__su_next_button }

    case __su_signin_button
    public var _su_signin_button: LocalizedStringAccessors { .__su_signin_button }

    case __su_email_address_button
    public var _su_email_address_button: LocalizedStringAccessors { .__su_email_address_button }

    case __su_proton_address_button
    public var _su_proton_address_button: LocalizedStringAccessors { .__su_proton_address_button }

    case __su_username_field_title
    public var _su_username_field_title: LocalizedStringAccessors { .__su_username_field_title }

    case __su_email_field_title
    public var _su_email_field_title: LocalizedStringAccessors { .__su_email_field_title }

    case __su_password_proton_view_title
    public var _su_password_proton_view_title: LocalizedStringAccessors { .__su_password_proton_view_title }

    case __su_password_email_view_title
    public var _su_password_email_view_title: LocalizedStringAccessors { .__su_password_email_view_title }

    case __su_password_field_title
    public var _su_password_field_title: LocalizedStringAccessors { .__su_password_field_title }

    case __su_password_field_hint
    public var _su_password_field_hint: LocalizedStringAccessors { .__su_password_field_hint }

    case __su_repeat_password_field_title
    public var _su_repeat_password_field_title: LocalizedStringAccessors { .__su_repeat_password_field_title }

    case __su_domains_sheet_title
    public var _su_domains_sheet_title: LocalizedStringAccessors { .__su_domains_sheet_title }

    case __su_recovery_view_title
    public var _su_recovery_view_title: LocalizedStringAccessors { .__su_recovery_view_title }

    case __su_recovery_view_title_optional
    public var _su_recovery_view_title_optional: LocalizedStringAccessors { .__su_recovery_view_title_optional }

    case __su_recovery_view_desc_old
    public var _su_recovery_view_desc_old: LocalizedStringAccessors { .__su_recovery_view_desc_old }

    case __su_recovery_view_desc
    public var _su_recovery_view_desc: LocalizedStringAccessors { .__su_recovery_view_desc }

    case __su_recovery_email_only_view_desc
    public var _su_recovery_email_only_view_desc: LocalizedStringAccessors { .__su_recovery_email_only_view_desc }

    case __su_recovery_seg_email
    public var _su_recovery_seg_email: LocalizedStringAccessors { .__su_recovery_seg_email }

    case __su_recovery_seg_phone
    public var _su_recovery_seg_phone: LocalizedStringAccessors { .__su_recovery_seg_phone }

    case __su_recovery_email_field_title
    public var _su_recovery_email_field_title: LocalizedStringAccessors { .__su_recovery_email_field_title }

    case __su_recovery_phone_field_title
    public var _su_recovery_phone_field_title: LocalizedStringAccessors { .__su_recovery_phone_field_title }

    case __su_recovery_t_c_desc
    public var _su_recovery_t_c_desc: LocalizedStringAccessors { .__su_recovery_t_c_desc }

    case __su_recovery_t_c_link
    public var _su_recovery_t_c_link: LocalizedStringAccessors { .__su_recovery_t_c_link }

    case __su_skip_button
    public var _su_skip_button: LocalizedStringAccessors { .__su_skip_button }

    case __su_recovery_skip_title
    public var _su_recovery_skip_title: LocalizedStringAccessors { .__su_recovery_skip_title }

    case __su_recovery_skip_desc
    public var _su_recovery_skip_desc: LocalizedStringAccessors { .__su_recovery_skip_desc }

    case __su_recovery_method_button
    public var _su_recovery_method_button: LocalizedStringAccessors { .__su_recovery_method_button }

    case __su_complete_view_title
    public var _su_complete_view_title: LocalizedStringAccessors { .__su_complete_view_title }

    case __su_complete_view_desc
    public var _su_complete_view_desc: LocalizedStringAccessors { .__su_complete_view_desc }

    case __su_complete_step_creation
    public var _su_complete_step_creation: LocalizedStringAccessors { .__su_complete_step_creation }

    case __su_complete_step_address_generation
    public var _su_complete_step_address_generation: LocalizedStringAccessors { .__su_complete_step_address_generation }

    case __su_complete_step_keys_generation
    public var _su_complete_step_keys_generation: LocalizedStringAccessors { .__su_complete_step_keys_generation }

    case __su_complete_step_payment_verification
    public var _su_complete_step_payment_verification: LocalizedStringAccessors { .__su_complete_step_payment_verification }

    case __su_complete_step_payment_validated
    public var _su_complete_step_payment_validated: LocalizedStringAccessors { .__su_complete_step_payment_validated }

    case __su_email_verification_view_title
    public var _su_email_verification_view_title: LocalizedStringAccessors { .__su_email_verification_view_title }

    case __su_email_verification_view_desc
    public var _su_email_verification_view_desc: LocalizedStringAccessors { .__su_email_verification_view_desc }

    case __su_email_verification_code_name
    public var _su_email_verification_code_name: LocalizedStringAccessors { .__su_email_verification_code_name }

    case __su_email_verification_code_desc
    public var _su_email_verification_code_desc: LocalizedStringAccessors { .__su_email_verification_code_desc }

    case __su_did_not_receive_code_button
    public var _su_did_not_receive_code_button: LocalizedStringAccessors { .__su_did_not_receive_code_button }

    case __su_terms_conditions_view_title
    public var _su_terms_conditions_view_title: LocalizedStringAccessors { .__su_terms_conditions_view_title }

    case __su_error_invalid_token_request
    public var _su_error_invalid_token_request: LocalizedStringAccessors { .__su_error_invalid_token_request }

    case __su_error_invalid_token
    public var _su_error_invalid_token: LocalizedStringAccessors { .__su_error_invalid_token }

    case __su_error_create_user_failed
    public var _su_error_create_user_failed: LocalizedStringAccessors { .__su_error_create_user_failed }

    case __su_error_invalid_hashed_password
    public var _su_error_invalid_hashed_password: LocalizedStringAccessors { .__su_error_invalid_hashed_password }

    case __su_error_password_empty
    public var _su_error_password_empty: LocalizedStringAccessors { .__su_error_password_empty }

    case __su_error_password_too_short
    public var _su_error_password_too_short: LocalizedStringAccessors { .__su_error_password_too_short }

    case __su_error_password_not_equal
    public var _su_error_password_not_equal: LocalizedStringAccessors { .__su_error_password_not_equal }

    case __su_error_email_already_used
    public var _su_error_email_already_used: LocalizedStringAccessors { .__su_error_email_already_used }

    case __su_error_missing_sub_user_configuration
    public var _su_error_missing_sub_user_configuration: LocalizedStringAccessors { .__su_error_missing_sub_user_configuration }

    case __su_invalid_verification_alert_message
    public var _su_invalid_verification_alert_message: LocalizedStringAccessors { .__su_invalid_verification_alert_message }

    case __su_invalid_verification_change_email_button
    public var _su_invalid_verification_change_email_button: LocalizedStringAccessors { .__su_invalid_verification_change_email_button }

    case __su_summary_title
    public var _su_summary_title: LocalizedStringAccessors { .__su_summary_title }

    case __su_summary_free_description
    public var _su_summary_free_description: LocalizedStringAccessors { .__su_summary_free_description }

    case __su_summary_free_description_replacement
    public var _su_summary_free_description_replacement: LocalizedStringAccessors { .__su_summary_free_description_replacement }

    case __su_summary_paid_description
    public var _su_summary_paid_description: LocalizedStringAccessors { .__su_summary_paid_description }

    case __su_summary_no_plan_description
    public var _su_summary_no_plan_description: LocalizedStringAccessors { .__su_summary_no_plan_description }

    case __su_summary_welcome
    public var _su_summary_welcome: LocalizedStringAccessors { .__su_summary_welcome }

    case __pu_select_plan_title
    public var _pu_select_plan_title: LocalizedStringAccessors { .__pu_select_plan_title }

    case __pu_current_plan_title
    public var _pu_current_plan_title: LocalizedStringAccessors { .__pu_current_plan_title }

    case __pu_subscription_title
    public var _pu_subscription_title: LocalizedStringAccessors { .__pu_subscription_title }

    case __pu_upgrade_plan_title
    public var _pu_upgrade_plan_title: LocalizedStringAccessors { .__pu_upgrade_plan_title }

    case __pu_plan_footer_desc
    public var _pu_plan_footer_desc: LocalizedStringAccessors { .__pu_plan_footer_desc }

    case __pu_plan_footer_desc_purchased
    public var _pu_plan_footer_desc_purchased: LocalizedStringAccessors { .__pu_plan_footer_desc_purchased }

    case __pu_select_plan_button
    public var _pu_select_plan_button: LocalizedStringAccessors { .__pu_select_plan_button }

    case __pu_upgrade_plan_button
    public var _pu_upgrade_plan_button: LocalizedStringAccessors { .__pu_upgrade_plan_button }

    case __pu_plan_details_renew_auto_expired
    public var _pu_plan_details_renew_auto_expired: LocalizedStringAccessors { .__pu_plan_details_renew_auto_expired }

    case __pu_plan_details_renew_expired
    public var _pu_plan_details_renew_expired: LocalizedStringAccessors { .__pu_plan_details_renew_expired }

    case __pu_plan_details_plan_details_unavailable_contact_administrator
    public var _pu_plan_details_plan_details_unavailable_contact_administrator: LocalizedStringAccessors { .__pu_plan_details_plan_details_unavailable_contact_administrator }

    case __pu_plan_details_storage
    public var _pu_plan_details_storage: LocalizedStringAccessors { .__pu_plan_details_storage }

    case __pu_plan_details_storage_per_user
    public var _pu_plan_details_storage_per_user: LocalizedStringAccessors { .__pu_plan_details_storage_per_user }

    case __pu_plan_details_price_time_period_no_unit
    public var _pu_plan_details_price_time_period_no_unit: LocalizedStringAccessors { .__pu_plan_details_price_time_period_no_unit }

    case __pu_plan_details_vpn_free_speed
    public var _pu_plan_details_vpn_free_speed: LocalizedStringAccessors { .__pu_plan_details_vpn_free_speed }

    case __pu_plan_details_custom_email
    public var _pu_plan_details_custom_email: LocalizedStringAccessors { .__pu_plan_details_custom_email }

    case __pu_plan_details_priority_support
    public var _pu_plan_details_priority_support: LocalizedStringAccessors { .__pu_plan_details_priority_support }

    case __pu_plan_details_adblocker
    public var _pu_plan_details_adblocker: LocalizedStringAccessors { .__pu_plan_details_adblocker }

    case __pu_plan_details_streaming_service
    public var _pu_plan_details_streaming_service: LocalizedStringAccessors { .__pu_plan_details_streaming_service }

    case __pu_plan_details_n_uneven_amounts_of_addresses_and_calendars
    public var _pu_plan_details_n_uneven_amounts_of_addresses_and_calendars: LocalizedStringAccessors { .__pu_plan_details_n_uneven_amounts_of_addresses_and_calendars }

    case __pu_plan_details_high_speed
    public var _pu_plan_details_high_speed: LocalizedStringAccessors { .__pu_plan_details_high_speed }

    case __pu_plan_details_highest_speed
    public var _pu_plan_details_highest_speed: LocalizedStringAccessors { .__pu_plan_details_highest_speed }

    case __pu_plan_details_multi_user_support
    public var _pu_plan_details_multi_user_support: LocalizedStringAccessors { .__pu_plan_details_multi_user_support }

    case __pu_plan_details_free_description
    public var _pu_plan_details_free_description: LocalizedStringAccessors { .__pu_plan_details_free_description }

    case __pu_plan_details_plus_description
    public var _pu_plan_details_plus_description: LocalizedStringAccessors { .__pu_plan_details_plus_description }

    case __pu_plan_details_pro_description
    public var _pu_plan_details_pro_description: LocalizedStringAccessors { .__pu_plan_details_pro_description }

    case __pu_plan_details_visionary_description
    public var _pu_plan_details_visionary_description: LocalizedStringAccessors { .__pu_plan_details_visionary_description }

    case __pu_plan_unfinished_error_title
    public var _pu_plan_unfinished_error_title: LocalizedStringAccessors { .__pu_plan_unfinished_error_title }

    case __pu_plan_unfinished_error_desc
    public var _pu_plan_unfinished_error_desc: LocalizedStringAccessors { .__pu_plan_unfinished_error_desc }

    case __pu_plan_unfinished_error_retry_button
    public var _pu_plan_unfinished_error_retry_button: LocalizedStringAccessors { .__pu_plan_unfinished_error_retry_button }

    case __pu_plan_unfinished_desc
    public var _pu_plan_unfinished_desc: LocalizedStringAccessors { .__pu_plan_unfinished_desc }

    case __pu_iap_in_progress_banner
    public var _pu_iap_in_progress_banner: LocalizedStringAccessors { .__pu_iap_in_progress_banner }

    case __splash_made_by
    public var _splash_made_by: LocalizedStringAccessors { .__splash_made_by }

    case __net_connection_error
    public var _net_connection_error: LocalizedStringAccessors { .__net_connection_error }

    case __net_api_might_be_blocked_message
    public var _net_api_might_be_blocked_message: LocalizedStringAccessors { .__net_api_might_be_blocked_message }

    case __net_api_might_be_blocked_button
    public var _net_api_might_be_blocked_button: LocalizedStringAccessors { .__net_api_might_be_blocked_button }

    case __net_insecure_connection_error
    public var _net_insecure_connection_error: LocalizedStringAccessors { .__net_insecure_connection_error }

    case __troubleshooting_support_from
    public var _troubleshooting_support_from: LocalizedStringAccessors { .__troubleshooting_support_from }

    case __troubleshooting_email_title
    public var _troubleshooting_email_title: LocalizedStringAccessors { .__troubleshooting_email_title }

    case __troubleshooting_twitter_title
    public var _troubleshooting_twitter_title: LocalizedStringAccessors { .__troubleshooting_twitter_title }

    case __troubleshooting_title
    public var _troubleshooting_title: LocalizedStringAccessors { .__troubleshooting_title }

    case __allow_alternative_routing
    public var _allow_alternative_routing: LocalizedStringAccessors { .__allow_alternative_routing }

    case __no_internet_connection
    public var _no_internet_connection: LocalizedStringAccessors { .__no_internet_connection }

    case __isp_problem
    public var _isp_problem: LocalizedStringAccessors { .__isp_problem }

    case __gov_block
    public var _gov_block: LocalizedStringAccessors { .__gov_block }

    case __antivirus_interference
    public var _antivirus_interference: LocalizedStringAccessors { .__antivirus_interference }

    case __firewall_interference
    public var _firewall_interference: LocalizedStringAccessors { .__firewall_interference }

    case __proton_is_down
    public var _proton_is_down: LocalizedStringAccessors { .__proton_is_down }

    case __no_solution
    public var _no_solution: LocalizedStringAccessors { .__no_solution }

    case __allow_alternative_routing_description
    public var _allow_alternative_routing_description: LocalizedStringAccessors { .__allow_alternative_routing_description }

    case __allow_alternative_routing_action_title
    public var _allow_alternative_routing_action_title: LocalizedStringAccessors { .__allow_alternative_routing_action_title }

    case __no_internet_connection_description
    public var _no_internet_connection_description: LocalizedStringAccessors { .__no_internet_connection_description }

    case __isp_problem_description
    public var _isp_problem_description: LocalizedStringAccessors { .__isp_problem_description }

    case __gov_block_description
    public var _gov_block_description: LocalizedStringAccessors { .__gov_block_description }

    case __antivirus_interference_description
    public var _antivirus_interference_description: LocalizedStringAccessors { .__antivirus_interference_description }

    case __firewall_interference_description
    public var _firewall_interference_description: LocalizedStringAccessors { .__firewall_interference_description }

    case __proton_is_down_description
    public var _proton_is_down_description: LocalizedStringAccessors { .__proton_is_down_description }

    case __proton_is_down_action_title
    public var _proton_is_down_action_title: LocalizedStringAccessors { .__proton_is_down_action_title }

    case __no_solution_description
    public var _no_solution_description: LocalizedStringAccessors { .__no_solution_description }

    case __troubleshoot_support_subject
    public var _troubleshoot_support_subject: LocalizedStringAccessors { .__troubleshoot_support_subject }

    case __troubleshoot_support_body
    public var _troubleshoot_support_body: LocalizedStringAccessors { .__troubleshoot_support_body }

    case __general_back_action
    public var _general_back_action: LocalizedStringAccessors { .__general_back_action }

    case __pu_plan_details_n_users
    public var _pu_plan_details_n_users: LocalizedStringAccessors { .__pu_plan_details_n_users }

    case __pu_plan_details_n_addresses
    public var _pu_plan_details_n_addresses: LocalizedStringAccessors { .__pu_plan_details_n_addresses }

    case __pu_plan_details_n_addresses_per_user
    public var _pu_plan_details_n_addresses_per_user: LocalizedStringAccessors { .__pu_plan_details_n_addresses_per_user }

    case __pu_plan_details_n_calendars
    public var _pu_plan_details_n_calendars: LocalizedStringAccessors { .__pu_plan_details_n_calendars }

    case __pu_plan_details_n_folders
    public var _pu_plan_details_n_folders: LocalizedStringAccessors { .__pu_plan_details_n_folders }

    case __pu_plan_details_countries
    public var _pu_plan_details_countries: LocalizedStringAccessors { .__pu_plan_details_countries }

    case __pu_plan_details_n_calendars_per_user
    public var _pu_plan_details_n_calendars_per_user: LocalizedStringAccessors { .__pu_plan_details_n_calendars_per_user }

    case __pu_plan_details_n_connections
    public var _pu_plan_details_n_connections: LocalizedStringAccessors { .__pu_plan_details_n_connections }

    case __pu_plan_details_n_vpn_connections
    public var _pu_plan_details_n_vpn_connections: LocalizedStringAccessors { .__pu_plan_details_n_vpn_connections }

    case __pu_plan_details_n_high_speed_connections
    public var _pu_plan_details_n_high_speed_connections: LocalizedStringAccessors { .__pu_plan_details_n_high_speed_connections }

    case __pu_plan_details_n_high_speed_connections_per_user
    public var _pu_plan_details_n_high_speed_connections_per_user: LocalizedStringAccessors { .__pu_plan_details_n_high_speed_connections_per_user }

    case __pu_plan_details_n_custom_domains
    public var _pu_plan_details_n_custom_domains: LocalizedStringAccessors { .__pu_plan_details_n_custom_domains }

    case __pu_plan_details_n_addresses_and_calendars
    public var _pu_plan_details_n_addresses_and_calendars: LocalizedStringAccessors { .__pu_plan_details_n_addresses_and_calendars }

    public func localizedString(from localizedStringInstance: LocalizedString) -> String {
        switch self {
        case .__hv_title: return localizedStringInstance._hv_title
        case .__hv_captha_method_name: return localizedStringInstance._hv_captha_method_name
        case .__hv_sms_method_name: return localizedStringInstance._hv_sms_method_name
        case .__hv_email_method_name: return localizedStringInstance._hv_email_method_name
        case .__hv_help_button: return localizedStringInstance._hv_help_button
        case .__hv_ok_button: return localizedStringInstance._hv_ok_button
        case .__hv_cancel_button: return localizedStringInstance._hv_cancel_button
        case .__hv_email_enter_label: return localizedStringInstance._hv_email_enter_label
        case .__hv_email_label: return localizedStringInstance._hv_email_label
        case .__hv_email_verification_button: return localizedStringInstance._hv_email_verification_button
        case .__hv_sms_enter_label: return localizedStringInstance._hv_sms_enter_label
        case .__hv_sms_label: return localizedStringInstance._hv_sms_label
        case .__hv_sms_search_placeholder: return localizedStringInstance._hv_sms_search_placeholder
        case .__hv_verification_enter_sms_code: return localizedStringInstance._hv_verification_enter_sms_code
        case .__hv_verification_enter_email_code: return localizedStringInstance._hv_verification_enter_email_code
        case .__hv_verification_code: return localizedStringInstance._hv_verification_code
        case .__hv_verification_code_hint: return localizedStringInstance._hv_verification_code_hint
        case .__hv_verification_verify_button: return localizedStringInstance._hv_verification_verify_button
        case .__hv_verification_verifying_button: return localizedStringInstance._hv_verification_verifying_button
        case .__hv_verification_not_receive_code_button: return localizedStringInstance._hv_verification_not_receive_code_button
        case .__hv_verification_error_alert_title: return localizedStringInstance._hv_verification_error_alert_title
        case .__hv_verification_error_alert_message: return localizedStringInstance._hv_verification_error_alert_message
        case .__hv_verification_error_alert_resend: return localizedStringInstance._hv_verification_error_alert_resend
        case .__hv_verification_error_alert_other_method: return localizedStringInstance._hv_verification_error_alert_other_method
        case .__hv_verification_new_alert_title: return localizedStringInstance._hv_verification_new_alert_title
        case .__hv_verification_new_alert_message: return localizedStringInstance._hv_verification_new_alert_message
        case .__hv_verification_new_alert_button: return localizedStringInstance._hv_verification_new_alert_button
        case .__hv_verification_sent_banner: return localizedStringInstance._hv_verification_sent_banner
        case .__hv_help_header: return localizedStringInstance._hv_help_header
        case .__hv_help_request_item_title: return localizedStringInstance._hv_help_request_item_title
        case .__hv_help_request_item_message: return localizedStringInstance._hv_help_request_item_message
        case .__hv_help_visit_item_title: return localizedStringInstance._hv_help_visit_item_title
        case .__hv_help_visit_item_message: return localizedStringInstance._hv_help_visit_item_message
        case .__fu_alert_title: return localizedStringInstance._fu_alert_title
        case .__fu_alert_learn_more_button: return localizedStringInstance._fu_alert_learn_more_button
        case .__fu_alert_update_button: return localizedStringInstance._fu_alert_update_button
        case .__fu_alert_quit_button: return localizedStringInstance._fu_alert_quit_button
        case .__ls_screen_title: return localizedStringInstance._ls_screen_title
        case .__ls_screen_subtitle: return localizedStringInstance._ls_screen_subtitle
        case .__ls_username_title: return localizedStringInstance._ls_username_title
        case .__ls_password_title: return localizedStringInstance._ls_password_title
        case .__ls_help_button: return localizedStringInstance._ls_help_button
        case .__ls_sign_in_button: return localizedStringInstance._ls_sign_in_button
        case .__ls_create_account_button: return localizedStringInstance._ls_create_account_button
        case .__ls_welcome_footer: return localizedStringInstance._ls_welcome_footer
        case .__ls_help_screen_title: return localizedStringInstance._ls_help_screen_title
        case .__ls_help_forgot_username: return localizedStringInstance._ls_help_forgot_username
        case .__ls_help_forgot_password: return localizedStringInstance._ls_help_forgot_password
        case .__ls_help_other_issues: return localizedStringInstance._ls_help_other_issues
        case .__ls_help_customer_support: return localizedStringInstance._ls_help_customer_support
        case .__ls_help_more_help: return localizedStringInstance._ls_help_more_help
        case .__ls_validation_invalid_username: return localizedStringInstance._ls_validation_invalid_username
        case .__ls_validation_invalid_password: return localizedStringInstance._ls_validation_invalid_password
        case .__ls_error_missing_keys_text_button: return localizedStringInstance._ls_error_missing_keys_text_button
        case .__ls_error_missing_keys_text: return localizedStringInstance._ls_error_missing_keys_text
        case .__ls_error_missing_keys_title: return localizedStringInstance._ls_error_missing_keys_title
        case .__ls_error_invalid_mailbox_password: return localizedStringInstance._ls_error_invalid_mailbox_password
        case .__ls_external_eccounts_not_supported_popup_title: return localizedStringInstance._ls_external_eccounts_not_supported_popup_title
        case .__ls_external_eccounts_not_supported_popup_local_desc: return localizedStringInstance._ls_external_eccounts_not_supported_popup_local_desc
        case .__ls_external_eccounts_not_supported_popup_action_button: return localizedStringInstance._ls_external_eccounts_not_supported_popup_action_button
        case .__ls_info_session_expired: return localizedStringInstance._ls_info_session_expired
        case .__ls_error_generic: return localizedStringInstance._ls_error_generic
        case .__ls_create_address_screen_title: return localizedStringInstance._ls_create_address_screen_title
        case .__ls_create_address_screen_info: return localizedStringInstance._ls_create_address_screen_info
        case .__ls_create_address_username_title: return localizedStringInstance._ls_create_address_username_title
        case .__ls_create_address_button_title: return localizedStringInstance._ls_create_address_button_title
        case .__ls_username_username_error: return localizedStringInstance._ls_username_username_error
        case .__ls_login_mailbox_screen_title: return localizedStringInstance._ls_login_mailbox_screen_title
        case .__ls_login_mailbox_field_title: return localizedStringInstance._ls_login_mailbox_field_title
        case .__ls_login_mailbox_button_title: return localizedStringInstance._ls_login_mailbox_button_title
        case .__ls_login_mailbox_forgot_password: return localizedStringInstance._ls_login_mailbox_forgot_password
        case .__ls_login_2fa_screen_title: return localizedStringInstance._ls_login_2fa_screen_title
        case .__ls_login_2fa_action_button_title: return localizedStringInstance._ls_login_2fa_action_button_title
        case .__ls_login_2fa_field_title: return localizedStringInstance._ls_login_2fa_field_title
        case .__ls_login_2fa_recovery_field_title: return localizedStringInstance._ls_login_2fa_recovery_field_title
        case .__ls_login_2fa_recovery_button_title: return localizedStringInstance._ls_login_2fa_recovery_button_title
        case .__ls_login_2fa_2fa_button_title: return localizedStringInstance._ls_login_2fa_2fa_button_title
        case .__ls_login_2fa_field_info: return localizedStringInstance._ls_login_2fa_field_info
        case .__ls_login_2fa_recovery_field_info: return localizedStringInstance._ls_login_2fa_recovery_field_info
        case .__error_occured: return localizedStringInstance._error_occured
        case .__general_ok_action: return localizedStringInstance._general_ok_action
        case .__warning: return localizedStringInstance._warning
        case .__do_you_want_to_bypass_validation: return localizedStringInstance._do_you_want_to_bypass_validation
        case .__yes_bypass_validation: return localizedStringInstance._yes_bypass_validation
        case .__no_dont_bypass_validation: return localizedStringInstance._no_dont_bypass_validation
        case .__popup_credits_applied_message: return localizedStringInstance._popup_credits_applied_message
        case .__popup_credits_applied_confirmation: return localizedStringInstance._popup_credits_applied_confirmation
        case .__popup_credits_applied_cancellation: return localizedStringInstance._popup_credits_applied_cancellation
        case .__error_apply_payment_on_registration_title: return localizedStringInstance._error_apply_payment_on_registration_title
        case .__error_apply_payment_on_registration_message: return localizedStringInstance._error_apply_payment_on_registration_message
        case .__retry: return localizedStringInstance._retry
        case .__error_apply_payment_on_registration_support: return localizedStringInstance._error_apply_payment_on_registration_support
        case .__error_unavailable_product: return localizedStringInstance._error_unavailable_product
        case .__error_invalid_purchase: return localizedStringInstance._error_invalid_purchase
        case .__error_reciept_lost: return localizedStringInstance._error_reciept_lost
        case .__error_another_user_transaction: return localizedStringInstance._error_another_user_transaction
        case .__error_backend_mismatch: return localizedStringInstance._error_backend_mismatch
        case .__error_sandbox_receipt: return localizedStringInstance._error_sandbox_receipt
        case .__error_no_hashed_username_arrived_in_transaction: return localizedStringInstance._error_no_hashed_username_arrived_in_transaction
        case .__error_no_active_username_in_user_data_service: return localizedStringInstance._error_no_active_username_in_user_data_service
        case .__error_transaction_failed_by_unknown_reason: return localizedStringInstance._error_transaction_failed_by_unknown_reason
        case .__error_no_new_subscription_in_response: return localizedStringInstance._error_no_new_subscription_in_response
        case .__error_unlock_to_proceed_with_iap: return localizedStringInstance._error_unlock_to_proceed_with_iap
        case .__error_please_sign_in_iap: return localizedStringInstance._error_please_sign_in_iap
        case .__error_credits_applied: return localizedStringInstance._error_credits_applied
        case .__error_wrong_token_status: return localizedStringInstance._error_wrong_token_status
        case .__login_username_org_dialog_title: return localizedStringInstance._login_username_org_dialog_title
        case .__login_username_org_dialog_action_button: return localizedStringInstance._login_username_org_dialog_action_button
        case .__login_username_org_dialog_message: return localizedStringInstance._login_username_org_dialog_message
        case .__ad_delete_account_title: return localizedStringInstance._ad_delete_account_title
        case .__ad_delete_account_button: return localizedStringInstance._ad_delete_account_button
        case .__ad_delete_account_message: return localizedStringInstance._ad_delete_account_message
        case .__ad_delete_account_success: return localizedStringInstance._ad_delete_account_success
        case .__ad_delete_network_error: return localizedStringInstance._ad_delete_network_error
        case .__ad_delete_close_button: return localizedStringInstance._ad_delete_close_button
        case .__as_switch_to_title: return localizedStringInstance._as_switch_to_title
        case .__as_accounts: return localizedStringInstance._as_accounts
        case .__as_manage_accounts: return localizedStringInstance._as_manage_accounts
        case .__as_signed_in_to_protonmail: return localizedStringInstance._as_signed_in_to_protonmail
        case .__as_signed_out_of_protonmail: return localizedStringInstance._as_signed_out_of_protonmail
        case .__as_signout: return localizedStringInstance._as_signout
        case .__as_remove_button: return localizedStringInstance._as_remove_button
        case .__as_remove_account_from_this_device: return localizedStringInstance._as_remove_account_from_this_device
        case .__as_remove_account: return localizedStringInstance._as_remove_account
        case .__as_remove_account_alert_text: return localizedStringInstance._as_remove_account_alert_text
        case .__as_signout_alert_text: return localizedStringInstance._as_signout_alert_text
        case .__as_dismiss_button: return localizedStringInstance._as_dismiss_button
        case .__as_sign_in_button: return localizedStringInstance._as_sign_in_button
        case .__su_main_view_title: return localizedStringInstance._su_main_view_title
        case .__su_main_view_desc: return localizedStringInstance._su_main_view_desc
        case .__su_next_button: return localizedStringInstance._su_next_button
        case .__su_signin_button: return localizedStringInstance._su_signin_button
        case .__su_email_address_button: return localizedStringInstance._su_email_address_button
        case .__su_proton_address_button: return localizedStringInstance._su_proton_address_button
        case .__su_username_field_title: return localizedStringInstance._su_username_field_title
        case .__su_email_field_title: return localizedStringInstance._su_email_field_title
        case .__su_password_proton_view_title: return localizedStringInstance._su_password_proton_view_title
        case .__su_password_email_view_title: return localizedStringInstance._su_password_email_view_title
        case .__su_password_field_title: return localizedStringInstance._su_password_field_title
        case .__su_password_field_hint: return localizedStringInstance._su_password_field_hint
        case .__su_repeat_password_field_title: return localizedStringInstance._su_repeat_password_field_title
        case .__su_domains_sheet_title: return localizedStringInstance._su_domains_sheet_title
        case .__su_recovery_view_title: return localizedStringInstance._su_recovery_view_title
        case .__su_recovery_view_title_optional: return localizedStringInstance._su_recovery_view_title_optional
        case .__su_recovery_view_desc_old: return localizedStringInstance._su_recovery_view_desc_old
        case .__su_recovery_view_desc: return localizedStringInstance._su_recovery_view_desc
        case .__su_recovery_email_only_view_desc: return localizedStringInstance._su_recovery_email_only_view_desc
        case .__su_recovery_seg_email: return localizedStringInstance._su_recovery_seg_email
        case .__su_recovery_seg_phone: return localizedStringInstance._su_recovery_seg_phone
        case .__su_recovery_email_field_title: return localizedStringInstance._su_recovery_email_field_title
        case .__su_recovery_phone_field_title: return localizedStringInstance._su_recovery_phone_field_title
        case .__su_recovery_t_c_desc: return localizedStringInstance._su_recovery_t_c_desc
        case .__su_recovery_t_c_link: return localizedStringInstance._su_recovery_t_c_link
        case .__su_skip_button: return localizedStringInstance._su_skip_button
        case .__su_recovery_skip_title: return localizedStringInstance._su_recovery_skip_title
        case .__su_recovery_skip_desc: return localizedStringInstance._su_recovery_skip_desc
        case .__su_recovery_method_button: return localizedStringInstance._su_recovery_method_button
        case .__su_complete_view_title: return localizedStringInstance._su_complete_view_title
        case .__su_complete_view_desc: return localizedStringInstance._su_complete_view_desc
        case .__su_complete_step_creation: return localizedStringInstance._su_complete_step_creation
        case .__su_complete_step_address_generation: return localizedStringInstance._su_complete_step_address_generation
        case .__su_complete_step_keys_generation: return localizedStringInstance._su_complete_step_keys_generation
        case .__su_complete_step_payment_verification: return localizedStringInstance._su_complete_step_payment_verification
        case .__su_complete_step_payment_validated: return localizedStringInstance._su_complete_step_payment_validated
        case .__su_email_verification_view_title: return localizedStringInstance._su_email_verification_view_title
        case .__su_email_verification_view_desc: return localizedStringInstance._su_email_verification_view_desc
        case .__su_email_verification_code_name: return localizedStringInstance._su_email_verification_code_name
        case .__su_email_verification_code_desc: return localizedStringInstance._su_email_verification_code_desc
        case .__su_did_not_receive_code_button: return localizedStringInstance._su_did_not_receive_code_button
        case .__su_terms_conditions_view_title: return localizedStringInstance._su_terms_conditions_view_title
        case .__su_error_invalid_token_request: return localizedStringInstance._su_error_invalid_token_request
        case .__su_error_invalid_token: return localizedStringInstance._su_error_invalid_token
        case .__su_error_create_user_failed: return localizedStringInstance._su_error_create_user_failed
        case .__su_error_invalid_hashed_password: return localizedStringInstance._su_error_invalid_hashed_password
        case .__su_error_password_empty: return localizedStringInstance._su_error_password_empty
        case .__su_error_password_too_short: return localizedStringInstance._su_error_password_too_short
        case .__su_error_password_not_equal: return localizedStringInstance._su_error_password_not_equal
        case .__su_error_email_already_used: return localizedStringInstance._su_error_email_already_used
        case .__su_error_missing_sub_user_configuration: return localizedStringInstance._su_error_missing_sub_user_configuration
        case .__su_invalid_verification_alert_message: return localizedStringInstance._su_invalid_verification_alert_message
        case .__su_invalid_verification_change_email_button: return localizedStringInstance._su_invalid_verification_change_email_button
        case .__su_summary_title: return localizedStringInstance._su_summary_title
        case .__su_summary_free_description: return localizedStringInstance._su_summary_free_description
        case .__su_summary_free_description_replacement: return localizedStringInstance._su_summary_free_description_replacement
        case .__su_summary_paid_description: return localizedStringInstance._su_summary_paid_description
        case .__su_summary_no_plan_description: return localizedStringInstance._su_summary_no_plan_description
        case .__su_summary_welcome: return localizedStringInstance._su_summary_welcome
        case .__pu_select_plan_title: return localizedStringInstance._pu_select_plan_title
        case .__pu_current_plan_title: return localizedStringInstance._pu_current_plan_title
        case .__pu_subscription_title: return localizedStringInstance._pu_subscription_title
        case .__pu_upgrade_plan_title: return localizedStringInstance._pu_upgrade_plan_title
        case .__pu_plan_footer_desc: return localizedStringInstance._pu_plan_footer_desc
        case .__pu_plan_footer_desc_purchased: return localizedStringInstance._pu_plan_footer_desc_purchased
        case .__pu_select_plan_button: return localizedStringInstance._pu_select_plan_button
        case .__pu_upgrade_plan_button: return localizedStringInstance._pu_upgrade_plan_button
        case .__pu_plan_details_renew_auto_expired: return localizedStringInstance._pu_plan_details_renew_auto_expired
        case .__pu_plan_details_renew_expired: return localizedStringInstance._pu_plan_details_renew_expired
        case .__pu_plan_details_plan_details_unavailable_contact_administrator: return localizedStringInstance._pu_plan_details_plan_details_unavailable_contact_administrator
        case .__pu_plan_details_storage: return localizedStringInstance._pu_plan_details_storage
        case .__pu_plan_details_storage_per_user: return localizedStringInstance._pu_plan_details_storage_per_user
        case .__pu_plan_details_price_time_period_no_unit: return localizedStringInstance._pu_plan_details_price_time_period_no_unit
        case .__pu_plan_details_vpn_free_speed: return localizedStringInstance._pu_plan_details_vpn_free_speed
        case .__pu_plan_details_custom_email: return localizedStringInstance._pu_plan_details_custom_email
        case .__pu_plan_details_priority_support: return localizedStringInstance._pu_plan_details_priority_support
        case .__pu_plan_details_adblocker: return localizedStringInstance._pu_plan_details_adblocker
        case .__pu_plan_details_streaming_service: return localizedStringInstance._pu_plan_details_streaming_service
        case .__pu_plan_details_n_uneven_amounts_of_addresses_and_calendars: return localizedStringInstance._pu_plan_details_n_uneven_amounts_of_addresses_and_calendars
        case .__pu_plan_details_high_speed: return localizedStringInstance._pu_plan_details_high_speed
        case .__pu_plan_details_highest_speed: return localizedStringInstance._pu_plan_details_highest_speed
        case .__pu_plan_details_multi_user_support: return localizedStringInstance._pu_plan_details_multi_user_support
        case .__pu_plan_details_free_description: return localizedStringInstance._pu_plan_details_free_description
        case .__pu_plan_details_plus_description: return localizedStringInstance._pu_plan_details_plus_description
        case .__pu_plan_details_pro_description: return localizedStringInstance._pu_plan_details_pro_description
        case .__pu_plan_details_visionary_description: return localizedStringInstance._pu_plan_details_visionary_description
        case .__pu_plan_unfinished_error_title: return localizedStringInstance._pu_plan_unfinished_error_title
        case .__pu_plan_unfinished_error_desc: return localizedStringInstance._pu_plan_unfinished_error_desc
        case .__pu_plan_unfinished_error_retry_button: return localizedStringInstance._pu_plan_unfinished_error_retry_button
        case .__pu_plan_unfinished_desc: return localizedStringInstance._pu_plan_unfinished_desc
        case .__pu_iap_in_progress_banner: return localizedStringInstance._pu_iap_in_progress_banner
        case .__splash_made_by: return localizedStringInstance._splash_made_by
        case .__net_connection_error: return localizedStringInstance._net_connection_error
        case .__net_api_might_be_blocked_message: return localizedStringInstance._net_api_might_be_blocked_message
        case .__net_api_might_be_blocked_button: return localizedStringInstance._net_api_might_be_blocked_button
        case .__net_insecure_connection_error: return localizedStringInstance._net_insecure_connection_error
        case .__troubleshooting_support_from: return localizedStringInstance._troubleshooting_support_from
        case .__troubleshooting_email_title: return localizedStringInstance._troubleshooting_email_title
        case .__troubleshooting_twitter_title: return localizedStringInstance._troubleshooting_twitter_title
        case .__troubleshooting_title: return localizedStringInstance._troubleshooting_title
        case .__allow_alternative_routing: return localizedStringInstance._allow_alternative_routing
        case .__no_internet_connection: return localizedStringInstance._no_internet_connection
        case .__isp_problem: return localizedStringInstance._isp_problem
        case .__gov_block: return localizedStringInstance._gov_block
        case .__antivirus_interference: return localizedStringInstance._antivirus_interference
        case .__firewall_interference: return localizedStringInstance._firewall_interference
        case .__proton_is_down: return localizedStringInstance._proton_is_down
        case .__no_solution: return localizedStringInstance._no_solution
        case .__allow_alternative_routing_description: return localizedStringInstance._allow_alternative_routing_description
        case .__allow_alternative_routing_action_title: return localizedStringInstance._allow_alternative_routing_action_title
        case .__no_internet_connection_description: return localizedStringInstance._no_internet_connection_description
        case .__isp_problem_description: return localizedStringInstance._isp_problem_description
        case .__gov_block_description: return localizedStringInstance._gov_block_description
        case .__antivirus_interference_description: return localizedStringInstance._antivirus_interference_description
        case .__firewall_interference_description: return localizedStringInstance._firewall_interference_description
        case .__proton_is_down_description: return localizedStringInstance._proton_is_down_description
        case .__proton_is_down_action_title: return localizedStringInstance._proton_is_down_action_title
        case .__no_solution_description: return localizedStringInstance._no_solution_description
        case .__troubleshoot_support_subject: return localizedStringInstance._troubleshoot_support_subject
        case .__troubleshoot_support_body: return localizedStringInstance._troubleshoot_support_body
        case .__general_back_action: return localizedStringInstance._general_back_action
        case .__pu_plan_details_n_users: return localizedStringInstance._pu_plan_details_n_users
        case .__pu_plan_details_n_addresses: return localizedStringInstance._pu_plan_details_n_addresses
        case .__pu_plan_details_n_addresses_per_user: return localizedStringInstance._pu_plan_details_n_addresses_per_user
        case .__pu_plan_details_n_calendars: return localizedStringInstance._pu_plan_details_n_calendars
        case .__pu_plan_details_n_folders: return localizedStringInstance._pu_plan_details_n_folders
        case .__pu_plan_details_countries: return localizedStringInstance._pu_plan_details_countries
        case .__pu_plan_details_n_calendars_per_user: return localizedStringInstance._pu_plan_details_n_calendars_per_user
        case .__pu_plan_details_n_connections: return localizedStringInstance._pu_plan_details_n_connections
        case .__pu_plan_details_n_vpn_connections: return localizedStringInstance._pu_plan_details_n_vpn_connections
        case .__pu_plan_details_n_high_speed_connections: return localizedStringInstance._pu_plan_details_n_high_speed_connections
        case .__pu_plan_details_n_high_speed_connections_per_user: return localizedStringInstance._pu_plan_details_n_high_speed_connections_per_user
        case .__pu_plan_details_n_custom_domains: return localizedStringInstance._pu_plan_details_n_custom_domains
        case .__pu_plan_details_n_addresses_and_calendars: return localizedStringInstance._pu_plan_details_n_addresses_and_calendars
        }
    }
    
}

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
    
    /// External accounts not supported popup title
    public lazy var _ls_external_eccounts_not_supported_popup_title = NSLocalizedString("Proton address required", bundle: Common.bundle, comment: "External accounts not supported popup title")
    
    /// External accounts not supported popup title
    public lazy var _ls_external_eccounts_not_supported_popup_local_desc = NSLocalizedString("Get a Proton Mail address linked to this account in your Proton web settings.", bundle: Common.bundle, comment: "External accounts not supported popup local desc")
    
    /// External accounts not supported popup learn more button
    public lazy var _ls_external_eccounts_not_supported_popup_action_button = NSLocalizedString("Learn more", bundle: Common.bundle, comment: "External accounts not supported popup learn more button")
    
    /// Session expired info
    public lazy var _ls_info_session_expired = NSLocalizedString("Your session has expired. Please log in again.", bundle: Common.bundle, comment: "Session expired info")

    /// Generic error message when no better error can be displayed
    public lazy var _ls_error_generic = NSLocalizedString("An error has occured", bundle: Common.bundle, comment: "Generic error message when no better error can be displayed")

    // Login create address

    /// Screen title for picking Proton mail username
    public lazy var _ls_create_address_screen_title = NSLocalizedString("Proton address required", bundle: Common.bundle, comment: "Screen title for creating Proton Mail address")

    /// Info about existing external Proton Mail address
    public lazy var _ls_create_address_screen_info = NSLocalizedString("You need a Proton email address to use Proton Mail and Proton Calendar.\nYou’ll still be able to use %@ to sign in, and to recover your account.", bundle: Common.bundle, comment: "Info about existing external Proton Mail address")

    /// Username field title
    public lazy var _ls_create_address_username_title = NSLocalizedString("Username", bundle: Common.bundle, comment: "Username field title")

    /// Action button title for picking Proton Mail username
    public lazy var _ls_create_address_button_title = NSLocalizedString("Continue", bundle: Common.bundle, comment: "Action button title for picking Proton Mail username")

    /// Username field error message
    public lazy var _ls_username_username_error = NSLocalizedString("Please enter a username.", bundle: Common.bundle, comment: "Username field error message")

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
    
    // Signup summary no plan description
    public lazy var _su_summary_no_plan_description = NSLocalizedString("Your Proton account was successfully created.", bundle: Common.bundle, comment: "Signup summary no plan description")
    
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
    
    /// Plan details price time period
    public lazy var _pu_plan_details_price_time_period_no_unit = NSLocalizedString("for %@", bundle: Common.bundle, comment: "Plan details price time period without unit — we delegate the units formatting to the operating system. Example: for 1 year 3 months")

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
    
    public lazy var _net_api_might_be_blocked_message = NSLocalizedString("The Proton servers are unreachable. It might be caused by wrong network configuration, Proton servers not working or Proton servers being blocked", bundle: Common.bundle, comment: "Message shown when we suspect that the Proton servers are blocked")
    
    public lazy var _net_api_might_be_blocked_button = NSLocalizedString("Troubleshoot", bundle: Common.bundle, comment: "Button for the error banner shown when we suspect that the Proton servers are blocked")
    
    /// Networking connection error
    public lazy var _net_insecure_connection_error = NSLocalizedString("The TLS certificate validation failed when trying to connect to the Proton API. Your current Internet connection may be monitored. To keep your data secure, we are preventing the app from accessing the Proton API.\nTo log in or access your account, switch to a new network and try to connect again.", bundle: Common.bundle, comment: "Networking insecure connection error")
    
    // network troubleshooting
    public lazy var _troubleshooting_support_from = NSLocalizedString("support form", comment: "network troubleshot view title")
    public lazy var _troubleshooting_email_title = NSLocalizedString("email", comment: "network troubleshot view title")
    public lazy var _troubleshooting_twitter_title = NSLocalizedString("Twitter", comment: "network troubleshot view title")
    
    public lazy var _troubleshooting_title = NSLocalizedString("TroubleShooting", comment: "network troubleshot view title")
    public lazy var _allow_alternative_routing = NSLocalizedString("Allow alternative routing", comment: "network troubleshot cell title")
    public lazy var _no_internet_connection = NSLocalizedString("No internet connection", comment: "network troubleshot cell title")
    public lazy var _isp_problem = NSLocalizedString("Internet Service Provider (ISP) problem", comment: "network troubleshot cell title")
    public lazy var _gov_block = NSLocalizedString("Government block", comment: "network troubleshot cell title")
    public lazy var _antivirus_interference = NSLocalizedString("Antivirus interference", comment: "network troubleshot cell title")
    public lazy var _firewall_interference = NSLocalizedString("Proxy/Firewall interference", comment: "network troubleshot cell title")
    public lazy var _proton_is_down = NSLocalizedString("Proton is down", comment: "network troubleshot cell title")
    public lazy var _no_solution = NSLocalizedString("Still can't find a solution", comment: "network troubleshot cell title")

    public lazy var _allow_alternative_routing_description = NSLocalizedString("In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@", comment: "alternative routing description")
    public lazy var _allow_alternative_routing_action_title = NSLocalizedString("Learn more", comment: "alternative routing link name in description")
    public lazy var _no_internet_connection_description = NSLocalizedString("Please make sure that your internet connection is working.", comment: "no internet connection description")
    public lazy var _isp_problem_description = NSLocalizedString("Try connecting to Proton from a different network (or use %1$@ or %2$@).", comment: "ISP problem description")
    public lazy var _gov_block_description = NSLocalizedString("Your country may be blocking access to Proton. Try using %1$@ (or any other VPN) or %2$@ to access Proton.", comment: "Goverment blocking description")
    public lazy var _antivirus_interference_description = NSLocalizedString("Temporarily disable or remove your antivirus software.", comment: "Antivirus interference description.")
    public lazy var _firewall_interference_description = NSLocalizedString("Disable any proxies or firewalls, or contact your network administrator.", comment: "Firewall interference description.")
    public lazy var _proton_is_down_description = NSLocalizedString("Check Proton Status for our system status.", comment: "Proton is down description.")
    public lazy var _proton_is_down_action_title = NSLocalizedString("Proton Status", comment: "Name of the link of Proton Status")
    public lazy var _no_solution_description = NSLocalizedString("Contact us directly through our support form, email (support@protonmail.zendesk.com), or Twitter.", comment: "No other solution description.")

    public lazy var _troubleshoot_support_subject = NSLocalizedString("Subject...", comment: "The subject of the email draft created in the network troubleshoot view.")
    public lazy var _troubleshoot_support_body = NSLocalizedString("Please share your problem.", comment: "The body of the email draft created in the network troubleshoot view.")
    
    /// "Back"
    public lazy var _general_back_action = NSLocalizedString("Back", comment: "top left back button")
}
