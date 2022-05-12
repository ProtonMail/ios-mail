//
//  Localization.swift
//  ProtonMail - Created on 4/18/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation

// object for all the localization strings, this avoid some issues with xcode 9 import/export
var LocalString = LocalizedString()

class LocalizedString {

    class func reset() {
        LocalString = LocalizedString()
    }

    // Mark Signup

    // Mark Link Opening Confirmaiton
    lazy var _about_to_open_link = NSLocalizedString("You are about to launch the web browser and navigate to", comment: "link opeining confirmation")
    lazy var _request_link_confirmation = NSLocalizedString("Request link confirmation", comment: "link opeining confirmation")

    // Mark Settings

    /// "%d Minute"
    lazy var _settings_auto_lock_minute  = NSLocalizedString("%d Minute", comment: "auto lock time format")
    /// "%d Minutes"
    lazy var _settings_auto_lock_minutes = NSLocalizedString("%d Minutes", comment: "auto lock time format")
    /// "**********"
    lazy var _settings_secret_x_string   = NSLocalizedString("**********", comment: "secret")
    /// "DisplayName"
    lazy var _settings_displayname_title = NSLocalizedString("DisplayName", comment: "Title in display name settings")
    /// "DISPLAY NAME"
    lazy var _settings_display_name_title = NSLocalizedString("Display Name", comment: "Title in settings")
    /// "Input Display Name…"
    lazy var _settings_input_display_name_placeholder = NSLocalizedString("Input Display Name…", comment: "place holder")
    /// "Signature"
    lazy var _settings_signature_title = NSLocalizedString("Signature", comment: "Title in signature settings")
    /// "Enable Default Signature"
    lazy var _settings_enable_default_signature_title = NSLocalizedString("Enable signature", comment: "Title")
    lazy var _settings_default_signature_placeholder = NSLocalizedString("Enter your signature here", comment: "")
    /// "Mobile Signature"
    lazy var _settings_mobile_signature_title = NSLocalizedString("Mobile Signature", comment: "Mobile Signature title in settings")
    /// "Enable Mobile Signature"
    lazy var _settings_enable_mobile_signature_title = NSLocalizedString("Enable signature", comment: "Title")
    /// "Notification Email"
    lazy var _settings_notification_email = NSLocalizedString("Recovery email", comment: "Title")
    /// "Enable Notification Email"
    lazy var _settings_notification_email_switch_title = NSLocalizedString("Enable email notices", comment: "Title")
    /// "Input Notification Email …"
    lazy var _settings_notification_email_placeholder = NSLocalizedString("Input Notification Email …", comment: "place holder")
    /// "Current password"
    lazy var _settings_current_password = NSLocalizedString("Current password", comment: "Placeholder")
    /// "New password"
    lazy var _settings_new_password = NSLocalizedString("New password", comment: "Placeholder")
    /// "Confirm new password"
    lazy var _settings_confirm_new_password = NSLocalizedString("Confirm new password", comment: "Placeholder")
    /// "Remove image metadata"
    lazy var _strip_metadata = NSLocalizedString("Remove image metadata", comment: "Settings row")
    /// "Default browser"
    lazy var _default_browser = NSLocalizedString("Default browser", comment: "Settings row")
    /// "Manage in device Settings"
    lazy var _manage_language_in_device_settings = NSLocalizedString("Manage in device Settings", comment: "Settings row")
    /// "Swiping gestures"
    lazy var _settings_swiping_gestures = NSLocalizedString("Swiping gestures", comment: "Swiping gestures")

    lazy var _networking = NSLocalizedString("Networking", comment: "section title ")

    // Mark Menu
    lazy var _menu_button         = NSLocalizedString("Menu", comment: "menu title")
    /// "Report a bug"
    lazy var _menu_bugs_title     = NSLocalizedString("Report a bug", comment: "menu title")
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

    // Mark Message localtion

    /// "All Mail"
    lazy var _locations_all_mail_title = NSLocalizedString("All Mail", comment: "mail location title")
    /// "INBOX"
    lazy var _locations_inbox_title    = NSLocalizedString("INBOX", comment: "mail location title")
    /// "STARRED"
    lazy var _locations_starred_title  = NSLocalizedString("STARRED", comment: "mail location title")
    /// "DRAFTS"
    lazy var _locations_draft_title    = NSLocalizedString("DRAFTS", comment: "mail location title")
    /// "SENT"
    lazy var _locations_outbox_title   = NSLocalizedString("SENT", comment: "mail location title")
    /// "TRASH"
    lazy var _locations_trash_title    = NSLocalizedString("TRASH", comment: "mail location title")
    /// "ARCHIVE"
    lazy var _locations_archive_title  = NSLocalizedString("ARCHIVE", comment: "mail location title")
    /// "SPAM"
    lazy var _locations_spam_title     = NSLocalizedString("SPAM", comment: "mail location title")
    /// "Trash"
    lazy var _locations_trash_desc    = NSLocalizedString("Trash", comment: "mail location desc")
    /// "Add Star"
    lazy var _locations_add_star_action     = NSLocalizedString("Add Star", comment: "mark message star")
    /// "Move to Archive"
    lazy var _locations_move_archive_action = NSLocalizedString("Move to Archive", comment: "move action")

    // Mark Messages

    /// "Message sent"
    lazy var _message_sent_ok_desc          = NSLocalizedString("Message sent", comment: "Description after message have been sent")
    lazy var _message_move_to_draft = NSLocalizedString("Your message has been moved to drafts", comment: "Description after message have been moved to drafts");
    /// "Sent Failed"
    lazy var _message_sent_failed_desc      = NSLocalizedString("Sent Failed", comment: "Description")
    /// "The draft cache is broken please try again"
    lazy var _message_draft_cache_is_broken = NSLocalizedString("The draft cache is broken. Please try again.", comment: "Description")
    /// "No Messages"
    lazy var _messages_no_messages = NSLocalizedString("No Messages", comment: "message when mailbox doesnt have emailsß")
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
    /// "Fwd:"
    lazy var _composer_short_forward = NSLocalizedString("Fwd:", comment: "abbreviation of forward:")
    /// "Fw:"
    lazy var _composer_short_forward_shorter = NSLocalizedString("Fw:", comment: "abbreviation of forward:")
    /// "wrote:"
    lazy var _composer_wrote = NSLocalizedString("wrote:", comment: "Title")

    /// "At {time}, e.g.: At 19:00"
    lazy var _composer_forward_header_at = NSLocalizedString("At %@", comment: "At {time}, e.g.: At 19:00")
    /// "On {date}, e.g.: On Aug 14"
    lazy var _composer_forward_header_on = NSLocalizedString("On %@", comment: "On {date}, e.g.: On Aug 14")
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
    /// "Set a password to encrypt this message for non-ProtonMail users."
    lazy var _composer_eo_desc       = NSLocalizedString("Set a password to encrypt this message for non-ProtonMail users.", comment: "Description")
    /// "Get more information"
    lazy var _composer_eo_info       = NSLocalizedString("Get more information", comment: "Action")
    /// "Message Password"
    lazy var _composer_eo_msg_pwd_placeholder = NSLocalizedString("Message Password", comment: "Placeholder")
    lazy var _composer_eo_msg_pwd_hint = NSLocalizedString("8 to 21 characters long", comment: "Placeholder")
    lazy var _composer_eo_msg_pwd_length_error = NSLocalizedString("The password must be between 8 and 21 characters long", comment: "Error message")
    lazy var _composer_eo_repeat_pwd = NSLocalizedString("Repeat password", comment: "textview title")
    lazy var _composer_eo_repeat_pwd_placeholder = NSLocalizedString("Passwords must match", comment: "Placeholder")
    lazy var _composer_eo_repeat_pwd_match_error = NSLocalizedString("The 2 passwords are not matching", comment: "Error message")
    /// "Password is required."
    lazy var _composer_eo_empty_pwd_desc = NSLocalizedString("Password cannot be empty.", comment: "Description")
    lazy var _composer_eo_remove_pwd = NSLocalizedString("Remove password", comment: "action title")
    /// "Confirm Password"
    lazy var _composer_eo_confirm_pwd_placeholder = NSLocalizedString("Confirm Password", comment: "Placeholder")
    /// "Message password does not match."
    lazy var _composer_eo_dismatch_pwd_desc       = NSLocalizedString("Message password does not match.", comment: "Description")
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
    /// "Change sender address to .."
    lazy var _composer_change_sender_address_to = NSLocalizedString("Change sender address to ..", comment: "Title")
    /// "Upgrade to a paid plan to send from your %@ address"
    lazy var _composer_change_paid_plan_sender_error = NSLocalizedString("Upgrade to a paid plan to send from your %@ address", comment: "Error")
    /// "Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@"
    lazy var _composer_sending_messages_from_a_paid_feature = NSLocalizedString("Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@", comment: "pm.me upgrade warning in composer")
    /// "From"
    lazy var _composer_from_label = NSLocalizedString("From", comment: "Title")
    /// "To"
    lazy var _composer_to_label = NSLocalizedString("To", comment: "Title")
    /// "Cc"
    lazy var _composer_cc_label = NSLocalizedString("Cc", comment: "Title")
    /// "Bcc"
    lazy var _composer_bcc_label = NSLocalizedString("Bcc", comment: "Title")
    /// "Subject"
    lazy var _composer_subject_placeholder = NSLocalizedString("Subject", comment: "Placeholder")
    lazy var _composer_draft_saved = NSLocalizedString("Draft saved", comment: "hint message")
    lazy var _composer_draft_moved_to_trash = NSLocalizedString("Draft moved to trash", comment: "hint message")
    lazy var _composer_draft_restored = NSLocalizedString("Draft restored", comment: "hint message")
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
    /// "Profile picture"
    lazy var _contacts_add_profile_picture = NSLocalizedString("Add photo", comment: "The button text for add profile picture")
    lazy var _contacts_edit_profile_picture = NSLocalizedString("Edit photo", comment: "The button text for edit profile picture")
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

    /// "API Server not reachable…"
    lazy var _general_api_server_not_reachable = NSLocalizedString("API Server not reachable…", comment: "when server not reachable")
    /// "Access to this account is disabled due to non-payment. Please log in through protonmail.com to pay your outstanding invoice(s)."
    lazy var _general_account_disabled_non_payment = NSLocalizedString("Access to this account is disabled due to non-payment. Please sign in through protonmail.com to pay your unpaid invoice.", comment: "error message")
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
    /// "Don't remind me again"
    lazy var _general_dont_remind_action = NSLocalizedString("Don't remind me again", comment: "Action")
    /// "Send"
    lazy var _general_send_action = NSLocalizedString("Send", comment: "Action")
    /// "Send anyway"
    lazy var _send_anyway = NSLocalizedString("Send anyway", comment: "Action")
    /// "Confirmation"
    lazy var _general_confirmation_title = NSLocalizedString("Confirmation", comment: "Title")
    /// "Draft"
    lazy var _general_draft_action = NSLocalizedString("Draft", comment: "Action")
    /// "The request timed out."
    lazy var _general_request_timed_out = NSLocalizedString("The request timed out.", comment: "Title")
    /// "No connectivity detected…"
    lazy var _general_no_connectivity_detected = NSLocalizedString("No connectivity detected…", comment: "Title")
    /// "The ProtonMail current offline…"
    lazy var _general_pm_offline = NSLocalizedString("ProtonMail is currently offline…", comment: "Title")
    /// "Save"
    lazy var _general_save_action = NSLocalizedString("Save", comment: "Title")
    /// "Edit"
    lazy var _general_edit_action = NSLocalizedString("Edit", comment: "Action")
    /// "Create"
    lazy var _general_create_action = NSLocalizedString("Create", comment: "top right action text")

    lazy var _general_message = NSLocalizedString("general_message", comment: "message number")
    lazy var _general_conversation = NSLocalizedString("general_conversation", comment: "conversation number")
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
    /// "Failed to initialize the app's saved data"
    lazy var _error_core_data_save_failed = NSLocalizedString("Failed to initialize the app's saved data", comment: "Description")
    /// "There was an error creating or loading the app's saved data."
    lazy var _error_core_data_load_failed = NSLocalizedString("There was an error creating or loading the app's saved data.", comment: "Description")

    /// "This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded."
    lazy var _messages_spam_100_warning = NSLocalizedString("This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
    /// "This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!"
    lazy var _messages_spam_101_warning = NSLocalizedString("This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
    /// "This message may be a phishing attempt. Please check the sender and contents to make sure they are legitimate."
    lazy var _messages_spam_102_warning = NSLocalizedString("This message may be a phishing attempt. Please check the sender and contents to make sure they are legitimate.", comment: "spam score warning")

    /// "Human Check Failed"
    lazy var _error_human_check_failed = NSLocalizedString("Human Check Failed", comment: "Description")

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

    /// "Do you want to cancel the process?"
    lazy var _contacts_import_cancel_wanring = NSLocalizedString("Do you want to cancel the process?", comment: "Description")

    lazy var _contacts_saved_offline_hint = NSLocalizedString("Contact saved, will be synced when connection is available", comment: "Hint when users create / edit contact offline ")
    lazy var _contacts_deleted_offline_hint = NSLocalizedString("Contact deleted, will be synced when connection is available", comment: "Hint when users delete contact offline ")

    /// "Confirm"
    lazy var _general_confirm_action = NSLocalizedString("Confirm", comment: "Action")

    /// "Cancelling"
    lazy var _contacts_cancelling_title = NSLocalizedString("Cancelling", comment: "Title")

    /// "Unknown"
    lazy var _general_unknown_title = NSLocalizedString("Unknown", comment: "title, default display name")

    /// "Import Error"
    lazy var _contacts_import_error = NSLocalizedString("Import Error", comment: "Action")

    /// "OK"
    lazy var _general_ok_action = NSLocalizedString("OK", comment: "Action")
    lazy var _general_later_action = NSLocalizedString("Later", comment: "Action")

    /// "Email address"
    lazy var _contacts_email_address_placeholder = NSLocalizedString("Email address", comment: "contact placeholder")

    /// "Back"
    lazy var _general_back_action = NSLocalizedString("Back", comment: "top left back button")

    /// "Human Check Warning"
    lazy var _signup_human_check_warning_title = NSLocalizedString("Human Check Warning", comment: "human check warning title")

    /// "Warning: Before you pass the human check you can't sent email!"
    lazy var _signup_human_check_warning = NSLocalizedString("Warning: Before you pass the human check you can't send email!", comment: "human check warning description")

    /// "Check Again"
    lazy var _signup_check_again_action = NSLocalizedString("Check Again", comment: "Action")

    /// "Cancel Check"
    lazy var _signup_cancel_check_action = NSLocalizedString("Cancel Check", comment: "Action")

    /// "None"
    lazy var _general_none = NSLocalizedString("None", comment: "Title")

    /// "Every time the app is accessed"
    lazy var _settings_every_time_enter_app = NSLocalizedString("Every time enter app", comment: "lock app option")

    /// "Default"
    lazy var _general_default = NSLocalizedString("Default", comment: "Title")

    lazy var _general_set = NSLocalizedString("Set", comment: "Title")

    /// "Please use the web version of ProtonMail to change your passwords!"
    lazy var _general_use_web_reset_pwd = NSLocalizedString("Please use the web version of ProtonMail to change your passwords!", comment: "Alert")

    /// "Resetting message cache …"
    lazy var _settings_resetting_cache = NSLocalizedString("Resetting message cache…", comment: "Title")

    /// "This preference will fallback to Safari if the browser of choice will be uninstalled."
    lazy var _settings_browser_disclaimer = NSLocalizedString("This preference will fallback to Safari if the browser of choice will be uninstalled.", comment: "Title")

    lazy var _unsupported_url = NSLocalizedString("The URL you are trying to access is not standard and may not load properly. Do you want to open it using your device's default browser?", comment: "Unsupported url alert message")

    /// "Auto Lock Time"
    lazy var _settings_auto_lock_time = NSLocalizedString("Auto Lock Time", comment: "Title")

    /// "Change default address to .."
    lazy var _settings_change_default_address_to = NSLocalizedString("Change default address to ..", comment: "Title")

    /// "You can't set the %@ address as default because it is a paid feature."
    lazy var _settings_change_paid_address_warning = NSLocalizedString("You can't set %@ address as default because it is a paid feature.", comment: "pm.me upgrade warning in composer")

    /// "Current Language is: "
    lazy var _settings_current_language_is = NSLocalizedString("Current Language is: ", comment: "Change language title")
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

    /// "Upload iOS contacts to ProtonMail?"
    lazy var _upload_ios_contacts_to_protonmail = NSLocalizedString("Upload iOS contacts to ProtonMail?", comment: "Description")

    /// "Delete Contact"
    lazy var _delete_contact = NSLocalizedString("Delete contact", comment: "Title-Contacts")

    /// "PIN code is required."
    lazy var _pin_code_cant_be_empty = NSLocalizedString("PIN code can't be empty.", comment: "Description")


    /// "Unknown Error"
    lazy var _unknown_error = NSLocalizedString("Unknown Error", comment: "Error")
    /// "Load remote content"
    lazy var _load_remote_content = NSLocalizedString("Load remote content", comment: "Action")

    lazy var _setting_change_password = NSLocalizedString("Change password", comment: "title")

    /// "Current signin password"
    lazy var _current_signin_password = NSLocalizedString("Current sign-in password", comment: "Title")

    /// "New signin password"
    lazy var _new_signin_password = NSLocalizedString("New sign-in password", comment: "Title")

    /// "Confirm new signin password"
    lazy var _confirm_new_signin_password = NSLocalizedString("Confirm new sign-in password", comment: "Title")

    /// "New mailbox password"
    lazy var _new_mailbox_password = NSLocalizedString("New mailbox password", comment: "Title")

    /// "Confirm new mailbox password"
    lazy var _confirm_new_mailbox_password = NSLocalizedString("Confirm new mailbox password", comment: "Title")

    /// "Unable to send the email"
    lazy var unable_to_send_the_email = NSLocalizedString("Unable to send the email", comment: "error when sending the message")

    /// "The draft format incorrectly sending failed!"
    lazy var _the_draft_incorrectly_sending_failed = NSLocalizedString("The draft format incorrectly sending failed!", comment: "error when sending the message")

    /// "Star"
    lazy var _star_unstar = NSLocalizedString("Star/unstar", comment: "Title")

    /// "ProtonMail"
    lazy var _protonmail = NSLocalizedString("ProtonMail", comment: "Title")

    /// "Remind Me Later"
    lazy var _remind_me_later = NSLocalizedString("Remind Me Later", comment: "Title")

    /// "Don't Show Again"
    lazy var _dont_show_again = NSLocalizedString("Don't Show Again", comment: "Title")

    // Mark : Onboarding
    lazy var _easily_up_to_date = NSLocalizedString("Easily up-to-date", comment: "Onboarding title")

    lazy var _simply_private = NSLocalizedString("Simply private", comment: "Onboarding title")

    lazy var _neat_and_tidy = NSLocalizedString("Neat and tidy", comment: "Onboarding title")

    lazy var _brand_new_look = NSLocalizedString("New look, same protection", comment: "Onboarding title")

    lazy var _onboarding_conversations = NSLocalizedString("Conversations", comment: "Onboarding title")

    lazy var _and_more = NSLocalizedString("And more…", comment: "Onboarding title")

    lazy var _easily_up_to_date_content = NSLocalizedString("Breeze through threaded messages in conversation mode.", comment: "Onboarding content")

    lazy var _simply_private_content = NSLocalizedString("Enjoy end-to-end encryption with even non-Proton contacts: Invite them to ProtonMail or manually encrypt their messages.", comment: "Onboarding content")

    lazy var _neat_and_tidy_content = NSLocalizedString("File, label, and color code messages to create your perfect, custom inbox.", comment: "Onboarding content")

    lazy var _brand_new_look_content = NSLocalizedString("Your encrypted email has been entirely redesigned for ease of use.", comment: "Onboarding content")

    lazy var _onboarding_conversations_content = NSLocalizedString("Breeze through threaded messages in conversation mode.", comment: "Onboarding content")

    lazy var _and_more_content = NSLocalizedString("Enjoy improvements like dark mode, an unread messages filter, and subfolders.", comment: "Onboarding content")

    lazy var _skip_btn_title = NSLocalizedString("Skip", comment: "skip button title in onboarding page")

    lazy var _next_btn_title = NSLocalizedString("Next", comment: "title of the next button")

    lazy var _get_started_title = NSLocalizedString("Get Started", comment: "title of the next button")

    /// "Unable to edit this message offline"
    lazy var _unable_to_edit_offline = NSLocalizedString("Unable to edit this message offline", comment: "Description")

    /// "Date: %@"
    lazy var _date = NSLocalizedString("Date: %@", comment: "like Date: 2017-10-10")

    /// "Details"
    lazy var _details = NSLocalizedString("Details", comment: "Title")

    /// "Hide Details"
    lazy var _hide_details = NSLocalizedString("Hide details", comment: "Title")

    /// "Phone number"
    lazy var _phone_number = NSLocalizedString("Phone number", comment: "contact placeholder")

    /// "By using ProtonMail, you agree to our (terms and conditions) and (privacy policy)."  -- for later
    lazy var _by_using_protonmail_you_agree_terms_ = NSLocalizedString("By using ProtonMail, you agree to our %@ and %@.", comment: "")

    /// "User is available!"
    lazy var _user_is_available = NSLocalizedString("User is available!", comment: "")

    lazy var _edit_contact = NSLocalizedString("Edit Contact", comment: "Contacts Edit contact")

    /// "Discard changes"
    lazy var _discard_changes = NSLocalizedString("Discard changes", comment: "Action")

    lazy var _general_discard = NSLocalizedString("Discard", comment: "Action")

    /// "Add new url"
    lazy var _add_new_url = NSLocalizedString("Add new URL", comment: "action")

    /// "Message Queue"
    lazy var _message_queue = NSLocalizedString("Message Queue", comment: "settings debug section title")
    /// "Error Logs"
    lazy var _error_logs = NSLocalizedString("Error Logs", comment: "settings debug section title")

    /// "signin Password"
    lazy var _signin_password = NSLocalizedString("Change account password", comment: "settings general section title")
    /// "Mailbox Password"
    lazy var _mailbox_password = NSLocalizedString("Change mailbox password", comment: "settings general section title")
    /// "Single Password"
    lazy var _single_password = NSLocalizedString("Change password", comment: "settings general section title")
    /// "Clear Local Message Cache"
    lazy var _clear_local_message_cache = NSLocalizedString("Clear Local Message Cache", comment: "settings general section title")
    /// "Auto Show Images"
    lazy var _auto_show_images = NSLocalizedString("Auto show remote content", comment: "settings general section title")
    lazy var _auto_show_embedded_images = NSLocalizedString("Auto-load embedded images", comment: "settings general section title")
    /// "Swipe Left to Right"
    lazy var _swipe_left_to_right = NSLocalizedString("Left to Right", comment: "settings swipe actions section title")
    /// "Swipe Right to Left"
    lazy var _swipe_right_to_left = NSLocalizedString("Right to Left", comment: "settings swipe actions section title")
    /// "Enable Touch ID"
    lazy var _enable_touchid = NSLocalizedString("Enable Touch ID", comment: "settings protection section title")
    /// "Enable Pin Protection"
    lazy var _enable_pin_protection = NSLocalizedString("Enable PIN Protection", comment: "settings protection section title")
    /// "Change Pin"
    lazy var _change_pin = NSLocalizedString("Change PIN", comment: "settings protection section title")
    /// "Entire App Protection"
    lazy var _protection_entire_app = NSLocalizedString("Protection Entire App", comment: "settings protection section title")
    /// "Enable Face ID"
    lazy var _enable_faceid = NSLocalizedString("Enable Face ID", comment: "settings protection section title")

    lazy var _unlock_required = NSLocalizedString("Unlock required", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    lazy var _enable_faceid_in_settings = NSLocalizedString("You disabled Face ID in your system settings. Face ID has been used to protect important account information. To access your account, go to settings and reactivate Face ID, or log back in.", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    lazy var _lock_wipe_desc = NSLocalizedString("All protection settings will be reset and wiped upon logging out of the app.", comment: "A description string in pin & faceID setting page")

    lazy var _go_to_settings = NSLocalizedString("Go to settings", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    lazy var _go_to_signin = NSLocalizedString("Go to sign-in", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

    // Mark Settings section title

    /// "Debug"
    lazy var _debug = NSLocalizedString("Debug", comment: "Title")
    /// "General Settings"
    lazy var _general_settings = NSLocalizedString("General Settings", comment: "Title")
    /// "Multiple Addresses"
    lazy var _multiple_addresses = NSLocalizedString("Multiple Addresses", comment: "Title")
    /// "Storage"
    lazy var _storage = NSLocalizedString("Storage", comment: "Title")
    /// "Message Swipe Actions"
    lazy var _message_swipe_actions = NSLocalizedString("Message Swipe Actions", comment: "Title")
    /// "Protection"
    lazy var _protection = NSLocalizedString("Protection", comment: "Title")
    /// "Language"
    lazy var _language = NSLocalizedString("Language", comment: "Title")

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

    /// "Can't get user auth info"
    lazy var _cant_get_user_auth_info = NSLocalizedString("Can't get user auth info", comment: "update password error")

    /// "The Password is wrong."
    lazy var _the_password_is_wrong = NSLocalizedString("The Password is wrong.", comment: "update password error")

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

    /// "Loading…"
    lazy var _loading_ = NSLocalizedString("Loading…", comment: "")


    /// "Can't decrypt this attachment!"
    lazy var _cant_decrypt_this_attachment = NSLocalizedString("Can't decrypt this attachment!", comment: "When quick look attachment but can't decrypt it!")

    /// "Can't find this attachment!"
    lazy var _cant_find_this_attachment = NSLocalizedString("Can't find this attachment!", comment: "when quick look attachment but can't find the data")
    /// "Recovery Email"
    lazy var _recovery_email = NSLocalizedString("Recovery email", comment: "Title")

    /// "Verification error"
    lazy var _verification_error = NSLocalizedString("Verification error", comment: "error title")

    /// "Verification of this content’s signature failed"
    lazy var _verification_of_this_contents_signature_failed = NSLocalizedString("Verification of this content’s signature failed", comment: "error details")

    /// "Decryption error"
    lazy var _decryption_error = NSLocalizedString("Decryption error", comment: "error title")

    /// "Decryption of this content failed"
    lazy var _decryption_of_this_content_failed = NSLocalizedString("Decryption of this content failed", comment: "error details")
    lazy var _decryption_of_this_message_failed = NSLocalizedString("decryption of this message's encrypted content failed.", comment: "error details")

    /// "Logs"
    lazy var _logs = NSLocalizedString("Logs", comment: "error title")

    /// "normal attachments"
    lazy var _normal_attachments = NSLocalizedString("normal attachments", comment: "Title")

    /// "in-line attachments"
    lazy var _inline_attachments = NSLocalizedString("inline attachments", comment: "Title")

    /// "Photo Library"
    lazy var _photo_library = NSLocalizedString("Photo Library", comment: "Title")
    lazy var _from_your_photo_library = NSLocalizedString("From your photo library", comment: "Title")
    lazy var _take_new_photo = NSLocalizedString("Take new photo", comment: "Title")
    lazy var _import_from = NSLocalizedString("Import from…", comment: "Title")

    lazy var _attachment_limit = NSLocalizedString("Attachment limit", comment: "Alert title")
    /// "The total attachment size cannot exceed 25MB"
    lazy var _the_total_attachment_size_cant_be_bigger_than_25mb = NSLocalizedString("The size limit for attachments is 25 MB.", comment: "Description")

    /// "Can't load the file"
    lazy var _cant_load_the_file = NSLocalizedString("Can't load the file", comment: "Error")

    /// "Can't copy the file"
    lazy var _system_cant_copy_the_file = NSLocalizedString("System can't copy the file", comment: "Error")

    /// "Can't open the file"
    lazy var _cant_open_the_file = NSLocalizedString("Can't open the file", comment: "Error")

    lazy var _learn_more = NSLocalizedString("Learn More", comment: "Action")

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
    lazy var _please_wait_in_foreground = NSLocalizedString("Please keep ProtonMail open until the operation is done.", comment: "Alert message")

    /// "Bug Description"
    lazy var _bug_description = NSLocalizedString("Bug Description", comment: "Title")

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

    /// "Share Alert"
    lazy var _share_alert = NSLocalizedString("Error", comment: "Title of alert in share extension.")

    /// "Failed to determine type of file"
    lazy var _failed_to_determine_file_type = NSLocalizedString("Failed to determine type of file", comment: "Error message")

    /// "Unsupported file type"
    lazy var _unsupported_file = NSLocalizedString("Unsupported file type", comment: "Error message")

    /// "Please use ProtonMail App signin first"
    lazy var _please_use_protonmail_app_signin_first = NSLocalizedString("Please use ProtonMail App sign-in first.", comment: "Description")

    /// "Can't copy the file"
    lazy var _cant_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")

    lazy var _no_photo_library_permission_content = NSLocalizedString("ProtonMail needs photo library access in your device settings.", comment: "The message about the app is not having the permission to access photo library")
    lazy var _no_photo_library_permission_title = NSLocalizedString("Forbidden", comment: "The title of alert that the app is not having the permission to access photo library")

    /// "Copy address"
    lazy var _copy_address    = NSLocalizedString("Copy address", comment: "Title")
    /// "Copy name"
    lazy var _copy_name       = NSLocalizedString("Copy name", comment: "Title")
    lazy var _general_copy = NSLocalizedString("Copy", comment: "Title")
    lazy var _general_cut = NSLocalizedString("Cut", comment: "Title")
    /// "Compose to"
    lazy var _compose_to      = NSLocalizedString("Compose to", comment: "Title")
    /// "Add to contacts"
    lazy var _add_to_contacts = NSLocalizedString("Add to contacts", comment: "Title")
    /// "Stored with zero access encryption"
    lazy var _stored_with_zero_access_encryption = NSLocalizedString("Stored with zero access encryption", comment: "encryption lock description")
    /// "Sent by you with end-to-end encryption"
    lazy var _sent_by_you_with_end_to_end_encryption = NSLocalizedString("Sent by you with end-to-end encryption", comment: "encryption lock description")
    /// "Sent by ProtonMail with zero access encryption"
    lazy var _sent_by_protonMail_with_zero_access_encryption = NSLocalizedString("Sent by ProtonMail with zero access encryption", comment: "encryption lock description for auto reply")
    /// "PGP-encrypted message"
    lazy var _pgp_encrypted_signed_message = NSLocalizedString("PGP-encrypted and signed message", comment: "encryption lock description")
    /// "PGP-encrypted message from verified address"
    lazy var _pgp_encrypted_message_from_verified_address = NSLocalizedString("PGP-encrypted message from verified address", comment: "encryption lock description")
    /// "PGP-signed message from verified address"
    lazy var _pgp_signed_message_from_verified_address = NSLocalizedString("PGP-signed message from verified address", comment: "encryption lock description")
    /// "Sender Verification Failed"
    lazy var _sender_verification_failed = NSLocalizedString("Sender Verification Failed", comment: "encryption lock description")
    /// "End-to-end encrypted message"
    lazy var _end_to_end_encrypted_message = NSLocalizedString("End-to-end encrypted message", comment: "encryption lock description")
    lazy var _end_to_end_encrypted_signed_message = NSLocalizedString("End-to-end encrypted and signed message", comment: "encryption lock description")
    /// "End-to-end encrypted message from verified address"
    lazy var _end_to_end_encrypted_message_from_verified_address = NSLocalizedString("End-to-end encrypted message from verified address", comment: "encryption lock description")

    // MARK: - Composer expiration warning
    lazy var _expiration_not_supported = NSLocalizedString("Expiration not supported", comment: "alert title")
    lazy var _we_recommend_setting_up_a_password = NSLocalizedString("We recommend setting up a password instead for the following recipients:", comment: "alert body before list of addresses")
    lazy var _we_recommend_setting_up_a_password_or_disabling_pgp = NSLocalizedString("We recommend setting up a password instead, or disabling PGP for the following recipients:", comment: "alert body before list of addresses")
    lazy var _extra_addresses = NSLocalizedString("+%d others", comment: "alert body for how many extra mail addresses, e.g. +3 others")

    // MARK: - Notifcations Snooze feature
    lazy var _general_notifications = NSLocalizedString("Notifications", comment: "A option title that enable/disable notification feature")
    /// "Snooze Notifications"
    lazy var _snooze_notifications = NSLocalizedString("Snooze Notifications", comment: "settings option")

    // MARK: - VoiceOver
    lazy var _folders = NSLocalizedString("Folders", comment: "VoiceOver: email belongs to folders")
    /// "Labels"
    lazy var _labels = NSLocalizedString("Labels", comment: "VoiceOver: email has lables")
    /// "Starred"
    lazy var _starred = NSLocalizedString("Starred", comment: "VoiceOver: email is starred")

    // MARK: - IAP

    lazy var _iap_unavailable = NSLocalizedString("Subscription information temporarily unavailable. Please try again later.", comment: "Fetch subscription data failed")

    lazy var _iap_disclamer = NSLocalizedString(self._iap_disclamer_private, comment: "Terms of purchase")
    private lazy var _iap_disclamer_private = """
    Upon confirming your purchase, your iTunes account will be charged the amount displayed, which includes ProtonMail Plus, and Apple's in-app purchase fee (Apple charges a fee of approximately 30% on purchases made through your iPhone/iPad).
    After making the purchase, you will automatically be upgraded to ProtonMail Plus for one year period, after which time you can renew or cancel, either online or through our iOS app.
    """

    lazy var _iap_bugreport_title = NSLocalizedString("Is this bug report about an in-app purchase?", comment: "Error message")

    lazy var _iap_bugreport_user_agreement = NSLocalizedString("Our Customer Support team will try to activate your service plan manually if you agree to attach technical data that AppStore provided to the app at the moment of purchase. This data does not include any details about your iTunes account, Apple ID, linked credit cards, or any other user information. Technical data only helps us check and verify that the transaction was fulfilled on the AppStore's servers.", comment: "Error message")

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
    
    lazy var _contact_groups_member_count_description = NSLocalizedString("contact_groups_member_count_description",
                                                                          comment: "The string that describes whether there are 0 or 1 member in the contact group")
    lazy var _contact_groups_selected_group_count_description = NSLocalizedString("%d Selected",
                                                                                  comment: "The string that describes how many contact groups are currently selected")
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

    lazy var _importing = NSLocalizedString("Importing", comment: "Downloading attachments from cloud")

    lazy var _importing_drop = NSLocalizedString("Importing attachment, that can take a while", comment: "Drag and drop zone for attachments")

    lazy var _drop_finished = NSLocalizedString("Attachment imported", comment: "Drag and drop zone for attachments")

    /// Invalid URL
    lazy var _invalid_url = NSLocalizedString("Invalid URL",
                                              comment: "Invalid URL error when click a url in contact")

    lazy var _general_more = NSLocalizedString("More", comment: "More actions button")
    lazy var _general_try_again = NSLocalizedString("Try again", comment: "Try again action")

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

    lazy var _signout_primary_account_from_manager_account_title = NSLocalizedString("Sign out", comment: "Alert title when sign out primary account from account manager")

    lazy var _signout_secondary_account_from_manager_account = NSLocalizedString("Are you sure you want to sign out?", comment: "Alert when sign out non-primary account from account manager")

    // Switch Account
    lazy var _switch_account_by_click_notification = NSLocalizedString("Switched to account '%@'", comment: "Alert when switched account by clicking notification of another account")

    // TrustKit

    lazy var _cert_validation_failed_title = NSLocalizedString("Insecure connection", comment: "Cert pinning failed alert title")
    lazy var _cert_validation_failed_message = NSLocalizedString("TLS certificate validation failed. Your connection may be monitored and the app is temporarily blocked for your safety.\n\nswitch networks immediately", comment: "Cert pinning failed alert message")

    lazy var _cert_validation_hardfailed_message = NSLocalizedString("TLS certificate validation failed. Your connection may be monitored and the app is temporarily blocked for your safety.\n\n", comment: "Cert pinning failed alert message")

    lazy var _cert_validation_failed_continue = NSLocalizedString("Disable Validation", comment: "Cert pinning failed alert message")

    // Springboard shortcuts
    lazy var _springboard_shortcuts_search = NSLocalizedString("Search", comment: "Springboard (3D Touch) shortcuts action")
    lazy var _springboard_shortcuts_starred = NSLocalizedString("Starred", comment: "Springboard (3D Touch) shortcuts action")
    lazy var _springboard_shortcuts_composer = NSLocalizedString("Compose", comment: "Springboard (3D Touch) shortcuts action")

    /// Account Manger
    lazy var _account = NSLocalizedString("Account", comment: "Account manager title")
    lazy var _duplicate_logged_in = NSLocalizedString("The user is already logged in", comment: "Alert when the account is already logged in")

    lazy var _free_account_limit_reached_title = NSLocalizedString("Limit reached", comment: "Title of alert when the free account limit is reached")
    lazy var _free_account_limit_reached = NSLocalizedString("Only one free account can be added", comment: "Alert when the free account limit is reached")

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
    lazy var _mailbox_storage = NSLocalizedString("Storage", comment: "cell title in device settings")

    lazy var _addresses = NSLocalizedString("Addresses", comment: "cell title in device settings")
    lazy var _snooze = NSLocalizedString("Snooze", comment: "Cell title in device settings - mute notification until a later time.")
    lazy var _mailbox = NSLocalizedString("Mailbox", comment: "cell title in device settings")

    lazy var _privacy = NSLocalizedString("Privacy", comment: "cell title in device settings")
    lazy var _local_storage_limit = NSLocalizedString("Local storage limit", comment: "cell title in device settings")

    lazy var _push_notification = NSLocalizedString("Notifications", comment: "cell title in device settings")
    lazy var _empty_cache = NSLocalizedString("Clear local cache", comment: "cell title in device setting")
    lazy var _dark_mode = NSLocalizedString("Dark mode", comment: "cell title in app setting")

    // Network troubleshooting
    lazy var _troubleshooting_title = NSLocalizedString("TroubleShooting", comment: "network troubleshot view title")
    lazy var _allow_alternative_routing = NSLocalizedString("Allow alternative routing", comment: "network troubleshot cell title")
    lazy var _no_internet_connection = NSLocalizedString("No internet connection", comment: "network troubleshot cell title")
    lazy var _isp_problem = NSLocalizedString("Internet Service Provider (ISP) problem", comment: "network troubleshot cell title")
    lazy var _gov_block = NSLocalizedString("Government block", comment: "network troubleshot cell title")
    lazy var _antivirus_interference = NSLocalizedString("Antivirus interference", comment: "network troubleshot cell title")
    lazy var _firewall_interference = NSLocalizedString("Proxy/Firewall interference", comment: "network troubleshot cell title")
    lazy var _proton_is_down = NSLocalizedString("Proton is down", comment: "network troubleshot cell title")
    lazy var _no_solution = NSLocalizedString("Still can't find a solution", comment: "network troubleshot cell title")

    lazy var _allow_alternative_routing_description = NSLocalizedString("In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@", comment: "alternative routing description")
    lazy var _allow_alternative_routing_action_title = NSLocalizedString("Learn more", comment: "alternative routing link name in description")
    lazy var _no_internet_connection_description = NSLocalizedString("Please make sure that your internet connection is working.", comment: "no internet connection description")
    lazy var _isp_problem_description = NSLocalizedString("Try connecting to Proton from a different network (or use %1$@ or %2$@).", comment: "ISP problem description")
    lazy var _gov_block_description = NSLocalizedString("Your country may be blocking access to Proton. Try using %1$@ (or any other VPN) or %2$@ to access Proton.", comment: "Goverment blocking description")
    lazy var _antivirus_interference_description = NSLocalizedString("Temporarily disable or remove your antivirus software.", comment: "Antivirus interference description.")
    lazy var _firewall_interference_description = NSLocalizedString("Disable any proxies or firewalls, or contact your network administrator.", comment: "Firewall interference description.")
    lazy var _proton_is_down_description = NSLocalizedString("Check Proton Status for our system status.", comment: "Proton is down description.")
    lazy var _proton_is_down_action_title = NSLocalizedString("Proton Status", comment: "Name of the link of Proton Status")
    lazy var _no_solution_description = NSLocalizedString("Contact us directly through our support form, email (support@protonmail.zendesk.com), or Twitter.", comment: "No other solution description.")

    lazy var _troubleshoot_support_subject = NSLocalizedString("Subject..", comment: "The subject of the email draft created in the network troubleshoot view.")
    lazy var _troubleshoot_support_body = NSLocalizedString("Please share your problem.", comment: "The body of the email draft created in the network troubleshoot view.")

    lazy var _recipient_not_found = NSLocalizedString("Recipient not found", comment: "The error message is shown in composer")
    lazy var _signle_address_invalid_error_content = NSLocalizedString("Email address is invalid", comment: "The error message is shown in composer")
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
    lazy var _messages_validation_failed_try_again = NSLocalizedString("Message could not be sent. At least one recipient email address/domain doesn't exist or is badly formatted.", comment: "message shown in the notification when the recipient validation is failed while sending")
    lazy var _message_of_unavailable_to_upgrade_url = NSLocalizedString("Plans can be edited on the web version.", comment: "")
    lazy var _week = NSLocalizedString("week", comment: "week")
    lazy var _day = NSLocalizedString("%d day", comment: "day")
    lazy var _days = NSLocalizedString("days", comment: "days")

    lazy var _hour = NSLocalizedString("%d hour", comment: "hour")
    lazy var _hours = NSLocalizedString("hours", comment: "hours")

    lazy var _minute = NSLocalizedString("minute", comment: "minute")

    lazy var _unread_action = NSLocalizedString("unread", comment: "The unread title of unread action button in mailbox view")

    lazy var _selected_navogationTitle = NSLocalizedString("Selected", comment: "The title of navigation bar title of mailbox view while selecting the message")
    lazy var _mailbox_no_result_secondary_label = NSLocalizedString("You're up to date", comment: "The secondary title of no result message")
    lazy var _mailbox_folder_no_result_secondary_label = NSLocalizedString("This folder is empty", comment: "The secondary title of no result message")

    lazy var _mailblox_last_update_time_more_than_1_hour = NSLocalizedString("Updated >1 hour ago", comment: "The title of last update status of more than 1 hour")
    lazy var _mailblox_last_update_time_just_now = NSLocalizedString("Updated just now", comment: "The title of last update status of updated just now")
    lazy var _mailblox_last_update_time = NSLocalizedString("Updated %d min ago", comment: "The title of last update status of updated time")

    lazy var _mailbox_offline_text = NSLocalizedString("You are offline", comment: "The text shown on the mailbox when the device is in offline mode")

    lazy var _mailbox_footer_no_result = NSLocalizedString("Encrypted by Proton", comment: "The footer shown when there is not result in the inbox")

    lazy var _mailbox_no_recipient = NSLocalizedString("No Recipient", comment: "Placeholder if message sender is empty")

    lazy var _signed_in_as = NSLocalizedString("Signed in as %@", comment: "The text shown on the mailbox when the primary user changed")

    // MARK: - Mailbox action sheet

    lazy var _title_of_star_action_in_action_sheet = NSLocalizedString("Star", comment: "The title of the star action in action sheet")

    lazy var _title_of_unstar_action_in_action_sheet = NSLocalizedString("Unstar", comment: "The title of the star action in action sheet")

    lazy var _title_of_unread_action_in_action_sheet = NSLocalizedString("Mark as unread", comment: "The title of the unread action in action sheet")

    lazy var _title_of_read_action_in_action_sheet = NSLocalizedString("Mark as read", comment: "The title of the read action in action sheet")

    lazy var _title_of_remove_action_in_action_sheet = NSLocalizedString("Move to trash", comment: "The title of the remove action in action sheet")

    lazy var _title_of_move_inbox_action_in_action_sheet = NSLocalizedString("Move to inbox", comment: "The title of the remove action in action sheet")

    lazy var _title_of_delete_action_in_action_sheet = NSLocalizedString("Delete", comment: "The title of the delete action in action sheet")

    lazy var _title_of_archive_action_in_action_sheet = NSLocalizedString("Archive", comment: "The title of the archive action in action sheet")

    lazy var _title_of_spam_action_in_action_sheet = NSLocalizedString("Move to spam", comment: "The title of the spam action in action sheet")

    lazy var _title_of_viewInLightMode_action_in_action_sheet = NSLocalizedString("View message in Light mode", comment: "The title of the view message in light mode action in action sheet")
    lazy var _title_of_viewInDarkMode_action_in_action_sheet = NSLocalizedString("View message in Dark mode", comment: "The title of the view message in dark mode action in action sheet")

    lazy var _settings_footer_of_combined_contact = NSLocalizedString("Turn this feature on to auto-complete email addresses using contacts from all your logged in accounts.", comment: "The footer of combined contact in settings")
    lazy var _settings_title_of_combined_contact = NSLocalizedString("Combined contacts", comment: "The title of combined contact in settings")

    lazy var _pin_code_setup1_title = NSLocalizedString("Set PIN code", comment: "The title of PIN code setup1 view ")
    lazy var _pin_code_setup1_textfield_title = NSLocalizedString("Enter new PIN code", comment: "The title of textfield of PIN code setup1")
    lazy var _pin_code_setup1_textfield_assistiveText = NSLocalizedString("Enter a PIN code with min 4 characters and max 21 characters.", comment: "The assistive text of textfield of PIN code setup1")
    lazy var _pin_code_setup1_textfield_pin_too_short = NSLocalizedString("PIN is too short", comment: "The error message of entering a short pin")
    lazy var _pin_code_setup1_textfield_pin_too_long = NSLocalizedString("PIN is too long", comment: "The error message of entering a long pin")

    lazy var _pin_code_setup1_button_title = NSLocalizedString("Continue", comment: "The title of button of PIN code setup1")

    lazy var _pin_code_setup2_title = NSLocalizedString("Repeat PIN code", comment: "The title of PIN code setup2 view ")
    lazy var _pin_code_setup2_textfield_title = NSLocalizedString("Repeat PIN code", comment: "The title of textfield of PIN code setup2")
    lazy var _pin_code_setup2_textfield_invalid_password = NSLocalizedString("The PIN codes must match!", comment: "The error message of entering an invalid password")
    lazy var _pin_code_setup2_button_title = NSLocalizedString("Confirm", comment: "The title of button of PIN code setup2")

    lazy var _settings_alternative_routing_footer = NSLocalizedString("In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@", comment: "The footer of alternative routing setting")
    lazy var _settings_alternative_routing_title = NSLocalizedString("Networking", comment: "The title of alternative routing settings")
    lazy var _settings_alternative_routing_learn = NSLocalizedString("Learn more", comment: "The title of learn more link")

    lazy var _settings_On_title = NSLocalizedString("On", comment: "The title of On setting options")
    lazy var _settings_Off_title = NSLocalizedString("Off", comment: "The title of Off setting options")

    lazy var _settings_change_pin_code_title = NSLocalizedString("Change PIN code", comment: "The title of change PIN code option in security settings")
    lazy var _settings_detail_re_auth_alert_title = NSLocalizedString("Re-authenticate", comment: "The title of re auth alert")
    lazy var _settings_detail_re_auth_alert_content = NSLocalizedString("Enter your password to make changes", comment: "The content of the re auth alert")
    // MARK: - Banners
    lazy var _banner_title_send_read_receipt = NSLocalizedString("Send read receipt", comment: "Title of the banner which is displayed when sender of the message requests a read receipt")

    lazy var _receipt_sent = NSLocalizedString("Receipt sent", comment: "A label text which is displayed after sending read receipt to sender")

    lazy var _banner_no_internet_connection = NSLocalizedString("We have trouble connecting to the servers. Please reconnect.", comment: "Message of a banner which is displayed on the messages list when offline")

    lazy var _single_message_delete_confirmation_alert_title = NSLocalizedString("Delete message", comment: "Title of message permanent deletion alert, singular")
    lazy var _messages_delete_confirmation_alert_title = NSLocalizedString("Delete %d Messages", comment: "Title of message permanent deletion alert, plural")
    lazy var _single_message_delete_confirmation_alert_message = NSLocalizedString("Are you sure you want to delete permanently this message?", comment: "Message of message permanent deletion alert, singular")
    lazy var _messages_delete_confirmation_alert_message = NSLocalizedString("Are you sure you want to delete permanently these %d messages?", comment: "Message of message permanent deletion alert, plural")

    lazy var _settings_notification_email_section_title = NSLocalizedString("Current Recovery Email", comment: "")

    lazy var _settings_recovery_email_empty_alert_title = NSLocalizedString("Recovery enabled", comment: "")
    lazy var _settings_recovery_email_empty_alert_content = NSLocalizedString("Please set a recovery / notification email", comment: "")
    // MARK: - Title of MessageSwipeActions
    lazy var _swipe_action_none = NSLocalizedString("Swipe to set up swipable actions", comment: "")
    lazy var _swipe_action_unread = NSLocalizedString("Unread", comment: "")
    lazy var _swipe_action_read = NSLocalizedString("Read", comment: "")
    lazy var _swipe_action_star = NSLocalizedString("Star", comment: "")
    lazy var _swipe_action_unstar = NSLocalizedString("Unstar", comment: "")
    lazy var _swipe_action_archive = NSLocalizedString("Archive", comment: "")
    lazy var _swipe_action_spam = NSLocalizedString("Spam", comment: "")

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
    lazy var _editing_folder_not_allowed = NSLocalizedString("Editing folder not allowed", comment: "Alert title")
    lazy var _creating_label_not_allowed = NSLocalizedString("Creating label not allowed", comment: "Alert title")
    lazy var _editing_label_not_allowed = NSLocalizedString("Editing label not allowed", comment: "Alert title")
    lazy var _upgrade_to_create_folder = NSLocalizedString("Please upgrade to a paid plan to use more than 3 folders", comment: "Alert message")
    lazy var _upgrade_to_create_label = NSLocalizedString("Please upgrade to a paid plan to use more than 3 labels", comment: "Alert message")
    lazy var _please_connect_and_retry = NSLocalizedString("Please connect and retry", comment: "Alert message is shown when the device doesn't have network connection")
    lazy var _folder_name_duplicated_message = NSLocalizedString("A sub-folder with this name already exists in the destination folder", comment: "Alert message is shown when folder name duplicated")
    lazy var _use_folder_color = NSLocalizedString("Use folder colors", comment: "Option title")
    lazy var _inherit_parent_color = NSLocalizedString("Inherit color from parent folder", comment: "Option title")
    lazy var _select_colour = NSLocalizedString("Select colour", comment: "section title")

    lazy var _message_body_view_not_connected_text = NSLocalizedString("You are not connected. We cannot display the content of your message.", comment: "")

    lazy var _banner_remote_content_title = NSLocalizedString("This message contains remote content.", comment: "")
    lazy var _banner_remote_content_new_title = NSLocalizedString("Load remote content", comment: "The title of loading remote content banner.")
    lazy var _banner_load_remote_content = NSLocalizedString("Load content", comment: "")
    lazy var _one_attachment_list_title = NSLocalizedString("attachment", comment: "")
    lazy var _attachments_list_title = NSLocalizedString("attachments", comment: "")

    lazy var _one_attachment_title = NSLocalizedString("Attachment", comment: "")
    lazy var _attachments_title = NSLocalizedString("Attachments", comment: "")
    lazy var _remove_attachment_warning = NSLocalizedString("Do you really want to remove this file from attachments?", comment: "")

    lazy var _banner_embedded_image_title = NSLocalizedString("This message contains embedded images.", comment: "")
    lazy var _banner_embedded_image_new_title = NSLocalizedString("Load embedded images", comment: "The title of loading embedded image banner.")
    lazy var _banner_remote_and_embedded_title = NSLocalizedString("This message contains remote content and embedded images", comment: "")
    lazy var _banner_load_embedded_image = NSLocalizedString("Load images", comment: "")
    lazy var _banner_trashed_message_title = NSLocalizedString("This conversation contains trashed messages", comment: "")
    lazy var _banner_non_trashed_message_title = NSLocalizedString("This conversation contains non-trashed messages.", comment: "")

    lazy var _message_action_sheet_title_sender = NSLocalizedString("Sender details", comment: "")

    // MARK: Action sheet action title
    lazy var _action_sheet_action_title_archive = NSLocalizedString("Archive", comment: "")
    lazy var _action_sheet_action_title_reply = NSLocalizedString("Reply", comment: "")
    lazy var _action_sheet_action_title_replyAll = NSLocalizedString("Reply all", comment: "")
    lazy var _action_sheet_action_title_forward = NSLocalizedString("Forward", comment: "")
    lazy var _action_sheet_action_title_labelAs = NSLocalizedString("Label as…", comment: "")
    lazy var _action_sheet_action_title_trash = NSLocalizedString("Move to trash", comment: "")
    lazy var _action_sheet_action_title_spam = NSLocalizedString("Move to spam", comment: "")
    lazy var _action_sheet_action_title_delete = NSLocalizedString("Delete", comment: "")
    lazy var _action_sheet_action_title_moveTo = NSLocalizedString("Move to…", comment: "")
    lazy var _action_sheet_action_title_print = NSLocalizedString("Print", comment: "")
    lazy var _action_sheet_action_title_view_headers = NSLocalizedString("View headers", comment: "")
    lazy var _action_sheet_action_title_view_html = NSLocalizedString("View HTML", comment: "")
    lazy var _action_sheet_action_title_phishing = NSLocalizedString("Report phishing", comment: "")
    lazy var _action_sheet_action_title_inbox = NSLocalizedString("Move to inbox", comment: "")
    lazy var _action_sheet_action_title_spam_to_inbox = NSLocalizedString("Not a spam (move to inbox)", comment: "")

    lazy var _move_to_done_button_title = NSLocalizedString("Done", comment: "")
    lazy var _move_to_title = NSLocalizedString("Move to", comment: "")
    lazy var _move_to_new_folder = NSLocalizedString("New Folder", comment: "")
    lazy var _discard_changes_title = NSLocalizedString("Do you want to discard your changes?", comment: "")
    lazy var _changes_will_discarded = NSLocalizedString("Your changes will be discarded", comment: "")

    lazy var _label_as_title = NSLocalizedString("Label as", comment: "")
    lazy var _label_as_also_archive = NSLocalizedString("Also archive?", comment: "Checkbox on Label as action sheet to  prompt if user wants to archive the conversation/message as well when applying one or more labels")
    lazy var _label_as_new_label = NSLocalizedString("New Label", comment: "")

    lazy var _undisclosed_recipients = NSLocalizedString("Undisclosed Recipients", comment: "")

    lazy var _unsubscribe = NSLocalizedString("Unsubscribe", comment: "")

    lazy var _unsubscribe_banner_description = NSLocalizedString("This message is from a mailing list.", comment: "")
    lazy var _unsubscribe_compact_banner_description = NSLocalizedString("Unsubscribe from mailing list", comment: "The title of unsubscribe banner")

    lazy var _auto_phising_banner_message = NSLocalizedString("Our system flagged this message as a phishing attempt. Please check that it is legitimate", comment: "")
    lazy var _auto_phising_banner_button_title = NSLocalizedString("Mark as legitimate", comment: "")

    lazy var _autoreply_banner_description = NSLocalizedString("This message is automatically generated as a response to a previous message.", comment: "")
    lazy var _autoreply_compact_banner_description = NSLocalizedString("This message was automatically generated", comment: "The title of auto reply banner")

    lazy var _dmarc_failed_banner_message = NSLocalizedString("This email has failed its domain’s authentication requirements. It may be spoofed or improperly forwarded!", comment: "The error message that the incoming mail failed dmarc authentication")
    lazy var _discard_warning = NSLocalizedString("Do you want to discard the changes?", comment: "Warning message")

    lazy var _conversation_settings_footer_title = NSLocalizedString("Group emails in the same conversation together.", comment: "")
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
    // MARK: - In App Feedback
    lazy var _your_feedback = NSLocalizedString("Your feedback", comment: "Title of user feedback view")
    lazy var _feedback_prompt = NSLocalizedString("How would you describe your experience with the new ProtonMail?", comment: "Prompt of user feedback view")
    lazy var _feedback_placeholder = NSLocalizedString("Tell us about your experience. (Optional)", comment: "Placeholder in text view destined to gather written user feedback")
    lazy var _send_feedback = NSLocalizedString("Send feedback", comment: "Title of button to send feedback")
    lazy var _feedback_awful = NSLocalizedString("Awful", comment: "Example feedback")
    lazy var _feedback_wonderful = NSLocalizedString("Wonderful", comment: "Example feedback")
    lazy var _provide_feedback = NSLocalizedString("Provide feedback", comment: "Title of menu action to trigger feedback view")
    lazy var _thank_you_feedback = NSLocalizedString("Thank you for your feedback!", comment: "Comment in banner thanking user for providing feedback")
    lazy var collalse_message_title_in_converation_view = NSLocalizedString("Collapse message", comment: "The title of button to collapse the expanded message in conversation view for VoiceOver.")

    lazy var _settings_dark_mode_section_title = NSLocalizedString("Appearance", comment: "The title of section inside the dark mode setting page")
    lazy var _settings_dark_mode_title_follow_system = NSLocalizedString("Follow device setting", comment: "The title of follow system option in dark mode setting")
    lazy var _settings_dark_mode_title_force_on = NSLocalizedString("Always on", comment: "The title of always on option in dark mode setting")
    lazy var _settings_dark_mode_title_force_off = NSLocalizedString("Always off", comment: "The title of always off option in dark mode setting")

    lazy var _inbox_swipe_to_trash_banner_title = NSLocalizedString("Message moved to trash", comment: "The title of banner that is shown after using swipe action to trash a message")
    lazy var _inbox_swipe_to_archive_banner_title = NSLocalizedString("1 Message moved to archive", comment: "The title of banner that is shown after using swipe action to archive a message")
    lazy var _inbox_swipe_to_spam_banner_title = NSLocalizedString("1 Message moved to spam", comment: "The title of banner that is shown after using swipe action to spam a message")
    lazy var _inbox_swipe_to_move_banner_title = NSLocalizedString("swipe_to_move_title", comment: "The title of swipe banner after swiping to move messages")
    lazy var _inbox_swipe_to_move_conversation_banner_title = NSLocalizedString("swipe_to_move_conversation_title", comment: "The title of swipe banner after swiping to move conversations")
    lazy var _inbox_swipe_to_label_banner_title = NSLocalizedString("swipe_to_label_title", comment: "The title of swipe banner after swiping to label messages")
    lazy var _inbox_swipe_to_label_conversation_banner_title = NSLocalizedString("swipe_to_label_conversation_title", comment: "The title of swipe banner after swiping to label conversations")

    lazy var _inbox_action_reverted_title = NSLocalizedString("Action reverted", comment: "The title of toast message that is shown after the undo action is done")
    lazy var _compose_message = NSLocalizedString("Compose message", comment: "An action title shows in ellipsis menu")
    lazy var _empty_trash = NSLocalizedString("Empty Trash", comment: "An action title shows in ellipsis menu")
    lazy var _empty_trash_folder = NSLocalizedString("Empty trash folder", comment: "Alert title")
    lazy var _empty_spam = NSLocalizedString("Empty Spam", comment: "An action title shows in ellipsis menu")
    lazy var _empty_spam_folder = NSLocalizedString("Empty spam folder", comment: "Alert title")
    lazy var _cannot_empty_folder_now = NSLocalizedString("Cannot empty folder right now.", comment: "Warning message")
    lazy var _clean_message_warning = NSLocalizedString("clean_message_warning", comment: "Warning message when users try to empty messages in the folder")
    lazy var _clean_conversation_warning = NSLocalizedString("clean_conversation_warning", comment: "Warning message when users try to empty conversations in the folder")
    lazy var _show_full_message = NSLocalizedString("…[Show full message]", comment: "Button title to show full encrypted message body when decryption failed")

    lazy var _token_revoke_noti_title = NSLocalizedString("Logged out of %@", comment: "The title of notification that will show when the token of one account is revoked")
    lazy var _token_revoke_noti_body = NSLocalizedString("Log in again to keep receiving updates", comment: "The body of notification that will show when the token of one account is revoked")
    lazy var _no_attachment_found = NSLocalizedString("No attachment found", comment: "Alert title when users want to send a message without attachments but contain attachment-related keywords in the message body")
    lazy var _do_you_want_to_send_message_anyway = NSLocalizedString("Do you want to send your message anyway?", comment: "Alert body for no attachment found")

    lazy var _action_bar_title_trash = NSLocalizedString("Trash", comment: "The title of first button in the action bar")
    lazy var _action_bar_title_delete = NSLocalizedString("Delete", comment: "The title of first button in the action bar")
    lazy var _action_bar_title_moveTo = NSLocalizedString("Move to Inbox", comment: "The title of first button in the action bar")
    lazy var _action_bar_title_more = NSLocalizedString("More", comment: "The title of first button in the action bar")
    lazy var _action_bar_title_labelAs = NSLocalizedString("Label", comment: "The title of first button in the action bar")
    lazy var _action_bar_title_reply = NSLocalizedString("Reply", comment: "The title of first button in the action bar")
    lazy var _action_bar_title_replyAll = NSLocalizedString("Reply All", comment: "The title of first button in the action bar")
    lazy var _composer_voiceover_show_cc_bcc = NSLocalizedString("Add cc and bcc", comment: "The title of the button in the composer that will show the cc/bcc field when voiceover is on.")
    lazy var _composer_voiceover_close_cc_bcc = NSLocalizedString("Close cc and bcc", comment: "The title of the button in the composer that will close the cc/bcc field when voiceover is on.")
    lazy var _composer_voiceover_select_other_sender = NSLocalizedString("Choose different sender address", comment: "The title of the button in the composer that can select different sender address.")
    lazy var _composer_voiceover_message_content = NSLocalizedString("Message content", comment: "The title of content of message in the composer that suggests the current selection is the content of the message.")

    lazy var _composer_voiceover_add_pwd = NSLocalizedString("Set mail password", comment: "The voiceiver title of the add password button in the tool bar of composer.")
    lazy var _composer_voiceover_add_exp = NSLocalizedString("Set mail expiration", comment: "The voiceiver title of the add expiration button in the tool bar of composer")
    lazy var _composer_voiceover_add_attachment = NSLocalizedString("Add attachment", comment: "The voiceiver title of the add attachment button in the tool bar of composer")
    lazy var _composer_voiceover_dismiss_keyboard = NSLocalizedString("Dismiss keyboard", comment: "The voiceover title of the dismiss keyboard action")

    lazy var _spam_open_link_title = NSLocalizedString("Warning: suspected fake website", comment: "The title of the link confirmation alert of spam email.")
    lazy var _spam_open_link_content = NSLocalizedString("This link leads to a website that might be trying to steal your information, such as passwords and credit card details.\n%@\n\nFor your security, do not continue.", comment: "The content of the link confirmation alert of spam email.")
    lazy var _spam_open_continue = NSLocalizedString("Ignore warning and continue", comment: "The title of the button to open the link in spam mail.")
    lazy var _spam_open_go_back = NSLocalizedString("Go back (recommended)", comment: "The title of the button to cancel the action of opening the link in spam mail.")

    lazy var _conversation_notice_title = NSLocalizedString("Conversations are optional", comment: "The title of the conversation notice view shown in the conversation view.")
    lazy var _conversation_notice_message = NSLocalizedString("You can disable conversations from settings any time.", comment: "The message of the conversation notice view shown in the conversation view.")
    lazy var _conversation_notice_action_title = NSLocalizedString("Show me", comment: "The button title of the conversation notice view shown in the conversation view.")
    lazy var _undo_send_description = NSLocalizedString("This feature delays sending your emails, giving you the opportunity to undo send during the selected time frame.", comment: "Description for undo send")
    lazy var _undo_send_seconds_options = NSLocalizedString("%d seconds", comment: "undo send seconds options, e.g. 5 seconds")
}
