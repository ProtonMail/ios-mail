//
//  Localization+Constants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/18/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

/// object for all the localization strings, this avoid some issues with xcode 9 import/export
class LocalString {
    
    
    //Mark Signup
    
    /// "(2048 bit)"
    static let _signup_key_2048_size   = NSLocalizedString("(2048 bit)", comment: "Key size text when setup key")
    /// "(4096 bit)"
    static let _signup_key_4096_size   = NSLocalizedString("(4096 bit)", comment: "Key size text when setup key")
    /// "*OPTIONAL"
    static let _signup_optional_text   = NSLocalizedString("*OPTIONAL", comment: "optional text field")
    /// "2fa Authentication failed please try to login again"
    static let _signup_2fa_auth_failed = NSLocalizedString("2fa Authentication failed please try to login again", comment: "2fa verification failed")
    
    
    // Mark Settings
    
    /// "%d Minute"
    static let _settings_auto_lock_minute  = NSLocalizedString("%d Minute", comment: "auto lock time format")
    /// "%d Minutes"
    static let _settings_auto_lock_minutes = NSLocalizedString("%d Minutes", comment: "auto lock time format")
    /// "**********"
    static let _settings_secret_x_string   = NSLocalizedString("**********", comment: "secret")
    /// "DisplayName"
    static let _settings_displayname_title = NSLocalizedString("DisplayName", comment: "Title")
    /// "DISPLAY NAME"
    static let _settings_display_name_title = NSLocalizedString("Display Name", comment: "Title")
    /// "Input Display Name ..."
    static let _settings_input_display_name_placeholder = NSLocalizedString("Input Display Name ...", comment: "place holder")
    /// "Signature"
    static let _settings_signature_title = NSLocalizedString("Signature", comment: "Title")
    /// "Email default signature"
    static let _settings_email_default_signature = NSLocalizedString("Email default signature", comment: "place holder")
    /// "Enable Default Signature"
    static let _settings_enable_default_signature_title = NSLocalizedString("Enable Default Signature", comment: "Title")
    /// "Mobile Signature"
    static let _settings_mobile_signature_title = NSLocalizedString("Mobile Signature", comment: "Title")
    /// "Only a paid user can modify default mobile signature or turn it off!"
    static let _settings_only_paid_to_modify_mobile_signature = NSLocalizedString("Only a paid user can modify default mobile signature or turn it off!", comment: "Description")
    /// "Enable Mobile Signature"
    static let _settings_enable_mobile_signature_title = NSLocalizedString("Enable Mobile Signature", comment: "Title")
    /// "ProtonMail Plus is required to customize your mobile signature"
    static let _settings_plus_is_required_to_modify_signature_notes = NSLocalizedString("ProtonMail Plus is required to customize your mobile signature", comment: "Description")
    /// "Notification Email"
    static let _settings_notification_email = NSLocalizedString("Notification Email", comment: "Title")
    /// "Also used to reset a forgotten password."
    static let _settings_notification_email_notes = NSLocalizedString("Also used to reset a forgotten password.", comment: "Description")
    /// "Notification / Recovery Email"
    static let _settings_notification_email_title = NSLocalizedString("Notification / Recovery Email", comment: "Title")
    /// "Enable Notification Email"
    static let _settings_notification_email_switch_title = NSLocalizedString("Enable Notification Email", comment: "Title")
    /// "Input Notification Email ..."
    static let _settings_notification_email_placeholder = NSLocalizedString("Input Notification Email ...", comment: "place holder")
    /// "Current password"
    static let _settings_current_password = NSLocalizedString("Current password", comment: "Placeholder")
    /// "New password"
    static let _settings_new_password = NSLocalizedString("New password", comment: "Placeholder")
    /// "Confirm new password"
    static let _settings_confirm_new_password = NSLocalizedString("Confirm new password", comment: "Placeholder")
    
    
    // Mark Menu
    
    /// "Report Bugs"
    static let _menu_bugs_title     = NSLocalizedString("Report Bugs", comment: "menu title")
    /// "Inbox"
    static let _menu_inbox_title    =  NSLocalizedString("Inbox", comment: "menu title")
    /// "Starred"
    static let _menu_starred_title  =  NSLocalizedString("Starred", comment: "menu title")
    /// "Archive"
    static let _menu_archive_title  =  NSLocalizedString("Archive", comment: "menu title")
    /// "Drafts"
    static let _menu_drafts_title   =  NSLocalizedString("Drafts", comment: "menu title")
    /// "All Mail"
    static let _menu_allmail_title  =  NSLocalizedString("All Mail", comment: "menu title")
    /// "Sent"
    static let _menu_sent_title     =  NSLocalizedString("Sent", comment: "menu title")
    /// "Trash"
    static let _menu_trash_title    =  NSLocalizedString("Trash", comment: "menu title")
    /// "Spam"
    static let _menu_spam_title     =  NSLocalizedString("Spam", comment: "menu title")
    /// "Contacts"
    static let _menu_contacts_title =  NSLocalizedString("Contacts", comment: "menu title")
    /// "Settings"
    static let _menu_settings_title =  NSLocalizedString("Settings", comment: "menu title")
    /// "Logout"
    static let _menu_signout_title  =  NSLocalizedString("Logout", comment: "menu title")
    /// "Feedback"
    static let _menu_feedback_title =  NSLocalizedString("Feedback", comment: "menu title")
    /// "Lock The App"
    static let _menu_lockapp_title  =  NSLocalizedString("Lock The App", comment: "menu title")
    
    
    
    // Mark Message localtion
    
    /// "All Mail"
    static let _locations_all_mail_title = NSLocalizedString("All Mail", comment: "mail location title")
    /// "INBOX"
    static let _locations_inbox_title    = NSLocalizedString("INBOX", comment: "mail location title")
    /// "STARRED"
    static let _locations_starred_title  = NSLocalizedString("STARRED", comment: "mail location title")
    /// "DRAFTS"
    static let _locations_draft_title    = NSLocalizedString("DRAFTS", comment: "mail location title")
    /// "SENT"
    static let _locations_outbox_title   = NSLocalizedString("SENT", comment: "mail location title")
    /// "TRASH"
    static let _locations_trash_title    = NSLocalizedString("TRASH", comment: "mail location title")
    /// "ARCHIVE"
    static let _locations_archive_title  = NSLocalizedString("ARCHIVE", comment: "mail location title")
    /// "SPAM"
    static let _locations_spam_title     = NSLocalizedString("SPAM", comment: "mail location title")
    
    /// "All Mail"
    static let _locations_all_mail_desc = NSLocalizedString("All Mail", comment: "mail location desc")
    /// "Inbox"
    static let _locations_inbox_desc    = NSLocalizedString("Inbox", comment: "mail location desc")
    /// "Starred"
    static let _locations_starred_desc  = NSLocalizedString("Starred", comment: "mail location desc")
    /// "Draft"
    static let _locations_draft_desc    = NSLocalizedString("Draft", comment: "mail location desc")
    /// "Outbox"
    static let _locations_outbox_desc   = NSLocalizedString("Outbox", comment: "mail location desc")
    /// "Trash"
    static let _locations_trash_desc    = NSLocalizedString("Trash", comment: "mail location desc")
    /// "Archive"
    static let _locations_archive_desc  = NSLocalizedString("Archive", comment: "mail location desc")
    /// "Spam"
    static let _locations_spam_desc     = NSLocalizedString("Spam", comment: "mail location desc")
    /// "Deleted"
    static let _locations_deleted_desc  = NSLocalizedString("Deleted", comment: "mail location desc")
    
    /// "Trash"
    static let _locations_deleted_action      = NSLocalizedString("Trash", comment: "move action")
    /// "Move to Inbox"
    static let _locations_move_inbox_action   = NSLocalizedString("Move to Inbox", comment: "move action")
    /// "Move to Draft"
    static let _locations_move_draft_action   = NSLocalizedString("Move to Draft", comment: "move action")
    /// "Move to Outbox"
    static let _locations_move_outbox_action  = NSLocalizedString("Move to Outbox", comment: "move action")
    /// "Move to Spam"
    static let _locations_move_spam_action    = NSLocalizedString("Move to Spam", comment: "move action")
    /// "Add Star"
    static let _locations_add_star_action     = NSLocalizedString("Add Star",  comment: "mark message star")
    /// "Move to Archive"
    static let _locations_move_archive_action = NSLocalizedString("Move to Archive", comment: "move action")
    /// "Move to Trash"
    static let _locations_move_trash_action   = NSLocalizedString("Move to Trash", comment: "move action")
    /// "Move to AllMail"
    static let _locations_move_allmail_action = NSLocalizedString("Move to AllMail", comment: "move action")
    
    
    // Mark Messages
    
    /// "Message sent"
    static let _message_sent_ok_desc          = NSLocalizedString("Message sent", comment: "Description")
    /// "Sent Failed"
    static let _message_sent_failed_desc      = NSLocalizedString("Sent Failed", comment: "Description")
    /// "The draft cache is broken please try again"
    static let _message_draft_cache_is_broken = NSLocalizedString("The draft cache is broken please try again", comment: "Description")
    /// "No Messages"
    static let _messages_no_messages = NSLocalizedString("No Messages", comment: "message when mailbox doesnt have emailsß")
    /// "Undo"
    static let _messages_undo_action = NSLocalizedString("Undo", comment: "Action")
    /// "Can't find the clicked message please try again!"
    static let _messages_cant_find_message = NSLocalizedString("Can't find the clicked message please try again!", comment: "Description")
    /// "Message has been deleted."
    static let _messages_has_been_deleted = NSLocalizedString("Message has been deleted.", comment: "Title")
    /// "Message has been moved."
    static let _messages_has_been_moved = NSLocalizedString("Message has been moved.", comment: "Title")
    /// "Archived"
    static let _messages_archived = NSLocalizedString("Archived", comment: "Description")
    /// "Spammed"
    static let _messages_spammed = NSLocalizedString("Spammed", comment: "Description")
    /// "Message %@"
    static let _messages_with_title = NSLocalizedString("Message %@", comment: "Message with title")
    /// "Labels have been applied."
    static let _messages_labels_applied = NSLocalizedString("Labels have been applied.", comment: "Title")
    /// "You have a new email!"
    static let _messages_you_have_new_email = NSLocalizedString("You have a new email!", comment: "Title")
    /// "You have %d new emails!"
    static let _messages_you_have_new_emails_with = NSLocalizedString("You have %d new emails!", comment: "Message")
    
    
    
    // Mark Composer

    /// "Re:"
    static let _composer_short_reply   = NSLocalizedString("Re:", comment: "abbreviation of reply:")
    /// "Fwd:"
    static let _composer_short_forward = NSLocalizedString("Fwd:", comment: "abbreviation of forward:")
    /// "On"
    static let _composer_on            = NSLocalizedString("On", comment: "Title")
    /// "wrote:"
    static let _composer_wrote         = NSLocalizedString("wrote:", comment: "Title")
    /// "Date:"
    static let _composer_date_field    = NSLocalizedString("Date:", comment: "message Date: text")
    /// "Subject:"
    static let _composer_subject_field = NSLocalizedString("Subject:", comment: "subject: text when forward")
    /// "Forwarded message"
    static let _composer_fwd_message   = NSLocalizedString("Forwarded message", comment: "forwarded message title")
    /// "Set Password"
    static let _composer_set_password  = NSLocalizedString("Set Password", comment: "Title")
    /// "Set a password to encrypt this message for non-ProtonMail users."
    static let _composer_eo_desc       = NSLocalizedString("Set a password to encrypt this message for non-ProtonMail users.", comment: "Description")
    /// "Get more information"
    static let _composer_eo_info       = NSLocalizedString("Get more information", comment: "Action")
    /// "Message Password"
    static let _composer_eo_msg_pwd_placeholder     = NSLocalizedString("Message Password", comment: "Placeholder")
    /// "Password cannot be empty."
    static let _composer_eo_empty_pwd_desc          = NSLocalizedString("Password cannot be empty.", comment: "Description")
    /// "Please set a password."
    static let _composer_eo_pls_set_password = NSLocalizedString("Please set a password.", comment: "Description")
    /// "Confirm Password"
    static let _composer_eo_confirm_pwd_placeholder = NSLocalizedString("Confirm Password", comment: "Placeholder")
    /// "Message password does not match."
    static let _composer_eo_dismatch_pwd_desc       = NSLocalizedString("Message password does not match.", comment: "Description")
    /// "Compose"
    static let _composer_compose_action = NSLocalizedString("Compose", comment: "Action")
    /// "Send message without subject?"
    static let _composer_send_no_subject_desc = NSLocalizedString("Send message without subject?", comment: "Description")
    /// "You need at least one recipient to send"
    static let _composer_no_recipient_error = NSLocalizedString("You need at least one recipient to send", comment: "Description")
    /// "Save draft"
    static let _composer_save_draft_action = NSLocalizedString("Save draft", comment: "Action")
    /// "Discard draft"
    static let _composer_discard_draft_action = NSLocalizedString("Discard draft", comment: "Action")
    /// "Change sender address to .."
    static let _composer_change_sender_address_to = NSLocalizedString("Change sender address to ..", comment: "Title")
    /// "Upgrade to a paid plan to send from your %@ address"
    static let _composer_change_paid_plan_sender_error = NSLocalizedString("Upgrade to a paid plan to send from your %@ address", comment: "Error")
    /// "Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@"
    static let _composer_sending_messages_from_a_paid_feature = NSLocalizedString("Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@", comment: "pm.me upgrade warning in composer")
    /// "days"
    static let _composer_eo_days_title = NSLocalizedString("days", comment: "Title")
    /// "Hours"
    static let _composer_eo_hours_title = NSLocalizedString("Hours", comment: "Title")
    /// "From"
    static let _composer_from_label = NSLocalizedString("From", comment: "Title")
    /// "To"
    static let _composer_to_label = NSLocalizedString("To", comment: "Title")
    /// "Cc"
    static let _composer_cc_label = NSLocalizedString("Cc", comment: "Title")
    /// "Bcc"
    static let _composer_bcc_label = NSLocalizedString("Bcc", comment: "Title")
    /// "Subject"
    static let _composer_subject_placeholder = NSLocalizedString("Subject", comment: "Placeholder")
    /// "Define Expiration Date"
    static let _composer_define_expiration_placeholder = NSLocalizedString("Define Expiration Date", comment: "Placeholder")
    /// "Define Password"
    static let _composer_define_password = NSLocalizedString("Define Password", comment: "place holder")
    
    

    
    
    // Mark Contacts
    
    /// "Add Organization"
    static let _contacts_add_org              = NSLocalizedString("Add Organization", comment: "new contacts add Organization ")
    /// "Add Nickname"
    static let _contacts_add_nickname         = NSLocalizedString("Add Nickname", comment: "new contacts add Nickname")
    /// "Add Title"
    static let _contacts_add_title            = NSLocalizedString("Add Title", comment: "new contacts add Title")
    /// "Add Birthday"
    static let _contacts_add_bd               = NSLocalizedString("Add Birthday", comment: "new contacts add Birthday")
    /// "Add Anniversary"
    static let _contacts_add_anniversary      = NSLocalizedString("Add Anniversary", comment: "new contacts add Anniversary")
    /// "Add Gender"
    static let _contacts_add_gender           = NSLocalizedString("Add Gender", comment: "new contacts add Gender")
    /// "Add Contact"
    static let _contacts_add_contact          = NSLocalizedString("Add Contact", comment: "Contacts add new contact")
    /// "Add Custom Label"
    static let _contacts_add_custom_label     = NSLocalizedString("Add Custom Label", comment: "add custom label type action")
    /// "Add new address"
    static let _contacts_add_new_address      = NSLocalizedString("Add new address", comment: "add new address action")
    /// "Add new custom field"
    static let _contacts_add_new_custom_field = NSLocalizedString("Add new custom field", comment: "new custom field action")
    /// "Add new email"
    static let _contacts_add_new_email        = NSLocalizedString("Add new email", comment: "new email action")
    /// "Add new phone number"
    static let _contacts_add_new_phone        = NSLocalizedString("Add new phone number", comment: "new phone action")
    /// "Add new field"
    static let _contacts_add_new_field        = NSLocalizedString("Add new field", comment: "new field action")
    /// we rename home to "Personal"
    static let _contacts_types_home_title     = NSLocalizedString("Personal", comment: "default vcard types")
    /// "Work"
    static let _contacts_types_work_title     = NSLocalizedString("Work", comment: "default vcard types")
    /// "Email"
    static let _contacts_types_email_title    = NSLocalizedString("Email", comment: "default vcard types")
    /// "Other"
    static let _contacts_types_other_title    = NSLocalizedString("Other", comment: "default vcard types")
    /// "Phone"
    static let _contacts_types_phone_title    = NSLocalizedString("Phone", comment: "default vcard types")
    /// "Mobile"
    static let _contacts_types_mobile_title   = NSLocalizedString("Mobile", comment: "default vcard types")
    /// "Fax"
    static let _contacts_types_fax_title      = NSLocalizedString("Fax", comment: "default vcard types")
    /// "Address"
    static let _contacts_types_address_title  = NSLocalizedString("Address", comment: "default vcard types")
    /// "URL"
    static let _contacts_types_url_title      = NSLocalizedString("URL", comment: "default vcard types")
    /// "Internet"
    static let _contacts_types_internet_title = NSLocalizedString("Internet", comment: "default vcard types")
    /// "All contacts are imported"
    static let _contacts_all_imported         = NSLocalizedString("All contacts are imported", comment: "Title")
    /// "Custom"
    static let _contacts_custom_type          = NSLocalizedString("Custom", comment: "contacts default label type")
    /// "Street"
    static let _contacts_street_field_placeholder = NSLocalizedString("Street", comment: "contact placeholder")
    /// "City"
    static let _contacts_city_field_placeholder = NSLocalizedString("City", comment: "contact placeholder")
    /// "State"
    static let _contacts_state_field_placeholder = NSLocalizedString("State", comment: "contact placeholder")
    /// "ZIP"
    static let _contacts_zip_field_placeholder = NSLocalizedString("ZIP", comment: "contact placeholder")
    /// "Country"
    static let _contacts_country_field_placeholder = NSLocalizedString("Country", comment: "contact placeholder")
    /// "Url"
    static let _contacts_vcard_url_placeholder = NSLocalizedString("Url", comment: "default vcard types")
    /// "Organization"
    static let _contacts_info_organization = NSLocalizedString("Organization", comment: "contacts talbe cell Organization title")
    /// "Nickname"
    static let _contacts_info_nickname = NSLocalizedString("Nickname", comment: "contacts talbe cell Nickname title")
    /// "Title"
    static let _contacts_info_title = NSLocalizedString("Title", comment: "contacts talbe cell Title title")
    /// "Birthday"
    static let _contacts_info_birthday = NSLocalizedString("Birthday", comment: "contacts talbe cell Birthday title")
    /// "Anniversary"
    static let _contacts_info_anniversary = NSLocalizedString("Anniversary", comment: "contacts talbe cell Anniversary title")
    /// "Gender"
    static let _contacts_info_gender = NSLocalizedString("Gender", comment: "contacts talbe cell gender title")
    /// "Contact Details"
    static let _contacts_contact_details_title = NSLocalizedString("Contact Details", comment: "contact section title")
    /// "Encrypted Contact Details"
    static let _contacts_encrypted_contact_details_title = NSLocalizedString("Encrypted Contact Details", comment: "contact section title")
    /// "Share Contact"
    static let _contacts_share_contact_action = NSLocalizedString("Share Contact", comment: "action")
    /// "Name"
    static let _contacts_name_title = NSLocalizedString("Name", comment: "title")
    /// "Notes"
    static let _contacts_info_notes = NSLocalizedString("Notes", comment: "title")
    
    
    
    
    // Mark Labels
    
    /// "Add Label"
    static let _labels_add_label_action     = NSLocalizedString("Add Label", comment: "add label action")
    /// "Add Folder"
    static let _labels_add_folder_action    = NSLocalizedString("Add Folder", comment: "Action")
    /// "Also Archive"
    static let _labels_apply_archive_check  = NSLocalizedString("Also Archive", comment: "archive when apply label")
    /// "Add New Folder"
    static let _labels_add_new_folder_title = NSLocalizedString("Add New Folder", comment: "add a new folder")
    /// "Add New Label"
    static let _labels_add_new_label_title  = NSLocalizedString("Add New Label", comment: "add a new folder")
    /// "Edit Label"
    static let _labels_edit_label_title     = NSLocalizedString("Edit Label", comment: "Title")
    /// "Folder Name"
    static let _labels_folder_name_text     = NSLocalizedString("Folder Name", comment: "place holder")
    /// "Label Name"
    static let _labels_label_name_text      = NSLocalizedString("Label Name", comment: "createing lable input place holder")
    /// "Manage Labels/Folders"
    static let _labels_manage_title         = NSLocalizedString("Manage Labels/Folders", comment: "Title")
    /// "Move to Folder"
    static let _labels_move_to_folder       = NSLocalizedString("Move to Folder", comment: "folder apply - title")
    /// "Edit Folder"
    static let _labels_edit_folder_title    = NSLocalizedString("Edit Folder", comment: "Title")
    
    // Mark General
    
    /// "API Server not reachable..."
    static let _general_api_server_not_reachable     =  NSLocalizedString("API Server not reachable...", comment: "when server not reachable")
    /// "Access to this account is disabled due to non-payment. Please sign in through protonmail.com to pay your unpaid invoice."
    static let _general_account_disabled_non_payment = NSLocalizedString("Access to this account is disabled due to non-payment. Please sign in through protonmail.com to pay your unpaid invoice.", comment: "error message")
    /// "Alert"
    static let _general_alert_title     = NSLocalizedString("Alert", comment: "Title")
    /// "Done"
    static let _general_done_button     = NSLocalizedString("Done", comment: "Done action")
    /// "Cancel"
    static let _general_cancel_button   = NSLocalizedString("Cancel", comment: "Cancel action")
    /// "Remove"
    static let _general_remove_button   = NSLocalizedString("Remove", comment: "remove action")
    /// "Apply"
    static let _general_apply_button    = NSLocalizedString("Apply", comment: "Apply action")
    /// "Reply"
    static let _general_reply_button    = NSLocalizedString("Reply", comment: "reply action")
    /// "Reply All"
    static let _general_replyall_button = NSLocalizedString("Reply All", comment: "reply all action")
    /// "Forward"
    static let _general_forward_button  = NSLocalizedString("Forward", comment: "forward action")    
    /// "From:"
    static let _general_from_label      = NSLocalizedString("From:", comment: "message From: field text")
    /// "To:"
    static let _general_to_label        = NSLocalizedString("To:", comment: "message To: feild")
    /// "Cc:"
    static let _general_cc_label        = NSLocalizedString("Cc:", comment: "message Cc: feild")
    /// "at"
    static let _general_at_label        = NSLocalizedString("at", comment: "like at 10:00pm")
    /// "Delete"
    static let _general_delete_action   = NSLocalizedString("Delete", comment: "general delete action")
    /// "Close"
    static let _general_close_action    = NSLocalizedString("Close", comment: "general close action")
    /// "Update"
    static let _general_update_action   = NSLocalizedString("Update", comment: "like top right action text")
    /// "Invalid access token please relogin"
    static let _general_invalid_access_token = NSLocalizedString("Invalid access token please relogin", comment: "Description")
    /// "A new version of ProtonMail app is available, please update to latest version."
    static let _general_force_upgrade_desc = NSLocalizedString("A new version of ProtonMail app is available, please update to latest version.", comment: "Description")
    /// "Search"
    static let _general_search_placeholder = NSLocalizedString("Search", comment: "Title")
    /// "Notice"
    static let _general_notice_alert_title = NSLocalizedString("Notice", comment: "Alert title")
    /// "Don't remind me again"
    static let _general_dont_remind_action = NSLocalizedString("Don't remind me again", comment: "Action")
    /// "Send"
    static let _general_send_action = NSLocalizedString("Send", comment: "Action")
    /// "Confirmation"
    static let _general_confirmation_title = NSLocalizedString("Confirmation", comment: "Title")
    /// "Draft"
    static let _general_draft_action = NSLocalizedString("Draft", comment: "Action")
    /// "OpenDraft"
    static let _general_opendraft_action = NSLocalizedString("OpenDraft", comment: "Action")
    /// "Plain text"
    static let _general_enc_type_plain_text = NSLocalizedString("Plain text", comment: "Title")
    /// "ProtonMail encrypted emails"
    static let _general_enc_pm_emails = NSLocalizedString("ProtonMail encrypted emails", comment: "Title")
    /// "Encrypted from outside"
    static let _general_enc_from_outside = NSLocalizedString("Encrypted from outside", comment: "Title")
    /// "Encrypted for outside"
    static let _general_enc_for_outside = NSLocalizedString("Encrypted for outside", comment: "Title")
    /// "Send plain but stored enc"
    static let _general_send_plain_but_stored_enc = NSLocalizedString("Send plain but stored enc", comment: "Title")
    /// "Encrypted for outside reply"
    static let _general_encrypted_for_outside_reply = NSLocalizedString("Encrypted for outside reply", comment: "Title")
    /// "Encrypted from outside pgp inline"
    static let _general_enc_from_outside_pgp_inline = NSLocalizedString("Encrypted from outside pgp inline", comment: "Title")
    /// "Encrypted from outside pgp mime"
    static let _general_enc_from_outside_pgp_mime = NSLocalizedString("Encrypted from outside pgp mime", comment: "Title")
    /// "Encrypted from outside signed pgp mime"
    static let _general_enc_from_outside_signed_pgp_mime = NSLocalizedString("Encrypted from outside signed pgp mime", comment: "Title")
    /// "The request timed out."
    static let _general_request_timed_out = NSLocalizedString("The request timed out.", comment: "Title")
    /// "No connectivity detected..."
    static let _general_no_connectivity_detected = NSLocalizedString("No connectivity detected...", comment: "Title")
    /// "The ProtonMail current offline..."
    static let _general_pm_offline = NSLocalizedString("The ProtonMail current offline...", comment: "Title")
    /// "Save"
    static let _general_save_action = NSLocalizedString("Save", comment: "Title")
    /// "Edit"
    static let _general_edit_action = NSLocalizedString("Edit", comment: "Action")
    /// "Create"
    static let _general_create_action = NSLocalizedString("Create", comment: "top right action text")
    
    
    
    /// Mark Error
    
    /// "Invalid UserName"
    static let _error_invalid_username = NSLocalizedString("Invalid UserName!", comment: "Error message")
    /// "Bad parameter"
    static let _error_bad_parameter_title = NSLocalizedString("Bad parameter", comment: "Error title")
    /// "Bad parameter: %@"
    static let _error_bad_parameter_desc = NSLocalizedString("Bad parameter: %@", comment: "Error Description")
    /// "Bad response"
    static let _error_bad_response_title = NSLocalizedString("Bad response", comment: "Error Description")
    /// "Can't not find the value from the response body"
    static let _error_cant_parse_response_body = NSLocalizedString("Can't not find the value from the response body", comment: "Description")
    /// "no object"
    static let _error_no_object = NSLocalizedString("no object", comment: "no object error, local only , this could be not translated!")
    /// "Unable to parse response"
    static let _error_unable_to_parse_response_title = NSLocalizedString("Unable to parse response", comment: "Description")
    /// "Unable to parse the response object:\n%@"
    static let _error_unable_to_parse_response_desc = NSLocalizedString("Unable to parse the response object:\n%@", comment: "Description")
    /// "Failed to initialize the application's saved data"
    static let _error_core_data_save_failed = NSLocalizedString("Failed to initialize the application's saved data", comment: "Description")
    /// "There was an error creating or loading the application's saved data."
    static let _error_core_data_load_failed = NSLocalizedString("There was an error creating or loading the application's saved data.", comment: "Description")
    
    

  
    
    
    /// "This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!"
    static let _messages_spam_100_warning = NSLocalizedString("This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
    /// "This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!"
    static let _messages_spam_101_warning = NSLocalizedString("This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")

    /// "Human Check Failed"
    static let _error_human_check_failed = NSLocalizedString("Human Check Failed", comment: "Description")

    /// "ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail"
    static let _error_pm_is_offline = NSLocalizedString("ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail", comment: "Description")

    /// "Sending Message"
    static let _messages_sending_message = NSLocalizedString("Sending Message", comment: "Description")

    /// "Message sending failed please try again"
    static let _messages_sending_failed_try_again = NSLocalizedString("Message sending failed please try again", comment: "Description")

    /// "Importing Contacts"
    static let _contacts_import_title = NSLocalizedString("Importing Contacts", comment: "import contact title")

    /// "Reading device contacts data..."
    static let _contacts_reading_contacts_data = NSLocalizedString("Reading device contacts data...", comment: "Title")

    /// "Contacts"
    static let _contacts_title = NSLocalizedString("Contacts", comment: "Action and title")

    /// "Do you want to cancel the process?"
    static let _contacts_import_cancel_wanring = NSLocalizedString("Do you want to cancel the process?", comment: "Description")

    /// "Confirm"
    static let _general_confirm_action = NSLocalizedString("Confirm", comment: "Action")

    /// "Cancelling"
    static let _contacts_cancelling_title = NSLocalizedString("Cancelling", comment: "Title")

    /// "Unknown"
    static let _general_unknown_title = NSLocalizedString("Unknown", comment: "title, default display name")

    /// "Import Error"
    static let _contacts_import_error = NSLocalizedString("Import Error", comment: "Action")

    /// "OK"
    static let _general_ok_action = NSLocalizedString("OK", comment: "Action")

    /// "Email address"
    static let _contacts_email_address_placeholder = NSLocalizedString("Email address", comment: "contact placeholder")

    /// "Choose a Password"
    static let _signup_choose_password = NSLocalizedString("Choose a Password", comment: "place holder")

    /// "Back"
    static let _general_back_action = NSLocalizedString("Back", comment: "top left back button")

    /// "Set passwords"
    static let _signup_set_passwords_title = NSLocalizedString("Set passwords", comment: "Signup passwords top title")

    /// "Note: This is used to log you into your account."
    static let _signup_set_pwd_note_1 = NSLocalizedString("Note: This is used to log you into your account.", comment: "setup password notes")

    /// "Note: This is used to encrypt and decrypt your messages. Do not lose this password, we cannot recover it."
    static let _signup_set_pwd_note_2 = NSLocalizedString("Note: This is used to encrypt and decrypt your messages. Do not lose this password, we cannot recover it.", comment: "setup password notes")
    
    /// "Create Account"
    static let _signup_create_account_action = NSLocalizedString("Create Account", comment: "Create account button")

    /// "Login password doesn't match"
    static let _signup_pwd_doesnt_match = NSLocalizedString("Login password doesn't match", comment: "Error")

    /// "Human Check Warning"
    static let _signup_human_check_warning_title = NSLocalizedString("Human Check Warning", comment: "human check warning title")

    /// "Warning: Before you pass the human check you can't sent email!!!"
    static let _signup_human_check_warning = NSLocalizedString("Warning: Before you pass the human check you can't sent email!!!", comment: "human check warning description")

    /// "Check Again"
    static let _signup_check_again_action = NSLocalizedString("Check Again", comment: "Action")

    /// "Cancel Check"
    static let _signup_cancel_check_action = NSLocalizedString("Cancel Check", comment: "Action")

    /// "TouchID is not enrolled, enable it in the system Settings"
    static let _general_touchid_not_enrolled = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "settings touchid error")

    /// "A passcode has not been set, enable it in the system Settings"
    static let _general_passcode_not_set = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "settings touchid error")

    /// "TouchID not available"
    static let _general_touchid_not_available = NSLocalizedString("TouchID not available", comment: "settings touchid/faceid error")

    /// "None"
    static let _general_none = NSLocalizedString("None", comment: "Title")

    /// "Every time enter app"
    static let _settings_every_time_enter_app = NSLocalizedString("Every time enter app", comment: "lock app option")

    /// "Default"
    static let _general_default = NSLocalizedString("Default", comment: "Title")

    /// "Please use the web version of ProtonMail to change your passwords!"
    static let _general_use_web_reset_pwd = NSLocalizedString("Please use the web version of ProtonMail to change your passwords!", comment: "Alert")

    /// "Resetting message cache ..."
    static let _settings_resetting_cache = NSLocalizedString("Resetting message cache ...", comment: "Title")

    /// "Auto Lock Time"
    static let _settings_auto_lock_time = NSLocalizedString("Auto Lock Time", comment: "Title")

    /// "Change default address to .."
    static let _settings_change_default_address_to = NSLocalizedString("Change default address to ..", comment: "Title")

    /// "You can't set %@ address as default because it is a paid feature."
    static let _settings_change_paid_address_warning = NSLocalizedString("You can't set %@ address as default because it is a paid feature.", comment: "pm.me upgrade warning in composer")

    /// "Current Language is: "
    static let _settings_current_language_is = NSLocalizedString("Current Language is: ", comment: "Change language title")

    /// "Enter Verification Code"
    static let _enter_verification_code = NSLocalizedString("Enter Verification Code", comment: "Title")
    
    /// "Human Verification"
    static let _human_verification = NSLocalizedString("Human Verification", comment: "top title")

    /// "We will send a verification code to the email address above."
    static let _we_will_send_a_verification_code_to_the_email_address = NSLocalizedString("We will send a verification code to the email address above.", comment: "email field notes")
    /// "Enter your existing email address."
    static let _enter_your_existing_email_address = NSLocalizedString("Enter your existing email address.", comment: "top title")
    /// "Continue"
    static let _genernal_continue = NSLocalizedString("Continue", comment: "Action")
    /// "Retry after %d seconds"
    static let _retry_after_seconds = NSLocalizedString("Retry after %d seconds", comment: "email verify code resend count down")
    /// "Send Verification Code"
    static let _send_verification_code = NSLocalizedString("Send Verification Code", comment: "Title")
    /// "Verification code request failed"
    static let _verification_code_request_failed = NSLocalizedString("Verification code request failed", comment: "Title")
    /// "Email address invalid"
    static let _email_address_invalid = NSLocalizedString("Email address invalid", comment: "Title")
    /// "Please input a valid email address."
    static let _please_input_a_valid_email_address = NSLocalizedString("Please input a valid email address.", comment: "error message")

    /// "Verification code sent"
    static let _verification_code_sent = NSLocalizedString("Verification code sent", comment: "Title")

    /// "Please check your email for the verification code."
    static let _please_check_email_for_code = NSLocalizedString("Please check your email for the verification code.", comment: "error message")

    /// "Create user failed"
    static let _create_user_failed = NSLocalizedString("Create user failed", comment: "error message title when create new user")

    /// "Default error, please try again."
    static let _default_error_please_try_again = NSLocalizedString("Default error, please try again.", comment: "error message when create new user")

    /// "Enter your PIN to unlock your inbox."
    static let _enter_pin_to_unlock_inbox = NSLocalizedString("Enter your PIN to unlock your inbox.", comment: "Title")

    /// "attempt remaining until secure data wipe!"
    static let _attempt_remaining_until_secure_data_wipe = NSLocalizedString("attempt remaining until secure data wipe!", comment: "Error")

    /// "attempts remaining until secure data wipe!"
    static let _attempts_remaining_until_secure_data_wipe = NSLocalizedString("attempts remaining until secure data wipe!", comment: "Error")

    /// "Incorrect PIN,"
    static let _incorrect_pin = NSLocalizedString("Incorrect PIN,", comment: "Error")

    /// "attempts remaining"
    static let _attempts_remaining = NSLocalizedString("attempts remaining", comment: "Description")

    /// "Upload iOS contacts to ProtonMail?"
    static let _upload_ios_contacts_to_protonmail = NSLocalizedString("Upload iOS contacts to ProtonMail?", comment: "Description")
    
    /// "Delete Contact"
    static let _delete_contact = NSLocalizedString("Delete Contact", comment: "Title-Contacts")
    
    /// "Login"
    static let _general_login = NSLocalizedString("Login", comment: "Title")

    
    /// "Authentication was cancelled by the system"
    static let _authentication_was_cancelled_by_the_system = NSLocalizedString("Authentication was cancelled by the system", comment: "Description")

    /// "Authentication failed"
    static let _authentication_failed = NSLocalizedString("Authentication failed", comment: "Description")

    /// "Pin code can't be empty."
    static let _pin_code_cant_be_empty = NSLocalizedString("Pin code can't be empty.", comment: "Description")

    /// "Enter your PIN"
    static let _enter_your_pin = NSLocalizedString("Enter your PIN", comment: "set pin title")

    /// "Re-Enter your PIN"
    static let _re_enter_your_pin = NSLocalizedString("Re-Enter your PIN", comment: "set pin title")

    
    

    /// "Key generation failed please try again"
    static let _key_generation_failed_please_try_again = NSLocalizedString("Key generation failed please try again", comment: "Error")

    /// "Authentication failed please try to login again"
    static let _authentication_failed_pls_try_again = NSLocalizedString("Authentication failed please try to login again", comment: "Error")

    /// "Unknown Error"
    static let _unknown_error = NSLocalizedString("Unknown Error", comment: "Error")

    /// "Fetch user info failed"
    static let _fetch_user_info_failed = NSLocalizedString("Fetch user info failed", comment: "Error")

    /// "Decrypt token failed please try again"
    static let _decrypt_token_failed_please_try_again = NSLocalizedString("Decrypt token failed please try again", comment: "Description")

    /// "Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation."
    static let _account_creation_has_been_disabled_pls_go_to_https = NSLocalizedString("Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation.", comment: "Error")

    /// "Create User failed please try again"
    static let _create_user_failed_please_try_again = NSLocalizedString("Create User failed please try again", comment: "Error")

    /// "Key invalid please go back try again"
    static let _key_invalid_please_go_back_try_again = NSLocalizedString("Key invalid please go back try again", comment: "Error")

    /// "Load remote content"
    static let _load_remote_content = NSLocalizedString("Load remote content", comment: "Action")

    /// "PASSWORD"
    static let _password = NSLocalizedString("Password", comment: "title")

    /// "Change Login Password"
    static let _change_login_password = NSLocalizedString("Change Login Password", comment: "change password input label")

    /// "Current login password"
    static let _current_login_password = NSLocalizedString("Current login password", comment: "Title")

    /// "New login password"
    static let _new_login_password = NSLocalizedString("New login password", comment: "Title")

    /// "Confirm new login password"
    static let _confirm_new_login_password = NSLocalizedString("Confirm new login password", comment: "Title")

    /// "Change Mailbox Password"
    static let _change_mailbox_password = NSLocalizedString("Change Mailbox Password", comment: "Title")

    /// "New mailbox password"
    static let _new_mailbox_password = NSLocalizedString("New mailbox password", comment: "Title")

    /// "Confirm new mailbox password"
    static let _confirm_new_mailbox_password = NSLocalizedString("Confirm new mailbox password", comment: "Title")

    /// "Change Single Password"
    static let _change_single_password = NSLocalizedString("Change Single Password", comment: "Title")

    /// "Unable to send the email"
    static let unable_to_send_the_email = NSLocalizedString("Unable to send the email", comment: "error when sending the message")

    /// "The draft format incorrectly sending failed!"
    static let _the_draft_incorrectly_sending_failed = NSLocalizedString("The draft format incorrectly sending failed!", comment: "error when sending the message")

    /// "Star"
    static let _star = NSLocalizedString("Star", comment: "Title")

    /// "ProtonMail"
    static let _protonmail = NSLocalizedString("ProtonMail", comment: "Title")

    /// "Remind Me Later"
    static let _remind_me_later = NSLocalizedString("Remind Me Later", comment: "Title")

    /// "Don't Show Again"
    static let _dont_show_again = NSLocalizedString("Don't Show Again", comment: "Title")

    /// "close tour"
    static let _close_tour = NSLocalizedString("close tour", comment: "Action")

    /// "Support ProtonMail"
    static let _support_protonmail = NSLocalizedString("Support ProtonMail", comment: "Action")


    // Mark : Onboarding
        
    /// "Your new encrypted email account has been set up and is ready to send and receive encrypted messages."
    static let _your_new_account_is_ready_to_send_and_receive_encrypted_messages = NSLocalizedString("Your new encrypted email account has been set up and is ready to send and receive encrypted messages.", comment: "Description")
    /// "You can customize swipe gestures in the ProtonMail App Settings."
    static let _you_can_customize_swipe_in_app_settings = NSLocalizedString("You can customize swipe gestures in the ProtonMail App Settings.", comment: "Description")
    /// "Create and add Labels to organize your inbox. Press and hold down on a message for all options."
    static let _create_and_add_labels_to_organize_inbox_and_hold_down_on_a_message_for_all_options = NSLocalizedString("Create and add Labels to organize your inbox. Press and hold down on a message for all options.", comment: "Description")
    /// "Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail."
    static let _your_inbox_is_now_protected_with_e2e_you_can_also_do_eo = NSLocalizedString("Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail.", comment: "Description")
    /// "Messages you send can be set to auto delete after a certain time period."
    static let _messages_you_send_can_be_set_to_auto_delete_after_a_certain_time_period = NSLocalizedString("Messages you send can be set to auto delete after a certain time period.", comment: "Description")
    /// "You can get help and support at protonmail.com/support. Bugs can also be reported with the app."
    static let _you_can_get_help_and_support_at_protonmail_support_and_bugs = NSLocalizedString("You can get help and support at protonmail.com/support. Bugs can also be reported with the app.", comment: "Description")
    /// "ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail."
    static let _protonmail_doesnt_sell_ads_or_abuse_your_privacy = NSLocalizedString("ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail.", comment: "Description")
    /// "Welcome to ProtonMail!"
    static let _welcome_to_protonmail = NSLocalizedString("Welcome to ProtonMail!", comment: "Title")
    /// "Quick swipe actions"
    static let _quick_swipe_actions = NSLocalizedString("Quick swipe actions", comment: "Title")
    /// "Label Management"
    static let _label_management = NSLocalizedString("Label Management", comment: "Title")
    /// "End-to-End Encryption"
    static let _end_to_end_encryption = NSLocalizedString("End-to-End Encryption", comment: "Title")
    /// "Expiring Messages"
    static let _expiring_messages = NSLocalizedString("Expiring Messages", comment: "Title")
    /// "Help & Support"
    static let _help_and_support = NSLocalizedString("Help & Support", comment: "Title")


    /// "Invalid credential"
    static let _invalid_credential = NSLocalizedString("Invalid credential", comment: "Error")

    /// "The authentication credentials are invalid."
    static let _the_authentication_credentials_are_invalid = NSLocalizedString("The authentication credentials are invalid.", comment: "Description")

    /// "Authentication Failed Wrong username or password"
    static let _authentication_failed_wrong_username_or_password = NSLocalizedString("Authentication Failed Wrong username or password", comment: "Description")

    /// "Unable to connect to the server"
    static let _unable_to_connect_to_the_server = NSLocalizedString("Unable to connect to the server", comment: "Description")

    /// "Unable to parse token"
    static let _unable_to_parse_token = NSLocalizedString("Unable to parse token", comment: "Error")

    /// "Unable to parse authentication token!"
    static let _unable_to_parse_authentication_token = NSLocalizedString("Unable to parse authentication token!", comment: "Description")

    /// "Unable to parse authentication info!"
    static let _unable_to_parse_authentication_info = NSLocalizedString("Unable to parse authentication info!", comment: "Description")

    /// "Invalid Password"
    static let _invalid_password = NSLocalizedString("Invalid Password", comment: "Error")

    /// "Unable to generate hash password!"
    static let _unable_to_generate_hash_password = NSLocalizedString("Unable to generate hash password!", comment: "Description")

    /// "SRP Client"
    static let _srp_client = NSLocalizedString("SRP Client", comment: "Error")

    /// "Unable to create SRP Client!"
    static let _unable_to_create_srp_client = NSLocalizedString("Unable to create SRP Client!", comment: "Description")

    /// "SRP Server"
    static let _srp_server = NSLocalizedString("SRP Server", comment: "Error")

    /// "Server proofs not valid!"
    static let _server_proofs_not_valid = NSLocalizedString("Server proofs not valid!", comment: "Description")

    /// "Srp single password keyslat invalid!"
    static let _srp_single_password_keyslat_invalid = NSLocalizedString("Srp single password keyslat invalid!", comment: "Description")

    /// "Unable to parse cased authentication token!"
    static let _unable_to_parse_cased_authentication_token = NSLocalizedString("Unable to parse cased authentication token!", comment: "Description")

    /// "Bad auth cache"
    static let _bad_auth_cache = NSLocalizedString("Bad auth cache", comment: "Error")

    /// "Local cache can't find mailbox password"
    static let _local_cache_cant_find_mailbox_password = NSLocalizedString("Local cache can't find mailbox password", comment: "Description")

    /// "Date: %@"
    static let _date = NSLocalizedString("Date: %@", comment: "like Date: 2017-10-10")

    /// "Details"
    static let _details = NSLocalizedString("Details", comment: "Title")

    /// "Hide Details"
    static let _hide_details = NSLocalizedString("Hide Details", comment: "Title")

    /// "Phone number"
    static let _phone_number = NSLocalizedString("Phone number", comment: "contact placeholder")

    /// "Username"
    static let _username = NSLocalizedString("Username", comment: "Title")

    
    

    /// "Create a new account"
    static let _create_a_new_account = NSLocalizedString("Create a new account", comment: "Signup top title")

    /// "Note: The Username is also your ProtonMail address."
    static let _notes_the_username_is_also_your_protonmail_address = NSLocalizedString("Note: The Username is also your ProtonMail address.", comment: "Signup user name notes")

    /// "By using protonmail, you agree to our"
    static let _notes_by_using_protonmail_you_agree_to_our = NSLocalizedString("By using protonmail, you agree to our", comment: "agree check box first part words")

    /// "terms and conditions"
    static let _notes_terms_and_conditions = NSLocalizedString("terms and conditions", comment: "agree check box terms")

    /// "and"
    static let _and = NSLocalizedString("and", comment: "agree check box middle word")

    /// "privacy policy."
    static let _privacy_policy = NSLocalizedString("privacy policy.", comment: "agree check box privacy")

    /// "Checking ...."
    static let _checking_ = NSLocalizedString("Checking ....", comment: "loading message")

    /// "User is available!"
    static let _user_is_available = NSLocalizedString("User is available!", comment: "")

    /// "User already exist!"
    static let _user_already_exist = NSLocalizedString("User already exist!", comment: "error when user already exist")

    /// "Please pick a user name first!"
    static let _please_pick_a_user_name_first = NSLocalizedString("Please pick a user name first!", comment: "Error")

    /// "In order to use our services, you must agree to ProtonMail's Terms of Service."
    static let _in_order_to_use_our_services_you_must_agree_to_protonmails_terms_of_service = NSLocalizedString("In order to use our services, you must agree to ProtonMail's Terms of Service.", comment: "Error")

    /// "Update Contact"
    static let _update_contact = NSLocalizedString("Update Contact", comment: "Contacts Update contact")

    /// "Do you want to save the unsaved changes?"
    static let _do_you_want_to_save_the_unsaved_changes = NSLocalizedString("Do you want to save the unsaved changes?", comment: "Title")

    /// "Discard changes"
    static let _discard_changes = NSLocalizedString("Discard changes", comment: "Action")

    /// "Add new url"
    static let _add_new_url = NSLocalizedString("Add new url", comment: "action")
    
    /// "English"
    static let _english = NSLocalizedString("English", comment: "Action")
    /// "German"
    static let _german = NSLocalizedString("German", comment: "Action")
    /// "French"
    static let _french = NSLocalizedString("French", comment: "Action")
    /// "Russian"
    static let _russian = NSLocalizedString("Russian", comment: "Action")
    /// "Spanish"
    static let _spanish = NSLocalizedString("Spanish", comment: "Action")
    /// "Turkish"
    static let _turkish = NSLocalizedString("Turkish", comment: "Action")
    /// "Polish"
    static let _polish = NSLocalizedString("Polish", comment: "Action")
    /// "Ukrainian"
    static let _ukrainian = NSLocalizedString("Ukrainian", comment: "Action")
    /// "Dutch"
    static let _dutch = NSLocalizedString("Dutch", comment: "Action")
    /// "Italian"
    static let _italian = NSLocalizedString("Italian", comment: "Action")
    /// "Portuguese Brazil"
    static let _portuguese_brazil = NSLocalizedString("Portuguese Brazil", comment: "Action")

    /// "Message Queue"
    static let _message_queue = NSLocalizedString("Message Queue", comment: "settings debug section title")
    /// "Error Logs"
    static let _error_logs = NSLocalizedString("Error Logs", comment: "settings debug section title")
    
    /// "Login Password"
    static let _login_password = NSLocalizedString("Login Password", comment: "settings general section title")
    /// "Mailbox Password"
    static let _mailbox_password = NSLocalizedString("Mailbox Password", comment: "settings general section title")
    /// "Single Password"
    static let _single_password = NSLocalizedString("Single Password", comment: "settings general section title")
    /// "Clear Local Message Cache"
    static let _clear_local_message_cache = NSLocalizedString("Clear Local Message Cache", comment: "settings general section title")
    /// "Auto Show Images"
    static let _auto_show_images = NSLocalizedString("Auto Show Images", comment: "settings general section title")
    /// "Swipe Left to Right"
    static let _swipe_left_to_right = NSLocalizedString("Swipe Left to Right", comment: "settings swipe actions section title")
    /// "Swipe Right to Left"
    static let _swipe_right_to_left = NSLocalizedString("Swipe Right to Left", comment: "settings swipe actions section title")
    /// "Change left swipe action"
    static let _change_left_swipe_action = NSLocalizedString("Change left swipe action", comment: "settings swipe actions section action description")
    /// "Change right swipe action"
    static let _change_right_swipe_action = NSLocalizedString("Change right swipe action", comment: "settings swipe actions section action description")
    /// "Enable TouchID"
    static let _enable_touchid = NSLocalizedString("Enable TouchID", comment: "settings protection section title")
    /// "Enable Pin Protection"
    static let _enable_pin_protection = NSLocalizedString("Enable Pin Protection", comment: "settings protection section title")
    /// "Change Pin"
    static let _change_pin = NSLocalizedString("Change Pin", comment: "settings protection section title")
    /// "Protection Entire App"
    static let _protection_entire_app = NSLocalizedString("Protection Entire App", comment: "settings protection section title")
    /// "Enable FaceID"
    static let _enable_faceid = NSLocalizedString("Enable FaceID", comment: "settings protection section title")

    
    
    // Mark Settings section title
    
    /// "Debug"
    static let _debug = NSLocalizedString("Debug", comment: "Title")
    /// "General Settings"
    static let _general_settings = NSLocalizedString("General Settings", comment: "Title")
    /// "Multiple Addresses"
    static let _multiple_addresses = NSLocalizedString("Multiple Addresses", comment: "Title")
    /// "Storage"
    static let _storage = NSLocalizedString("Storage", comment: "Title")
    /// "Message Swipe Actions"
    static let _message_swipe_actions = NSLocalizedString("Message Swipe Actions", comment: "Title")
    /// "Protection"
    static let _protection = NSLocalizedString("Protection", comment: "Title")
    /// "Language"
    static let _language = NSLocalizedString("Language", comment: "Title")
    /// "Labels/Folders"
    static let _labels_folders = NSLocalizedString("Labels/Folders", comment: "Title")


    /// "You have unsaved changes. Do you want to save it?"
    static let _you_have_unsaved_changes_do_you_want_to_save_it = NSLocalizedString("You have unsaved changes. Do you want to save it?", comment: "Confirmation message")

    /// "Save Changes"
    static let _save_changes = NSLocalizedString("Save Changes", comment: "title")

    /// "Recovery Code"
    static let _recovery_code = NSLocalizedString("Recovery Code", comment: "Title")

    /// "Two Factor Code"
    static let _two_factor_code = NSLocalizedString("Two Factor Code", comment: "Placeholder")

    /// "Authentication"
    static let _authentication = NSLocalizedString("Authentication", comment: "Title")

    /// "Enter"
    static let _enter = NSLocalizedString("Enter", comment: "Action")

    /// "Space Warning"
    static let _space_warning = NSLocalizedString("Space Warning", comment: "Title")

    /// "Hide"
    static let _hide = NSLocalizedString("Hide", comment: "Action")

    /// "Change Password"
    static let _change_password = NSLocalizedString("Change Password", comment: "update password error title")

    /// "Can't get a Moduls ID!"
    static let _cant_get_a_moduls_id = NSLocalizedString("Can't get a Moduls ID!", comment: "update password error = typo:Modulus")

    /// "Can't get a Moduls!"
    static let _cant_get_a_moduls = NSLocalizedString("Can't get a Moduls!", comment: "update password error = typo:Modulus")

    /// "Invalid hashed password!"
    static let _invalid_hashed_password = NSLocalizedString("Invalid hashed password!", comment: "update password error")

    /// "Can't create a SRP verifier!"
    static let _cant_create_a_srp_verifier = NSLocalizedString("Can't create a SRP verifier!", comment: "update password error")

    /// "Can't create a SRP Client"
    static let _cant_create_a_srp_client = NSLocalizedString("Can't create a SRP Client", comment: "update password error")

    /// "Can't get user auth info"
    static let _cant_get_user_auth_info = NSLocalizedString("Can't get user auth info", comment: "update password error")

    /// "The Password is wrong."
    static let _the_password_is_wrong = NSLocalizedString("The Password is wrong.", comment: "update password error")

    /// "The new password not match."
    static let _the_new_password_not_match = NSLocalizedString("The new password not match.", comment: "update password error")

    /// "The new password can't empty."
    static let _the_new_password_cant_empty = NSLocalizedString("The new password can't empty.", comment: "update password error")

    /// "The private key update failed."
    static let _the_private_key_update_failed = NSLocalizedString("The private key update failed.", comment: "update password error")

    /// "Password update failed"
    static let _password_update_failed = NSLocalizedString("Password update failed", comment: "update password error")

    /// "Update Notification Email"
    static let _update_notification_email = NSLocalizedString("Update Notification Email", comment: "update notification email error title")



    /// "Unable to get contacts"
    static let _unable_to_get_contacts = NSLocalizedString("Unable to get contacts", comment: "Error")

    /// "Apply Labels"
    static let _apply_labels = NSLocalizedString("Apply Labels", comment: "Title")

    /// "Can't download message body, please try again."
    static let _cant_download_message_body_please_try_again = NSLocalizedString("Can't download message body, please try again.", comment: "Error")

    /// "Print"
    static let _print = NSLocalizedString("Print", comment: "Action")

    /// "Unable to decrypt message."
    static let _unable_to_decrypt_message = NSLocalizedString("Unable to decrypt message.", comment: "Error")

    /// "Loading..."
    static let _loading_ = NSLocalizedString("Loading...", comment: "")

    /// "Please wait until the email downloaded!"
    static let _please_wait_until_the_email_downloaded = NSLocalizedString("Please wait until the email downloaded!", comment: "The")

    /// "Can't decrypt this attachment!"
    static let _cant_decrypt_this_attachment = NSLocalizedString("Can't decrypt this attachment!", comment: "When quick look attachment but can't decrypt it!")

    /// "Can't find this attachment!"
    static let _cant_find_this_attachment = NSLocalizedString("Can't find this attachment!", comment: "when quick look attachment but can't find the data")

    /// "Encryption Setup"
    static let _encryption_setup = NSLocalizedString("Encryption Setup", comment: "key setup top title")

    /// "High Security"
    static let _high_security = NSLocalizedString("High Security", comment: "Key size checkbox")

    /// "Extreme Security"
    static let _extreme_security = NSLocalizedString("Extreme Security", comment: "Key size checkbox")

    /// "The current standard"
    static let _the_current_standard = NSLocalizedString("The current standard", comment: "key size notes")

    /// "The highest level of encryption available."
    static let _the_highest_level_of_encryption_available = NSLocalizedString("The highest level of encryption available.", comment: "key size note part 1")

    /// "Can take several minutes to setup."
    static let _can_take_several_minutes_to_setup = NSLocalizedString("Can take several minutes to setup.", comment: "key size note part 2")

    

    /// "Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer."
    static let _mobile_signups_are_disabled_pls_later_pm_com = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.", comment: "Description")

    /// "Key generation failed"
    static let _key_generation_failed = NSLocalizedString("Key generation failed", comment: "Error")

    /// "Your Country Code"
    static let _your_country_code = NSLocalizedString("Your Country Code", comment: "view top title")

    /// "DECRYPT MAILBOX"
    static let _decrypt_mailbox = NSLocalizedString("DECRYPT MAILBOX", comment: "Title")

    /// "Decrypt"
    static let _decrypt = NSLocalizedString("Decrypt", comment: "Action")

    /// "RESET MAILBOX PASSWORD"
    static let _reset_mailbox_password = NSLocalizedString("RESET MAILBOX PASSWORD", comment: "Action")

    /// "The mailbox password is incorrect."
    static let _the_mailbox_password_is_incorrect = NSLocalizedString("The mailbox password is incorrect.", comment: "Error")

    /// "Incorrect password"
    static let _incorrect_password = NSLocalizedString("Incorrect password", comment: "Title")


    /// "To reset your mailbox password, please use the web version of ProtonMail at protonmail.com"
    static let _to_reset_your_mailbox_password_please_use_the_web_version_of_protonmail = NSLocalizedString("To reset your mailbox password, please use the web version of ProtonMail at protonmail.com", comment: "Description")

    /// "Recovery Email"
    static let _recovery_email = NSLocalizedString("Recovery Email", comment: "Title")
    /// "Congratulations!"
    static let _congratulations = NSLocalizedString("Congratulations!", comment: "view top title")

    /// "Your new secure email\r\n account is ready."
    static let _your_new_secure_email_account_is_ready = NSLocalizedString("Your new secure email\r\n account is ready.", comment: "view top title")

    /// "When you send an email, this is the name that appears in the sender field."
    static let _send_an_email_this_name_that_appears_in_sender_field = NSLocalizedString("When you send an email, this is the name that appears in the sender field.", comment: "display name notes")

    /// "The optional recovery email address allows you to reset your login password if you forget it."
    static let _the_optional_recovery_email_address_allows_you_to_reset_your_login_password_if_you_forget_it = NSLocalizedString("The optional recovery email address allows you to reset your login password if you forget it.", comment: "recovery email notes")

    /// "Keep me updated about new features"
    static let _keep_me_updated_about_new_features = NSLocalizedString("Keep me updated about new features", comment: "Title")

    /// "Go to inbox"
    static let _go_to_inbox = NSLocalizedString("Go to inbox", comment: "Action")

    /// "Recovery Email Warning"
    static let _recovery_email_warning = NSLocalizedString("Recovery Email Warning", comment: "Title")

    /// "Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?"
    static let _warning_did_not_set_a_recovery_email_so_account_recovery_is_impossible = NSLocalizedString("Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?", comment: "Description")
    
    /// "To prevent abuse of ProtonMail,\r\n we need to verify that you are human."
    static let _to_prevent_abuse_of_protonmail_we_need_to_verify_that_you_are_human = NSLocalizedString("To prevent abuse of ProtonMail,\r\n we need to verify that you are human.", comment: "human verification notes")

    /// "Please select one of the following options:"
    static let _please_select_one_of_the_following_options = NSLocalizedString("Please select one of the following options:", comment: "human check select option title")

    /// "CAPTCHA"
    static let _captcha = NSLocalizedString("CAPTCHA", comment: "human check option button")

    /// "Email Verification"
    static let _email_verification = NSLocalizedString("Email Verification", comment: "human check option button")

    /// "Phone Verification"
    static let _phone_verification = NSLocalizedString("Phone Verification", comment: "human check option button")

    /// "Verification error"
    static let _verification_error = NSLocalizedString("Verification error", comment: "error title")

    /// "Verification of this content’s signature failed"
    static let _verification_of_this_contents_signature_failed = NSLocalizedString("Verification of this content’s signature failed", comment: "error details")

    /// "Decryption error"
    static let _decryption_error = NSLocalizedString("Decryption error", comment: "error title")

    /// "Decryption of this content failed"
    static let _decryption_of_this_content_failed = NSLocalizedString("Decryption of this content failed", comment: "error details")

    /// "Logs"
    static let _logs = NSLocalizedString("Logs", comment: "error title")

    /// "normal attachments"
    static let _normal_attachments = NSLocalizedString("normal attachments", comment: "Title")

    /// "inline attachments"
    static let _inline_attachments = NSLocalizedString("inline attachments", comment: "Title")

    /// "Photo Library"
    static let _photo_library = NSLocalizedString("Photo Library", comment: "Title")

    /// "Take a Photo"
    static let _take_a_photo = NSLocalizedString("Take a Photo", comment: "Title")

    /// "Import File From..."
    static let _import_file_from_ = NSLocalizedString("Import File From...", comment: "Title")

    /// "The total attachment size can't be bigger than 25MB"
    static let _the_total_attachment_size_cant_be_bigger_than_25mb = NSLocalizedString("The total attachment size can't be bigger than 25MB", comment: "Description")

    /// "Can't load the file"
    static let _cant_load_the_file = NSLocalizedString("Can't load the file", comment: "Error")

    /// "System can't copy the file"
    static let _system_cant_copy_the_file = NSLocalizedString("System can't copy the file", comment: "Error")

    /// "Can't open the file"
    static let _cant_open_the_file = NSLocalizedString("Can't open the file", comment: "Error")


    /// "Cell phone number"
    static let _cell_phone_number = NSLocalizedString("Cell phone number", comment: "place holder")

    /// "Enter your cell phone number"
    static let _enter_your_cell_phone_number = NSLocalizedString("Enter your cell phone number", comment: "human verification top title")

    /// "We will send a verification code to the cell phone above."
    static let _we_will_send_a_verification_code_to_the_cell_phone_above = NSLocalizedString("We will send a verification code to the cell phone above.", comment: "text field notes")
    
    /// "Phone number invalid"
    static let _phone_number_invalid = NSLocalizedString("Phone number invalid", comment: "Title")

    /// "Please input a valid cell phone number."
    static let _please_input_a_valid_cell_phone_number = NSLocalizedString("Please input a valid cell phone number.", comment: "Description")

    /// "Please check your cell phone for the verification code."
    static let _please_check_your_cell_phone_for_the_verification_code = NSLocalizedString("Please check your cell phone for the verification code.", comment: "Description")
    /// "Got it"
    static let _got_it = NSLocalizedString("Got it", comment: "Action")

    /// "PREMIUM FEATURE"
    static let _premium_feature = NSLocalizedString("PREMIUM FEATURE", comment: "Upgrade warning title")

    /// "Looking to secure your contact's details?"
    static let _looking_to_secure_your_contacts_details = NSLocalizedString("Looking to secure your contact's details?", comment: "Upgrade warning title")

    /// "ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email."
    static let _protonmail_plus_enables_you_to_add_and_edit_contact_details_beyond_ = NSLocalizedString("ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email.", comment: "Upgrade warning message")

    /// "Upgrading is not possible in the app."
    static let _upgrading_is_not_possible_in_the_app = NSLocalizedString("Upgrading is not possible in the app.", comment: "Upgrade warning message")

    /// "The verification failed!"
    static let _the_verification_failed = NSLocalizedString("The verification failed!", comment: "Error")

    /// "Retry"
    static let _retry = NSLocalizedString("Retry", comment: "Action")

    /// "Unknow Error"
    static let _unknow_error = NSLocalizedString("Unknow Error", comment: "Description")

    
    /// "Message expired"
    static let _message_expired = NSLocalizedString("Message expired", comment: "")

    /// "Expires in %d days %d hours %d mins %d seconds"
    static let _expires_in_days_hours_mins_seconds = NSLocalizedString("Expires in %d days %d hours %d mins %d seconds", comment: "expiration time count down")

    /// "Sign Out"
    static let _sign_out = NSLocalizedString("Sign Out", comment: "Action")

    /// "Rate & Review"
    static let _rate_review = NSLocalizedString("Rate & Review", comment: "Title")

    /// "Tweet about ProtonMail"
    static let _tweet_about_protonmail = NSLocalizedString("Tweet about ProtonMail", comment: "Title")

    /// "Share it with your friends"
    static let _share_it_with_your_friends = NSLocalizedString("Share it with your friends", comment: "Title")

    /// "Contact the ProtonMail team"
    static let _contact_the_protonmail_team = NSLocalizedString("Contact the ProtonMail team", comment: "Title")

    /// "Trouble shooting guide"
    static let _trouble_shooting_guide = NSLocalizedString("Trouble shooting guide", comment: "Title")

    /// "Help us to make privacy the default in the web."
    static let _help_us_to_make_privacy_the_default_in_the_web = NSLocalizedString("Help us to make privacy the default in the web.", comment: "Title")

    /// "Help us to improve ProtonMail with your input."
    static let _help_us_to_improve_protonmail_with_your_input = NSLocalizedString("Help us to improve ProtonMail with your input.", comment: "Title")

    /// "We would like to know what we can do better."
    static let _we_would_like_to_know_what_we_can_do_better = NSLocalizedString("We would like to know what we can do better.", comment: "Title")
    

    /// "USER LOGIN"
    static let _user_login = NSLocalizedString("USER LOGIN", comment: "Title")

    /// "NEED AN ACCOUNT? SIGN UP."
    static let _need_an_account_sign_up = NSLocalizedString("NEED AN ACCOUNT? SIGN UP.", comment: "Action")

    /// "FORGOT PASSWORD?"
    static let _forgot_password = NSLocalizedString("FORGOT PASSWORD?", comment: "login page forgot pwd")




    /// "Please use the web application to reset your password."
    static let _please_use_the_web_application_to_reset_your_password = NSLocalizedString("Please use the web application to reset your password.", comment: "Alert")

    /// "Bug Description"
    static let _bug_description = NSLocalizedString("Bug Description", comment: "Title")
    
    /// "Bug Report Received"
    static let _bug_report_received = NSLocalizedString("Bug Report Received", comment: "Title")

    /// "Thank you for submitting a bug report.  We have added your report to our bug tracking system."
    static let _thank_you_for_submitting_a_bug_report_we_have_added_your_report_to_our_bug_tracking_system = NSLocalizedString("Thank you for submitting a bug report.  We have added your report to our bug tracking system.", comment: "")

    /// "Label as..."
    static let _label_as_ = NSLocalizedString("Label as...", comment: "Title")

    /// "Move to..."
    static let _move_to_ = NSLocalizedString("Move to...", comment: "Title")

    /// "Mark as unread"
    static let _mark_as_unread = NSLocalizedString("Mark as unread", comment: "Action")

    /// "All of your existing encrypted emails will be lost forever, but you will still be able to view your unencrypted emails.\n\nTHIS ACTION CANNOT BE UNDONE!"
    static let _all_of_your_existing_encrypted_emails_will_be_lost_forever_but_you_will_still_be_able_to_view_your_unencrypted_emails_ = NSLocalizedString("All of your existing encrypted emails will be lost forever, but you will still be able to view your unencrypted emails.\n\nTHIS ACTION CANNOT BE UNDONE!", comment: "Description")

    /// "Display Name Updated"
    static let _display_name_updated = NSLocalizedString("Display Name Updated", comment: "Title")

    /// "The display name is now %@."
    static let _the_display_name_is_now = NSLocalizedString("The display name is now %@.", comment: "Description")

    /// "Signature Updated"
    static let _signature_updated = NSLocalizedString("Signature Updated", comment: "Title")

    /// "Your signature has been updated."
    static let _your_signature_has_been_updated = NSLocalizedString("Your signature has been updated.", comment: "Description")

    /// "Password Mismatch"
    static let _password_mismatch = NSLocalizedString("Password Mismatch", comment: "Title")

    /// "The password you entered does not match the current password."
    static let _the_password_you_entered_does_not_match_the_current_password = NSLocalizedString("The password you entered does not match the current password.", comment: "Description")

    /// "Password Updated"
    static let _password_updated = NSLocalizedString("Password Updated", comment: "Title")

    /// "Please use your new password when signing in."
    static let _please_use_your_new_password_when_signing_in = NSLocalizedString("Please use your new password when signing in.", comment: "Description")

    /// "The passwords you entered do not match."
    static let _the_passwords_you_entered_do_not_match = NSLocalizedString("The passwords you entered do not match.", comment: "Description")

    /// "Can't load share content!"
    static let _cant_load_share_content = NSLocalizedString("Can't load share content!", comment: "Description")

    /// "Share Alert"
    static let _share_alert = NSLocalizedString("Share Alert", comment: "Title")

    /// "Please use ProtonMail App login first"
    static let _please_use_protonmail_app_login_first = NSLocalizedString("Please use ProtonMail App login first", comment: "Description")
 

}
