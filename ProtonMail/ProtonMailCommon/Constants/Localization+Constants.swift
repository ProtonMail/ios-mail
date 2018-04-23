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
    
    
    // Mark Composer

    /// "Re:"
    static let _composer_short_reply = NSLocalizedString("Re:", comment: "abbreviation of reply:")
    /// "Fwd:"
    static let _composer_short_forward = NSLocalizedString("Fwd:", comment: "abbreviation of forward:")
    /// "On"
    static let _composer_on = NSLocalizedString("On", comment: "Title")
    /// "wrote:"
    static let _composer_wrote = NSLocalizedString("wrote:", comment: "Title")
    /// "Date:"
    static let _composer_date_field = NSLocalizedString("Date:", comment: "message Date: text")
    /// "Subject:"
    static let _composer_subject_field = NSLocalizedString("Subject:", comment: "subject: text when forward")
    /// "Forwarded message"
    static let _composer_fwd_message = NSLocalizedString("Forwarded message", comment: "forwarded message title")
    /// "Set Password"
    static let _composer_set_password = NSLocalizedString("Set Password", comment: "Title")
    /// "Set a password to encrypt this message for non-ProtonMail users."
    static let _composer_eo_desc = NSLocalizedString("Set a password to encrypt this message for non-ProtonMail users.", comment: "Description")
    /// "Get more information"
    static let _composer_eo_info = NSLocalizedString("Get more information", comment: "Action")
    /// "Message Password"
    static let _composer_eo_msg_pwd_placeholder = NSLocalizedString("Message Password", comment: "Placeholder")
    /// "The message password can't be empty"
    static let _composer_eo_empty_pwd_desc = NSLocalizedString("The message password can't be empty", comment: "Description")
    /// "Confirm Password"
    static let _composer_eo_confirm_pwd_placeholder = NSLocalizedString("Confirm Password", comment: "Placeholder")
    /// "The message password didn't match"
    static let _composer_eo_dismatch_pwd_desc = NSLocalizedString("The message password didn't match", comment: "Description")

    
    
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
    /// "Folder Name"
    static let _labels_folder_name_text     = NSLocalizedString("Folder Name", comment: "place holder")
    /// "Label Name"
    static let _labels_label_name_text      = NSLocalizedString("Label Name", comment: "createing lable input place holder")
    /// "Create"
    static let _labels_create_action        = NSLocalizedString("Create", comment: "top right action text")
    /// "Manage Labels/Folders"
    static let _labels_manage_title = NSLocalizedString("Manage Labels/Folders", comment: "Title")

    
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
    static let _general_from_label = NSLocalizedString("From:", comment: "message From: field text")
    /// "To:"
    static let _general_to_label = NSLocalizedString("To:", comment: "message To: feild")
    /// "Cc:"
    static let _general_cc_label = NSLocalizedString("Cc:", comment: "message Cc: feild")
    /// "at"
    static let _general_at_label = NSLocalizedString("at", comment: "like at 10:00pm")
    /// "Delete"
    static let _general_delete_action = NSLocalizedString("Delete", comment: "general delete action")
    /// "Close"
    static let _general_close_action = NSLocalizedString("Close", comment: "general close action")
    
    

    
//    /// "Custom"
//    static let custom = NSLocalizedString("Custom", comment: "default label type")
//
//    /// "Edit Label"
//    static let edit_label = NSLocalizedString("Edit Label", comment: "Title")
//
//    /// "Label Name"
//    static let label_name = NSLocalizedString("Label Name", comment: "place holder")
//
//    /// "Update"
//    static let update = NSLocalizedString("Update", comment: "top right action text")
//
//    /// "Message sent"
//    static let message_sent = NSLocalizedString("Message sent", comment: "Description")
//
//    /// "Sending Failed"
//    static let sending_failed = NSLocalizedString("Sending Failed", comment: "Description")
//
//    /// "Sent Failed"
//    static let sent_failed = NSLocalizedString("Sent Failed", comment: "Description")
//
//    /// "The draft cache is broken please try again"
//    static let the_draft_cache_is_broken_please_try_again = NSLocalizedString("The draft cache is broken please try again", comment: "Description")
//
//    /// "Invalid access token please relogin"
//    static let invalid_access_token_please_relogin = NSLocalizedString("Invalid access token please relogin", comment: "Description")
//
//    /// "A new version of ProtonMail app is available, please update to latest version."
//    static let a_new_version_of_protonmail_app_is_available,_please_update_to_latest_version. = NSLocalizedString("A new version of ProtonMail app is available, please update to latest version.", comment: "Description")
//
//    /// "Search"
//    static let search = NSLocalizedString("Search", comment: "Title")
//
//    /// "Invalid UserName"
//    static let invalid_username = NSLocalizedString("Invalid UserName", comment: "Error")
//
//    /// "The UserName have been taken."
//    static let the_username_have_been_taken. = NSLocalizedString("The UserName have been taken.", comment: "Error Description")
//
//    /// "Bad parameter"
//    static let bad_parameter = NSLocalizedString("Bad parameter", comment: "Description")
//
//    /// "Bad parameter: %@"
//    static let bad_parameter:_%@ = NSLocalizedString("Bad parameter: %@", comment: "Description")
//
//    /// "Bad path"
//    static let bad_path = NSLocalizedString("Bad path", comment: "Description")
//
//    /// "Unable to construct a valid URL with the following path: %@"
//    static let unable_to_construct_a_valid_url_with_the_following_path:_%@ = NSLocalizedString("Unable to construct a valid URL with the following path: %@", comment: "Description")
//
//    /// "Bad response"
//    static let bad_response = NSLocalizedString("Bad response", comment: "Description")
//
//    /// "Can't not find the value from the response body"
//    static let can't_not_find_the_value_from_the_response_body = NSLocalizedString("Can't not find the value from the response body", comment: "Description")
//
//    /// "<no object>"
//    static let <no_object> = NSLocalizedString("<no object>", comment: "no object error, local only , this could be not translated!")
//
//    /// "Unable to parse response"
//    static let unable_to_parse_response = NSLocalizedString("Unable to parse response", comment: "Description")
//
//    /// "Unable to parse the response object:\n%@"
//    static let unable_to_parse_the_response_object:\n%@ = NSLocalizedString("Unable to parse the response object:\n%@", comment: "Description")
//
//    /// "Draft"
//    static let draft = NSLocalizedString("Draft", comment: "Action")
//
//    /// "OpenDraft"
//    static let opendraft = NSLocalizedString("OpenDraft", comment: "Action")
//
//    /// "Url"
//    static let url = NSLocalizedString("Url", comment: "default vcard types")
//
//    /// "Failed to initialize the application's saved data"
//    static let failed_to_initialize_the_application's_saved_data = NSLocalizedString("Failed to initialize the application's saved data", comment: "Description")
//
//    /// "There was an error creating or loading the application's saved data."
//    static let there_was_an_error_creating_or_loading_the_application's_saved_data. = NSLocalizedString("There was an error creating or loading the application's saved data.", comment: "Description")
//
//
//    /// "Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@"
//    static let sending_messages_from_%@_address_is_a_paid_feature._your_message_will_be_sent_from_your_default_address_%@ = NSLocalizedString("Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@", comment: "pm.me upgrade warning in composer")
//
//    /// "Notice"
//    static let notice = NSLocalizedString("Notice", comment: "Alert")
//
//    /// "Don't remind me again"
//    static let don't_remind_me_again = NSLocalizedString("Don't remind me again", comment: "Action")
//
//    /// "Compose"
//    static let compose = NSLocalizedString("Compose", comment: "Action")
//
//    /// "Send message without subject?"
//    static let send_message_without_subject? = NSLocalizedString("Send message without subject?", comment: "Description")
//
//    /// "Send"
//    static let send = NSLocalizedString("Send", comment: "Action")
//
//    /// "You need at least one recipient to send"
//    static let you_need_at_least_one_recipient_to_send = NSLocalizedString("You need at least one recipient to send", comment: "Description")
//
//    /// "Confirmation"
//    static let confirmation = NSLocalizedString("Confirmation", comment: "Title")
//
//    /// "Save draft"
//    static let save_draft = NSLocalizedString("Save draft", comment: "Action")
//
//    /// "Discard draft"
//    static let discard_draft = NSLocalizedString("Discard draft", comment: "Action")
//
//    /// "Change sender address to .."
//    static let change_sender_address_to_.. = NSLocalizedString("Change sender address to ..", comment: "Title")
//
//    /// "Upgrade to a paid plan to send from your %@ address"
//    static let upgrade_to_a_paid_plan_to_send_from_your_%@_address = NSLocalizedString("Upgrade to a paid plan to send from your %@ address", comment: "Error")
//
//    /// "days"
//    static let days = NSLocalizedString("days", comment: "")
//
//    /// "Hours"
//    static let hours = NSLocalizedString("Hours", comment: "")
//
//    /// "days"
//    static let days = NSLocalizedString("days", comment: "")
//
//    /// "Hours"
//    static let hours = NSLocalizedString("Hours", comment: "")
//
//    /// "Street"
//    static let street = NSLocalizedString("Street", comment: "contact placeholder")
//
//    /// "Street"
//    static let street = NSLocalizedString("Street", comment: "contact placeholder")
//
//    /// "City"
//    static let city = NSLocalizedString("City", comment: "contact placeholder")
//
//    /// "State"
//    static let state = NSLocalizedString("State", comment: "contact placeholder")
//
//    /// "ZIP"
//    static let zip = NSLocalizedString("ZIP", comment: "contact placeholder")
//
//    /// "Country"
//    static let country = NSLocalizedString("Country", comment: "contact placeholder")
//
//    /// "Move to Folder"
//    static let move_to_folder = NSLocalizedString("Move to Folder", comment: "folder apply - title")
//
//    /// "Navigation Title - Test"
//    static let navigation_title_-_test = NSLocalizedString("Navigation Title - Test", comment: "Test")
//
//    /// "this is description - Test"
//    static let this_is_description_-_test = NSLocalizedString("this is description - Test", comment: "Test")
//
//    /// "Section Title - Test"
//    static let section_title_-_test = NSLocalizedString("Section Title - Test", comment: "Test")
//
//    /// "Enable - Test"
//    static let enable_-_test = NSLocalizedString("Enable - Test", comment: "Test")
//
//    /// "Please input ... - Test"
//    static let please_input_..._-_test = NSLocalizedString("Please input ... - Test", comment: "Test")
//
//    /// "test value"
//    static let test_value = NSLocalizedString("test value", comment: "Test")
//
//    /// "DisplayName"
//    static let displayname = NSLocalizedString("DisplayName", comment: "Title")
//
//    /// "DISPLAY NAME"
//    static let display_name = NSLocalizedString("DISPLAY NAME", comment: "Title")
//
//    /// "Input Display Name ..."
//    static let input_display_name_... = NSLocalizedString("Input Display Name ...", comment: "place holder")
//
//    /// "Signature"
//    static let signature = NSLocalizedString("Signature", comment: "Title")
//
//    /// "Email default signature"
//    static let email_default_signature = NSLocalizedString("Email default signature", comment: "place holder")
//
//    /// "SIGNATURE"
//    static let signature = NSLocalizedString("SIGNATURE", comment: "Title")
//
//    /// "Enable Default Signature"
//    static let enable_default_signature = NSLocalizedString("Enable Default Signature", comment: "Title")
//
//    /// "Mobile Signature"
//    static let mobile_signature = NSLocalizedString("Mobile Signature", comment: "Title")
//
//    /// "Only a paid user can modify default mobile signature or turn it off!"
//    static let only_a_paid_user_can_modify_default_mobile_signature_or_turn_it_off! = NSLocalizedString("Only a paid user can modify default mobile signature or turn it off!", comment: "Description")
//
//    /// "Only plus user could modify default mobile signature or turn it off!"
//    static let only_plus_user_could_modify_default_mobile_signature_or_turn_it_off! = NSLocalizedString("Only plus user could modify default mobile signature or turn it off!", comment: "Description")
//
//    /// "Mobile Signature"
//    static let mobile_signature = NSLocalizedString("Mobile Signature", comment: "Title")
//
//    /// "Enable Mobile Signature"
//    static let enable_mobile_signature = NSLocalizedString("Enable Mobile Signature", comment: "Title")
//
//    /// "ProtonMail Plus is required to customize your mobile signature"
//    static let protonmail_plus_is_required_to_customize_your_mobile_signature = NSLocalizedString("ProtonMail Plus is required to customize your mobile signature", comment: "Description")
//
//    /// "Notification Email"
//    static let notification_email = NSLocalizedString("Notification Email", comment: "Title")
//
//    /// "Also used to reset a forgotten password."
//    static let also_used_to_reset_a_forgotten_password. = NSLocalizedString("Also used to reset a forgotten password.", comment: "Description")
//
//    /// "Notification / Recovery Email"
//    static let notification_/_recovery_email = NSLocalizedString("Notification / Recovery Email", comment: "Title")
//
//    /// "Enable Notification Email"
//    static let enable_notification_email = NSLocalizedString("Enable Notification Email", comment: "Title")
//
//    /// "Input Notification Email ..."
//    static let input_notification_email_... = NSLocalizedString("Input Notification Email ...", comment: "place holder")
//
//    /// "Edit Folder"
//    static let edit_folder = NSLocalizedString("Edit Folder", comment: "Title")
//
//    /// "Folder Name"
//    static let folder_name = NSLocalizedString("Folder Name", comment: "folder editing editfeild place holder")
//
//    /// "Update"
//    static let update = NSLocalizedString("Update", comment: "right top action button")
//
//    /// "Message password does not match."
//    static let message_password_does_not_match. = NSLocalizedString("Message password does not match.", comment: "Error")
//
//    /// "Password cannot be empty."
//    static let password_cannot_be_empty. = NSLocalizedString("Password cannot be empty.", comment: "Error")
//
//    /// "Please set a password."
//    static let please_set_a_password. = NSLocalizedString("Please set a password.", comment: "Description")
//
//    /// "From"
//    static let from = NSLocalizedString("From", comment: "Title")
//
//    /// "Subject"
//    static let subject = NSLocalizedString("Subject", comment: "Placeholder")
//
//    /// "Define Expiration Date"
//    static let define_expiration_date = NSLocalizedString("Define Expiration Date", comment: "Placeholder")
//
//    /// "Define Password"
//    static let define_password = NSLocalizedString("Define Password", comment: "place holder")
//
//    /// "Define Password"
//    static let define_password = NSLocalizedString("Define Password", comment: "place holder")
//
//    /// "To"
//    static let to = NSLocalizedString("To", comment: "Title")
//
//    /// "Cc"
//    static let cc = NSLocalizedString("Cc", comment: "Title")
//
//    /// "Bcc"
//    static let bcc = NSLocalizedString("Bcc", comment: "Title")
//
//    /// "Organization"
//    static let organization = NSLocalizedString("Organization", comment: "contacts talbe cell Organization title")
//
//    /// "Nickname"
//    static let nickname = NSLocalizedString("Nickname", comment: "contacts talbe cell Nickname title")
//
//    /// "Title"
//    static let title = NSLocalizedString("Title", comment: "contacts talbe cell Title title")
//
//    /// "Birthday"
//    static let birthday = NSLocalizedString("Birthday", comment: "contacts talbe cell Birthday title")
//
//    /// "Anniversary"
//    static let anniversary = NSLocalizedString("Anniversary", comment: "contacts talbe cell Anniversary title")
//
//    /// "Gender"
//    static let gender = NSLocalizedString("Gender", comment: "contacts talbe cell gender title")
//
//    /// "Plain text"
//    static let plain_text = NSLocalizedString("Plain text", comment: "Title")
//
//    /// "ProtonMail encrypted emails"
//    static let protonmail_encrypted_emails = NSLocalizedString("ProtonMail encrypted emails", comment: "Title")
//
//    /// "Encrypted from outside"
//    static let encrypted_from_outside = NSLocalizedString("Encrypted from outside", comment: "Title")
//
//    /// "Encrypted for outside"
//    static let encrypted_for_outside = NSLocalizedString("Encrypted for outside", comment: "Title")
//
//    /// "Send plain but stored enc"
//    static let send_plain_but_stored_enc = NSLocalizedString("Send plain but stored enc", comment: "Title")
//
//    /// "Draft"
//    static let draft = NSLocalizedString("Draft", comment: "Title")
//
//    /// "Encrypted for outside reply"
//    static let encrypted_for_outside_reply = NSLocalizedString("Encrypted for outside reply", comment: "Title")
//
//    /// "Encrypted from outside pgp inline"
//    static let encrypted_from_outside_pgp_inline = NSLocalizedString("Encrypted from outside pgp inline", comment: "Title")
//
//    /// "Encrypted from outside pgp mime"
//    static let encrypted_from_outside_pgp_mime = NSLocalizedString("Encrypted from outside pgp mime", comment: "Title")
//
//    /// "Encrypted from outside signed pgp mime"
//    static let encrypted_from_outside_signed_pgp_mime = NSLocalizedString("Encrypted from outside signed pgp mime", comment: "Title")
//
//    /// "No Messages"
//    static let no_messages = NSLocalizedString("No Messages", comment: "message when mailbox doesnt have emailsß")
//
//    /// "Undo"
//    static let undo = NSLocalizedString("Undo", comment: "Action")
//
//    /// "INBOX"
//    static let inbox = NSLocalizedString("INBOX", comment: "Title")
//
//    /// "Can't find the clicked message please try again!"
//    static let can't_find_the_clicked_message_please_try_again! = NSLocalizedString("Can't find the clicked message please try again!", comment: "Description")
//
//    /// "Can't find the clicked message please try again!"
//    static let can't_find_the_clicked_message_please_try_again! = NSLocalizedString("Can't find the clicked message please try again!", comment: "Description")
//
//    /// "Message has been deleted."
//    static let message_has_been_deleted. = NSLocalizedString("Message has been deleted.", comment: "Title")
//
//    /// "Message has been moved."
//    static let message_has_been_moved. = NSLocalizedString("Message has been moved.", comment: "Title")
//
//    /// "Archived"
//    static let archived = NSLocalizedString("Archived", comment: "Description")
//
//    /// "Message has been moved."
//    static let message_has_been_moved. = NSLocalizedString("Message has been moved.", comment: "Title")
//
//    /// "Deleted"
//    static let deleted = NSLocalizedString("Deleted", comment: "Description")
//
//    /// "Message has been deleted."
//    static let message_has_been_deleted. = NSLocalizedString("Message has been deleted.", comment: "Title")
//
//    /// "Spammed"
//    static let spammed = NSLocalizedString("Spammed", comment: "Description")
//
//    /// "Message has been moved."
//    static let message_has_been_moved. = NSLocalizedString("Message has been moved.", comment: "Title")
//
//    /// "Message %@"
//    static let message_%@ = NSLocalizedString("Message %@", comment: "Message with title")
//
//    /// "Labels have been applied."
//    static let labels_have_been_applied. = NSLocalizedString("Labels have been applied.", comment: "Title")
//
//    /// "Message has been moved."
//    static let message_has_been_moved. = NSLocalizedString("Message has been moved.", comment: "Title")
//
//    /// "The request timed out."
//    static let the_request_timed_out. = NSLocalizedString("The request timed out.", comment: "Title")
//
//    /// "No connectivity detected..."
//    static let no_connectivity_detected... = NSLocalizedString("No connectivity detected...", comment: "Title")
//
//    /// "The ProtonMail current offline..."
//    static let the_protonmail_current_offline... = NSLocalizedString("The ProtonMail current offline...", comment: "Title")
//
//    /// "You have a new email!"
//    static let you_have_a_new_email! = NSLocalizedString("You have a new email!", comment: "Title")
//
//    /// "You have %d new emails!"
//    static let you_have_%d_new_emails! = NSLocalizedString("You have %d new emails!", comment: "Message")
//
//    /// "No connectivity detected..."
//    static let no_connectivity_detected... = NSLocalizedString("No connectivity detected...", comment: "Title")
//
//    /// "Save"
//    static let save = NSLocalizedString("Save", comment: "Title")
//
//    /// "Current password"
//    static let current_password = NSLocalizedString("Current password", comment: "Placeholder")
//
//    /// "New password"
//    static let new_password = NSLocalizedString("New password", comment: "Placeholder")
//
//    /// "Confirm new password"
//    static let confirm_new_password = NSLocalizedString("Confirm new password", comment: "Placeholder")
//
//    /// "Edit"
//    static let edit = NSLocalizedString("Edit", comment: "Action")
//
//    /// "Contact Details"
//    static let contact_details = NSLocalizedString("Contact Details", comment: "contact section title")
//
//    /// "Encrypted Contact Details"
//    static let encrypted_contact_details = NSLocalizedString("Encrypted Contact Details", comment: "contact section title")
//
//    /// "Share Contact"
//    static let share_contact = NSLocalizedString("Share Contact", comment: "action")
//
//    /// "Name"
//    static let name = NSLocalizedString("Name", comment: "title")
//
//    /// "Notes"
//    static let notes = NSLocalizedString("Notes", comment: "title")
//
//    /// "This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!"
//    static let this_email_seems_to_be_from_a_protonmail_address_but_came_from_outside_our_system_and_failed_our_authentication_requirements._it_may_be_spoofed_or_improperly_forwarded! = NSLocalizedString("This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
//
//    /// "This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!"
//    static let this_email_has_failed_its_domain's_authentication_requirements._it_may_be_spoofed_or_improperly_forwarded! = NSLocalizedString("This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
//
//    /// ""
//    static let  = NSLocalizedString("", comment: "")
//
//    /// "Human Check Failed"
//    static let human_check_failed = NSLocalizedString("Human Check Failed", comment: "Description")
//
//    /// "ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail"
//    static let protonmail_is_currently_offline,_check_our_twitter_for_the_current_status:_https://twitter.com/protonmail = NSLocalizedString("ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail", comment: "Description")
//
//    /// "Sending Message"
//    static let sending_message = NSLocalizedString("Sending Message", comment: "Description")
//
//    /// "Sending Message"
//    static let sending_message = NSLocalizedString("Sending Message", comment: "Description")
//
//    /// "Message sending failed please try again"
//    static let message_sending_failed_please_try_again = NSLocalizedString("Message sending failed please try again", comment: "Description")
//
//    /// "Importing Contacts"
//    static let importing_contacts = NSLocalizedString("Importing Contacts", comment: "import contact title")
//
//    /// "Reading device contacts data..."
//    static let reading_device_contacts_data... = NSLocalizedString("Reading device contacts data...", comment: "Title")
//
//    /// "Contacts"
//    static let contacts = NSLocalizedString("Contacts", comment: "Action")
//
//    /// "Do you want to cancel the process?"
//    static let do_you_want_to_cancel_the_process? = NSLocalizedString("Do you want to cancel the process?", comment: "Description")
//
//    /// "Confirm"
//    static let confirm = NSLocalizedString("Confirm", comment: "Action")
//
//    /// "Cancelling"
//    static let cancelling = NSLocalizedString("Cancelling", comment: "Title")
//
//    /// "Unknown"
//    static let unknown = NSLocalizedString("Unknown", comment: "title, default display name")
//
//    /// "Cancelling"
//    static let cancelling = NSLocalizedString("Cancelling", comment: "Title")
//
//    /// "Import Error"
//    static let import_error = NSLocalizedString("Import Error", comment: "Action")
//
//    /// "OK"
//    static let ok = NSLocalizedString("OK", comment: "Action")
//
//    /// "Email address"
//    static let email_address = NSLocalizedString("Email address", comment: "contact placeholder")
//
//    /// "No managedObjectContext"
//    static let no_managedobjectcontext = NSLocalizedString("No managedObjectContext", comment: "this is a system object can't find, this could be not trasnlated")
//
//    /// "Choose a Password"
//    static let choose_a_password = NSLocalizedString("Choose a Password", comment: "place holder")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Set passwords"
//    static let set_passwords = NSLocalizedString("Set passwords", comment: "Signup passwords top title")
//
//    /// "Note: This is used to log you into your account."
//    static let note:_this_is_used_to_log_you_into_your_account. = NSLocalizedString("Note: This is used to log you into your account.", comment: "setup password notes")
//
//    /// "Note: This is used to encrypt and decrypt your messages. Do not lose this password, we cannot recover it."
//    static let note:_this_is_used_to_encrypt_and_decrypt_your_messages._do_not_lose_this_password,_we_cannot_recover_it. = NSLocalizedString("Note: This is used to encrypt and decrypt your messages. Do not lose this password, we cannot recover it.", comment: "setup password notes")
//
//    /// "Create Account"
//    static let create_account = NSLocalizedString("Create Account", comment: "Create account button")
//
//    /// "Login password doesn't match"
//    static let login_password_doesn't_match = NSLocalizedString("Login password doesn't match", comment: "Error")
//
//    /// "Human Check Warning"
//    static let human_check_warning = NSLocalizedString("Human Check Warning", comment: "human check warning title")
//
//    /// "Warning: Before you pass the human check you can't sent email!!!"
//    static let warning:_before_you_pass_the_human_check_you_can't_sent_email!!! = NSLocalizedString("Warning: Before you pass the human check you can't sent email!!!", comment: "human check warning description")
//
//    /// "Check Again"
//    static let check_again = NSLocalizedString("Check Again", comment: "Action")
//
//    /// "Cancel Check"
//    static let cancel_check = NSLocalizedString("Cancel Check", comment: "Action")
//
//    /// "SETTINGS"
//    static let settings = NSLocalizedString("SETTINGS", comment: "Title")
//
//    /// "TouchID is not enrolled, enable it in the system Settings"
//    static let touchid_is_not_enrolled,_enable_it_in_the_system_settings = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "settings touchid error")
//
//    /// "A passcode has not been set, enable it in the system Settings"
//    static let a_passcode_has_not_been_set,_enable_it_in_the_system_settings = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "settings touchid error")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "settings touchid/faceid error")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "settings touchid error")
//
//    /// "None"
//    static let none = NSLocalizedString("None", comment: "")
//
//    /// "Every time enter app"
//    static let every_time_enter_app = NSLocalizedString("Every time enter app", comment: "")
//
//    /// "Unknown"
//    static let unknown = NSLocalizedString("Unknown", comment: "")
//
//    /// "Default"
//    static let default = NSLocalizedString("Default", comment: "Title")
//
//    /// "Unkonw Version"
//    static let unkonw_version = NSLocalizedString("Unkonw Version", comment: "")
//
//    /// "LibVersion"
//    static let libversion = NSLocalizedString("LibVersion", comment: "lib version text")
//
//    /// "AppVersion"
//    static let appversion = NSLocalizedString("AppVersion", comment: "")
//
//    /// "LibVersion"
//    static let libversion = NSLocalizedString("LibVersion", comment: "")
//
//    /// "Please use the web version of ProtonMail to change your passwords!"
//    static let please_use_the_web_version_of_protonmail_to_change_your_passwords! = NSLocalizedString("Please use the web version of ProtonMail to change your passwords!", comment: "Alert")
//
//    /// "Please use the web version of ProtonMail to change your passwords.!"
//    static let please_use_the_web_version_of_protonmail_to_change_your_passwords.! = NSLocalizedString("Please use the web version of ProtonMail to change your passwords.!", comment: "Alert")
//
//    /// "Resetting message cache ..."
//    static let resetting_message_cache_... = NSLocalizedString("Resetting message cache ...", comment: "Title")
//
//    /// "Auto Lock Time"
//    static let auto_lock_time = NSLocalizedString("Auto Lock Time", comment: "Title")
//
//    /// "None"
//    static let none = NSLocalizedString("None", comment: "")
//
//    /// "Every time enter app"
//    static let every_time_enter_app = NSLocalizedString("Every time enter app", comment: "")
//
//    /// "Change default address to .."
//    static let change_default_address_to_.. = NSLocalizedString("Change default address to ..", comment: "Title")
//
//    /// "You can't set %@ address as default because it is a paid feature."
//    static let you_can't_set_%@_address_as_default_because_it_is_a_paid_feature. = NSLocalizedString("You can't set %@ address as default because it is a paid feature.", comment: "pm.me upgrade warning in composer")
//
//    /// "Current Language is: "
//    static let current_language_is:_ = NSLocalizedString("Current Language is: ", comment: "Change language title")
//
//    /// "Email address"
//    static let email_address = NSLocalizedString("Email address", comment: "Title")
//
//    /// "Enter Verification Code"
//    static let enter_verification_code = NSLocalizedString("Enter Verification Code", comment: "Title")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Human Verification"
//    static let human_verification = NSLocalizedString("Human Verification", comment: "top title")
//
//    /// "We will send a verification code to the email address above."
//    static let we_will_send_a_verification_code_to_the_email_address_above. = NSLocalizedString("We will send a verification code to the email address above.", comment: "email field notes")
//
//    /// "Enter your existing email address."
//    static let enter_your_existing_email_address. = NSLocalizedString("Enter your existing email address.", comment: "top title")
//
//    /// "Continue"
//    static let continue = NSLocalizedString("Continue", comment: "Action")
//
//    /// "Retry after %d seconds"
//    static let retry_after_%d_seconds = NSLocalizedString("Retry after %d seconds", comment: "email verify code resend count down")
//
//    /// "Send Verification Code"
//    static let send_verification_code = NSLocalizedString("Send Verification Code", comment: "Title")
//
//    /// "Verification code request failed"
//    static let verification_code_request_failed = NSLocalizedString("Verification code request failed", comment: "Title")
//
//    /// "Email address invalid"
//    static let email_address_invalid = NSLocalizedString("Email address invalid", comment: "Title")
//
//    /// "Please input a valid email address."
//    static let please_input_a_valid_email_address. = NSLocalizedString("Please input a valid email address.", comment: "error message")
//
//    /// "Verification code sent"
//    static let verification_code_sent = NSLocalizedString("Verification code sent", comment: "Title")
//
//    /// "Please check your email for the verification code."
//    static let please_check_your_email_for_the_verification_code. = NSLocalizedString("Please check your email for the verification code.", comment: "error message")
//
//    /// "Create user failed"
//    static let create_user_failed = NSLocalizedString("Create user failed", comment: "error message title when create new user")
//
//    /// "Default error, please try again."
//    static let default_error,_please_try_again. = NSLocalizedString("Default error, please try again.", comment: "error message when create new user")
//
//    /// "Enter your PIN to unlock your inbox."
//    static let enter_your_pin_to_unlock_your_inbox. = NSLocalizedString("Enter your PIN to unlock your inbox.", comment: "Title")
//
//    /// "CONFIRM"
//    static let confirm = NSLocalizedString("CONFIRM", comment: "Action")
//
//    /// "attempt remaining until secure data wipe!"
//    static let attempt_remaining_until_secure_data_wipe! = NSLocalizedString("attempt remaining until secure data wipe!", comment: "Error")
//
//    /// "attempts remaining until secure data wipe!"
//    static let attempts_remaining_until_secure_data_wipe! = NSLocalizedString("attempts remaining until secure data wipe!", comment: "Error")
//
//    /// "Incorrect PIN,"
//    static let incorrect_pin, = NSLocalizedString("Incorrect PIN,", comment: "Error")
//
//    /// "attempts remaining"
//    static let attempts_remaining = NSLocalizedString("attempts remaining", comment: "Description")
//
//    /// "CONTACTS"
//    static let contacts = NSLocalizedString("CONTACTS", comment: "Title")
//
//    /// "Search"
//    static let search = NSLocalizedString("Search", comment: "Placeholder")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "Action")
//
//    /// "This contact belongs to your Address Book."
//    static let this_contact_belongs_to_your_address_book. = NSLocalizedString("This contact belongs to your Address Book.", comment: "")
//
//    /// "Please, manage it in your phone."
//    static let please,_manage_it_in_your_phone. = NSLocalizedString("Please, manage it in your phone.", comment: "Title")
//
//    /// "Contacts"
//    static let contacts = NSLocalizedString("Contacts", comment: "Action")
//
//    /// "Upload iOS contacts to ProtonMail?"
//    static let upload_ios_contacts_to_protonmail? = NSLocalizedString("Upload iOS contacts to ProtonMail?", comment: "Description")
//
//    /// "Confirm"
//    static let confirm = NSLocalizedString("Confirm", comment: "Action")
//
//    /// "Delete Contact"
//    static let delete_contact = NSLocalizedString("Delete Contact", comment: "Title-Contacts")
//
//
//    /// "Login"
//    static let login = NSLocalizedString("Login", comment: "")
//
//    /// "Authentication was cancelled by the system"
//    static let authentication_was_cancelled_by_the_system = NSLocalizedString("Authentication was cancelled by the system", comment: "Description")
//
//    /// "Authentication failed"
//    static let authentication_failed = NSLocalizedString("Authentication failed", comment: "Description")
//
//    /// "TouchID is not enrolled, enable it in the system Settings"
//    static let touchid_is_not_enrolled,_enable_it_in_the_system_settings = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "Description")
//
//    /// "A passcode has not been set, enable it in the system Settings"
//    static let a_passcode_has_not_been_set,_enable_it_in_the_system_settings = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "Description")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "Description")
//
//    /// "Pin code can't be empty."
//    static let pin_code_can't_be_empty. = NSLocalizedString("Pin code can't be empty.", comment: "Description")
//
//    /// "Enter your PIN"
//    static let enter_your_pin = NSLocalizedString("Enter your PIN", comment: "set pin title")
//
//    /// "Re-Enter your PIN"
//    static let re-enter_your_pin = NSLocalizedString("Re-Enter your PIN", comment: "set pin title")
//
//    /// "CREATE"
//    static let create = NSLocalizedString("CREATE", comment: "setup pin action")
//
//    /// "CONFIRM"
//    static let confirm = NSLocalizedString("CONFIRM", comment: "setup pin action")
//
//    /// "Key generation failed please try again"
//    static let key_generation_failed_please_try_again = NSLocalizedString("Key generation failed please try again", comment: "Error")
//
//    /// "Key generation failed please try again"
//    static let key_generation_failed_please_try_again = NSLocalizedString("Key generation failed please try again", comment: "Error")
//
//    /// "Authentication failed please try to login again"
//    static let authentication_failed_please_try_to_login_again = NSLocalizedString("Authentication failed please try to login again", comment: "Error")
//
//    /// "Unknown Error"
//    static let unknown_error = NSLocalizedString("Unknown Error", comment: "Error")
//
//    /// "Fetch user info failed"
//    static let fetch_user_info_failed = NSLocalizedString("Fetch user info failed", comment: "Error")
//
//    /// "Decrypt token failed please try again"
//    static let decrypt_token_failed_please_try_again = NSLocalizedString("Decrypt token failed please try again", comment: "Description")
//
//    /// "Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation."
//    static let instant_protonmail_account_creation_has_been_temporarily_disabled._please_go_to_https://protonmail.com/invite_to_request_an_invitation. = NSLocalizedString("Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation.", comment: "Error")
//
//    /// "Create User failed please try again"
//    static let create_user_failed_please_try_again = NSLocalizedString("Create User failed please try again", comment: "Error")
//
//    /// "Create User failed please try again"
//    static let create_user_failed_please_try_again = NSLocalizedString("Create User failed please try again", comment: "Error")
//
//    /// "Key invalid please go back try again"
//    static let key_invalid_please_go_back_try_again = NSLocalizedString("Key invalid please go back try again", comment: "Error")
//
//    /// "Load remote content"
//    static let load_remote_content = NSLocalizedString("Load remote content", comment: "Action")
//
//    /// "PASSWORD"
//    static let password = NSLocalizedString("PASSWORD", comment: "change login password navigation title")
//
//    /// "Change Login Password"
//    static let change_login_password = NSLocalizedString("Change Login Password", comment: "change password input label")
//
//    /// "Current login password"
//    static let current_login_password = NSLocalizedString("Current login password", comment: "Title")
//
//    /// "New login password"
//    static let new_login_password = NSLocalizedString("New login password", comment: "Title")
//
//    /// "Confirm new login password"
//    static let confirm_new_login_password = NSLocalizedString("Confirm new login password", comment: "Title")
//
//    /// "PASSWORD"
//    static let password = NSLocalizedString("PASSWORD", comment: "change mailbox password navigation title")
//
//    /// "Change Mailbox Password"
//    static let change_mailbox_password = NSLocalizedString("Change Mailbox Password", comment: "Title")
//
//    /// "Current login password"
//    static let current_login_password = NSLocalizedString("Current login password", comment: "Title")
//
//    /// "New mailbox password"
//    static let new_mailbox_password = NSLocalizedString("New mailbox password", comment: "Title")
//
//    /// "Confirm new mailbox password"
//    static let confirm_new_mailbox_password = NSLocalizedString("Confirm new mailbox password", comment: "Title")
//
//    /// "PASSWORD"
//    static let password = NSLocalizedString("PASSWORD", comment: "change signle password navigation title")
//
//    /// "Change Single Password"
//    static let change_single_password = NSLocalizedString("Change Single Password", comment: "Title")
//
//    /// "Current password"
//    static let current_password = NSLocalizedString("Current password", comment: "Title")
//
//    /// "New password"
//    static let new_password = NSLocalizedString("New password", comment: "Title")
//
//    /// "Confirm new password"
//    static let confirm_new_password = NSLocalizedString("Confirm new password", comment: "Title")
//
//    /// "Unable to send the email"
//    static let unable_to_send_the_email = NSLocalizedString("Unable to send the email", comment: "error when sending the message")
//
//    /// "The draft format incorrectly sending failed!"
//    static let the_draft_format_incorrectly_sending_failed! = NSLocalizedString("The draft format incorrectly sending failed!", comment: "error when sending the message")
//
//    /// "Trash"
//    static let trash = NSLocalizedString("Trash", comment: "Title")
//
//    /// "Spam"
//    static let spam = NSLocalizedString("Spam", comment: "Title")
//
//    /// "Star"
//    static let star = NSLocalizedString("Star", comment: "Title")
//
//    /// "Archive"
//    static let archive = NSLocalizedString("Archive", comment: "Title")
//
//    /// "ProtonMail"
//    static let protonmail = NSLocalizedString("ProtonMail", comment: "Title")
//
//    /// "Remind Me Later"
//    static let remind_me_later = NSLocalizedString("Remind Me Later", comment: "Title")
//
//    /// "Don't Show Again"
//    static let don't_show_again = NSLocalizedString("Don't Show Again", comment: "Title")
//
//    /// "close tour"
//    static let close_tour = NSLocalizedString("close tour", comment: "Action")
//
//    /// "Support ProtonMail"
//    static let support_protonmail = NSLocalizedString("Support ProtonMail", comment: "Action")
//
//    /// "Unknown"
//    static let unknown = NSLocalizedString("Unknown", comment: "title, default display name")
//
//    /// "Your new encrypted email account has been set up and is ready to send and receive encrypted messages."
//    static let your_new_encrypted_email_account_has_been_set_up_and_is_ready_to_send_and_receive_encrypted_messages. = NSLocalizedString("Your new encrypted email account has been set up and is ready to send and receive encrypted messages.", comment: "Description")
//
//    /// "You can customize swipe gestures in the ProtonMail App Settings."
//    static let you_can_customize_swipe_gestures_in_the_protonmail_app_settings. = NSLocalizedString("You can customize swipe gestures in the ProtonMail App Settings.", comment: "Description")
//
//    /// "Create and add Labels to organize your inbox. Press and hold down on a message for all options."
//    static let create_and_add_labels_to_organize_your_inbox._press_and_hold_down_on_a_message_for_all_options. = NSLocalizedString("Create and add Labels to organize your inbox. Press and hold down on a message for all options.", comment: "Description")
//
//    /// "Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail."
//    static let your_inbox_is_now_protected_with_end-to-end_encryption._to_automatically_securely_email_friends,_have_them_get_protonmail!_you_can_also_manually_encrypt_messages_to_them_if_they_don't_use_protonmail. = NSLocalizedString("Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail.", comment: "Description")
//
//    /// "Messages you send can be set to auto delete after a certain time period."
//    static let messages_you_send_can_be_set_to_auto_delete_after_a_certain_time_period. = NSLocalizedString("Messages you send can be set to auto delete after a certain time period.", comment: "Description")
//
//    /// "You can get help and support at protonmail.com/support. Bugs can also be reported with the app."
//    static let you_can_get_help_and_support_at_protonmail.com/support._bugs_can_also_be_reported_with_the_app. = NSLocalizedString("You can get help and support at protonmail.com/support. Bugs can also be reported with the app.", comment: "Description")
//
//    /// "ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail."
//    static let protonmail_doesn't_sell_ads_or_abuse_your_privacy._your_support_is_essential_to_keeping_protonmail_running._you_can_upgrade_to_a_paid_account_or_donate_to_support_protonmail. = NSLocalizedString("ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail.", comment: "Description")
//
//    /// "Welcome to ProtonMail!"
//    static let welcome_to_protonmail! = NSLocalizedString("Welcome to ProtonMail!", comment: "Title")
//
//    /// "Quick swipe actions"
//    static let quick_swipe_actions = NSLocalizedString("Quick swipe actions", comment: "Title")
//
//    /// "Label Management"
//    static let label_management = NSLocalizedString("Label Management", comment: "Title")
//
//    /// "End-to-End Encryption"
//    static let end-to-end_encryption = NSLocalizedString("End-to-End Encryption", comment: "Title")
//
//    /// "Expiring Messages"
//    static let expiring_messages = NSLocalizedString("Expiring Messages", comment: "Title")
//
//    /// "Help & Support"
//    static let help_&_support = NSLocalizedString("Help & Support", comment: "Title")
//
//    /// "Support ProtonMail"
//    static let support_protonmail = NSLocalizedString("Support ProtonMail", comment: "Title")
//
//    /// "Token expired"
//    static let token_expired = NSLocalizedString("Token expired", comment: "Error")
//
//    /// "The authentication token has expired."
//    static let the_authentication_token_has_expired. = NSLocalizedString("The authentication token has expired.", comment: "Description")
//
//    /// "Invalid credential"
//    static let invalid_credential = NSLocalizedString("Invalid credential", comment: "Error")
//
//    /// "The authentication credentials are invalid."
//    static let the_authentication_credentials_are_invalid. = NSLocalizedString("The authentication credentials are invalid.", comment: "Description")
//
//    /// "Authentication Failed Wrong username or password"
//    static let authentication_failed_wrong_username_or_password = NSLocalizedString("Authentication Failed Wrong username or password", comment: "Description")
//
//    /// "Unable to connect to the server"
//    static let unable_to_connect_to_the_server = NSLocalizedString("Unable to connect to the server", comment: "Description")
//
//    /// "Unable to parse token"
//    static let unable_to_parse_token = NSLocalizedString("Unable to parse token", comment: "Error")
//
//    /// "Unable to parse authentication token!"
//    static let unable_to_parse_authentication_token! = NSLocalizedString("Unable to parse authentication token!", comment: "Description")
//
//    /// "Unable to parse token"
//    static let unable_to_parse_token = NSLocalizedString("Unable to parse token", comment: "Error")
//
//    /// "Unable to parse authentication info!"
//    static let unable_to_parse_authentication_info! = NSLocalizedString("Unable to parse authentication info!", comment: "Description")
//
//    /// "Invalid Password"
//    static let invalid_password = NSLocalizedString("Invalid Password", comment: "Error")
//
//    /// "Unable to generate hash password!"
//    static let unable_to_generate_hash_password! = NSLocalizedString("Unable to generate hash password!", comment: "Description")
//
//    /// "SRP Client"
//    static let srp_client = NSLocalizedString("SRP Client", comment: "Error")
//
//    /// "Unable to create SRP Client!"
//    static let unable_to_create_srp_client! = NSLocalizedString("Unable to create SRP Client!", comment: "Description")
//
//    /// "SRP Server"
//    static let srp_server = NSLocalizedString("SRP Server", comment: "Error")
//
//    /// "Server proofs not valid!"
//    static let server_proofs_not_valid! = NSLocalizedString("Server proofs not valid!", comment: "Description")
//
//    /// "Invalid Password"
//    static let invalid_password = NSLocalizedString("Invalid Password", comment: "Error")
//
//    /// "Srp single password keyslat invalid!"
//    static let srp_single_password_keyslat_invalid! = NSLocalizedString("Srp single password keyslat invalid!", comment: "Description")
//
//    /// "Unable to parse token"
//    static let unable_to_parse_token = NSLocalizedString("Unable to parse token", comment: "Error")
//
//    /// "Unable to parse cased authentication token!"
//    static let unable_to_parse_cased_authentication_token! = NSLocalizedString("Unable to parse cased authentication token!", comment: "Description")
//
//    /// "Bad auth cache"
//    static let bad_auth_cache = NSLocalizedString("Bad auth cache", comment: "Error")
//
//    /// "Local cache can't find mailbox password"
//    static let local_cache_can't_find_mailbox_password = NSLocalizedString("Local cache can't find mailbox password", comment: "Description")
//
//    /// "Date: %@"
//    static let date:_%@ = NSLocalizedString("Date: %@", comment: "like Date: 2017-10-10")
//
//    /// "Details"
//    static let details = NSLocalizedString("Details", comment: "Title")
//
//    /// "Date: %@"
//    static let date:_%@ = NSLocalizedString("Date: %@", comment: "")
//
//    /// "Date: %@"
//    static let date:_%@ = NSLocalizedString("Date: %@", comment: "")
//
//    /// "Hide Details"
//    static let hide_details = NSLocalizedString("Hide Details", comment: "Title")
//
//    /// "Details"
//    static let details = NSLocalizedString("Details", comment: "Title")
//
//    /// "Custom"
//    static let custom = NSLocalizedString("Custom", comment: "custom label type default")
//
//    /// "Custom"
//    static let custom = NSLocalizedString("Custom", comment: "custom label type default")
//
//    /// "Phone number"
//    static let phone_number = NSLocalizedString("Phone number", comment: "contact placeholder")
//
//    /// "Username"
//    static let username = NSLocalizedString("Username", comment: "Title")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Create a new account"
//    static let create_a_new_account = NSLocalizedString("Create a new account", comment: "Signup top title")
//
//    /// "Note: The Username is also your ProtonMail address."
//    static let note:_the_username_is_also_your_protonmail_address. = NSLocalizedString("Note: The Username is also your ProtonMail address.", comment: "Signup user name notes")
//
//    /// "By using protonmail, you agree to our"
//    static let by_using_protonmail,_you_agree_to_our = NSLocalizedString("By using protonmail, you agree to our", comment: "agree check box first part words")
//
//    /// "terms and conditions"
//    static let terms_and_conditions = NSLocalizedString("terms and conditions", comment: "agree check box terms")
//
//    /// "and"
//    static let and = NSLocalizedString("and", comment: "agree check box middle word")
//
//    /// "privacy policy."
//    static let privacy_policy. = NSLocalizedString("privacy policy.", comment: "agree check box privacy")
//
//    /// "Create Account"
//    static let create_account = NSLocalizedString("Create Account", comment: "Create account button")
//
//    /// "Checking ...."
//    static let checking_.... = NSLocalizedString("Checking ....", comment: "loading message")
//
//    /// "User is available!"
//    static let user_is_available! = NSLocalizedString("User is available!", comment: "")
//
//    /// "User already exist!"
//    static let user_already_exist! = NSLocalizedString("User already exist!", comment: "error when user already exist")
//
//    /// "Please pick a user name first!"
//    static let please_pick_a_user_name_first! = NSLocalizedString("Please pick a user name first!", comment: "Error")
//
//    /// "In order to use our services, you must agree to ProtonMail's Terms of Service."
//    static let in_order_to_use_our_services,_you_must_agree_to_protonmail's_terms_of_service. = NSLocalizedString("In order to use our services, you must agree to ProtonMail's Terms of Service.", comment: "Error")
//
//    /// "Update Contact"
//    static let update_contact = NSLocalizedString("Update Contact", comment: "Contacts Update contact")
//
//    /// "Save"
//    static let save = NSLocalizedString("Save", comment: "Action-Contacts")
//
//    /// "Do you want to save the unsaved changes?"
//    static let do_you_want_to_save_the_unsaved_changes? = NSLocalizedString("Do you want to save the unsaved changes?", comment: "Title")
//
//    /// "Save"
//    static let save = NSLocalizedString("Save", comment: "Action")
//
//    /// "Discard changes"
//    static let discard_changes = NSLocalizedString("Discard changes", comment: "Action")
//
//    /// "Add new url"
//    static let add_new_url = NSLocalizedString("Add new url", comment: "action")
//
//    /// "Delete Contact"
//    static let delete_contact = NSLocalizedString("Delete Contact", comment: "action")
//
//    /// "Encrypted Contact Details"
//    static let encrypted_contact_details = NSLocalizedString("Encrypted Contact Details", comment: "title")
//
//    /// "Delete Contact"
//    static let delete_contact = NSLocalizedString("Delete Contact", comment: "Title-Contacts")
//
//    /// "English"
//    static let english = NSLocalizedString("English", comment: "Action")
//
//    /// "German"
//    static let german = NSLocalizedString("German", comment: "Action")
//
//    /// "French"
//    static let french = NSLocalizedString("French", comment: "Action")
//
//    /// "Russian"
//    static let russian = NSLocalizedString("Russian", comment: "Action")
//
//    /// "Spanish"
//    static let spanish = NSLocalizedString("Spanish", comment: "Action")
//
//    /// "Turkish"
//    static let turkish = NSLocalizedString("Turkish", comment: "Action")
//
//    /// "Polish"
//    static let polish = NSLocalizedString("Polish", comment: "Action")
//
//    /// "Ukrainian"
//    static let ukrainian = NSLocalizedString("Ukrainian", comment: "Action")
//
//    /// "Dutch"
//    static let dutch = NSLocalizedString("Dutch", comment: "Action")
//
//    /// "Italian"
//    static let italian = NSLocalizedString("Italian", comment: "Action")
//
//    /// "Portuguese Brazil"
//    static let portuguese_brazil = NSLocalizedString("Portuguese Brazil", comment: "Action")
//
//    /// "Message Queue"
//    static let message_queue = NSLocalizedString("Message Queue", comment: "settings debug section title")
//
//    /// "Error Logs"
//    static let error_logs = NSLocalizedString("Error Logs", comment: "settings debug section title")
//
//    /// "Notification Email"
//    static let notification_email = NSLocalizedString("Notification Email", comment: "settings general section title")
//
//    /// "Login Password"
//    static let login_password = NSLocalizedString("Login Password", comment: "settings general section title")
//
//    /// "Mailbox Password"
//    static let mailbox_password = NSLocalizedString("Mailbox Password", comment: "settings general section title")
//
//    /// "Single Password"
//    static let single_password = NSLocalizedString("Single Password", comment: "settings general section title")
//
//    /// "Clear Local Message Cache"
//    static let clear_local_message_cache = NSLocalizedString("Clear Local Message Cache", comment: "settings general section title")
//
//    /// "Auto Show Images"
//    static let auto_show_images = NSLocalizedString("Auto Show Images", comment: "settings general section title")
//
//    /// "Swipe Left to Right"
//    static let swipe_left_to_right = NSLocalizedString("Swipe Left to Right", comment: "settings swipe actions section title")
//
//    /// "Swipe Right to Left"
//    static let swipe_right_to_left = NSLocalizedString("Swipe Right to Left", comment: "settings swipe actions section title")
//
//    /// "Change left swipe action"
//    static let change_left_swipe_action = NSLocalizedString("Change left swipe action", comment: "settings swipe actions section action description")
//
//    /// "Change right swipe action"
//    static let change_right_swipe_action = NSLocalizedString("Change right swipe action", comment: "settings swipe actions section action description")
//
//    /// "Enable TouchID"
//    static let enable_touchid = NSLocalizedString("Enable TouchID", comment: "settings protection section title")
//
//    /// "Enable Pin Protection"
//    static let enable_pin_protection = NSLocalizedString("Enable Pin Protection", comment: "settings protection section title")
//
//    /// "Change Pin"
//    static let change_pin = NSLocalizedString("Change Pin", comment: "settings protection section title")
//
//    /// "Protection Entire App"
//    static let protection_entire_app = NSLocalizedString("Protection Entire App", comment: "settings protection section title")
//
//    /// "Auto Lock Time"
//    static let auto_lock_time = NSLocalizedString("Auto Lock Time", comment: "settings protection section title")
//
//    /// "Enable FaceID"
//    static let enable_faceid = NSLocalizedString("Enable FaceID", comment: "settings protection section title")
//
//    /// ""
//    static let  = NSLocalizedString("", comment: "")
//
//    /// "Display Name"
//    static let display_name = NSLocalizedString("Display Name", comment: "Title")
//
//    /// "Signature"
//    static let signature = NSLocalizedString("Signature", comment: "Title")
//
//    /// "Mobile Signature"
//    static let mobile_signature = NSLocalizedString("Mobile Signature", comment: "Title")
//    /// "Debug"
//    static let debug = NSLocalizedString("Debug", comment: "Title")
//
//    /// "General Settings"
//    static let general_settings = NSLocalizedString("General Settings", comment: "Title")
//
//    /// "Multiple Addresses"
//    static let multiple_addresses = NSLocalizedString("Multiple Addresses", comment: "Title")
//
//    /// "Storage"
//    static let storage = NSLocalizedString("Storage", comment: "Title")
//
//    /// ""
//    static let  = NSLocalizedString("", comment: "")
//
//    /// "Message Swipe Actions"
//    static let message_swipe_actions = NSLocalizedString("Message Swipe Actions", comment: "Title")
//
//    /// "Protection"
//    static let protection = NSLocalizedString("Protection", comment: "Title")
//
//    /// "Language"
//    static let language = NSLocalizedString("Language", comment: "Title")
//
//    /// "Labels/Folders"
//    static let labels/folders = NSLocalizedString("Labels/Folders", comment: "Title")
//
//    /// "Save"
//    static let save = NSLocalizedString("Save", comment: "Title")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "Action")
//
//    /// "Login Password"
//    static let login_password = NSLocalizedString("Login Password", comment: "Placeholder")
//
//    /// "Confirmation"
//    static let confirmation = NSLocalizedString("Confirmation", comment: "Title")
//
//    /// "You have unsaved changes. Do you want to save it?"
//    static let you_have_unsaved_changes._do_you_want_to_save_it? = NSLocalizedString("You have unsaved changes. Do you want to save it?", comment: "Confirmation message")
//
//    /// "Save Changes"
//    static let save_changes = NSLocalizedString("Save Changes", comment: "title")
//
//    /// "Recovery Code"
//    static let recovery_code = NSLocalizedString("Recovery Code", comment: "Title")
//
//    /// "Two Factor Code"
//    static let two_factor_code = NSLocalizedString("Two Factor Code", comment: "Placeholder")
//
//    /// "Login Password"
//    static let login_password = NSLocalizedString("Login Password", comment: "Placeholder")
//
//    /// "Authentication"
//    static let authentication = NSLocalizedString("Authentication", comment: "Title")
//
//    /// "Enter"
//    static let enter = NSLocalizedString("Enter", comment: "Action")
//
//    /// "Space Warning"
//    static let space_warning = NSLocalizedString("Space Warning", comment: "Title")
//
//    /// "Hide"
//    static let hide = NSLocalizedString("Hide", comment: "Action")
//
//    /// "Change Password"
//    static let change_password = NSLocalizedString("Change Password", comment: "update password error title")
//
//    /// "Invalid UserName!"
//    static let invalid_username! = NSLocalizedString("Invalid UserName!", comment: "update password error when input invalid username")
//
//    /// "Can't get a Moduls ID!"
//    static let can't_get_a_moduls_id! = NSLocalizedString("Can't get a Moduls ID!", comment: "update password error = typo:Modulus")
//
//    /// "Can't get a Moduls!"
//    static let can't_get_a_moduls! = NSLocalizedString("Can't get a Moduls!", comment: "update password error = typo:Modulus")
//
//    /// "Invalid hashed password!"
//    static let invalid_hashed_password! = NSLocalizedString("Invalid hashed password!", comment: "update password error")
//
//    /// "Can't create a SRP verifier!"
//    static let can't_create_a_srp_verifier! = NSLocalizedString("Can't create a SRP verifier!", comment: "update password error")
//
//    /// "Can't create a SRP Client"
//    static let can't_create_a_srp_client = NSLocalizedString("Can't create a SRP Client", comment: "update password error")
//
//    /// "Can't get user auth info"
//    static let can't_get_user_auth_info = NSLocalizedString("Can't get user auth info", comment: "update password error")
//
//    /// "The Password is wrong."
//    static let the_password_is_wrong. = NSLocalizedString("The Password is wrong.", comment: "update password error")
//
//    /// "The new password not match."
//    static let the_new_password_not_match. = NSLocalizedString("The new password not match.", comment: "update password error")
//
//    /// "The new password can't empty."
//    static let the_new_password_can't_empty. = NSLocalizedString("The new password can't empty.", comment: "update password error")
//
//    /// "The private key update failed."
//    static let the_private_key_update_failed. = NSLocalizedString("The private key update failed.", comment: "update password error")
//
//    /// "Password update failed"
//    static let password_update_failed = NSLocalizedString("Password update failed", comment: "update password error")
//
//    /// "Update Notification Email"
//    static let update_notification_email = NSLocalizedString("Update Notification Email", comment: "update notification email error title")
//
//    /// "Invalid UserName!"
//    static let invalid_username! = NSLocalizedString("Invalid UserName!", comment: "update notification email error")
//
//    /// "Invalid hashed password!"
//    static let invalid_hashed_password! = NSLocalizedString("Invalid hashed password!", comment: "update notification email error")
//
//    /// "Can't create a SRP verifier!"
//    static let can't_create_a_srp_verifier! = NSLocalizedString("Can't create a SRP verifier!", comment: "update notification email error")
//
//    /// "Can't create a SRP Client"
//    static let can't_create_a_srp_client = NSLocalizedString("Can't create a SRP Client", comment: "update notification email error")
//
//    /// "Can't get user auth info"
//    static let can't_get_user_auth_info = NSLocalizedString("Can't get user auth info", comment: "update notification email error")
//
//    /// "Password update failed"
//    static let password_update_failed = NSLocalizedString("Password update failed", comment: "update notification email error")
//
//    /// "Update Notification Email"
//    static let update_notification_email = NSLocalizedString("Update Notification Email", comment: "update notification email error title when signup")
//
//    /// "Can't get a Moduls ID!"
//    static let can't_get_a_moduls_id! = NSLocalizedString("Can't get a Moduls ID!", comment: "sign up user error when can't get moduls id")
//
//    /// "Can't get a Moduls!"
//    static let can't_get_a_moduls! = NSLocalizedString("Can't get a Moduls!", comment: "sign up user error")
//
//    /// "Invalid hashed password!"
//    static let invalid_hashed_password! = NSLocalizedString("Invalid hashed password!", comment: "sign up user error")
//
//    /// "Can't create a SRP verifier!"
//    static let can't_create_a_srp_verifier! = NSLocalizedString("Can't create a SRP verifier!", comment: "sign up user error")
//
//    /// "Create user failed"
//    static let create_user_failed = NSLocalizedString("Create user failed", comment: "sign up user error")
//
//    /// "Unable to get contacts"
//    static let unable_to_get_contacts = NSLocalizedString("Unable to get contacts", comment: "Error")
//
//    /// "Apply Labels"
//    static let apply_labels = NSLocalizedString("Apply Labels", comment: "Title")
//
//    /// "No connectivity detected..."
//    static let no_connectivity_detected... = NSLocalizedString("No connectivity detected...", comment: "Error")
//
//    /// "The request timed out."
//    static let the_request_timed_out. = NSLocalizedString("The request timed out.", comment: "Error")
//
//    /// "No connectivity detected..."
//    static let no_connectivity_detected... = NSLocalizedString("No connectivity detected...", comment: "Error")
//
//    /// "Can't download message body, please try again."
//    static let can't_download_message_body,_please_try_again. = NSLocalizedString("Can't download message body, please try again.", comment: "Error")
//
//    /// "Can't download message body, please try again."
//    static let can't_download_message_body,_please_try_again. = NSLocalizedString("Can't download message body, please try again.", comment: "Error")
//
//    /// "Can't download message body, please try again."
//    static let can't_download_message_body,_please_try_again. = NSLocalizedString("Can't download message body, please try again.", comment: "Error")
//
//    /// "Can't download message body, please try again."
//    static let can't_download_message_body,_please_try_again. = NSLocalizedString("Can't download message body, please try again.", comment: "Error")
//
//    /// "Print"
//    static let print = NSLocalizedString("Print", comment: "Action")
//
//    /// "Unable to decrypt message."
//    static let unable_to_decrypt_message. = NSLocalizedString("Unable to decrypt message.", comment: "Error")
//
//    /// "Loading..."
//    static let loading... = NSLocalizedString("Loading...", comment: "")
//
//    /// "Please wait until the email downloaded!"
//    static let please_wait_until_the_email_downloaded! = NSLocalizedString("Please wait until the email downloaded!", comment: "The")
//
//    /// "Can't decrypt this attachment!"
//    static let can't_decrypt_this_attachment! = NSLocalizedString("Can't decrypt this attachment!", comment: "When quick look attachment but can't decrypt it!")
//
//    /// "Can't find this attachment!"
//    static let can't_find_this_attachment! = NSLocalizedString("Can't find this attachment!", comment: "when quick look attachment but can't find the data")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Encryption Setup"
//    static let encryption_setup = NSLocalizedString("Encryption Setup", comment: "key setup top title")
//
//    /// "High Security"
//    static let high_security = NSLocalizedString("High Security", comment: "Key size checkbox")
//
//    /// "Extreme Security"
//    static let extreme_security = NSLocalizedString("Extreme Security", comment: "Key size checkbox")
//
//    /// "The current standard"
//    static let the_current_standard = NSLocalizedString("The current standard", comment: "key size notes")
//
//    /// "The highest level of encryption available."
//    static let the_highest_level_of_encryption_available. = NSLocalizedString("The highest level of encryption available.", comment: "key size note part 1")
//
//    /// "Can take several minutes to setup."
//    static let can_take_several_minutes_to_setup. = NSLocalizedString("Can take several minutes to setup.", comment: "key size note part 2")
//
//    /// "Continue"
//    static let continue = NSLocalizedString("Continue", comment: "key setup continue button")
//
//    /// "Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer."
//    static let mobile_signups_are_temporarily_disabled._please_try_again_later,_or_try_signing_up_at_protonmail.com_using_a_desktop_or_laptop_computer. = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.", comment: "Description")
//
//    /// "Key generation failed"
//    static let key_generation_failed = NSLocalizedString("Key generation failed", comment: "Error")
//
//    /// "Your Country Code"
//    static let your_country_code = NSLocalizedString("Your Country Code", comment: "view top title")
//
//    /// "MAILBOX PASSWORD"
//    static let mailbox_password = NSLocalizedString("MAILBOX PASSWORD", comment: "Title")
//
//    /// "DECRYPT MAILBOX"
//    static let decrypt_mailbox = NSLocalizedString("DECRYPT MAILBOX", comment: "Title")
//
//    /// "Decrypt"
//    static let decrypt = NSLocalizedString("Decrypt", comment: "Action")
//
//    /// "RESET MAILBOX PASSWORD"
//    static let reset_mailbox_password = NSLocalizedString("RESET MAILBOX PASSWORD", comment: "Action")
//
//    /// "The mailbox password is incorrect."
//    static let the_mailbox_password_is_incorrect. = NSLocalizedString("The mailbox password is incorrect.", comment: "Error")
//
//    /// "Incorrect password"
//    static let incorrect_password = NSLocalizedString("Incorrect password", comment: "Title")
//
//    /// "Incorrect password"
//    static let incorrect_password = NSLocalizedString("Incorrect password", comment: "Title")
//
//    /// "The mailbox password is incorrect."
//    static let the_mailbox_password_is_incorrect. = NSLocalizedString("The mailbox password is incorrect.", comment: "Error")
//
//    /// "To reset your mailbox password, please use the web version of ProtonMail at protonmail.com"
//    static let to_reset_your_mailbox_password,_please_use_the_web_version_of_protonmail_at_protonmail.com = NSLocalizedString("To reset your mailbox password, please use the web version of ProtonMail at protonmail.com", comment: "Description")
//
//    /// "Recovery Email"
//    static let recovery_email = NSLocalizedString("Recovery Email", comment: "Title")
//
//    /// "Display Name"
//    static let display_name = NSLocalizedString("Display Name", comment: "Title")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Congratulations!"
//    static let congratulations! = NSLocalizedString("Congratulations!", comment: "view top title")
//
//    /// "Your new secure email\r\n account is ready."
//    static let your_new_secure_email\r\n_account_is_ready. = NSLocalizedString("Your new secure email\r\n account is ready.", comment: "view top title")
//
//    /// "When you send an email, this is the name that appears in the sender field."
//    static let when_you_send_an_email,_this_is_the_name_that_appears_in_the_sender_field. = NSLocalizedString("When you send an email, this is the name that appears in the sender field.", comment: "display name notes")
//
//    /// "The optional recovery email address allows you to reset your login password if you forget it."
//    static let the_optional_recovery_email_address_allows_you_to_reset_your_login_password_if_you_forget_it. = NSLocalizedString("The optional recovery email address allows you to reset your login password if you forget it.", comment: "recovery email notes")
//
//    /// "Keep me updated about new features"
//    static let keep_me_updated_about_new_features = NSLocalizedString("Keep me updated about new features", comment: "Title")
//
//    /// "Go to inbox"
//    static let go_to_inbox = NSLocalizedString("Go to inbox", comment: "Action")
//
//    /// "Recovery Email Warning"
//    static let recovery_email_warning = NSLocalizedString("Recovery Email Warning", comment: "Title")
//
//    /// "Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?"
//    static let warning:_you_did_not_set_a_recovery_email_so_account_recovery_is_impossible_if_you_forget_your_password._proceed_without_recovery_email? = NSLocalizedString("Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?", comment: "Description")
//
//    /// "Confirm"
//    static let confirm = NSLocalizedString("Confirm", comment: "Title")
//
//    /// "Please input a valid email address."
//    static let please_input_a_valid_email_address. = NSLocalizedString("Please input a valid email address.", comment: "Description")
//
//    /// "Please input a valid email address."
//    static let please_input_a_valid_email_address. = NSLocalizedString("Please input a valid email address.", comment: "Description")
//
//    /// "Unknown"
//    static let unknown = NSLocalizedString("Unknown", comment: "title, default display name")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Human Verification"
//    static let human_verification = NSLocalizedString("Human Verification", comment: "human verification top title")
//
//    /// "To prevent abuse of ProtonMail,\r\n we need to verify that you are human."
//    static let to_prevent_abuse_of_protonmail,\r\n_we_need_to_verify_that_you_are_human. = NSLocalizedString("To prevent abuse of ProtonMail,\r\n we need to verify that you are human.", comment: "human verification notes")
//
//    /// "Please select one of the following options:"
//    static let please_select_one_of_the_following_options: = NSLocalizedString("Please select one of the following options:", comment: "human check select option title")
//
//    /// "CAPTCHA"
//    static let captcha = NSLocalizedString("CAPTCHA", comment: "human check option button")
//
//    /// "Email Verification"
//    static let email_verification = NSLocalizedString("Email Verification", comment: "human check option button")
//
//    /// "Phone Verification"
//    static let phone_verification = NSLocalizedString("Phone Verification", comment: "human check option button")
//
//    /// "Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer."
//    static let mobile_signups_are_temporarily_disabled._please_try_again_later,_or_try_signing_up_at_protonmail.com_using_a_desktop_or_laptop_computer. = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.", comment: "signup human check error description when mobile signup disabled")
//
//    /// "Verification error"
//    static let verification_error = NSLocalizedString("Verification error", comment: "error title")
//
//    /// "Verification of this content’s signature failed"
//    static let verification_of_this_content’s_signature_failed = NSLocalizedString("Verification of this content’s signature failed", comment: "error details")
//
//    /// "Decryption error"
//    static let decryption_error = NSLocalizedString("Decryption error", comment: "error title")
//
//    /// "Decryption of this content failed"
//    static let decryption_of_this_content_failed = NSLocalizedString("Decryption of this content failed", comment: "error details")
//
//    /// "Logs"
//    static let logs = NSLocalizedString("Logs", comment: "error title")
//
//    /// "normal attachments"
//    static let normal_attachments = NSLocalizedString("normal attachments", comment: "Title")
//
//    /// "inline attachments"
//    static let inline_attachments = NSLocalizedString("inline attachments", comment: "Title")
//
//    /// "Photo Library"
//    static let photo_library = NSLocalizedString("Photo Library", comment: "Title")
//
//    /// "Take a Photo"
//    static let take_a_photo = NSLocalizedString("Take a Photo", comment: "Title")
//
//    /// "Import File From..."
//    static let import_file_from... = NSLocalizedString("Import File From...", comment: "Title")
//
//    /// "The total attachment size can't be bigger than 25MB"
//    static let the_total_attachment_size_can't_be_bigger_than_25mb = NSLocalizedString("The total attachment size can't be bigger than 25MB", comment: "Description")
//
//    /// "Can't load the file"
//    static let can't_load_the_file = NSLocalizedString("Can't load the file", comment: "Error")
//
//    /// "Can't load the file"
//    static let can't_load_the_file = NSLocalizedString("Can't load the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "System can't copy the file"
//    static let system_can't_copy_the_file = NSLocalizedString("System can't copy the file", comment: "Error")
//
//    /// "System can't copy the file"
//    static let system_can't_copy_the_file = NSLocalizedString("System can't copy the file", comment: "Error")
//
//    /// "Can't open the file"
//    static let can't_open_the_file = NSLocalizedString("Can't open the file", comment: "Error")
//
//    /// "Can't open the file"
//    static let can't_open_the_file = NSLocalizedString("Can't open the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Can't copy the file"
//    static let can't_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")
//
//    /// "Cell phone number"
//    static let cell_phone_number = NSLocalizedString("Cell phone number", comment: "place holder")
//
//    /// "Enter Verification Code"
//    static let enter_verification_code = NSLocalizedString("Enter Verification Code", comment: "place holder")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Human Verification"
//    static let human_verification = NSLocalizedString("Human Verification", comment: "human verification top title")
//
//    /// "Enter your cell phone number"
//    static let enter_your_cell_phone_number = NSLocalizedString("Enter your cell phone number", comment: "human verification top title")
//
//    /// "We will send a verification code to the cell phone above."
//    static let we_will_send_a_verification_code_to_the_cell_phone_above. = NSLocalizedString("We will send a verification code to the cell phone above.", comment: "text field notes")
//
//    /// "Continue"
//    static let continue = NSLocalizedString("Continue", comment: "Action")
//
//    /// "Retry after %d seconds"
//    static let retry_after_%d_seconds = NSLocalizedString("Retry after %d seconds", comment: "Title")
//
//    /// "Send Verification Code"
//    static let send_verification_code = NSLocalizedString("Send Verification Code", comment: "Title")
//
//    /// "Verification code request failed"
//    static let verification_code_request_failed = NSLocalizedString("Verification code request failed", comment: "Title")
//
//    /// "Phone number invalid"
//    static let phone_number_invalid = NSLocalizedString("Phone number invalid", comment: "Title")
//
//    /// "Please input a valid cell phone number."
//    static let please_input_a_valid_cell_phone_number. = NSLocalizedString("Please input a valid cell phone number.", comment: "Description")
//
//    /// "Verification code sent"
//    static let verification_code_sent = NSLocalizedString("Verification code sent", comment: "Title")
//
//    /// "Please check your cell phone for the verification code."
//    static let please_check_your_cell_phone_for_the_verification_code. = NSLocalizedString("Please check your cell phone for the verification code.", comment: "Description")
//
//    /// "Create user failed"
//    static let create_user_failed = NSLocalizedString("Create user failed", comment: "Title")
//
//    /// "Default error, please try again."
//    static let default_error,_please_try_again. = NSLocalizedString("Default error, please try again.", comment: "Description")
//
//    /// "Got it"
//    static let got_it = NSLocalizedString("Got it", comment: "Action")
//
//    /// "PREMIUM FEATURE"
//    static let premium_feature = NSLocalizedString("PREMIUM FEATURE", comment: "Upgrade warning title")
//
//    /// "Looking to secure your contact's details?"
//    static let looking_to_secure_your_contact's_details? = NSLocalizedString("Looking to secure your contact's details?", comment: "Upgrade warning title")
//
//    /// "ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email."
//    static let protonmail_plus/professional/visionary_enables_you_to_add_and_edit_contact_details_beyond_just_your_contact’s_name_and_email._by_using_protonmail,_this_data_will_be_as_secure_as_your_end-to-end_encrypted_email. = NSLocalizedString("ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email.", comment: "Upgrade warning message")
//
//    /// "Upgrading is not possible in the app."
//    static let upgrading_is_not_possible_in_the_app. = NSLocalizedString("Upgrading is not possible in the app.", comment: "Upgrade warning message")
//
//    /// "Back"
//    static let back = NSLocalizedString("Back", comment: "top left back button")
//
//    /// "Human Verification"
//    static let human_verification = NSLocalizedString("Human Verification", comment: "view top title")
//
//    /// "Continue"
//    static let continue = NSLocalizedString("Continue", comment: "Action")
//
//    /// "Create user failed"
//    static let create_user_failed = NSLocalizedString("Create user failed", comment: "Title")
//
//    /// "Default error, please try again."
//    static let default_error,_please_try_again. = NSLocalizedString("Default error, please try again.", comment: "Error")
//
//    /// "The verification failed!"
//    static let the_verification_failed! = NSLocalizedString("The verification failed!", comment: "Error")
//
//    /// "Retry"
//    static let retry = NSLocalizedString("Retry", comment: "Action")
//
//    /// "Unknow Error"
//    static let unknow_error = NSLocalizedString("Unknow Error", comment: "Description")
//
//    /// "Unknow Error"
//    static let unknow_error = NSLocalizedString("Unknow Error", comment: "Description")
//
//    /// "Message expired"
//    static let message_expired = NSLocalizedString("Message expired", comment: "")
//
//    /// "Expires in %d days %d hours %d mins %d seconds"
//    static let expires_in_%d_days_%d_hours_%d_mins_%d_seconds = NSLocalizedString("Expires in %d days %d hours %d mins %d seconds", comment: "expiration time count down")
//
//    /// "Confirm"
//    static let confirm = NSLocalizedString("Confirm", comment: "Action")
//
//    /// "Sign Out"
//    static let sign_out = NSLocalizedString("Sign Out", comment: "Action")
//
//    /// "Rate & Review"
//    static let rate_&_review = NSLocalizedString("Rate & Review", comment: "Title")
//
//    /// "Tweet about ProtonMail"
//    static let tweet_about_protonmail = NSLocalizedString("Tweet about ProtonMail", comment: "Title")
//
//    /// "Share it with your friends"
//    static let share_it_with_your_friends = NSLocalizedString("Share it with your friends", comment: "Title")
//
//    /// "Contact the ProtonMail team"
//    static let contact_the_protonmail_team = NSLocalizedString("Contact the ProtonMail team", comment: "Title")
//
//    /// "Trouble shooting guide"
//    static let trouble_shooting_guide = NSLocalizedString("Trouble shooting guide", comment: "Title")
//
//    /// "Help us to make privacy the default in the web."
//    static let help_us_to_make_privacy_the_default_in_the_web. = NSLocalizedString("Help us to make privacy the default in the web.", comment: "Title")
//
//    /// "Help us to improve ProtonMail with your input."
//    static let help_us_to_improve_protonmail_with_your_input. = NSLocalizedString("Help us to improve ProtonMail with your input.", comment: "Title")
//
//    /// "We would like to know what we can do better."
//    static let we_would_like_to_know_what_we_can_do_better. = NSLocalizedString("We would like to know what we can do better.", comment: "Title")
//
//    /// "Enter your PIN to unlock your inbox."
//    static let enter_your_pin_to_unlock_your_inbox. = NSLocalizedString("Enter your PIN to unlock your inbox.", comment: "Title")
//
//    /// "CONFIRM"
//    static let confirm = NSLocalizedString("CONFIRM", comment: "Action")
//
//    /// "attempt remaining until secure data wipe!"
//    static let attempt_remaining_until_secure_data_wipe! = NSLocalizedString("attempt remaining until secure data wipe!", comment: "Error")
//
//    /// "attempts remaining until secure data wipe!"
//    static let attempts_remaining_until_secure_data_wipe! = NSLocalizedString("attempts remaining until secure data wipe!", comment: "Error")
//
//    /// "Incorrect PIN,"
//    static let incorrect_pin, = NSLocalizedString("Incorrect PIN,", comment: "Error")
//
//    /// "attempts remaining"
//    static let attempts_remaining = NSLocalizedString("attempts remaining", comment: "Description")
//
//    /// "Current Language is: "
//    static let current_language_is:_ = NSLocalizedString("Current Language is: ", comment: "Change language title")
//
//    /// "v"
//    static let v = NSLocalizedString("v", comment: "versions first character ")
//
//    /// "v"
//    static let v = NSLocalizedString("v", comment: "versions first character ")
//
//    /// "Login"
//    static let login = NSLocalizedString("Login", comment: "touch id box title like Login: email@email.com")
//
//    /// "Authentication was cancelled by the system"
//    static let authentication_was_cancelled_by_the_system = NSLocalizedString("Authentication was cancelled by the system", comment: "Description")
//
//    /// "Authentication failed"
//    static let authentication_failed = NSLocalizedString("Authentication failed", comment: "Description")
//
//    /// "TouchID is not enrolled, enable it in the system Settings"
//    static let touchid_is_not_enrolled,_enable_it_in_the_system_settings = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "Description")
//
//    /// "A passcode has not been set, enable it in the system Settings"
//    static let a_passcode_has_not_been_set,_enable_it_in_the_system_settings = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "Description")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "Description")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "Description")
//
//    /// "USER LOGIN"
//    static let user_login = NSLocalizedString("USER LOGIN", comment: "Title")
//
//    /// "Username"
//    static let username = NSLocalizedString("Username", comment: "Title")
//
//    /// "Password"
//    static let password = NSLocalizedString("Password", comment: "Title")
//
//    /// "LOGIN"
//    static let login = NSLocalizedString("LOGIN", comment: "Title")
//
//    /// "NEED AN ACCOUNT? SIGN UP."
//    static let need_an_account?_sign_up. = NSLocalizedString("NEED AN ACCOUNT? SIGN UP.", comment: "Action")
//
//    /// "FORGOT PASSWORD?"
//    static let forgot_password? = NSLocalizedString("FORGOT PASSWORD?", comment: "login page forgot pwd")
//
//    /// "The mailbox password is incorrect."
//    static let the_mailbox_password_is_incorrect. = NSLocalizedString("The mailbox password is incorrect.", comment: "Description")
//
//    /// "Incorrect password"
//    static let incorrect_password = NSLocalizedString("Incorrect password", comment: "Title")
//
//    /// "Incorrect password"
//    static let incorrect_password = NSLocalizedString("Incorrect password", comment: "Title")
//
//    /// "The mailbox password is incorrect."
//    static let the_mailbox_password_is_incorrect. = NSLocalizedString("The mailbox password is incorrect.", comment: "Description")
//
//    /// "Please use the web application to reset your password."
//    static let please_use_the_web_application_to_reset_your_password. = NSLocalizedString("Please use the web application to reset your password.", comment: "Alert")
//
//    /// "Send"
//    static let send = NSLocalizedString("Send", comment: "Action")
//
//    /// "Bug Description"
//    static let bug_description = NSLocalizedString("Bug Description", comment: "Title")
//
//    /// "REPORT BUGS"
//    static let report_bugs = NSLocalizedString("REPORT BUGS", comment: "Title")
//
//    /// "OK"
//    static let ok = NSLocalizedString("OK", comment: "Action")
//
//    /// "Bug Report Received"
//    static let bug_report_received = NSLocalizedString("Bug Report Received", comment: "Title")
//
//    /// "Thank you for submitting a bug report.  We have added your report to our bug tracking system."
//    static let thank_you_for_submitting_a_bug_report.__we_have_added_your_report_to_our_bug_tracking_system. = NSLocalizedString("Thank you for submitting a bug report.  We have added your report to our bug tracking system.", comment: "")
//
//    /// "OK"
//    static let ok = NSLocalizedString("OK", comment: "Action")
//
//    /// "Label as..."
//    static let label_as... = NSLocalizedString("Label as...", comment: "Title")
//
//    /// "Move to..."
//    static let move_to... = NSLocalizedString("Move to...", comment: "Title")
//
//    /// "Mark as unread"
//    static let mark_as_unread = NSLocalizedString("Mark as unread", comment: "Action")
//
//    /// "TouchID is not enrolled, enable it in the system Settings"
//    static let touchid_is_not_enrolled,_enable_it_in_the_system_settings = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "Touch id error message")
//
//    /// "A passcode has not been set, enable it in the system Settings"
//    static let a_passcode_has_not_been_set,_enable_it_in_the_system_settings = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "Touch id error message")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "Touch id error message")
//
//    /// "All of your existing encrypted emails will be lost forever, but you will still be able to view your unencrypted emails.\n\nTHIS ACTION CANNOT BE UNDONE!"
//    static let all_of_your_existing_encrypted_emails_will_be_lost_forever,_but_you_will_still_be_able_to_view_your_unencrypted_emails.\n\nthis_action_cannot_be_undone! = NSLocalizedString("All of your existing encrypted emails will be lost forever, but you will still be able to view your unencrypted emails.\n\nTHIS ACTION CANNOT BE UNDONE!", comment: "Description")
//
//    /// "Display Name Updated"
//    static let display_name_updated = NSLocalizedString("Display Name Updated", comment: "Title")
//
//    /// "The display name is now %@."
//    static let the_display_name_is_now_%@. = NSLocalizedString("The display name is now %@.", comment: "Description")
//
//    /// "Signature Updated"
//    static let signature_updated = NSLocalizedString("Signature Updated", comment: "Title")
//
//    /// "Your signature has been updated."
//    static let your_signature_has_been_updated. = NSLocalizedString("Your signature has been updated.", comment: "Description")
//
//    /// "Password Mismatch"
//    static let password_mismatch = NSLocalizedString("Password Mismatch", comment: "Title")
//
//    /// "The password you entered does not match the current password."
//    static let the_password_you_entered_does_not_match_the_current_password. = NSLocalizedString("The password you entered does not match the current password.", comment: "Description")
//
//    /// "Password Updated"
//    static let password_updated = NSLocalizedString("Password Updated", comment: "Title")
//
//    /// "Please use your new password when signing in."
//    static let please_use_your_new_password_when_signing_in. = NSLocalizedString("Please use your new password when signing in.", comment: "Description")
//
//    /// "Password Mismatch"
//    static let password_mismatch = NSLocalizedString("Password Mismatch", comment: "Title")
//
//    /// "The passwords you entered do not match."
//    static let the_passwords_you_entered_do_not_match. = NSLocalizedString("The passwords you entered do not match.", comment: "Description")
//
//    /// "OK"
//    static let ok = NSLocalizedString("OK", comment: "Action")
//
//    /// "Can't load share content!"
//    static let can't_load_share_content! = NSLocalizedString("Can't load share content!", comment: "Description")
//
//    /// "Can't load share content!"
//    static let can't_load_share_content! = NSLocalizedString("Can't load share content!", comment: "Description")
//
//    /// "The total attachment size can't be bigger than 25MB"
//    static let the_total_attachment_size_can't_be_bigger_than_25mb = NSLocalizedString("The total attachment size can't be bigger than 25MB", comment: "Description")
//
//    /// "Can't load share content!"
//    static let can't_load_share_content! = NSLocalizedString("Can't load share content!", comment: "Description")
//
//    /// "Can't load share content!"
//    static let can't_load_share_content! = NSLocalizedString("Can't load share content!", comment: "Description")
//
//    /// "Share Alert"
//    static let share_alert = NSLocalizedString("Share Alert", comment: "Title")
//
//    /// "Please use ProtonMail App login first"
//    static let please_use_protonmail_app_login_first = NSLocalizedString("Please use ProtonMail App login first", comment: "Description")
//
//    /// "Login"
//    static let login = NSLocalizedString("Login", comment: "")
//
//    /// "Authentication was cancelled by the system"
//    static let authentication_was_cancelled_by_the_system = NSLocalizedString("Authentication was cancelled by the system", comment: "Description")
//
//    /// "Authentication was cancelled by the user"
//    static let authentication_was_cancelled_by_the_user = NSLocalizedString("Authentication was cancelled by the user", comment: "Description")
//
//    /// "Authentication failed"
//    static let authentication_failed = NSLocalizedString("Authentication failed", comment: "Description")
//
//    /// "Authentication failed"
//    static let authentication_failed = NSLocalizedString("Authentication failed", comment: "Description")
//
//    /// "TouchID is not enrolled, enable it in the system Settings"
//    static let touchid_is_not_enrolled,_enable_it_in_the_system_settings = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "Description")
//
//    /// "A passcode has not been set, enable it in the system Settings"
//    static let a_passcode_has_not_been_set,_enable_it_in_the_system_settings = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "Description")
//
//    /// "TouchID not available"
//    static let touchid_not_available = NSLocalizedString("TouchID not available", comment: "Description")
//
//    /// "Compose"
//    static let compose = NSLocalizedString("Compose", comment: "Action")
//
//    /// "Send message without subject?"
//    static let send_message_without_subject? = NSLocalizedString("Send message without subject?", comment: "Description")
//
//    /// "Send"
//    static let send = NSLocalizedString("Send", comment: "Action")
//
//    /// "Confirmation"
//    static let confirmation = NSLocalizedString("Confirmation", comment: "Title")
//
//    /// "Save draft"
//    static let save_draft = NSLocalizedString("Save draft", comment: "Title")
//
//    /// "Discard draft"
//    static let discard_draft = NSLocalizedString("Discard draft", comment: "Title")
//
//    /// "You need at least one recipient to send"
//    static let you_need_at_least_one_recipient_to_send = NSLocalizedString("You need at least one recipient to send", comment: "Description")
//
//    /// "Change sender address to .."
//    static let change_sender_address_to_.. = NSLocalizedString("Change sender address to ..", comment: "Title")
//
//    /// "Upgrade to a paid plan to send from your %@ address"
//    static let upgrade_to_a_paid_plan_to_send_from_your_%@_address = NSLocalizedString("Upgrade to a paid plan to send from your %@ address", comment: "Error")
//
//    /// "days"
//    static let days = NSLocalizedString("days", comment: "")
//
//    /// "Hours"
//    static let hours = NSLocalizedString("Hours", comment: "")
//
//    /// "days"
//    static let days = NSLocalizedString("days", comment: "")
//
//    /// "Hours"
//    static let hours = NSLocalizedString("Hours", comment: "")
//
//    /// "Pin code can't be empty."
//    static let pin_code_can't_be_empty. = NSLocalizedString("Pin code can't be empty.", comment: "Description")
//
//
//

    
    
    

}
