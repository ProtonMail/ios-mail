//
//  Localization.swift
//  Proton Mail - Created on 4/18/18.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

// object for all the localization strings, this avoid some issues with xcode 9 import/export
var LocalString = LocalizedString()

class LocalizedString {
    // Mark Link Opening Confirmaiton
    lazy var _about_to_open_link = NSLocalizedString("You are about to launch the web browser and navigate to", comment: "link opeining confirmation")
    lazy var _request_link_confirmation = NSLocalizedString("Request link confirmation", comment: "link opeining confirmation")

    // Mark Settings

    /// "%d Minutes"
    lazy var _settings_auto_lock_minutes = NSLocalizedString("%d Minutes", comment: "auto lock time format")
    /// "DISPLAY NAME"
    lazy var _settings_display_name_title = NSLocalizedString("Display Name", comment: "Title in settings")
    /// "Input Display Name…"
    lazy var _settings_input_display_name_placeholder = NSLocalizedString("Input Display Name…", comment: "place holder")
    /// "Signature"
    lazy var _settings_signature_title = NSLocalizedString("Signature", comment: "Title in signature settings")
    /// "Enable Default Signature"
    lazy var _settings_enable_signature_title = NSLocalizedString("Enable signature", comment: "Title")
    lazy var _settings_default_signature_placeholder = NSLocalizedString("Enter your signature here", comment: "")
    /// "Mobile Signature"
    lazy var _settings_mobile_signature_title = NSLocalizedString("Mobile Signature", comment: "Mobile Signature title in settings")
    /// "Notification Email"
    lazy var _settings_notification_email = NSLocalizedString("Recovery email", comment: "Title")
    /// "Enable Notification Email"
    lazy var _settings_notification_email_switch_title = NSLocalizedString("Enable email notices", comment: "Title")
    /// "Input Notification Email…"
    lazy var _settings_notification_email_placeholder = NSLocalizedString("Input Notification Email…", comment: "place holder")
    /// "Remove image metadata"
    lazy var _strip_metadata = NSLocalizedString("Remove image metadata", comment: "Settings row")
    /// "Remove image metadata"
    lazy var _block_email_tracking = NSLocalizedString("Block email tracking", comment: "Settings row")
    /// "Default browser"
    lazy var _default_browser = NSLocalizedString("Default browser", comment: "Settings row")

    // Mark Menu
    lazy var _menu_button         = NSLocalizedString("Menu", comment: "menu title")
    /// "Report a problem"
    lazy var _menu_bugs_title     = NSLocalizedString("Report a problem", comment: "menu title")
    /// "Inbox"
    lazy var _menu_inbox_title = NSLocalizedString("Inbox", comment: "menu title")
    /// "Starred"
    lazy var _menu_starred_title = NSLocalizedString("Starred", comment: "menu title")
    /// "Archive"
    lazy var _menu_archive_title = NSLocalizedString("Archive", comment: "menu title")
    /// "Drafts"
    lazy var _menu_drafts_title = NSLocalizedString("Drafts", comment: "menu title")
    /// "All Mail"
    lazy var _menu_allmail_title = NSLocalizedString("All Mail", comment: "menu title")
    /// "Sent"
    lazy var _menu_sent_title = NSLocalizedString("Sent", comment: "menu title")
    /// "Trash"
    lazy var _menu_trash_title = NSLocalizedString("Trash", comment: "menu title")
    /// "Spam"
    lazy var _menu_spam_title = NSLocalizedString("Spam", comment: "menu title")
    /// "Contacts"
    lazy var _menu_contacts_title = NSLocalizedString("Contacts", comment: "menu title")
    /// "Contact Groups"
    lazy var _menu_contact_group_title = NSLocalizedString("Groups", comment: "menu title (contact groups)")
    /// "Settings"
    lazy var _menu_settings_title = NSLocalizedString("Settings", comment: "menu title")
    /// "Sign out"
    lazy var _menu_signout_title = NSLocalizedString("Sign out", comment: "menu title")
    /// "Lock The App"
    lazy var _menu_lockapp_title = NSLocalizedString("Lock The App", comment: "menu title")
    /// "Subscription"
    lazy var _menu_service_plan_title = NSLocalizedString("Subscription", comment: "menu title")
    /// "Manage accounts"
    lazy var _menu_manage_accounts = NSLocalizedString("Manage accounts", comment: "menu title")
    lazy var _menu_add_attachment = NSLocalizedString("Add attachment", comment: "menu title")
    /// "Refer a friend"
    lazy var _menu_refer_a_friend = NSLocalizedString("Refer a friend", comment: "menu title")

    // Mark Message localtion
     lazy var _locations_scheduled_title     = NSLocalizedString("Scheduled", comment: "mail location title")

    // Mark Messages

    /// "Message sent"
    lazy var _message_sent_ok_desc          = NSLocalizedString("Message sent", comment: "Description after message have been sent")

    lazy var _folder_no_message = NSLocalizedString("Nothing to see here", comment: "The title will be shown when foler doesnt have emails")
    lazy var _folder_is_empty = NSLocalizedString("This folder is empty", comment: "The subtitle will be shown when folder doesnt have emails")

    lazy var _inbox_no_message = NSLocalizedString("You are all caught up!", comment: "The title of empty inbox")
    lazy var _inbox_time_to_relax = NSLocalizedString("Time to relax", comment: "The subtitle of empty inbox")

    /// "Undo"
    lazy var _messages_undo_action = NSLocalizedString("Undo", comment: "Action")
    /// "Message has been deleted."
    lazy var _messages_has_been_deleted = NSLocalizedString("Message has been deleted.", comment: "Title")
    /// "Message has been moved."
    lazy var _messages_has_been_moved = NSLocalizedString("Message has been moved.", comment: "Title")
    /// "You're going to delete the message irreversibly. Are you sure?"
    lazy var _messages_will_be_removed_irreversibly = NSLocalizedString("You're going to delete the message irreversibly. Are you sure?", comment: "Confirmation message before deleting a message")
    /// "You have a new email!"
    lazy var _messages_you_have_new_email = NSLocalizedString("You have a new email!", comment: "Title")
    /// "You have %d new emails!"
    lazy var _messages_you_have_new_emails_with = NSLocalizedString("You have %d new emails!", comment: "Message")

    // Mark Composer

    /// "Re:"
    lazy var _composer_short_reply   = NSLocalizedString("Re:", comment: "abbreviation of reply:")
    /// "Fw:"
    lazy var _composer_short_forward_shorter = NSLocalizedString("Fw:", comment: "abbreviation of forward:")
    /// "wrote:"
    lazy var _composer_wrote = NSLocalizedString("wrote:", comment: "Title")

    /// "On {date} at {time}, e.g.: On Sat, Aug 14, 2021 at 19:00"
    lazy var _composer_forward_header_on_detail = NSLocalizedString("On %@ at %@", comment: "On {date} at {time}, e.g.: On Sat, Aug 14, 2021 at 19:00")

    /// "Date:"
    lazy var _composer_date_field    = NSLocalizedString("Date:", comment: "message Date: text")
    /// "Subject:"
    lazy var _composer_subject_field = NSLocalizedString("Subject:", comment: "subject: text when forward")
    /// "Forwarded message"
    lazy var _composer_fwd_message   = NSLocalizedString("Forwarded message", comment: "forwarded message title")
    /// "Set Password"
    lazy var _composer_set_password  = NSLocalizedString("Set Password", comment: "Title")
    /// "Set a password to encrypt this message for non-Proton Mail users."
    lazy var _composer_eo_desc       = NSLocalizedString("Set a password to encrypt this message for non-Proton Mail users.", comment: "Description")
    /// "Message Password"
    lazy var _composer_eo_msg_pwd_placeholder = NSLocalizedString("Message Password", comment: "Placeholder")
    lazy var _composer_eo_msg_pwd_hint = NSLocalizedString("8 to 21 characters long", comment: "Placeholder")
    lazy var _composer_eo_msg_pwd_length_error = NSLocalizedString("The password must be between 8 and 21 characters long", comment: "Error message")
    lazy var _composer_eo_repeat_pwd = NSLocalizedString("Repeat password", comment: "textview title")
    lazy var _composer_eo_repeat_pwd_placeholder = NSLocalizedString("Passwords must match", comment: "Placeholder")
    lazy var _composer_eo_repeat_pwd_match_error = NSLocalizedString("The 2 passwords are not matching", comment: "Error message")
    lazy var _composer_eo_remove_pwd = NSLocalizedString("Remove password", comment: "action title")
    lazy var _composer_password_hint_title = NSLocalizedString("Password Hint", comment: "title")
    lazy var _composer_password_apply = NSLocalizedString("Apply Password", comment: "button title")
    /// "Compose"
    lazy var _composer_compose_action = NSLocalizedString("Compose", comment: "Action")
    lazy var _composer_expiration_title = NSLocalizedString("Message expiration", comment: "Composer expiration page title")
    lazy var _composer_expiration_custom = NSLocalizedString("Custom", comment: "Custom option for time config picker")
    /// "Send message without subject?"
    lazy var _composer_send_no_subject_desc = NSLocalizedString("Send message without subject?", comment: "Description")
    /// "You need at least one recipient to send"
    lazy var _composer_no_recipient_error = NSLocalizedString("You need at least one recipient to send", comment: "Description")
    /// "Upgrade to a paid plan to send from your %@ address"
    lazy var _composer_change_paid_plan_sender_error = NSLocalizedString("Upgrade to a paid plan to send from your %@ address", comment: "Error")
    /// "Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@"
    lazy var _composer_sending_messages_from_a_paid_feature = NSLocalizedString("Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@", comment: "pm.me upgrade warning in composer")
    /// "From"
    lazy var _composer_from_label = NSLocalizedString("From", comment: "Title")
    /// "Bcc"
    lazy var _composer_bcc_label = NSLocalizedString("Bcc", comment: "Title")
    /// "Subject"
    lazy var _composer_subject_placeholder = NSLocalizedString("Subject", comment: "Placeholder")
    lazy var _composer_draft_saved = NSLocalizedString("Draft saved", comment: "hint message")
    /// "Define Hint (Optional)"
    lazy var _define_hint_optional = NSLocalizedString("Define Hint (Optional)", comment: "Placeholder")
    /// "Clear Style"
    lazy var _clear_style = NSLocalizedString("Clear Style", comment: "Menu action to remove text formatting")

    // Mark Contacts

    /// "Add Organization"
    lazy var _contacts_add_org              = NSLocalizedString("Add organization", comment: "new contacts add Organization ")
    /// "Add Nickname"
    lazy var _contacts_add_nickname         = NSLocalizedString("Add nickname", comment: "new contacts add Nickname")
    /// "Add Title"
    lazy var _contacts_add_title            = NSLocalizedString("Add title", comment: "new contacts add Title")
    /// "Add Birthday"
    lazy var _contacts_add_bd               = NSLocalizedString("Add birthday", comment: "new contacts add Birthday")
    /// "Add Anniversary"
    lazy var _contacts_add_anniversary      = NSLocalizedString("Add anniversary", comment: "new contacts add Anniversary")
    /// "Add Gender"
    lazy var _contacts_add_gender           = NSLocalizedString("Add gender", comment: "new contacts add Gender")
    /// "Add Contact"
    lazy var _contacts_new_contact          = NSLocalizedString("New contact", comment: "Contacts add new contact")
    /// "Add new address"
    lazy var _contacts_add_new_address      = NSLocalizedString("Add new address", comment: "add new address action")
    /// "Add new custom field"
    lazy var _contacts_add_new_custom_field = NSLocalizedString("Add new custom field", comment: "new custom field action")
    /// "Add new email"
    lazy var _contacts_add_new_email        = NSLocalizedString("Add new email", comment: "new email action")
    /// "Add new phone number"
    lazy var _contacts_add_new_phone        = NSLocalizedString("Add new phone number", comment: "new phone action")
    /// "Add new field"
    lazy var _contacts_add_new_field        = NSLocalizedString("Add new field", comment: "new field action")
    /// we rename home to "Personal"
    lazy var _contacts_types_home_title     = NSLocalizedString("Personal", comment: "default vcard types")
    /// "Work"
    lazy var _contacts_types_work_title     = NSLocalizedString("Work", comment: "default vcard types")
    /// "Email"
    lazy var _contacts_types_email_title    = NSLocalizedString("Email", comment: "default vcard types")
    /// "Other"
    lazy var _contacts_types_other_title    = NSLocalizedString("Other", comment: "default vcard types")
    /// "Phone"
    lazy var _contacts_types_phone_title    = NSLocalizedString("Phone", comment: "default vcard types")
    /// "Mobile"
    lazy var _contacts_types_mobile_title   = NSLocalizedString("Mobile", comment: "default vcard types")
    /// "Fax"
    lazy var _contacts_types_fax_title      = NSLocalizedString("Fax", comment: "default vcard types")
    /// "Address"
    lazy var _contacts_types_address_title  = NSLocalizedString("Address", comment: "default vcard types")
    /// "URL"
    lazy var _contacts_types_url_title      = NSLocalizedString("URL", comment: "default vcard types")
    /// "Internet"
    lazy var _contacts_types_internet_title = NSLocalizedString("Internet", comment: "default vcard types")
    /// "All contacts are imported"
    lazy var _contacts_all_imported         = NSLocalizedString("All contacts are imported", comment: "Title")
    /// "Custom"
    lazy var _contacts_custom_type          = NSLocalizedString("Custom", comment: "contacts default label type")
    /// "Street"
    lazy var _contacts_street_field_placeholder = NSLocalizedString("Street", comment: "contact placeholder")
    /// "City"
    lazy var _contacts_city_field_placeholder = NSLocalizedString("City", comment: "contact placeholder")
    /// "State"
    lazy var _contacts_state_field_placeholder = NSLocalizedString("State", comment: "contact placeholder")
    /// "ZIP"
    lazy var _contacts_zip_field_placeholder = NSLocalizedString("ZIP", comment: "contact placeholder")
    /// "Country"
    lazy var _contacts_country_field_placeholder = NSLocalizedString("Country", comment: "contact placeholder")
    /// "Url"
    lazy var _contacts_vcard_url_placeholder = NSLocalizedString("URL", comment: "default vcard types")
    /// "Organization"
    lazy var _contacts_info_organization = NSLocalizedString("Organization", comment: "contacts talbe cell Organization title")
    /// "Nickname"
    lazy var _contacts_info_nickname = NSLocalizedString("Nickname", comment: "contacts talbe cell Nickname title")
    /// "Title"
    lazy var _contacts_info_title = NSLocalizedString("Title", comment: "contacts talbe cell Title title")
    /// "Birthday"
    lazy var _contacts_info_birthday = NSLocalizedString("Birthday", comment: "contacts talbe cell Birthday title")
    /// "Anniversary"
    lazy var _contacts_info_anniversary = NSLocalizedString("Anniversary", comment: "contacts talbe cell Anniversary title")
    /// "Gender"
    lazy var _contacts_info_gender = NSLocalizedString("Gender", comment: "contacts talbe cell gender title")
    lazy var _contacts_email_contact_title = NSLocalizedString("Email contact", comment: "Send an email to the current contact (button title text)")
    lazy var _contacts_call_contact_title = NSLocalizedString("Call contact", comment: "Call the contact (button title text)")
    /// "Email addresses"
    lazy var _contacts_email_addresses_title = NSLocalizedString("Email addresses", comment: "contact detail view, email addresses section title")
    /// "Encrypted Contact Details"
    lazy var _contacts_encrypted_contact_details_title = NSLocalizedString("Encrypted contact details", comment: "contact section title")
    /// "Share Contact"
    lazy var _contacts_share_contact_action = NSLocalizedString("Share contact", comment: "action")
    /// "Notes"
    lazy var _contacts_info_notes = NSLocalizedString("Notes", comment: "title")
    /// "Upload Contacts"
    lazy var _contacts_upload_device_contacts = NSLocalizedString("Upload device contacts", comment: "Action")

    lazy var _contacts_action_sheet_title = NSLocalizedString("Create", comment: "")

    // Mark Labels

    /// "Add Label"
    lazy var _labels_add_label_action     = NSLocalizedString("Add Label", comment: "add label action")
    /// "Add Folder"
    lazy var _labels_add_folder_action    = NSLocalizedString("Add Folder", comment: "Action")
    /// "Folder Name"
    lazy var _labels_folder_name_text     = NSLocalizedString("Folder Name", comment: "place holder")
    /// "Label Name"
    lazy var _labels_label_name_text      = NSLocalizedString("Label Name", comment: "createing lable input place holder")

    // Mark General

    /// "Access to this account is disabled due to non-payment. Please log in through proton.me to pay your outstanding invoice(s)."
    lazy var _general_account_disabled_non_payment = NSLocalizedString("Access to this account is disabled due to non-payment. Please sign in through proton.me to pay your unpaid invoice.", comment: "error message")
    /// "Alert"
    lazy var _general_alert_title     = NSLocalizedString("Alert", comment: "Title")
    /// "Done"
    lazy var _general_done_button     = NSLocalizedString("Done", comment: "Done action")
    /// "Cancel"
    lazy var _general_cancel_button   = NSLocalizedString("Cancel", comment: "Cancel action")

    /// "Open"
    lazy var _general_open_button     = NSLocalizedString("Open", comment: "Open action")
    /// "Remove"
    lazy var _general_remove_button   = NSLocalizedString("Remove", comment: "remove action")
    /// "Apply"
    lazy var _general_apply_button    = NSLocalizedString("Apply", comment: "Apply action")
    /// "Reply"
    lazy var _general_reply_button    = NSLocalizedString("Reply", comment: "reply action")
    /// "Reply All"
    lazy var _general_replyall_button = NSLocalizedString("Reply all", comment: "reply all action")
    /// "Forward"
    lazy var _general_forward_button  = NSLocalizedString("Forward", comment: "forward action")
    /// "From:"
    lazy var _general_from_label      = NSLocalizedString("From:", comment: "message From: field text")
    /// "To:"
    lazy var _general_to_label        = NSLocalizedString("To", comment: "message To: feild")
    /// "Cc:"
    lazy var _general_cc_label        = NSLocalizedString("Cc", comment: "message Cc: feild")
    /// "Cc:"
    lazy var _general_bcc_label = NSLocalizedString("Bcc:", comment: "message Bcc: feild")
    /// "Delete"
    lazy var _general_delete_action   = NSLocalizedString("Delete", comment: "general delete action")
    /// "Close"
    lazy var _general_close_action    = NSLocalizedString("Close", comment: "general close action")
    /// "Cancel"
    lazy var _general_cancel_action = NSLocalizedString("Cancel", comment: "general cancel action")
    /// "Invalid access token. Please try loging in again."
    lazy var _general_invalid_access_token = NSLocalizedString("Your session has expired because you have been inactive for a while or because it has been revoked. Please log back in.", comment: "Description")
    /// "Search"
    lazy var _general_search_placeholder = NSLocalizedString("Search", comment: "Title")
    /// "Notice"
    lazy var _general_notice_alert_title = NSLocalizedString("Notice", comment: "Alert title")
    /// "Error"
    lazy var _general_error_alert_title = NSLocalizedString("Error", comment: "Alert title")
    /// "Don't remind me again"
    lazy var _general_dont_remind_action = NSLocalizedString("Don't remind me again", comment: "Action")
    /// "Send"
    lazy var _general_send_action = NSLocalizedString("Send", comment: "Action")
    lazy var _general_schedule_send_action = NSLocalizedString("Schedule send", comment: "Action")
    lazy var _message_saved_to_draft = NSLocalizedString("Message saved to Drafts", comment: "Alert title")
    lazy var _schedule_send_unavailable_message = NSLocalizedString("Too many messages waiting to be sent.\nPlease wait until another message has been sent to schedule this one.", comment: "Alert message")
    lazy var _schedule_send_future_warning = NSLocalizedString("The sending time needs to be at least 5 minutes in the future.", comment: "Warning message")
    /// "Send anyway"
    lazy var _send_anyway = NSLocalizedString("Send anyway", comment: "Action")
    /// "Confirmation"
    lazy var _general_confirmation_title = NSLocalizedString("Confirmation", comment: "Title")
    /// "Draft"
    lazy var _general_draft_action = NSLocalizedString("Draft", comment: "Action")
    /// "The request timed out."
    lazy var _general_request_timed_out = NSLocalizedString("The request timed out.", comment: "Title")
    /// "Proton servers are not reachable"
    lazy var _general_proton_unreachable = NSLocalizedString("Proton servers are unreachable.\nVisit our status page for details.", comment: "Message")
    /// "No connectivity detected…"
    lazy var _general_no_connectivity_detected = NSLocalizedString("No connectivity detected…", comment: "Title")
    /// "The Proton Mail current offline…"
    lazy var _general_pm_offline = NSLocalizedString("Proton Mail is currently offline…", comment: "Title")
    /// "Save"
    lazy var _general_save_action = NSLocalizedString("Save", comment: "Title")
    /// "Edit"
    lazy var _general_edit_action = NSLocalizedString("Edit", comment: "Action")
    /// "Create"
    lazy var _general_create_action = NSLocalizedString("Create", comment: "top right action text")

    lazy var _general_message = NSLocalizedString("%u message", comment: "message number")
    lazy var _general_conversation = NSLocalizedString("%u conversation", comment: "conversation number")
    lazy var _general_subscription = NSLocalizedString("Subscription", comment: "The title of a subscription plans screen")

    /// Mark Error

    /// "Invalid username"
    lazy var _error_invalid_username = NSLocalizedString("Invalid username!", comment: "Error message")
    /// "Bad parameter"
    lazy var _error_bad_parameter_title = NSLocalizedString("Bad parameter", comment: "Error title")
    /// "Bad parameter: %@"
    lazy var _error_bad_parameter_desc = NSLocalizedString("Bad parameter: %@", comment: "Error Description")
    /// "Bad response"
    lazy var _error_bad_response_title = NSLocalizedString("Bad response", comment: "Error Description")
    /// "Can't find the value from the response body."
    lazy var _error_cant_parse_response_body = NSLocalizedString("Can't find the value from the response body", comment: "Description")
    /// "no object"
    lazy var _error_no_object = NSLocalizedString("no object", comment: "no object error, local only , this could be not translated!")
    /// "Unable to parse response"
    lazy var _error_unable_to_parse_response_title = NSLocalizedString("Unable to parse response", comment: "Description")
    /// "Unable to parse the response object:\n%@"
    lazy var _error_unable_to_parse_response_desc = NSLocalizedString("Unable to parse the response object:\n%@", comment: "Description")

    /// "This email seems to be from a Proton Mail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded."
    lazy var _messages_spam_100_warning = NSLocalizedString("This email seems to be from a Proton Mail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
    /// "This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded."
    lazy var _messages_spam_101_warning = NSLocalizedString("This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded.", comment: "spam score warning")
    /// "This message may be a phishing attempt. Please check the sender and contents to make sure they are legitimate."
    lazy var _messages_spam_102_warning = NSLocalizedString("This message may be a phishing attempt. Please check the sender and contents to make sure they are legitimate.", comment: "spam score warning")

    /// "Sending Message"
    lazy var _messages_sending_message = NSLocalizedString("Sending Message", comment: "Description")
    lazy var _message_queued_for_sending = NSLocalizedString("Offline, message queued for sending", comment: "Sending message when device doesn't have netowrk connection description")

    /// "Message sending failed. Please try again."
    lazy var _messages_sending_failed_try_again = NSLocalizedString("Message sending failed. Please try again.", comment: "Description")

    /// "Importing Contacts"
    lazy var _contacts_import_title = NSLocalizedString("Importing Contacts", comment: "import contact title")

    /// "Reading contacts data from device…"
    lazy var _contacts_reading_contacts_data = NSLocalizedString("Reading device contacts data…", comment: "Title")

    /// "Contacts"
    lazy var _contacts_title = NSLocalizedString("Contacts", comment: "Action and title")
    lazy var _contacts_importing = NSLocalizedString("Importing contacts...", comment: "title for the contact import indicator")

    /// "Do you want to cancel the process?"
    lazy var _contacts_import_cancel_wanring = NSLocalizedString("Do you want to cancel the process?", comment: "Description")

    lazy var _contacts_saved_offline_hint = NSLocalizedString("Contact saved, will be synced when connection is available", comment: "Hint when users create / edit contact offline ")
    lazy var _contacts_deleted_offline_hint = NSLocalizedString("Contact deleted, will be synced when connection is available", comment: "Hint when users delete contact offline ")

    /// "Confirm"
    lazy var _general_confirm_action = NSLocalizedString("Confirm", comment: "Action")

    /// "Canceling"
    lazy var _contacts_cancelling_title = NSLocalizedString("Canceling", comment: "Title")

    /// "Unknown"
    lazy var _general_unknown_title = NSLocalizedString("Unknown", comment: "title, default display name")

    /// "Import Error"
    lazy var _contacts_import_error = NSLocalizedString("Import Error", comment: "Action")

    /// "OK"
    lazy var _general_ok_action = NSLocalizedString("OK", comment: "Action")
    lazy var _general_later_action = NSLocalizedString("Later", comment: "Action")
    lazy var _general_disabled_action = NSLocalizedString("Disabled", comment: "Action")

    /// "Email address"
    lazy var _contacts_email_address_placeholder = NSLocalizedString("Email address", comment: "contact placeholder")

    /// "Back"
    lazy var _general_back_action = NSLocalizedString("Back", comment: "top left back button")

    /// "None"
    lazy var _general_none = NSLocalizedString("None", comment: "Title")

    /// "Every time the app is accessed"
    lazy var _settings_every_time_enter_app = NSLocalizedString("Every time enter app", comment: "lock app option")

    /// "Default"
    lazy var _general_default = NSLocalizedString("Default", comment: "Title")

    lazy var _general_set = NSLocalizedString("Set", comment: "Title")

    /// "Resetting message cache …"
    lazy var _settings_resetting_cache = NSLocalizedString("Resetting message cache…", comment: "Title")

    /// "This preference will fallback to Safari if the browser of choice is uninstalled."
    lazy var _settings_browser_disclaimer = NSLocalizedString("This preference will fallback to Safari if the browser of choice is uninstalled.", comment: "Title")

    lazy var _unsupported_url = NSLocalizedString("The URL you are trying to access is not standard and may not load properly. Do you want to open it using your device's default browser?", comment: "Unsupported url alert message")

    /// "Auto Lock Time"
    lazy var _settings_auto_lock_time = NSLocalizedString("Auto Lock Time", comment: "A Title of available auto lock time action sheet")

    /// "Change default address to…"
    lazy var _settings_change_default_address_to = NSLocalizedString("Change default address to…", comment: "Title")

    /// "You can't set the %@ address as default because it is a paid feature."
    lazy var _settings_change_paid_address_warning = NSLocalizedString("You can't set %@ address as default because it is a paid feature.", comment: "pm.me upgrade warning in composer")

    /// "Continue"
    lazy var _genernal_continue = NSLocalizedString("Continue", comment: "Action")
    /// "Please input a valid email address."
    lazy var _please_input_a_valid_email_address = NSLocalizedString("Please input a valid email address.", comment: "error message")

    /// "Enter your PIN to unlock your inbox."
    lazy var _enter_pin_to_unlock_inbox = NSLocalizedString("Enter your PIN to unlock your inbox.", comment: "Title")

    /// "attempt remaining until secure data wipe!"
    lazy var _attempt_remaining_until_secure_data_wipe = NSLocalizedString("%d attempt remaining until secure data wipe!", comment: "Error")

    /// "Incorrect PIN."
    lazy var _incorrect_pin = NSLocalizedString("Incorrect PIN.", comment: "Error")

    /// "attempts remaining"
    lazy var _attempt_remaining = NSLocalizedString("%d attempt remaining", comment: "Description")

    /// "Upload iOS contacts to Proton Mail?"
    lazy var _upload_ios_contacts_to_protonmail = NSLocalizedString("Upload iOS contacts to Proton Mail?", comment: "Description")

    /// "Delete Contact"
    lazy var _delete_contact = NSLocalizedString("Delete contact", comment: "Title-Contacts")

    /// "PIN code is required."
    lazy var _pin_code_cant_be_empty = NSLocalizedString("PIN code can't be empty.", comment: "Description")


    /// "Unknown Error"
    lazy var _unknown_error = NSLocalizedString("Unknown Error", comment: "Error")
    /// "Load remote content"
    lazy var _load_remote_content = NSLocalizedString("Load remote content", comment: "Action")

    /// "Star"
    lazy var _star_unstar = NSLocalizedString("Star/unstar", comment: "Title")

    /// "Proton Mail"
    lazy var _protonmail = NSLocalizedString("Proton Mail", comment: "Title")

    /// "Remind Me Later"
    lazy var _remind_me_later = NSLocalizedString("Remind Me Later", comment: "Title")

    /// "Don't Show Again"
    lazy var _dont_show_again = NSLocalizedString("Don't Show Again", comment: "Title")

    // Mark : Onboarding
    lazy var _easily_up_to_date = NSLocalizedString("Easily up-to-date", comment: "Onboarding title")

    lazy var _privacy_for_all = NSLocalizedString("Privacy for all", comment: "Onboarding title")

    lazy var _neat_and_tidy = NSLocalizedString("Neat and tidy", comment: "Onboarding title")

    lazy var _brand_new_proton = NSLocalizedString("Updated Proton, unified protection", comment: "Welcome to rebranding title")

    lazy var _easily_up_to_date_content = NSLocalizedString("Breeze through threaded messages in conversation mode.", comment: "Onboarding content")

    lazy var _privacy_for_all_content = NSLocalizedString("Invite your contacts to Proton Mail to enjoy seamless end-to-end encryption, or add password protection to messages you send them.", comment: "Onboarding content")

    lazy var _neat_and_tidy_content = NSLocalizedString("File, label, and color code messages to create your perfect, custom inbox.", comment: "Onboarding content")

    lazy var _brand_new_proton_content = NSLocalizedString("Introducing Proton’s refreshed look.\nMany services, one mission. Welcome to an Internet where privacy is the default.", comment: "Welcome to rebranding content")

    lazy var _skip_btn_title = NSLocalizedString("Skip", comment: "skip button title in onboarding page")

    lazy var _next_btn_title = NSLocalizedString("Next", comment: "title of the next button")

    lazy var _get_started_title = NSLocalizedString("Get Started", comment: "title of the next button")

    /// "Unable to edit this message offline"
    lazy var _unable_to_edit_offline = NSLocalizedString("Unable to edit this message offline", comment: "Description")

    /// "Date: %@"
    lazy var _date = NSLocalizedString("Date: %@", comment: "like Date: 2017-10-10")

    /// "Hide Details"
    lazy var _hide_details = NSLocalizedString("Hide details", comment: "Title")

    /// "Phone number"
    lazy var _phone_number = NSLocalizedString("Phone number", comment: "contact placeholder")

    lazy var _edit_contact = NSLocalizedString("Edit Contact", comment: "Contacts Edit contact")

    /// "Discard changes"
    lazy var _discard_changes = NSLocalizedString("Discard changes", comment: "Action")

    lazy var _general_discard = NSLocalizedString("Discard", comment: "Action")
    lazy var _general_discarded = NSLocalizedString("Discarded", comment: "Message shown to user after discarding action is done")

    /// "Add new url"
    lazy var _add_new_url = NSLocalizedString("Add new URL", comment: "action")

    lazy var _auto_load_remote_content = NSLocalizedString("Auto-load remote content", comment: "settings general section title")
    lazy var _auto_load_embedded_images = NSLocalizedString("Auto-load embedded images", comment: "settings general section title")
    /// "Swipe Left to Right"
    lazy var _swipe_left_to_right = NSLocalizedString("Left to Right", comment: "settings swipe actions section title")
    /// "Swipe Right to Left"
    lazy var _swipe_right_to_left = NSLocalizedString("Right to Left", comment: "settings swipe actions section title")

    lazy var _unlock_required = NSLocalizedString("Unlock required", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    lazy var _enable_faceid_in_settings = NSLocalizedString("You disabled %1$@ in your system settings. %2$@ has been used to protect important account information. To access your account, go to settings and reactivate %3$@, or log back in.", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    lazy var _lock_wipe_desc = NSLocalizedString("All protection settings will be reset and wiped upon signing out of the app.", comment: "A description string in pin & faceID setting page")

    lazy var _timing = NSLocalizedString("Timing", comment: "A section title for timing section to set auto lock timing")

    lazy var _go_to_settings = NSLocalizedString("Go to settings", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    lazy var _go_to_signin = NSLocalizedString("Go to sign in", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    /// "You have unsaved changes. Do you want to save it?"
    lazy var _you_have_unsaved_changes_do_you_want_to_save_it = NSLocalizedString("You have unsaved changes. Do you want to save it?", comment: "Confirmation message")

    /// "Save Changes"
    lazy var _save_changes = NSLocalizedString("Save Changes", comment: "title")

    /// "Recovery Code"
    lazy var _recovery_code = NSLocalizedString("Recovery Code", comment: "Title")

    /// "Two Factor Code"
    lazy var _two_factor_code = NSLocalizedString("Two Factor Code", comment: "Placeholder")

    /// "Authentication"
    lazy var _authentication = NSLocalizedString("Authentication", comment: "Title")

    /// "Enter"
    lazy var _enter = NSLocalizedString("Enter", comment: "Action in 2fa popup view")

    /// "Storage Warning"
    lazy var _space_warning = NSLocalizedString("Storage Warning", comment: "Title")
    lazy var _space_all_used_warning = NSLocalizedString("You have used up all of your storage space (%@). Please upgrade your plan to continue to send and receive emails.", comment: "Content of space warning")
    lazy var _space_partial_used_warning = NSLocalizedString("You have used %d%% of your storage space (%@). Please upgrade your plan to continue to send and receive emails.", comment: "Content of space warning")
    lazy var _storage_full = NSLocalizedString("Storage full", comment: "Alert title")
    lazy var _storage_exceeded = NSLocalizedString("Storage quota exceeded", comment: "Storage warning")
    lazy var _please_upgrade_plan = NSLocalizedString("Please upgrade your plan", comment: "Content of storage full alert")
    lazy var _upgrade_suggestion = NSLocalizedString("Please upgrade your plan to continue to send and receive emails.", comment: "Content of storage full alert")

    /// "Warning"
    lazy var _warning = NSLocalizedString("Warning", comment: "Title")

    /// "Hide"
    lazy var _hide = NSLocalizedString("Hide", comment: "Action")
    /// "Show"
    lazy var _show = NSLocalizedString("Show", comment: "Action")

    /// "Change Password"
    lazy var _change_password = NSLocalizedString("Change Password", comment: "update password error title")

    /// "Can't get a Modulus ID!"
    lazy var _cant_get_a_modulus_id = NSLocalizedString("Can't get a Modulus ID!", comment: "update password error = typo:Modulus")

    /// "Can't get a Modulus!"
    lazy var _cant_get_a_modulus = NSLocalizedString("Can't get a Modulus!", comment: "update password error = typo:Modulus")

    /// "Invalid hashed password!"
    lazy var _invalid_hashed_password = NSLocalizedString("Invalid hashed password!", comment: "update password error")

    lazy var _password_needs_at_least_8_chars = NSLocalizedString("The new password needs to be at least 8 characters long", comment: "update password error")

    /// "Can't create a SRP verifier!"
    lazy var _cant_create_a_srp_verifier = NSLocalizedString("Can't create a SRP verifier!", comment: "update password error")

    /// "Can't create a SRP Client"
    lazy var _cant_create_a_srp_client = NSLocalizedString("Can't create a SRP Client", comment: "update password error")

    /// "The password is wrong."
    lazy var _the_password_is_wrong = NSLocalizedString("The password is wrong.", comment: "update password error")

    /// "The new password does not match."
    lazy var _the_new_password_not_match = NSLocalizedString("The new password does not match.", comment: "update password error")

    /// "The new password is required."
    lazy var _the_new_password_cant_empty = NSLocalizedString("The new password can't be empty.", comment: "update password error")

    /// "The private key update failed."
    lazy var _the_private_key_update_failed = NSLocalizedString("The private key update failed.", comment: "update password error")

    /// "Password update failed"
    lazy var _password_update_failed = NSLocalizedString("Password update failed", comment: "update password error")

    /// "Update Notification Email"
    lazy var _update_notification_email = NSLocalizedString("Update Notification Email", comment: "update notification email error title")

    /// "Apply Labels"
    lazy var _apply_labels = NSLocalizedString("Apply Labels", comment: "Title")

    /// "Message headers"
    lazy var _message_headers = NSLocalizedString("Message headers", comment: "Title of the view showing the message header")

    /// "HTML"
    lazy var _message_html = NSLocalizedString("HTML", comment: "Title of the view showing the message HTML source")
    lazy var _message_body = NSLocalizedString("Message body", comment: "Title of the view showing the message body")

    /// "Confirm phishing report"
    lazy var _confirm_phishing_report = NSLocalizedString("Confirm phishing report", comment: "alert title")

    /// "Reporting a message as a phishing attempt will send the message to us, so we can analyze it and improve our filters. This means that we will be able to see the contents of the message in full."
    lazy var _reporting_a_message_as_a_phishing_ = NSLocalizedString("Reporting a message as a phishing attempt will send the message to us, so we can analyze it and improve our filters. This means that we will be able to see the contents of the message in full.", comment: "alert message")

    /// "Verification error"
    lazy var _verification_error = NSLocalizedString("Verification error", comment: "error title")

    /// "Verification of this content’s signature failed"
    lazy var _verification_of_this_contents_signature_failed = NSLocalizedString("Verification of this content’s signature failed", comment: "error details")

    /// "Decryption error"
    lazy var _decryption_error = NSLocalizedString("Decryption error", comment: "error title")

    /// "Decryption of this content failed"
    lazy var _decryption_of_this_content_failed = NSLocalizedString("Decryption of this content failed", comment: "error details")
    lazy var _decryption_of_this_message_failed = NSLocalizedString("Decryption of this message's encrypted content failed.", comment: "error details")

    /// "Logs"
    lazy var _logs = NSLocalizedString("Logs", comment: "error title")

    /// "normal attachments"
    lazy var _normal_attachments = NSLocalizedString("normal attachments", comment: "Title")

    /// "in-line attachments"
    lazy var _inline_attachments = NSLocalizedString("inline attachments", comment: "Title")

    lazy var _from_your_photo_library = NSLocalizedString("From your photo library", comment: "Title")
    lazy var _take_new_photo = NSLocalizedString("Take new photo", comment: "Title")
    lazy var _import_from = NSLocalizedString("Import from…", comment: "Title")

    lazy var _attachment_limit = NSLocalizedString("Attachment limit", comment: "Alert title")
    /// "The total attachment size cannot exceed 25MB"
    lazy var _the_total_attachment_size_cant_be_bigger_than_25mb = NSLocalizedString("The size limit for attachments is 25 MB.", comment: "Description")

    /// "Can't load the file"
    lazy var _cant_load_the_file = NSLocalizedString("Can't load the file", comment: "Error")

    /// "Can't open the file"
    lazy var _cant_open_the_file = NSLocalizedString("Can't open the file", comment: "Error")

    lazy var _learn_more = NSLocalizedString("Learn more", comment: "Action")

    /// "Retry"
    lazy var _retry = NSLocalizedString("Retry", comment: "Action")

    /// On Fri, Jul 23, 2021 at 3:40 PM
    /// %@ is 12-hour clock or 24-hour clock
    lazy var _reply_time_desc = NSLocalizedString("'On' E, MMM d, yyyy 'at' %@", comment: "reply time template, e.g. On Fri, Jul 23, 2021 at 3:40 PM. E, M...yyyy is date formate")

    /// "Message expired"
    lazy var _message_expired = NSLocalizedString("Message expired", comment: "")

    /// "This message will expire in %dD %dH %dM"
    lazy var _expires_in_days_hours_mins_seconds = NSLocalizedString("This message will expire in %dD %dH %dM", comment: "expiration time count down")

    /// "Sign Out"
    lazy var _sign_out = NSLocalizedString("Sign Out", comment: "Action")

    // "Sending Message"
    lazy var _sending_message = NSLocalizedString("Sending in progress", comment: "Alert title")

    // "Closing"
    lazy var _closing_draft = NSLocalizedString("Closing", comment: "the message will show when closing a draft from the share extension")

    // "This can take a while, please do not dismiss the app"
    lazy var _please_wait_in_foreground = NSLocalizedString("Please keep Proton Mail open until the operation is done.", comment: "Alert message")

    /// "Bug Report Received"
    lazy var _bug_report_received = NSLocalizedString("Bug Report Received", comment: "Title")

    /// "Thank you for submitting a bug report.  We have added your report to our bug tracking system."
    lazy var _thank_you_for_submitting_a_bug_report_we_have_added_your_report_to_our_bug_tracking_system = NSLocalizedString("Thank you for submitting a bug report.  We have added your report to our bug tracking system.", comment: "")

    /// "Offline Callback On Bug Report"
    lazy var _offline_bug_report = NSLocalizedString("Offline", comment: "Title of the alert when the device is offline")

    /// "Label as…"
    lazy var _label_as_ = NSLocalizedString("Label as…", comment: "Title")

    /// "Move to…"
    lazy var _move_to_ = NSLocalizedString("Move to…", comment: "Title")

    /// "Mark as unread"
    lazy var _mark_as_unread_read = NSLocalizedString("Mark as read/unread", comment: "Action")

    /// "Move to Archive"
    lazy var _move_to_archive = NSLocalizedString("Move to archive", comment: "Action title of move to archive")

    /// "Move to Spam"
    lazy var _move_to_spam = NSLocalizedString("Move to spam", comment: "Action title of move to spam")

    lazy var _none = NSLocalizedString("None", comment: "Action title of none")

    /// "Can't load share content!"
    lazy var _cant_load_share_content = NSLocalizedString("Failed to load content!\nPlease try again.", comment: "This is a generic error when the user uses share feature. It is like when you share files from Dropbox but cant read the file correctly")

    /// "Failed to determine type of file"
    lazy var _failed_to_determine_file_type = NSLocalizedString("Failed to determine type of file", comment: "Error message")

    /// "Unsupported file type"
    lazy var _unsupported_file = NSLocalizedString("Unsupported file type", comment: "Error message")

    /// "Can't copy the file"
    lazy var _cant_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")

    /// "Copy address"
    lazy var _copy_address    = NSLocalizedString("Copy address", comment: "Title")
    /// "Copy name"
    lazy var _copy_name       = NSLocalizedString("Copy name", comment: "Title")
    lazy var _general_copy = NSLocalizedString("Copy", comment: "Title")
    lazy var _general_cut = NSLocalizedString("Cut", comment: "Title")
    /// "Add to contacts"
    lazy var _add_to_contacts = NSLocalizedString("Add to contacts", comment: "Title")
    /// "Sender Verification Failed"
    lazy var _sender_verification_failed = NSLocalizedString("Sender Verification Failed", comment: "encryption lock description")
    /// "End-to-end encrypted message"
    lazy var _end_to_end_encrypted_message = NSLocalizedString("End-to-end encrypted message", comment: "encryption lock description")

    // MARK: - Composer expiration warning
    lazy var _expiration_not_supported = NSLocalizedString("Expiration not supported", comment: "alert title")
    lazy var _we_recommend_setting_up_a_password = NSLocalizedString("We recommend setting up a password instead for the following recipients:", comment: "alert body before list of addresses")
    lazy var _we_recommend_setting_up_a_password_or_disabling_pgp = NSLocalizedString("We recommend setting up a password instead, or disabling PGP for the following recipients:", comment: "alert body before list of addresses")
    lazy var _extra_addresses = NSLocalizedString("+%d others", comment: "alert body for how many extra mail addresses, e.g. +3 others")

    // MARK: - Notifcations Snooze feature
    lazy var _general_notifications = NSLocalizedString("Notifications", comment: "A option title that enable/disable notification feature")

    // MARK: - VoiceOver
    lazy var _folders = NSLocalizedString("Folders", comment: "VoiceOver: email belongs to folders")
    /// "Labels"
    lazy var _labels = NSLocalizedString("Labels", comment: "VoiceOver: email has lables")

    // MARK: - IAP

    lazy var _iap_bugreport_title = NSLocalizedString("Is this bug report about an in-app purchase?", comment: "Error message")

    lazy var _iap_bugreport_user_agreement = NSLocalizedString("Our Customer Support team will try to activate your service plan manually if you agree to attach technical data that App Store provided to the app at the moment of purchase. This data does not include any details about your iTunes account, Apple ID, linked payment cards, or any other user information. Technical data only helps us check and verify that the transaction was fulfilled on the App Store's servers.", comment: "Error message")

    lazy var _iap_bugreport_yes = NSLocalizedString("Yes, attach details of payment", comment: "Error message")

    lazy var _iap_bugreport_no = NSLocalizedString("No, not related to in-app purchase", comment: "Error message")

    // contact group

    lazy var _contact_groups_group_name_instruction_label = NSLocalizedString("Group name",
                                                                              comment: "The instruction label for the group name textfield")
    lazy var _contact_groups_new = NSLocalizedString("New group",
                                                     comment: "The title for the contact group creation view")
    lazy var _contact_groups_edit = NSLocalizedString("Edit group",
                                                      comment: "The title for the contact group editing view")
    lazy var _contact_groups_manage_addresses = NSLocalizedString("Manage addresses",
                                                                  comment: "The title for the view where user can manage emails in the contact group")
    lazy var _contact_groups_add_contacts = NSLocalizedString("Add contacts",
                                                                  comment: "The title for the view where user can manage emails in the contact group")

    lazy var _contact_groups_edit_avartar = NSLocalizedString("Edit avatar",
                                                              comment: "The title for the view where user can select the color for the group")
    lazy var _contact_groups_delete = NSLocalizedString("Delete contact group",
                                                        comment: "The description of the button for deleting the contact group")

    lazy var _contact_groups_member_count_description = NSLocalizedString("%d member",
                                                                          comment: "How many members in the contact group, e.g. 0 member, 2 members")

    lazy var _contact_group_no_contact_group_associated_with_contact_email = NSLocalizedString("None",
                                                                                               comment: "A *short* description saying that there is no contact group associated with this contact email")

    // contact group errors

    lazy var _contact_groups_no_email_selected = NSLocalizedString("Please select at least one email for the contact group",
                                                                   comment: "The message will show up when the user attempts to create a contact group without any email selected")
    lazy var _contact_groups_no_name_entered = NSLocalizedString("Please provide a group name",
                                                                 comment: "The message will show up when the user attempts to create a contact group without any name specified")

    lazy var _contact_groups_api_update_error = NSLocalizedString("Can't update contact group through the API",
                                                                  comment: "The error message will be shown when the update of the contact group through API failed")

    // general error
    lazy var _cannot_get_coredata_context = NSLocalizedString("Can't delete contact group through API",
                                                              comment: "The error message will be shown when the deletionn of the contact group through API failed")
    lazy var _type_casting_error = NSLocalizedString("Type casting error",
                                                     comment: "Internal type casting error")
    lazy var _internal_error = NSLocalizedString("Internal Error",
                                                 comment: "The preconditions are not met")

    // Drag and drop
    lazy var _drop_here = NSLocalizedString("+ Drop here to add as attachment", comment: "Drag and drop zone for attachments")

    lazy var _importing_drop = NSLocalizedString("Importing attachment, that can take a while", comment: "Drag and drop zone for attachments")

    lazy var _drop_finished = NSLocalizedString("Attachment imported", comment: "Drag and drop zone for attachments")

    /// Invalid URL
    lazy var _invalid_url = NSLocalizedString("Invalid URL",
                                              comment: "Invalid URL error when click a url in contact")

    lazy var _general_more = NSLocalizedString("More", comment: "More actions button")

    // Local notifications

    lazy var _message_not_sent_title = NSLocalizedString("Problem sending message", comment: "Local notification title")

    lazy var _message_not_sent_message = NSLocalizedString("We could not send your message, possibly because of a poor network connection. Your message was saved to Drafts and will be sent automatically the next time you open the app.", comment: "Local notification text")

    /// Signout
    lazy var _signout_title = NSLocalizedString("Sign out", comment: "Alert title to confirm signout")
    lazy var _signout_confirmation = NSLocalizedString("You will be switched to %@", comment: "Alert to confirm signout")
    lazy var _signout_confirmation_in_bio = NSLocalizedString("Are you sure you want to sign out?", comment: "Alert to confirm sign out")
    lazy var _signout_confirmation_one_account = NSLocalizedString("Are you sure you want to sign out %@?", comment: "Alert to confirm sign out when only one account signed in")
    lazy var _signout_confirmation_having_pending_message = NSLocalizedString("There are unsent messages that will be lost if you sign out", comment: "Alert to confirm signout with pending message in the queue")

    lazy var _message_list_no_email_selected = NSLocalizedString("Please select at least one email",
                                                                   comment: "The message will show up when the user attempts to apply label/folder in inbox without select any emails")

    lazy var _signout_account_switched_when_token_revoked = NSLocalizedString("Signed out from %@ and signed in with %@", comment: "Alert when auth token is revoked and switch to another")

    lazy var _signout_secondary_account_from_manager_account = NSLocalizedString("Are you sure you want to sign out?", comment: "Alert when sign out non-primary account from account manager")

    // Switch Account
    lazy var _switch_account_by_click_notification = NSLocalizedString("Switched to account '%@'", comment: "Alert when switched account by clicking notification of another account")

    // TrustKit

    lazy var _cert_validation_failed_title = NSLocalizedString("Insecure connection", comment: "Cert pinning failed alert title")
    lazy var _cert_validation_failed_message = NSLocalizedString("TLS certificate validation failed. Your connection may be monitored and the app is temporarily blocked for your safety.\n\nSwitch networks immediately.", comment: "Cert pinning failed alert message")

    lazy var _cert_validation_hardfailed_message = NSLocalizedString("TLS certificate validation failed. Your connection may be monitored and the app is temporarily blocked for your safety.", comment: "Cert pinning failed alert message")

    lazy var _cert_validation_failed_continue = NSLocalizedString("Disable Validation", comment: "Cert pinning failed alert message")

    // Springboard shortcuts
    lazy var _springboard_shortcuts_search = NSLocalizedString("Search", comment: "Springboard (3D Touch) shortcuts action")
    lazy var _springboard_shortcuts_composer = NSLocalizedString("Compose", comment: "Springboard (3D Touch) shortcuts action")

    /// Account Manger
    lazy var _account = NSLocalizedString("Account", comment: "Account manager title")
    lazy var _duplicate_logged_in = NSLocalizedString("The user is already signed in", comment: "Alert when the account is already logged in")

    lazy var _free_account_limit_reached_title = NSLocalizedString("Limit reached", comment: "Title of alert when the free account limit is reached")
    lazy var _free_account_limit_reached = NSLocalizedString("Only two free accounts can be added", comment: "Alert when the free account limit is reached")

    /// New Settings
    lazy var _account_settings = NSLocalizedString("Account settings", comment: "section title in settings")
    lazy var _app_settings = NSLocalizedString("App settings", comment: "section title in settings")
    lazy var _app_general_settings = NSLocalizedString("General settings", comment: "section title in settings")

    lazy var _app_pin = NSLocalizedString("App PIN", comment: "security title in settings")
    lazy var _app_pin_with_touchid = NSLocalizedString("App PIN & Touch ID", comment: "security title in settings")
    lazy var _app_pin_with_faceid = NSLocalizedString("App PIN & Face ID", comment: "security title in settings")

    lazy var _app_language = NSLocalizedString("Language", comment: "cell title in device settings")
    lazy var _combined_contacts = NSLocalizedString("Combined contacts", comment: "cell title in device settings")

    lazy var _swipe_actions = NSLocalizedString("Swipe actions", comment: "cell title in app settings")
    lazy var _alternative_routing = NSLocalizedString("Alternative routing", comment: "cell title in app settings")

    lazy var _addresses = NSLocalizedString("Addresses", comment: "cell title in device settings")
    lazy var _snooze = NSLocalizedString("Snooze", comment: "Cell title in device settings - mute notification until a later time.")
    lazy var _mailbox = NSLocalizedString("Mailbox", comment: "cell title in device settings")

    lazy var _privacy = NSLocalizedString("Privacy", comment: "cell title in device settings")
    lazy var _local_storage_limit = NSLocalizedString("Local storage limit", comment: "cell title in device settings")

    lazy var _push_notification = NSLocalizedString("Notifications", comment: "cell title in device settings")
    lazy var _empty_cache = NSLocalizedString("Clear local cache", comment: "cell title in device setting")
    lazy var _dark_mode = NSLocalizedString("Dark mode", comment: "cell title in app setting")

    // Network troubleshooting
    lazy var _allow_alternative_routing = NSLocalizedString("Allow alternative routing", comment: "network troubleshot cell title")
    lazy var _no_internet_connection = NSLocalizedString("No internet connection", comment: "network troubleshot cell title")

    lazy var _recipient_not_found = NSLocalizedString("Recipient not found", comment: "The error message is shown in composer")
    lazy var _signle_address_invalid_error_content = NSLocalizedString("Invalid email address", comment: "The error message is shown in composer")
    lazy var _address_invalid_error_content = NSLocalizedString("At least one recipient email address is improperly formatted, please double check them.", comment: "incorrect email format error in composer")
    lazy var _address_invalid_error_title = NSLocalizedString("Error sending", comment: "incorrect email format error in composer")

    lazy var _address_in_group_not_found_error = NSLocalizedString("At least one email address in the group could not be found", comment: "incorrect email format error while sending")
    lazy var _address_invalid_error_sending = NSLocalizedString("At least one recipient email address/domain doesn't exist or is badly formatted. Message moved to drafts.", comment: "incorrect email format error while sending")
    lazy var _address_invalid_warning_sending = NSLocalizedString("You have entered at least one invalid email address. Please verify your recipients.", comment: "incorrect email format error while sending")
    lazy var _address_in_group_not_found_warning = NSLocalizedString("At least one email address in the group could not be found.", comment: "incorrect email format error while sending")
    lazy var _address_non_exist_warning = NSLocalizedString("You have entered at least one unknown recipient. Please verify your recipients.", comment: "incorrect email format error while sending")
    lazy var _address_invalid_error_sending_title = NSLocalizedString("Sending failed", comment: "title of incorrect email format error while sending")
    lazy var _address_invalid_error_to_draft_action_title = NSLocalizedString("Go to drafts", comment: "title of alert acton of incorrect email format error")

    lazy var _mailbox_draft_is_uploading = NSLocalizedString("Draft is still uploading…", comment: "title of toast message that user taps the message which is uploading")
    lazy var _mailbox_draft_is_sending = NSLocalizedString("Sending message…", comment: "content of the sending mesage that will display this text on the date label")

    lazy var _unread_action = NSLocalizedString("unread", comment: "The unread title of unread action button in mailbox view")

    lazy var _selected_navogationTitle = NSLocalizedString("%d selected", comment: "The title of navigation bar of mailbox view when selecting messages, singular and plural possible")

    lazy var _mailblox_last_update_time_more_than_1_hour = NSLocalizedString("Updated >1 hour ago", comment: "The title of last update status of more than 1 hour")
    lazy var _mailblox_last_update_time_just_now = NSLocalizedString("Updated just now", comment: "The title of last update status of updated just now")
    lazy var _mailblox_last_update_time = NSLocalizedString("Updated %d min ago", comment: "The title of last update status of updated time")

    lazy var _mailbox_offline_text = NSLocalizedString("You are offline", comment: "The text shown on the mailbox when the device is in offline mode")

    lazy var _mailbox_footer_no_result = NSLocalizedString("Encrypted by Proton", comment: "The footer shown when there is not result in the inbox")

    lazy var _signed_in_as = NSLocalizedString("Signed in as %@", comment: "The text shown on the mailbox when the primary user changed")

    // MARK: - Mailbox action sheet

    lazy var _title_of_star_action_in_action_sheet = NSLocalizedString("Star", comment: "The title of the star action in action sheet")

    lazy var _title_of_unstar_action_in_action_sheet = NSLocalizedString("Unstar", comment: "The title of the star action in action sheet")

    lazy var _title_of_unread_action_in_action_sheet = NSLocalizedString("Mark as unread", comment: "The title of the unread action in action sheet")

    lazy var _title_of_read_action_in_action_sheet = NSLocalizedString("Mark as read", comment: "The title of the read action in action sheet")

    lazy var _title_of_remove_action_in_action_sheet = NSLocalizedString("Move to trash", comment: "The title of the remove action in action sheet")

    lazy var _title_of_move_inbox_action_in_action_sheet = NSLocalizedString("Move to inbox", comment: "The title of the remove action in action sheet")

    lazy var _title_of_delete_action_in_action_sheet = NSLocalizedString("Delete", comment: "The title of the delete action in action sheet")

    lazy var _title_of_spam_action_in_action_sheet = NSLocalizedString("Move to spam", comment: "The title of the spam action in action sheet")

    lazy var _title_of_viewInLightMode_action_in_action_sheet = NSLocalizedString("View message in Light mode", comment: "The title of the view message in light mode action in action sheet")
    lazy var _title_of_viewInDarkMode_action_in_action_sheet = NSLocalizedString("View message in Dark mode", comment: "The title of the view message in dark mode action in action sheet")

    lazy var _settings_alternative_routing_footer = NSLocalizedString("In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@", comment: "The footer of alternative routing setting")
    lazy var _settings_alternative_routing_title = NSLocalizedString("Networking", comment: "The title of alternative routing settings")
    lazy var _settings_alternative_routing_learn = NSLocalizedString("Learn more", comment: "The title of learn more link")

    lazy var _settings_On_title = NSLocalizedString("On", comment: "The title of On setting options")
    lazy var _settings_Off_title = NSLocalizedString("Off", comment: "The title of Off setting options")

    lazy var _settings_detail_re_auth_alert_title = NSLocalizedString("Re-authenticate", comment: "The title of re auth alert")
    lazy var _settings_detail_re_auth_alert_content = NSLocalizedString("Enter your password to make changes", comment: "The content of the re auth alert")
    // MARK: - Banners
    lazy var _banner_title_send_read_receipt = NSLocalizedString("Send read receipt", comment: "Title of the banner which is displayed when sender of the message requests a read receipt")

    lazy var _receipt_sent = NSLocalizedString("Receipt sent", comment: "A label text which is displayed after sending read receipt to sender")

    lazy var _banner_no_internet_connection = NSLocalizedString("We have trouble connecting to the servers. Please reconnect.", comment: "Message of a banner which is displayed on the messages list when offline")

    lazy var _single_message_delete_confirmation_alert_title = NSLocalizedString("Delete message", comment: "Title of message permanent deletion alert, singular")
    lazy var _messages_delete_confirmation_alert_title = NSLocalizedString("Delete %d Messages", comment: "Title of message permanent deletion alert, plural")
    lazy var _messages_delete_confirmation_alert_message = NSLocalizedString("Are you sure you want to delete these %d messages permanently?", comment: "Message of message permanent deletion alert, plural")

    lazy var _settings_notification_email_section_title = NSLocalizedString("Current Recovery Email", comment: "")

    lazy var _settings_recovery_email_empty_alert_title = NSLocalizedString("Recovery enabled", comment: "")
    lazy var _settings_recovery_email_empty_alert_content = NSLocalizedString("Please set a recovery / notification email", comment: "")
    // MARK: - Title of MessageSwipeActions
    lazy var _swipe_action_unread = NSLocalizedString("Unread", comment: "")
    lazy var _swipe_action_read = NSLocalizedString("Read", comment: "")
    lazy var _swipe_action_star = NSLocalizedString("Star", comment: "")
    lazy var _swipe_action_unstar = NSLocalizedString("Unstar", comment: "")

    lazy var _setting_swipe_action_info_title = NSLocalizedString("Set up swipe gestures to access most used actions.", comment: "")

    lazy var _setting_swipe_action_none_selection_title = NSLocalizedString("Tap here to set", comment: "")
    lazy var _setting_swipe_action_none_display_title = NSLocalizedString("Not set", comment: "")
    lazy var _your_folders = NSLocalizedString("Your folders", comment: "The section title of folder manager table")
    lazy var _new_folder = NSLocalizedString("New folder", comment: "The title of create folder page")
    lazy var _edit_folder = NSLocalizedString("Edit folder", comment: "The title of edit folder page")
    lazy var _delete_folder = NSLocalizedString("Delete folder", comment: "The title of delete folder button")
    lazy var _your_labels = NSLocalizedString("Your labels", comment: "The section title of label manager table")
    lazy var _new_label = NSLocalizedString("New label", comment: "The title of create label page")
    lazy var _edit_label = NSLocalizedString("Edit label", comment: "The title of edit label page")
    lazy var _delete_label = NSLocalizedString("Delete label", comment: "The title of delete label button")
    lazy var _reorder = NSLocalizedString("Reorder", comment: "The button to enable label list reorder")
    lazy var _parent_folder = NSLocalizedString("Parent folder", comment: "Setting option title of folder setting page")
    lazy var _delete_folder_message = NSLocalizedString("This action cannot be undone. Emails stored in this folder will not be deleted and can be found in the All Mail folder.", comment: "Alert message when user tries to delete folder")
    lazy var _delete_label_message = NSLocalizedString("This action cannot be undone.", comment: "Alert message when user tries to delete label")
    lazy var _discard_change_message = NSLocalizedString("Any unsaved changes will be lost.", comment: "Alert message when user tries to discard unsaved changes")
    lazy var _color_inherited_from_parent_folder = NSLocalizedString("Inherited from parent folder", comment: "A label message")
    lazy var _creating_folder_not_allowed = NSLocalizedString("Creating folder not allowed", comment: "Alert title")
    lazy var _creating_label_not_allowed = NSLocalizedString("Creating label not allowed", comment: "Alert title")
    lazy var _upgrade_to_create_folder = NSLocalizedString("Please upgrade to a paid plan to use more than 3 folders", comment: "Alert message")
    lazy var _upgrade_to_create_label = NSLocalizedString("Please upgrade to a paid plan to use more than 3 labels", comment: "Alert message")
    lazy var _please_connect_and_retry = NSLocalizedString("Please connect and retry", comment: "Alert message is shown when the device doesn't have network connection")
    lazy var _use_folder_color = NSLocalizedString("Use folder colors", comment: "Option title")
    lazy var _inherit_parent_color = NSLocalizedString("Inherit color from parent folder", comment: "Option title")
    lazy var _select_color = NSLocalizedString("Select color", comment: "section title")

    lazy var _message_body_view_not_connected_text = NSLocalizedString("You are not connected. We cannot display the content of your message.", comment: "")

    lazy var _banner_remote_content_new_title = NSLocalizedString("Load remote content", comment: "The title of loading remote content banner.")
    lazy var _attachment = NSLocalizedString("%d attachment", comment: "e.g. 3 attachments")

    lazy var _remove_attachment_warning = NSLocalizedString("Do you really want to remove this file from attachments?", comment: "")

    lazy var _banner_embedded_image_new_title = NSLocalizedString("Load embedded images", comment: "The title of loading embedded image banner.")
    lazy var _banner_trashed_message_title = NSLocalizedString("This conversation contains trashed messages", comment: "")
    lazy var _banner_non_trashed_message_title = NSLocalizedString("This conversation contains non-trashed messages.", comment: "")

    // MARK: Action sheet group title
    lazy var _action_sheet_group_title_message_actions = NSLocalizedString("Message actions", comment: "")
    lazy var _action_sheet_group_title_manage = NSLocalizedString("Manage", comment: "")
    lazy var _action_sheet_group_title_move_message = NSLocalizedString("Move message", comment: "")
    lazy var _action_sheet_group_title_more = NSLocalizedString("More", comment: "")

    // MARK: Action sheet action title
    lazy var _action_sheet_action_title_reply = NSLocalizedString("Reply", comment: "")
    lazy var _action_sheet_action_title_replyAll = NSLocalizedString("Reply all", comment: "")
    lazy var _action_sheet_action_title_forward = NSLocalizedString("Forward", comment: "")
    lazy var _action_sheet_action_title_labelAs = NSLocalizedString("Label as…", comment: "")
    lazy var _action_sheet_action_title_trash = NSLocalizedString("Move to trash", comment: "")
    lazy var _action_sheet_action_title_spam = NSLocalizedString("Move to spam", comment: "")
    lazy var _action_sheet_action_title_delete = NSLocalizedString("Delete", comment: "")
    lazy var _action_sheet_action_title_moveTo = NSLocalizedString("Move to…", comment: "")
    lazy var _action_sheet_action_title_print = NSLocalizedString("Print", comment: "")
    lazy var _action_sheet_action_title_saveAsPDF = NSLocalizedString("Save as PDF", comment: "")
    lazy var _action_sheet_action_title_view_headers = NSLocalizedString("View headers", comment: "")
    lazy var _action_sheet_action_title_view_html = NSLocalizedString("View HTML", comment: "")
    lazy var _action_sheet_action_title_phishing = NSLocalizedString("Report phishing", comment: "")
    lazy var _action_sheet_action_title_inbox = NSLocalizedString("Move to inbox", comment: "")
    lazy var _action_sheet_action_title_spam_to_inbox = NSLocalizedString("Not spam (move to inbox)", comment: "")

    lazy var _move_to_done_button_title = NSLocalizedString("Done", comment: "")
    lazy var _move_to_title = NSLocalizedString("Move to", comment: "")
    lazy var _discard_changes_title = NSLocalizedString("Do you want to discard your changes?", comment: "")
    lazy var _changes_will_discarded = NSLocalizedString("Your changes will be discarded", comment: "")

    lazy var _label_as_title = NSLocalizedString("Label as", comment: "")
    lazy var _label_as_also_archive = NSLocalizedString("Also archive?", comment: "Checkbox on Label as action sheet to  prompt if user wants to archive the conversation/message as well when applying one or more labels")
    lazy var _label_as_new_label = NSLocalizedString("New Label", comment: "")

    lazy var _undisclosed_recipients = NSLocalizedString("Undisclosed Recipients", comment: "")

    lazy var _auto_phising_banner_message = NSLocalizedString("Our system flagged this message as a phishing attempt. Please check that it is legitimate.", comment: "")
    lazy var _auto_phising_banner_button_title = NSLocalizedString("Mark as legitimate", comment: "")

    lazy var _autoreply_compact_banner_description = NSLocalizedString("This message was automatically generated", comment: "The title of auto reply banner")

    lazy var _dmarc_failed_banner_message = NSLocalizedString("This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded.", comment: "The error message that the incoming mail failed dmarc authentication")
    lazy var _discard_warning = NSLocalizedString("Do you want to discard the changes?", comment: "Warning message")

    lazy var _conversation_settings_footer_title = NSLocalizedString("Group emails from the same conversation together.", comment: "")
    lazy var _conversation_settings_row_title = NSLocalizedString("Conversation grouping", comment: "")
    lazy var _conversation_settings_title = NSLocalizedString("Conversation mode", comment: "")
    lazy var _account_settings_undo_send_row_title = NSLocalizedString("Undo send", comment: "")

    lazy var _security_protection_title_none = NSLocalizedString("None", comment: "The protection title of None protection")
    lazy var _security_protection_title_pin = NSLocalizedString("PIN code", comment: "The protection title of PIN code protection")
    lazy var _security_protection_title_faceid = NSLocalizedString("Face ID", comment: "The protection title of Face ID protection")
    lazy var _security_protection_title_touchid = NSLocalizedString("Touch ID", comment: "The protection title of Touch ID protection")

    lazy var _conversation_new_message_button = NSLocalizedString("New Message", comment: "The title of the button that shows in the conversation view when there is new message coming.")
    lazy var _accessibility_list_view_custom_action_of_switch_editing_mode = NSLocalizedString("Switch selection mode", comment: "The string that will be read by VoiceOver if the user wants to switch selection mode.")

    lazy var _yesterday = NSLocalizedString("Yesterday", comment: "")

    // MARK: - Accessibility
    lazy var _menu_open_account_switcher = NSLocalizedString("Open account switcher", comment: "VoiceOver title of account switcher button in the menu")

    lazy var _star_btn_in_message_view = NSLocalizedString("Star", comment: "VoiceOver title of star button in the message view")

    lazy var _attachmets_are_uploading_info = NSLocalizedString("Sending will be available\nwhen attachments are uploaded", comment: "text displayed in composer when attachments are uploading")
    lazy var _attachment_upload_failed_title = NSLocalizedString("Attachment failure", comment: "Alert title when attachment upload failed")
    lazy var _attachment_upload_failed_body = NSLocalizedString("The following files couldn't be attached:", comment: "Alert message when attachment upload failed")

    lazy var _menu_expand_folder = NSLocalizedString("Expand folder", comment: "The title of voice over action of expanding the folder")
    lazy var _menu_collapse_folder = NSLocalizedString("Collapse folder", comment: "The title of voice over action of collapsing the folder")

    lazy var _indox_accessibility_switch_unread = NSLocalizedString("Switch unread filter", comment: "The title of voice over action that switches the unread filter status in the inbox")
    lazy var collalse_message_title_in_converation_view = NSLocalizedString("Collapse message", comment: "The title of button to collapse the expanded message in conversation view for VoiceOver.")

    lazy var _settings_dark_mode_section_title = NSLocalizedString("Appearance", comment: "The title of section inside the dark mode setting page")
    lazy var _settings_dark_mode_title_follow_system = NSLocalizedString("Follow device setting", comment: "The title of follow system option in dark mode setting")
    lazy var _settings_dark_mode_title_force_on = NSLocalizedString("Always on", comment: "The title of always on option in dark mode setting")
    lazy var _settings_dark_mode_title_force_off = NSLocalizedString("Always off", comment: "The title of always off option in dark mode setting")

    lazy var _inbox_swipe_to_trash_banner_title = NSLocalizedString("Message moved to trash", comment: "The title of banner that is shown after using swipe action to trash a message")
    lazy var _inbox_swipe_to_archive_banner_title = NSLocalizedString("1 message moved to archive", comment: "The title of banner that is shown after using swipe action to archive a message")
    lazy var _inbox_swipe_to_spam_banner_title = NSLocalizedString("1 Message moved to spam", comment: "The title of banner that is shown after using swipe action to spam a message")
    lazy var _inbox_swipe_to_move_banner_title = NSLocalizedString("%1$d message moved to %2$@", comment: "The title of swipe banner after swiping to move messages")
    lazy var _inbox_swipe_to_move_conversation_banner_title = NSLocalizedString("%1$d conversation moved to %2$@", comment: "The title of swipe banner after swiping to move conversations")
    lazy var _inbox_swipe_to_label_banner_title = NSLocalizedString("%d message labeled", comment: "The title of swipe banner after swiping to label messages")
    lazy var _inbox_swipe_to_label_conversation_banner_title = NSLocalizedString("%d conversation labeled", comment: "The title of swipe banner after swiping to label conversations")

    lazy var _inbox_action_reverted_title = NSLocalizedString("Action reverted", comment: "The title of toast message that is shown after the undo action is done")
    lazy var _compose_message = NSLocalizedString("Compose message", comment: "An action title shows in ellipsis menu")
    lazy var _empty_trash = NSLocalizedString("Empty Trash", comment: "An action title shows in ellipsis menu")
    lazy var _empty_trash_folder = NSLocalizedString("Empty trash folder", comment: "Alert title")
    lazy var _empty_spam = NSLocalizedString("Empty Spam", comment: "An action title shows in ellipsis menu")
    lazy var _empty_spam_folder = NSLocalizedString("Empty spam folder", comment: "Alert title")
    lazy var _cannot_empty_folder_now = NSLocalizedString("Cannot empty folder right now.", comment: "Warning message")
    lazy var _clean_message_warning = NSLocalizedString("Are you sure you want to permanently delete all messages within '%@'?", comment: "Warning message when users try to empty messages in the folder")
    lazy var _show_full_message = NSLocalizedString("…[Show full message]", comment: "Button title to show full encrypted message body when decryption failed")

    lazy var _token_revoke_noti_title = NSLocalizedString("Signed out of %@", comment: "The title of notification that will show when the token of one account is revoked")
    lazy var _token_revoke_noti_body = NSLocalizedString("Sign in again to keep receiving updates", comment: "The body of notification that will show when the token of one account is revoked")
    lazy var _no_attachment_found = NSLocalizedString("No attachment found", comment: "Alert title when users want to send a message without attachments but contain attachment-related keywords in the message body")
    lazy var _do_you_want_to_send_message_anyway = NSLocalizedString("Do you want to send your message anyway?", comment: "Alert body for no attachment found")

    lazy var _composer_voiceover_show_cc_bcc = NSLocalizedString("Add CC and BCC", comment: "The title of the button in the composer that will show the cc/bcc field when voiceover is on.")
    lazy var _composer_voiceover_close_cc_bcc = NSLocalizedString("Close CC and BCC", comment: "The title of the button in the composer that will close the cc/bcc field when voiceover is on.")
    lazy var _composer_voiceover_select_other_sender = NSLocalizedString("Choose different sender address", comment: "The title of the button in the composer that can select different sender address.")

    lazy var _composer_voiceover_add_pwd = NSLocalizedString("Set mail password", comment: "The voiceiver title of the add password button in the tool bar of composer.")
    lazy var _composer_voiceover_add_exp = NSLocalizedString("Set mail expiration", comment: "The voiceiver title of the add expiration button in the tool bar of composer")
    lazy var _composer_voiceover_add_attachment = NSLocalizedString("Add attachment", comment: "The voiceiver title of the add attachment button in the tool bar of composer")
    lazy var _composer_voiceover_dismiss_keyboard = NSLocalizedString("Dismiss keyboard", comment: "The voiceover title of the dismiss keyboard action")

    lazy var _spam_open_link_title = NSLocalizedString("Warning: suspected fake website", comment: "The title of the link confirmation alert of spam email.")
    lazy var _spam_open_link_content = NSLocalizedString("This link leads to a website that might be trying to steal your information, such as passwords and credit card details.\n%@\n\nFor your security, do not continue.", comment: "The content of the link confirmation alert of spam email.")
    lazy var _spam_open_continue = NSLocalizedString("Ignore warning and continue", comment: "The title of the button to open the link in spam mail.")
    lazy var _spam_open_go_back = NSLocalizedString("Go back (recommended)", comment: "The title of the button to cancel the action of opening the link in spam mail.")

    lazy var _undo_send_description = NSLocalizedString("This feature delays sending your emails, giving you the opportunity to undo send during the selected time frame.", comment: "Description for undo send")
    lazy var _undo_send_seconds_options = NSLocalizedString("%d seconds", comment: "undo send seconds options, e.g. 5 seconds")
    lazy var _edit_scheduled_button_title = NSLocalizedString("Edit", comment: "The button title of the scheduled message banner.")
    lazy var _edit_scheduled_button_message = NSLocalizedString("This message will be sent on %@ at %@", comment: "The title of the scheduled message banner.")

    lazy var _scheduled_message_time_in_minute = NSLocalizedString("In %d minutes", comment: "The title of the time label of the scheduled message that is about to be sent in 30 minutes.")
    lazy var _scheduled_message_time_today = NSLocalizedString("Today, %@", comment: "The title of the time label of the scheduled message that is about to be sent today.")
    lazy var _scheduled_message_time_tomorrow = NSLocalizedString("Tomorrow, %@", comment: "The title of the time label of the scheduled message that is about to be sent tomorrow.")

    lazy var _delete_scheduled_alert_title = NSLocalizedString("Schedule will be removed", comment: "The title of the alert that will be shown when user tries to delete a scheduled message.")
    lazy var _delete_scheduled_alert_message = NSLocalizedString("These %d messages will move to Drafts and have their schedule removed.", comment: "The content of the alert that will be shown when user tries to delete a scheduled message.")
    lazy var _message_moved_to_drafts = NSLocalizedString("%d message moved to Drafts", comment: "Banner message")

    lazy var _composer_send_msg_which_was_schedule_send_title = NSLocalizedString("Send immediately?", comment: "The alert title of the user trying to send a message that was schedule-send.")
    lazy var _composer_send_msg_which_was_schedule_send_message = NSLocalizedString("This message is no longer scheduled to be sent later. If you still want to send it later, you can tap on \"Schedule send\"", comment: "The message of the alert of the user trying to send a message that was schedule-send.")
    lazy var _composer_send_msg_which_was_schedule_send_action_title = NSLocalizedString("Send immediately", comment: "The action title of the alert of the user trying to send a message that was schedule-send.")

    lazy var _schedule_introduction_view_content = NSLocalizedString("You can now schedule your messages to be sent later", comment: "The content of the introducation view of the schedule send")
    lazy var _scheduling_message_title = NSLocalizedString("Scheduling message...", comment: "The title of the banner that will be shown when you schedule a message.")

    lazy var _end_to_send_verified_recipient_of_sent = NSLocalizedString("Sent by you with end-to-end encryption to verified recipient", comment: "The message after tapping the encryption icon.")
    lazy var _zero_access_verified_recipient_of_sent = NSLocalizedString("Sent by Proton Mail with zero-access encryption to verified recipient", comment: "The message after tapping the encryption icon.")
    lazy var _end_to_end_encryption_of_sent = NSLocalizedString("Sent by you with end-to-end encryption", comment: "The message after tapping the encryption icon.")
    lazy var _zero_access_by_pm_of_sent = NSLocalizedString("Sent by Proton Mail with zero-access encryption", comment: "The message after tapping the encryption icon.")
    lazy var _zero_access_of_msg = NSLocalizedString("Stored with zero-access encryption", comment: "The message after tapping the encryption icon.")

    lazy var _end_to_end_encryption_verified_of_received = NSLocalizedString("End-to-end encrypted message from verified sender", comment: "The message after tapping the encryption icon of message received.")
    lazy var _end_to_end_encryption_signed_of_received = NSLocalizedString("End-to-end encrypted and signed message", comment: "The message after tapping the encryption icon of message received.")
    lazy var _pgp_encrypted_verified_of_received = NSLocalizedString("PGP-encrypted message from verified sender", comment: "The message after tapping the encryption icon of message received.")
    lazy var _pgp_encrypted_signed_of_received = NSLocalizedString("PGP-encrypted and signed message", comment: "The message after tapping the encryption icon of message received.")
    lazy var _pgp_signed_verified_of_received = NSLocalizedString("PGP-signed message from verified sender", comment: "The message after tapping the encryption icon of message received.")
    lazy var _pgp_encrypted_of_received = NSLocalizedString("PGP-encrypted message", comment: "The message after tapping the encryption icon of message received.")
    lazy var _pgp_signed_of_received = NSLocalizedString("PGP-signed message", comment: "The message after tapping the encryption icon of message received.")
    lazy var _pgp_signed_verification_failed_of_received = NSLocalizedString("PGP-signed message. Sender verification failed", comment: "The message after tapping the encryption icon of message received.")

    lazy var _end_to_end_encrypted_to_verified_recipient = NSLocalizedString("End-to-end encrypted to verified recipient", comment: "The message after tapping the encryption icon of recipient in composer.")
    lazy var _end_to_end_encrypted_of_recipient = NSLocalizedString("End-to-end encrypted", comment: "The message after tapping the encryption icon of recipient in composer.")
    lazy var _pgp_encrypted_to_verified_recipient = NSLocalizedString("PGP-encrypted to verified recipient", comment: "The message after tapping the encryption icon of recipient in composer.")
    lazy var _pgp_encrypted_to_recipient = NSLocalizedString("PGP-encrypted", comment: "The message after tapping the encryption icon of recipient in composer.")
    lazy var _pgp_signed_to_recipient = NSLocalizedString("PGP-signed", comment: "The message after tapping the encryption icon of recipient in composer.")

    lazy var _encPref_error_internal_user_disable = NSLocalizedString("Email address disabled", comment: "The error message while calculating the encryption preferences")
    lazy var _encPref_error_internal_user_no_apiKey = NSLocalizedString("No keys retrieved for internal user", comment: "The error message while calculating the encryption preferences")
    lazy var _encPref_error_internal_user_no_valid_apiKey = NSLocalizedString("No valid keys retrieved for internal user", comment: "The error message while calculating the encryption preferences")
    lazy var _encPref_error_internal_user_primary_not_pinned = NSLocalizedString("Trusted keys are not valid for sending", comment: "The error message while calculating the encryption preferences")
    lazy var _encPref_error_internal_user_no_valid_wkd_key = NSLocalizedString("No WKD key retrieved for user is valid for sending", comment: "The error message while calculating the encryption preferences")
    lazy var _encPref_error_internal_user_no_valid_pinned_key = NSLocalizedString("The sending key is not valid", comment: "The error message while calculating the encryption preferences")

    lazy var _less_than_1min_in_list_view = NSLocalizedString("<1m", comment: "The time label for message is about to be sent less in 1 minute in the list view.")
    lazy var _less_than_1min_not_in_list_view = NSLocalizedString("less than 1 minute", comment: "The time label for message is about to be sent less in 1 minute not in the list view.")

    lazy var _scheduled_send_message_timeup: String = NSLocalizedString("The message is being sent and will move to the Sent folder once sending is complete.", comment: "The alert title of user trying to open a scheduled-send message after its time is up.")

    lazy var _toolbar_customize_header_title_of_first_section = NSLocalizedString("Toolbar actions (select up to 5)", comment: "The title of the section header in the toolbar customize view.")
    lazy var _toolbar_customize_header_title_of_second_section = NSLocalizedString("Available actions", comment: "The title of the section header in the toolbar customize view.")

    lazy var _toolbar_customize_info_title: String = NSLocalizedString("You can choose and rearrange the actions in your toolbar", comment: "The title of the info bubble view in toolbar customization view.")
    lazy var _toolbar_customize_reset_alert_title: String = NSLocalizedString("Reset to default?", comment: "The title of the alert after tapping reset in toolbar customization view.")
    lazy var _toolbar_customize_reset_alert_content: String = NSLocalizedString("The actions in the toolbar will be reset to default", comment: "The content of the alert after tapping reset in toolbar customization view.")
    lazy var _toolbar_customize_reset_button__title: String = NSLocalizedString("Reset to default", comment: "The title of the reset button in toolbar customization view.")

    lazy var _toolbar_customize_general_title: String = NSLocalizedString("Customize toolbar", comment: "The title of the item in the App settings section of the device setting view.")
    lazy var _toolbar_setting_segment_title_message: String = NSLocalizedString("Message", comment: "The title of the first item in the segment control of the Customize toolbar setting view.")
    lazy var _toolbar_setting_info_title_message: String = NSLocalizedString("This toolbar is visible when reading a message.", comment: "The title of the info label in the first segment of the Customize toolbar setting view.")
    lazy var _toolbar_setting_info_title_inbox: String = NSLocalizedString("This toolbar appears when selecting multiple messages in your inbox.", comment: "The title of the info label in the second segment of the Customize toolbar setting view.")

    lazy var _toolbar_spotlight_content: String = NSLocalizedString("You can now choose and rearrange the actions in this bar", comment: "The content of the Customize toolbar spotlight view.")

    var _title_notification_action_mark_as_read: String {
        L10n.PushNotificationAction.mark_as_read
    }
    var _title_notification_action_archive: String {
        L10n.PushNotificationAction.archive
    }
    var _title_notification_action_move_to_trash: String {
        L10n.PushNotificationAction.move_to_trash
    }
}

enum L10n {
    struct AlertBox {
        static let alertBoxMailPercentageText = NSLocalizedString("Your Mail storage is %@ full", comment: "Title of the banner alert")
        static let alertBoxDrivePercentageText = NSLocalizedString("Your Drive storage is %@ full", comment: "Title of the banner alert")
        static let alertBoxMailFullText = NSLocalizedString("Your Mail storage is full", comment: "Title of the banner alert")
        static let alertBoxDriveFullText = NSLocalizedString("Your Drive storage is full", comment: "Title of the banner alert")
        static let alertBoxDescription = NSLocalizedString("Upgrade to get more storage.", comment: "Description of the banner alert")
        static let alertBoxDismissButtonTitle = NSLocalizedString("Not now", comment: "Get more storage button action")
        static let alertBoxButtonTitle = NSLocalizedString("Get more storage", comment: "Get more storage button action")
    }

    struct DynamicFontSize {
        struct Spotlight {
            static let title = NSLocalizedString("Sized for reading", comment: "Spotlight title")
            static let body = NSLocalizedString("Now the body text of your emails will also be shown in your preferred reading size.", comment: "Spotlight body")
        }
    }

    struct LockedStateAlertBox {
        static let alertBoxMailFullText = NSLocalizedString("Your Mail storage is full", comment: "Title of the banner alert")
        static let alertBoxDriveFullText = NSLocalizedString("Your Drive storage is full", comment: "Title of the banner alert")
        static let alertBoxStorageFullText = NSLocalizedString("Your storage is full", comment: "Title of the banner alert")
        static let alertBoxSubscriptionEndedText = NSLocalizedString("Your subscription has ended", comment: "Title of the banner alert")
        static let alertBoxAccountAtRiskText = NSLocalizedString("Your account is at risk of deletion", comment: "Title of the banner alert")
        static let alertBoxMailFullDescription = NSLocalizedString("To send or receive emails, free up space or upgrade for more storage.", comment: "Description of the banner alert")
        static let alertBoxDriveFullDescription = NSLocalizedString("To upload files, free up space or upgrade for more storage.", comment: "Description of the banner alert")
        static let alertBoxDescriptionForPrimaryAdmin = NSLocalizedString("Upgrade to restore full access and to avoid data loss.", comment: "Description of the banner alert")
        static let alertBoxDescriptionForOrgMember = NSLocalizedString("To avoid data loss, ask your admin to upgrade.", comment: "Description of the banner alert")
        static let alertBoxDefaultButtonTitle = NSLocalizedString("Get more storage", comment: "Get more storage button action")
        static let alertBoxButtonTitleForPrimaryAdmin = NSLocalizedString("Upgrade", comment: "Upgrade button action")
        static let alertBoxButtonTitleForOrgMember = NSLocalizedString("Learn more", comment: "Learn more storage button action")
    }
    struct BlockSender {
        static let blockActionTitleLong = NSLocalizedString("Block messages from this sender", comment: "Button to block a sender")
        static let blockActionTitleShort = NSLocalizedString("Block", comment: "Button to block a sender, keep it short to fit in the UI")
        static let blockListSettingsItem = NSLocalizedString("Block list", comment: "Settings item to open blocked sender list")
        static let blockListScreenTitle = NSLocalizedString("Blocked Senders", comment: "Title of the blocked sender list screen")
        static let cannotRefreshWhileOffline = NSLocalizedString("Update queued, awaiting connectivity...", comment: "Shown when the user attempts to manually refresh the list of blocked senders while offline")
        static let emptyList = NSLocalizedString("No blocked senders", comment: "Placeholder for empty sender list")
        static let explanation = NSLocalizedString("New emails from %@ won’t be delivered and will be permanently deleted. Manage blocked email addresses in settings.", comment: "")
        static let senderIsBlockedBanner = NSLocalizedString("Sender has been blocked", comment: "Banner in the message view")
        static let successfulBlockConfirmation = NSLocalizedString("Sender %@ blocked", comment: "Toast confirming the block")
        static let successfulUnblockConfirmation = NSLocalizedString("Sender %@ unblocked", comment: "Toast confirming the unblock")
        static let unblockActionTitleLong = NSLocalizedString("Unblock sender", comment: "Button to unblock a sender")
        static let unblockActionTitleShort = NSLocalizedString("Unblock", comment: "Button to unblock a sender, keep it short to fit in the UI")
    }

    struct CalendarLandingPage {
        static let headline = NSLocalizedString("Your schedule is worth protecting", comment: "Headline of the Calendar landing page")
        static let subheadline = NSLocalizedString("Your calendar is a record of your life, Proton Calendar helps keep it private.", comment: "Subheadline of the Calendar landing page")
        static let getCalendar = NSLocalizedString("Get Proton Calendar app", comment: "Button to open the App Store page for Proton Calendar")
    }

    struct EmailTrackerProtection {
        static let title = NSLocalizedString("Email tracking protection", comment: "Name of the feature")
        static let no_email_trackers_found = NSLocalizedString("No email trackers found", comment: "Short hint in the header view")
        static let n_email_trackers_blocked = NSLocalizedString("%d email trackers blocked", comment: "Title of the tracker list. Only used if there is at least one tracker.")
        static let email_trackers_can_violate_your_privacy = NSLocalizedString("Email trackers can violate your privacy.", comment: "Tracker protection feature explanation")
        static let proton_found_n_trackers_on_this_message = NSLocalizedString("Proton found %d trackers on this message.", comment: "Tracker protection results")
        static let some_images_failed_to_load = NSLocalizedString("Some images could not be loaded with tracking protection.", comment: "The banner shown in case of proxy failure")
        static let load = NSLocalizedString("Load", comment: "Button inside the banner")
    }

    struct Event {
        static let noTitle = NSLocalizedString("(no title)", comment: "Title of an event with missing title")
        static let organizer = NSLocalizedString("Organizer", comment: "As in: event organizer")
        static let participantCount = NSLocalizedString("%u participants", comment: "Title of the button to expand participant list")
        static let showLess = NSLocalizedString("Show less", comment: "Button to hide some items in the list to conserve screen estate")
        static let eventAlreadyEnded = NSLocalizedString("This event already ended", comment: "Text shown when opening an invitation for a past event")
        static let eventCancelled = NSLocalizedString("This event has been cancelled", comment: "Text shown when opening an invitation for a cancelled event")
        static let attendingPrompt = NSLocalizedString("Attending?", comment: "Prompt above yes/no/maybe buttons")
        static let yesShort = NSLocalizedString("Yes", comment: "Part of a yes/no/maybe prompt")
        static let noShort = NSLocalizedString("No", comment: "Part of a yes/no/maybe prompt")
        static let maybeShort = NSLocalizedString("Maybe", comment: "Part of a yes/no/maybe prompt")
        static let yesLong = NSLocalizedString("Yes, I'll attend", comment: "Confirm attending an event")
        static let noLong = NSLocalizedString("No, I won't attend", comment: "Deny attending an event")
        static let maybeLong = NSLocalizedString("I might attend", comment: "Neither confirm nor deny attending an event")
        static let attendanceOptional = NSLocalizedString("(Attendance optional)", comment: "Information that the user is an optional participant")
        static let every = NSLocalizedString("Every %@", comment: "As in: Every 3 days")
        static let onDays = NSLocalizedString("on %@", comment: "As in: on Saturday")
        static let onThe = NSLocalizedString("on the %@", comment: "As in: on the last Saturday")
        static let onDay = NSLocalizedString("on day %u", comment: "Phrase \"on day\" with an ordinal, e.g. on day 6 of a given month")
        static let times = NSLocalizedString("%d times", comment: "Count, as in: 1 time, 2 times")
        static let until = NSLocalizedString("until %@", comment: "As in: Until Sep 27, 2025")
    }

    // this can be removed once CALIOS-2736 is done
    enum InvitationEmail {
        static let emailInvitationSubjectFullDateWithTimeAndTimeZone = NSLocalizedString(
            "%1@ at %2@ %3@",
            comment: "Event date format used in email sent with an invitation answer. Example: January 28, 2023 at 8:00 PM (GMT+2), where %1@ - month, day, and year, %2@ - hour, %3@ - time zone offset"
        )

        static let accepted = NSLocalizedString("accepted", comment: "Status in an email body sent with an invitation answer")
        static let declined = NSLocalizedString("declined", comment: "Status in an email body sent with an invitation answer")
        static let tentativelyAccepted = NSLocalizedString("tentatively accepted", comment: "Status in an email body sent with an invitation answer")

        enum Body {
            static let content = NSLocalizedString(
                "%1@ has %2@ your invitation to %3@",
                comment: "Body of an email sent with an invitation answer. Format: <event_attendee_email> has <accepted|tentatively accepted|declined> your invitation to <event_title>"
            )

            static let title = NSLocalizedString("You are invited to %@", comment: "Part of the body of the email sent to the participants that indicates the event's title")
            static let location = NSLocalizedString("LOCATION:\n%@", comment: "Part of the body of the email sent to the participants that indicates the event's location")
            static let notes = NSLocalizedString("DESCRIPTION:\n%@", comment: "Part of the body of the email sent to the participants that indicates the event's notes")
        }

        static let cancellationBody = NSLocalizedString("%@ was cancelled.", comment: "Body of the email sent to the participants that indicates the event has been cancelled")

        enum Answer {
            enum Subject {
                static let allDaySingle = NSLocalizedString("Re: Invitation for an event on %@", comment: "Subject of the email sent to the participants invited to a given all-day single event after answering")

                static let other = NSLocalizedString(
                    "Re: Invitation for an event starting on %@",
                    comment: "Subject of an email sent with an invitation answer after answering"
                )
            }
        }
    }

    struct Recurrence {
        static let daily = NSLocalizedString("Daily", comment: "Occurring every day")
        static let weekly = NSLocalizedString("Weekly", comment: "Occurring every week")
        static let monthly = NSLocalizedString("Monthly", comment: "Occurring every month")
        static let yearly = NSLocalizedString("Yearly", comment: "Occurring every year")
        static let first = NSLocalizedString("first", comment: "\"1st\" spelled out")
        static let second = NSLocalizedString("second", comment: "\"2nd\" spelled out")
        static let third = NSLocalizedString("third", comment: "\"3rd\" spelled out")
        static let fourth = NSLocalizedString("fourth", comment: "\"4th\" spelled out")
        static let last = NSLocalizedString("last", comment: "Opposite of \"first\"")
    }

    struct RSVP {
        struct Spotlight {
            static let title = NSLocalizedString("Easily RSVP to events", comment: "Title of the spotlight view")
            static let body = NSLocalizedString("Now you can respond to an invitation or view the event in Proton Calendar with just one tap. ", comment: "Body of the spotlight view")
        }
    }

    struct SideMenuStorageAlert {
        static let menuTitle = NSLocalizedString("Max Storage", comment: "Menu title")
        static let alertBoxMailTitle = NSLocalizedString("Storage: %@ full", comment: "Cell title that shows the percentage of the storage")
        static let alertBoxDriveTitle = NSLocalizedString("Drive: %@ full", comment: "Cell title that shows the percentage of the storage")
        static let alertBoxCaption = NSLocalizedString("Get more storage", comment: "Description of the action")
    }

    struct OfficialBadge {
        static let title = NSLocalizedString("Official", comment: "Official badge next to sender's name")
    }

    struct ReferralProgram {
        static let linkCopied = NSLocalizedString("Link copied.", comment: "The banner title after tapping link copy button in referral share view.")
        static let title = NSLocalizedString("Invite friends to Proton,\n get up to $90 in credits!", comment: "The article title of the referral share view.")
        static let content = NSLocalizedString("Invite your friends to Proton: they try Mail Plus for free, and you earn credits when they subscribe to a paid plan.", comment: "The article content of the referral share view.")
        static let inviteLinkTitle = NSLocalizedString("Your invite link", comment: "The title link of the textfield of the referral link in referral share view.")
        static let shareTitle = NSLocalizedString("Share", comment: "The title of the share button in referral share view.")
        static let trackRewardTitle = NSLocalizedString("Track your rewards", comment: "The title of the track reward button in referral share view.")
        static let termsAndConditionTitle = NSLocalizedString("Terms & conditions", comment: "The title of the terms and conditions button in referral share view.")
        static let shareContent = NSLocalizedString("I’ve been using Proton Mail and thought you might like it. It’s a secure email service that protects your privacy. Sign up with this link to get 1 month of premium features for free:", comment: "The content that is shared through the action: `Share the link`")

        static let promptContent = NSLocalizedString("Your privacy is better protected if your contacts also use Proton Mail. Invite your friends to Proton, and you will each get premium benefits for free.", comment: "The content of the referral prompt view.")
        static let referAFriend = NSLocalizedString("Refer a friend", comment: "The title of the refer button in referral prompt view.")
        static let maybeLater = NSLocalizedString("Maybe later", comment: "The title of the maybe later button in referral prompt view.")
	}

    struct SettingsContacts {
        static let combinedContacts = NSLocalizedString("Combined contacts", comment: "The title of combined contact in settings")
        static let combinedContactsFooter = NSLocalizedString("Turn this feature on to auto-complete email addresses using contacts from all your signed in accounts.", comment: "The footer of combined contact in settings")
        static let autoImportContacts = NSLocalizedString("Auto-import device contacts", comment: "contacts auto import title in settings")
        static let autoImportContactsFooter = NSLocalizedString("Turn this feature on to automatically add new contacts from your device to the Proton Mail app.", comment: "contacts auto import footer in settings")
        static let autoImportAlertTitle = NSLocalizedString("Auto-import enabled", comment: "Auto import alert title")
        static let autoImportAlertMessage = NSLocalizedString("The initial import may take some time and will only occur when the app is in the foreground.", comment: "Auto import alert message")
        static let authoriseContactsInSettingsApp = NSLocalizedString("Access to contacts was disabled. To enable auto-import, go to settings and enable contact permission.", comment: "Alert to ask user to reauthorise access to contacts")
    }

    struct SettingsLockScreen {
        static let protectionTitle = NSLocalizedString("Protection", comment: "Settings lock protection section")
        static let advancedSettings = NSLocalizedString("Advanced settings", comment: "Settings lock advanced settings section")
        static let appKeyProtection = NSLocalizedString("AppKey protection", comment: "Settings lock AppKey feature")
        static let appKeyProtectionDescription = NSLocalizedString("AppKey further protects your Proton information in case of elaborate attacks, such as an attacker cloning the contents of your device. %1$@", comment: "Settings lock AppKey description")
        static let appKeyDisclaimerTitle = NSLocalizedString("Disclaimer", comment: "AppKey disclaimer title when turning on")
        static let appKeyDisclaimer = NSLocalizedString("Notification actions and other background processes will become unavailable", comment: "AppKey disclaimer when turning on")
    }

    struct ScheduledSend {
        static let tomorrow = NSLocalizedString("Tomorrow", comment: "One of schedule time options")
        static let custom = NSLocalizedString("Custom", comment: "Option for set up custom schedule send date")
        static let asSchedule = NSLocalizedString("As scheduled", comment: "One of the schedule time options")
        static let upSellTitle = NSLocalizedString("Set your own schedule", comment: "The title of the up sell content of the scheduled send.")
        static let upSellContent = NSLocalizedString("Unlock custom message scheduling and other benefits when you upgrade your plan.", comment: "The content of the up sell content of the scheduled send.")
        static let upgradeTitle = NSLocalizedString("Upgrade now", comment: "The title of the upgrade button in the schedule send promotion view.")
        static let itemSchedule = NSLocalizedString("Schedule messages at any time", comment: "The up sell bullet point in the schedule send promotion view.")
        static let itemStorage = NSLocalizedString("Up to 500 GB of storage", comment: "The up sell bullet point in the schedule send promotion view.")
        static let itemAddresses = NSLocalizedString("Up to 15 email addresses", comment: "The up sell bullet point in the schedule send promotion view.")
        static let itemDomain = NSLocalizedString("Up to 3 custom email domains", comment: "The up sell bullet point in the schedule send promotion view.")
        static let itemAliases = NSLocalizedString("Hide My Email aliases", comment: "The up sell bullet point in the schedule send promotion view.")
        static let inTheMorning = NSLocalizedString("In the morning", comment: "One of schedule time options")
    }

    struct PushNotificationAction {
        static let mark_as_read = NSLocalizedString("Mark as read", comment: "Push notification action mark as read")
        static let archive = NSLocalizedString("Archive (verb)", comment: "Push notification action archive")
        static let move_to_trash = NSLocalizedString("Move to trash", comment: "Push notification action move to trash")
    }

    struct Settings {
        static let passwordUpdated = NSLocalizedString("Password updated", comment: "Message to show to user after updating password.")
        static let applicationLogs = NSLocalizedString("Application logs", comment: "Title for application logs settings option")
    }

    struct Spotlight {
        static let new = NSLocalizedString("New!", comment: "Badge present on some spotlights")
        static let gotIt = NSLocalizedString("Got it", comment: "Got it action")
    }

    struct NextMsgAfterMove {
        static let settingTitle = NSLocalizedString("Jump to next email", comment: "The title of the setting of the next msg after move")
        static let rowTitle = NSLocalizedString("Jump to next email", comment: "The title of the row inside the setting page of next msg after move function.")
        static let rowFooterTitle = NSLocalizedString("Automatically show the next email when an open email is deleted, archived, or moved.", comment: "The footer title of the setting row of the next msg after move functions.")
        static let spotlightButtonTitle = NSLocalizedString("Turn on feature", comment: "The title of the button of the jump to next message spotlight.")
        static let spotlightMessage = NSLocalizedString("View the next email in your inbox when you delete or move the current email.", comment: "The content of the jump to next message spotlight.")
        static let spotlightTitle = NSLocalizedString("Read emails faster", comment: "The title of the jump to next message spotlight.")
	}

    struct Error {
        static let core_data_setup_generic_messsage = NSLocalizedString("An unexpected error occurred, please contact support.\nError: %@", comment: "Message for error when app set up at launch fails")
        static let core_data_setup_insufficient_disk_title = NSLocalizedString("Insufficient disk space", comment: "Title for error when app set up at launch fails")
        static let core_data_setup_insufficient_disk_messsage = NSLocalizedString("The application cannot open due to insufficient disk space. Please delete some data and try again", comment: "Message for error when app set up at launch fails")
        static let cant_open_message = NSLocalizedString("Couldn't open the message, try again.", comment: "Error message when open message failed")
        static let sign_in_message = NSLocalizedString("Please sign in to the Proton Mail app.", comment: "Error message when user open the share extension without account logged in.")
    }

    struct ActionSheetActionTitle {
        static let reply_in_conversation = NSLocalizedString("Reply (to last message)", comment: "The action title in the action sheet of the reply action in conversation view.")
        static let forward_in_conversation = NSLocalizedString("Forward (last message)", comment: "The action title in the action sheet of the forward action in conversation view.")
        static let replyAll_in_conversation = NSLocalizedString("Reply all (to last message)", comment: "The action title in the action sheet of the reply action in conversation view.")
        static let newMessage = NSLocalizedString("New message", comment: "The action title in the action sheet of the composing new message")
	}

    struct Toolbar {
        static let customizeSpotlight = NSLocalizedString("Customize (verb)", comment: "The action title of the button on the toolbar customization spotlight view. (verb)")
    }

    struct BugReport {
        static let placeHolder = NSLocalizedString(
            "Bug Report Place Holder",
            comment: "The place holder text in the bug report view."
        )
        static let includeLogs = NSLocalizedString(
            "Include logs",
            comment: "Checkbox to attach local application logs to the bug report."
        )
    }

    struct Search {
        static let noResultSubTitle = NSLocalizedString(
            "Try a different search term.",
            comment: "The sub title of the search view if there is no result."
        )
        static let noResultsTitle = NSLocalizedString("No results found", comment: "zero messages matching search query")
    }

    struct AutoDeleteSettings {
        static let settingTitle = NSLocalizedString("Auto-delete", comment: "The title of the setting of the auto-delete option")
        static let rowTitle = NSLocalizedString("Auto-delete unwanted messages", comment: "The title of the row inside the setting page of auto delete option")
        static let rowFooterTitle = NSLocalizedString("Messages in trash or spam longer than 30 days will be automatically deleted.", comment: "The footer title of the setting row of the auto delete option")
        static let enableAlertTitle = NSLocalizedString("Delete messages?", comment: "Title of the alert to confirm enabling of the auto delete option")
        static let enableAlertMessage = NSLocalizedString("This will delete all messages that are in trash or spam for more than 30 days, including messages currently in these folders.", comment: "Message of the alert to confirm enabling of the auto delete option")
        static let enableAlertButton = NSLocalizedString("Enable", comment: "Button to enable auto delete")
    }

    struct AutoDeleteBanners {
        static let freeUpsell = NSLocalizedString("Upgrade to automatically delete messages that have been in trash or spam for more than 30 days.", comment: "Text to advertise the auto delete feature to free users")
        static let learnMore = NSLocalizedString("Learn more", comment: "Title of button to learn more about upgrading for auto delete")

        static let paidPrompt = NSLocalizedString("Automatically delete messages that have been in trash and spam for more than 30 days.", comment: "Text to prompt paid users to enable the auto delete feature")
        static let enableButtonTitle = NSLocalizedString("Enable", comment: "Title of button to enable auto delete option")
        static let noThanksButtonTitle = NSLocalizedString("No, thanks", comment: "Title of button to discard auto delete option")

        static let enabledInfoText = NSLocalizedString("Messages that have been in trash and spam more than 30 days will be automatically deleted.", comment: "Text to inform users they have the auto delete feature enabled")
        static let emptySpam = NSLocalizedString("Empty spam", comment: "Title of button to empty spam folder")
        static let emptyTrash = NSLocalizedString("Empty trash", comment: "Title of button to empty trash folder")
    }

    struct ProtonCalendarIntegration {
        static let downloadCalendarAlert = NSLocalizedString("Download the latest version of the Proton Calendar to open this event", comment: "Alert prompting to update Calendar")
        static let downloadInAppStore = NSLocalizedString("Download in App Store", comment: "Button to open App Store")
        static let openInCalendar = NSLocalizedString("Open in Proton Calendar", comment: "Button to open the Calendar app")
	}

    struct AutoDeleteUpsellSheet {
        static let title = NSLocalizedString("Clear out the junk", comment: "Title of the sheet to advertise the auto delete feature to free users")
        static let description = NSLocalizedString("Automatically clear out messages older than 30 days from trash and spam. Enjoy this and other benefits when you upgrade.", comment: "Text content of the sheet to advertise the auto delete feature to free users")

        static let upsellLineOne = NSLocalizedString("Up to 3 TB of storage", comment: "Text to advertise what upgrading will provide")
        static let upsellLineTwo = NSLocalizedString("Up to 15 email addresses", comment: "Text to advertise what upgrading will provide")
        static let upsellLineFour = NSLocalizedString("Custom email domains", comment: "Text to advertise what upgrading will provide")
        static let upgradeButtonTitle = NSLocalizedString("Upgrade now", comment: "Title of button to upgrade to a paid plan")
    }

    struct Compose {
        static let senderChanged = NSLocalizedString("Sender changed", comment: "Alert title, shows when current sender address in the composer is invalid anymore.")
        static let senderChangedMessage = NSLocalizedString("The original sender of this message is no longer valid. Your message will be sent from your default address %@.", comment: "Alert message, shows when current sender address in the composer is invalid anymore, the placeholder is a mail address.")
        static let blockSenderChangeMessage = NSLocalizedString("Please retry after all attachments are uploaded.", comment: "The alert message that will be shown when user tries to change the sender if there is any attachment being uploaded.")
        static let sendingWithShareExtensionWhileOfflineIsNotSupported = NSLocalizedString("Sending with the Share extension while offline is not supported", comment: "Alert title")
    }

    struct ContactEdit {
        static let displayNamePlaceholder = NSLocalizedString("Display name", comment: "The placeholder for the display name text field in contact edit view.")
        static let firstNamePlaceholder = NSLocalizedString("First name", comment: "The placeholder for the first name text field in contact edit view.")
        static let lastNamePlaceholder = NSLocalizedString("Last name", comment: "The placeholder for the last name text field in contact edit view.")
        static let emptyDisplayNameError = NSLocalizedString("Display name field cannot be empty", comment: "The error message that is shown when no display name provided in contact edit view")
        static let contactNameTooLong = NSLocalizedString("Contact name is too long", comment: "The error message that is shown when display name is too long provided in contact edit view")
        static let addPhoto = NSLocalizedString("Add photo", comment: "The button text for add profile picture in contact edit view")
        static let editPhoto = NSLocalizedString("Edit photo", comment: "The button text for edit profile picture in contact edit view")
    }

    struct MailBox {
        static let selectAll = NSLocalizedString("Select all", comment: "The title of select all button for select all messages feature")
        static let unselectAll = NSLocalizedString("Unselect all", comment: "The title of unselect all button for select all messages feature")
        static let maximumSelectionReached = NSLocalizedString("Maximum selection reached", comment: "Warning message will be shown to user when user try to select more than acceptable message")
        static let noRecipient = NSLocalizedString("No Recipient", comment: "A strings shows on a draft when recipient is empty")
    }

    struct PinCodeSetup {
        static let disablePinCode = NSLocalizedString("Disable PIN code", comment: "The title of PIN code disable view ")
        static let setPinCode = NSLocalizedString("Set PIN code", comment: "The title of PIN code setup1 view ")
        static let repeatPinCode = NSLocalizedString("Repeat PIN code", comment: "The title of PIN code setup2 view ")
        static let enterNewPinCode = NSLocalizedString("Enter new PIN code", comment: "The title of textfield of PIN code setup1")
        static let enterNewPinCodeAssistiveText = NSLocalizedString("Enter a PIN code with min 4 characters and max 21 characters.", comment: "The assistive text of textfield of PIN code setup1")
        static let pinTooShortError = NSLocalizedString("PIN is too short", comment: "The error message of entering a short pin")
        static let pinTooLongError = NSLocalizedString("PIN is too long", comment: "The error message of entering a long pin")
        static let pinMustMatch = NSLocalizedString("The PIN codes must match!", comment: "The error message of entering an invalid password")
        static let enterOldPinCode = NSLocalizedString("Please enter old pin code ", comment: "The textField title when user trying to update its pin code setting")
        static let changePinCode = NSLocalizedString("Change PIN code", comment: "The title of change PIN code option in security settings")
    }

    struct Unsubscribe {
        static let bannerMessage = NSLocalizedString("Unsubscribe from mailing list", comment: "The title of unsubscribe banner")
        static let confirmationTitle = NSLocalizedString("Unsubscribe?", comment: "The title of unsubscribe confirmation")
        static let confirmationMessage = NSLocalizedString("This will unsubscribe you from the mailing list. The sender will be notified to no longer send emails to this address.", comment: "Unsubscribe confirmation message")
    }

    struct AttachmentPreview {
        static let cannotPreviewMessage = NSLocalizedString("Unable to preview this attachment", comment: "Alert telling the user that we are unable to preview this attachment")
        static let downloadingAttachment = NSLocalizedString("Downloading attachment", comment: "Title for banner saying that we are currently downloading the attachment to preview it")
    }

    struct Snooze {
        static let title = NSLocalizedString("Snooze", comment: "The title of the snooze location in the menu")
        static let bannerTitle = NSLocalizedString("Snoozed until %@", comment: "The banner title that is shown in the message detail view.")
        static let buttonTitle = NSLocalizedString("Unsnooze", comment: "The title of the button in the banner that is shown in the message detail view.")
        static let successBannerTitle = NSLocalizedString("Snooze until %@", comment: "A message shows to user after snoozing a conversation on the bottom banner the placeholder is a date, example, Snoozed until Tue, Apr 25, 08:00")
        static let unsnoozeSuccessBannerTitle = NSLocalizedString("Conversation unsnoozed", comment: "Notification banner when user unsnooze a conversation")
        static let snoozeUntil = NSLocalizedString("Snooze until...", comment: "The title of snooze config in action sheet")
        static let laterThisWeek = NSLocalizedString("Later this week", comment: "One of snooze option shows in action sheet")
        static let thisWeekend = NSLocalizedString("This weekend", comment: "One of snooze option shows in action sheet")
        static let nextWeek = NSLocalizedString("Next week", comment: "One of snooze option shows in action sheet")
        static let selectTimeInFuture = NSLocalizedString("Please select a time in the future", comment: "An error message will be shown to user when user select past snooze time")
        static let promotionTitle = NSLocalizedString("Want to snooze any time?", comment: "The title of snooze promotion view")
        static let promotionDesc = NSLocalizedString("Unlock custom snooze times when you upgrade", comment: "The content description of snooze promotion view")
        static let addressBenefit = NSLocalizedString("Up to 15 email addresses/aliases", comment: "The benefit item for snooze promotion view")
        static let folderBenefit = NSLocalizedString("Unlimited folders, labels, and filters", comment: "The benefit item for snooze promotion view")
        static let domainBenefit = NSLocalizedString("Custom email domains", comment: "The benefit item for snooze promotion view")
    }

	struct InlineAttachment {
        static let addAsAttachment = NSLocalizedString("Add it as attachment", comment: "The title of the action option that will make the inline attachment as normal attachment.")
	}

    struct MessageNavigation {
        static let settingTitle = NSLocalizedString("Swipe to next message", comment: "The title in setting page")
        static let settingDesc = NSLocalizedString(
            "Allow navigating through messages by swiping left or right.",
            comment: "Description text for setting"
        )
    }

    struct AutoImportContacts {
        static let spotlightTitle = NSLocalizedString("Your contacts at your fingertips", comment: "The title of the spotlight of the auto import contacts.")
        static let spotlightMessage = NSLocalizedString("No need to leave the app to find an email address. Sync contacts from your device to Proton Mail.", comment: "The message of the spotlight of the auto import contacts.")
        static let spotlightButtonTitle = NSLocalizedString("Enable auto-import", comment: "The title of the button of the spotlight of the auto import contacts.")
        static let noContactTitle = NSLocalizedString("No contacts yet", comment: "The title for no contact hint view")
        static let noContactDesc = NSLocalizedString("Import contacts from your device to send emails and invites with ease.", comment: "The description for no contact hint view")
        static let autoImportContactButtonTitle = NSLocalizedString("Auto-import contacts", comment: "Button title for no contact hint view")
        static let importingTitle = NSLocalizedString("Importing your contacts", comment: "A title show to user after auto import button is clicked but contacts hasn't imported yet")
        static let importingDesc = NSLocalizedString("Your contacts will appear here shortly.", comment: "A message show to user after auto import button is clicked but contacts hasn't imported yet")
        static let contactBannerTitle = NSLocalizedString("Automatically add new contacts from your device.", comment: "The title of the dismissable banner in the contacts view.")
        static let contactBannerButtonTitle = NSLocalizedString("Enable auto-import", comment: "The title of the button of the dismissable banner in the contacts view.")
    }

    struct AccountSettings {
        static let privacyAndData = NSLocalizedString("Privacy and data", comment: "The title of the privacy and data in the account setting.")
        static let storage = NSLocalizedString("Storage", comment: "cell title in device settings")
        static let recoveryEmail = NSLocalizedString("Recovery email", comment: "Title")
        static let loginPassword = NSLocalizedString("Change account password", comment: "settings general section title")
        static let mailboxPassword = NSLocalizedString("Change mailbox password", comment: "settings general section title")
        static let singlePassword = NSLocalizedString("Change password", comment: "settings general section title")
        static let securityKeys = NSLocalizedString("Security keys", comment: "settings general section title")
    }

    enum PremiumPerks {
        static let storage = NSLocalizedString("15 GB storage", comment: "Description of a feature of a paid subscription")
        static let emailAddresses = NSLocalizedString("%u email addresses", comment: "Description of a feature of a paid subscription")
        static let customEmailDomain = NSLocalizedString("Custom email domain", comment: "Description of a feature of a paid subscription")
        static let customEmailDomainSupport = NSLocalizedString("Custom email domain support", comment: "Description of a feature of a paid subscription")
        static let personalCalendars = NSLocalizedString("%u personal calendars", comment: "Description of a feature of a paid subscription")
        static let freePlanPerk = NSLocalizedString("1 GB Storage and 1 email", comment: "Description of a feature of a paid subscription")
        static let endToEndEncryption = NSLocalizedString("End-to-end encryption", comment: "Description of a feature of a paid subscription")
        static let desktopApp = NSLocalizedString("Access to desktop app", comment: "Description of a feature of a paid subscription")
        static let priorityCustomerSupport = NSLocalizedString("Priority customer support", comment: "Description of a feature of a paid subscription")
        static let other = NSLocalizedString("+%u premium features", comment: "Description of a feature of a paid subscription")
        static let nGBTotalStorage = NSLocalizedString("%u GB total storage", comment: "Description of a feature of a paid subscription")
        static let nTBTotalStorage = NSLocalizedString("%u TB total storage", comment: "Description of a feature of a paid subscription")
        static let yearlyFreeStorageBonuses = NSLocalizedString("Yearly free storage bonuses", comment: "Description of a feature of a paid subscription")
        static let yourOwnCustomEmailDomain = NSLocalizedString("Your own custom email domain", comment: "Description of a feature of a paid subscription")
        static let calendarSharing = NSLocalizedString("Calendar sharing", comment: "Description of a feature of a paid subscription")
        static let shortDomain = NSLocalizedString("Your own short @pm.me email alias", comment: "Description of a feature of a paid subscription")
        static let customScheduleAndSnoozeTimes = NSLocalizedString("Custom schedule send and snooze times", comment: "Description of a feature of a paid subscription")
        static let mailDesktopApp = NSLocalizedString("Proton Mail desktop app", comment: "Description of a feature of a paid subscription")
        static let versionHistory = NSLocalizedString("Version history", comment: "Description of a feature of a paid subscription")
        static let sentinelProgram = NSLocalizedString("Proton Sentinel program", comment: "Description of a feature of a paid subscription")
        static let mailAndPremiumFeatures = NSLocalizedString("Proton Mail and all premium productivity features", comment: "Description of a feature of a paid subscription")
        static let driveWithVersionHistory = NSLocalizedString("Proton Drive including version history", comment: "Description of a feature of a paid subscription")
        static let pass = NSLocalizedString("Proton Pass", comment: "Description of a feature of a paid subscription")
        static let vpn = NSLocalizedString("Proton VPN", comment: "Description of a feature of a paid subscription")
        static let mailAutomaticEmailForwarding = NSLocalizedString("Proton Mail with automatic email forwarding", comment: "Description of a feature of a paid subscription")
        static let passDarkWebMonitoring = NSLocalizedString("Proton Pass with Dark Web Monitoring", comment: "Description of a feature of a paid subscription")
        static let vpnMalware = NSLocalizedString("Proton VPN with malware and ad-blocking", comment: "Description of a feature of a paid subscription")
        static let catchAllEmailAddress = NSLocalizedString("Catch-all email address", comment: "Description of a feature of a paid subscription")
        static let colleaguesAvailability = NSLocalizedString("See your colleagues’ availability", comment: "Description of a feature of a paid subscription")
        static let automaticEmailForwarding = NSLocalizedString("Automatic email forwarding", comment: "Description of a feature of a paid subscription")
        static let earlyAccess = NSLocalizedString("Early access to new apps and features", comment: "Description of a feature of a paid subscription")
        static let nGBStoragePerUser = NSLocalizedString("%u GB storage per user", comment: "Description of a feature of a paid subscription")
        static let nEmailAddressesPerUser = NSLocalizedString("%u email addresses per user", comment: "Description of a feature of a paid subscription")
        static let unlimitedFoldersAndLabels = NSLocalizedString("Unlimited folders and labels", comment: "Description of a feature of a paid subscription")
        static let nCustomEmailDmains = NSLocalizedString("%u custom email domains", comment: "Description of a feature of a paid subscription")
        static let desktopAppAndEmailClientSupport = NSLocalizedString("Desktop app and email client support (via IMAP)", comment: "Description of a feature of a paid subscription")

        // carousel
        static let nTimesMoreStorage = NSLocalizedString("%ux more storage", comment: "Description of a feature of a paid subscription")
        static let nTimesMoreStorageDesc = NSLocalizedString("Get %u GB—plenty of space to securely store your messages, files, and photos", comment: "Description of a feature of a paid subscription")
        static let nTimesMoreAddresses = NSLocalizedString("%ux more email addresses", comment: "Description of a feature of a paid subscription")
        static let nTimesMoreAddressesDesc = NSLocalizedString("Create up to %u email addresses, including @pm.me ones, to meet your needs.", comment: "Description of a feature of a paid subscription")
        static let customEmailDomainDesc = NSLocalizedString("Connect your own domain and send your professional or branded emails securely.", comment: "Description of a feature of a paid subscription")
        static let desktopAppDesc = NSLocalizedString("Open your email and calendar with one click and avoid browser distractions.", comment: "Description of a feature of a paid subscription")
        static let labelsDesc = NSLocalizedString("Organize your emails using your preferred filing and labeling system.", comment: "Description of a feature of a paid subscription")
        static let customerSupportDesc = NSLocalizedString("Enjoy faster response time from dedicated support staff should an issue arise.", comment: "Description of a feature of a paid subscription")
    }

    struct PrivacyAndDataSettings {
        static let telemetry = NSLocalizedString("Anonymous telemetry", comment: "The title of the telemetry setting.")
        static let crashReport = NSLocalizedString("Anonymous crash reports", comment: "The title of the crash report setting.")
        static let telemetrySubtitle = NSLocalizedString("To improve our services, we sometimes collect anonymized usage data.", comment: "The subtitle of the anonymous telemetry setting.")
        static let crashReportSubtitle = NSLocalizedString("If the app crashes, a report will be sent to our engineers with details of the cause. These will only be used to improve the app.", comment: "The subtitle of the crash report setting.")
    }

    enum Upsell {
        static let upgradeToPlan = NSLocalizedString("Upgrade to %@", comment: "Title of the upsell page.")
        static let mailPlusDescription = NSLocalizedString("To unlock more storage and premium features.", comment: "Subtitle of the upsell page.")
        static let freePlan = NSLocalizedString("Free", comment: "Shorthand for the free plan, as opposed to a paid plan")
        static let autoRenewalNotice = NSLocalizedString("Auto-renews at the same price and terms unless canceled.", comment: "Auto-renewal notice")
        static let perMonth = NSLocalizedString("/month", comment: "Displayed next to the monthly price")
        static let getPlan = NSLocalizedString("Get %@", comment: "CTA button to purchase a plan (e.g. Get Mail Plus)")
        static let save = NSLocalizedString("Save %u%%", comment: "In the context of a discount")
        static let invalidProductID = NSLocalizedString("Invalid product ID: $@", comment: "Error when trying to purchase an invalid product")
        static let purchaseAlreadyInProgress = NSLocalizedString("Purchase already in progress", comment: "Error when the user tries to purchase a plan before the current transaction is finished")

        // pages
        static let autoDeleteTitle = NSLocalizedString("Clear out old trash and spam", comment: "Title of the upsell page")
        static let autoDeleteDescription = NSLocalizedString("Enjoy a tidier mailbox and benefit from other premium features with %@.", comment: "Subtitle of the upsell page")
        static let contactGroupsTitle = NSLocalizedString("Group your contacts", comment: "Title of the upsell page")
        static let contactGroupsDescription = NSLocalizedString("Easily send emails to a group and enjoy other premium features with %@.", comment: "Subtitle of the upsell page")
        static let labelsTitle = NSLocalizedString("Need more labels or folders?", comment: "Title of the upsell page")
        static let labelsDescription = NSLocalizedString("Get them and other premium features when you upgrade to %@.", comment: "Subtitle of the upsell page")
        static let mobileSignatureTitle = NSLocalizedString("Customize your signature", comment: "Title of the upsell page")
        static let mobileSignatureDescription = NSLocalizedString("Use your own mobile signature and enjoy other premium features with %@.", comment: "Subtitle of the upsell page")
        static let scheduleSendTitle = NSLocalizedString("Schedule now, send later", comment: "Title of the upsell page")
        static let scheduleSendDescription = NSLocalizedString("Enjoy custom schedule send and other premium features with %@.", comment: "Subtitle of the upsell page")
        static let snoozeTitle = NSLocalizedString("Bad time for this email?", comment: "Title of the upsell page")
        static let snoozeDescription = NSLocalizedString("Snooze it for a time of your choosing. Get custom snooze and more with %@.", comment: "Subtitle of the upsell page")

        // onboarding
        static let chooseAPlan = NSLocalizedString("Choose a plan", comment: "Title of the upsell page")
        static let annual = NSLocalizedString("Annual", comment: "Refers to an annual billing cycle")
        static let bestValue = NSLocalizedString("Best value", comment: "Label on the Proton Unlimited plan")
        static let nMoreFeatures = NSLocalizedString("%u more features", comment: "Button to expand the feature list")
        static let billedAtEvery = NSLocalizedString("Billed at %1$@ every %2$@", comment: "1st parameter is the full price, 2nd is the cycle: '1 month', '12 months' etc")
        static let premiumValueIncluded = NSLocalizedString("Premium value included", comment: "In the list of premium plan features")
    }
    
    enum ReminderModal {
        static let title = NSLocalizedString("Your subscription is ending soon", comment: "The title of the modal")
        static let subtitle = NSLocalizedString("Reactivate by %@ to keep these features:", comment: "The subtitle of the modal")
        static let reactivateSubscriptionButtonTitle = NSLocalizedString("Reactivate subscription", comment: "Title of the modal button")
        static let successMessage = NSLocalizedString("Subscription reactivated", comment: "Confirmation message after reactivation subscription")
        static let errorMessage = NSLocalizedString("Subscription reactivation failed", comment: "Error message while reactivation subscription")
    }
}
