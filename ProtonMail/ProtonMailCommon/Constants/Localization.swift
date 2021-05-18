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

/// object for all the localization strings, this avoid some issues with xcode 9 import/export
/// this o
var LocalString = LocalizedString()

class LocalizedString {

    class func reset() {
        LocalString = LocalizedString()
    }

    //Mark Signup

    /// "(2048 bit)"
    lazy var _signup_key_2048_size = NSLocalizedString("(2048 bit)", comment: "Key size text when setup key")
    /// "(4096 bit)"
    lazy var _signup_key_4096_size   = NSLocalizedString("(4096 bit)", comment: "Key size text when setup key")
    /// "*OPTIONAL"
    lazy var _signup_optional_text   = NSLocalizedString("*OPTIONAL", comment: "optional text field")
    /// "2fa Authentication failed please try to login again"
    lazy var _signup_2fa_auth_failed = NSLocalizedString("2FA failed. Please try to login again.", comment: "2fa verification failed")

    // Mark Link Opening Confirmaiton
    lazy var _about_to_open_link = NSLocalizedString("You are about to launch the web browser and navigate to", comment: "link opeining confirmation")
    lazy var _request_link_confirmation = NSLocalizedString("Request Link Confirmation", comment: "link opeining confirmation")
    
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
    /// "Input Display Name ..."
    lazy var _settings_input_display_name_placeholder = NSLocalizedString("Input Display Name ...", comment: "place holder")
    /// "Signature"
    lazy var _settings_signature_title = NSLocalizedString("Signature", comment: "Title in signature settings")
    /// "Email default signature"
    lazy var _settings_email_default_signature = NSLocalizedString("Email default signature", comment: "place holder")
    /// "Enable Default Signature"
    lazy var _settings_enable_default_signature_title = NSLocalizedString("Enable Default Signature", comment: "Title")
    /// "Mobile Signature"
    lazy var _settings_mobile_signature_title = NSLocalizedString("Mobile Signature", comment: "Mobile Signature title in settings")
    /// "Modifying or turning off the default mobile signature is a paid feature."
    lazy var _settings_only_paid_to_modify_mobile_signature = NSLocalizedString("Modifying or turning off the default mobile signature is a paid feature.", comment: "Description")
    /// "Enable Mobile Signature"
    lazy var _settings_enable_mobile_signature_title = NSLocalizedString("Enable Mobile Signature", comment: "Title")
    /// "ProtonMail Plus is required to customize your mobile signature"
    lazy var _settings_plus_is_required_to_modify_signature_notes = NSLocalizedString("ProtonMail Plus is required to customize your mobile signature", comment: "Description")
    /// "Notification Email"
    lazy var _settings_notification_email = NSLocalizedString("Notification Email", comment: "Title")
    /// "Also used to reset a forgotten password."
    lazy var _settings_notification_email_notes = NSLocalizedString("Also used to reset a forgotten password.", comment: "Description")
    /// "Notification / Recovery Email"
    lazy var _settings_notification_email_title = NSLocalizedString("Notification / Recovery Email", comment: "Title")
    /// "Enable Notification Email"
    lazy var _settings_notification_email_switch_title = NSLocalizedString("Enable Notification Email", comment: "Title")
    /// "Input Notification Email ..."
    lazy var _settings_notification_email_placeholder = NSLocalizedString("Input Notification Email ...", comment: "place holder")
    /// "Current password"
    lazy var _settings_current_password = NSLocalizedString("Current password", comment: "Placeholder")
    /// "New password"
    lazy var _settings_new_password = NSLocalizedString("New password", comment: "Placeholder")
    /// "Confirm new password"
    lazy var _settings_confirm_new_password = NSLocalizedString("Confirm new password", comment: "Placeholder")
    /// "Remove image meta-data"
    lazy var _strip_metadata = NSLocalizedString("Remove image meta-data", comment: "Settings row")
    /// "Default browser"
    lazy var _default_browser = NSLocalizedString("Default browser", comment: "Settings row")
    /// "Manage in device Settings"
    lazy var _manage_language_in_device_settings = NSLocalizedString("Manage in device Settings", comment: "Settings row")
    /// "Swiping gestures"
    lazy var _settings_swiping_gestures = NSLocalizedString("Swiping gestures", comment: "Swiping gestures")
    
    lazy var _networking = NSLocalizedString("Networking", comment: "section title ")
    
    
    // Mark Menu
    lazy var _menu_button         = NSLocalizedString("Menu", comment: "menu title")
    /// "Report Bugs"
    lazy var _menu_bugs_title     = NSLocalizedString("Report Bugs", comment: "menu title")
    /// "Inbox"
    lazy var _menu_inbox_title    =  NSLocalizedString("Inbox", comment: "menu title")
    /// "Starred"
    lazy var _menu_starred_title  =  NSLocalizedString("Starred", comment: "menu title")
    /// "Archive"
    lazy var _menu_archive_title  =  NSLocalizedString("Archive", comment: "menu title")
    /// "Drafts"
    lazy var _menu_drafts_title   =  NSLocalizedString("Drafts", comment: "menu title")
    /// "All Mail"
    lazy var _menu_allmail_title  =  NSLocalizedString("All Mail", comment: "menu title")
    /// "Sent"
    lazy var _menu_sent_title     =  NSLocalizedString("Sent", comment: "menu title")
    /// "Trash"
    lazy var _menu_trash_title    =  NSLocalizedString("Trash", comment: "menu title")
    /// "Spam"
    lazy var _menu_spam_title     =  NSLocalizedString("Spam", comment: "menu title")
    /// "Contacts"
    lazy var _menu_contacts_title =  NSLocalizedString("Contacts", comment: "menu title")
    /// "Contact Groups"
    lazy var _menu_contact_group_title = NSLocalizedString("Groups", comment: "menu title (contact groups)")
    /// "Settings"
    lazy var _menu_settings_title =  NSLocalizedString("Settings", comment: "menu title")
    /// "Logout"
    lazy var _menu_signout_title  =  NSLocalizedString("Logout", comment: "menu title")
    /// "Feedback"
    lazy var _menu_feedback_title =  NSLocalizedString("Feedback", comment: "menu title")
    /// "Lock The App"
    lazy var _menu_lockapp_title  =  NSLocalizedString("Lock The App", comment: "menu title")
    /// "Subscription"
    lazy var _menu_service_plan_title  =  NSLocalizedString("Subscription", comment: "menu title")
    /// "Manage accounts"
    lazy var _menu_manage_accounts  =  NSLocalizedString("Manage accounts", comment: "menu title")
    /// "Add accounts"
    lazy var _menu_add_account  =  NSLocalizedString("Add accounts", comment: "menu title")


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

    /// "All Mail"
    lazy var _locations_all_mail_desc = NSLocalizedString("All Mail", comment: "mail location desc")
    /// "Inbox"
    lazy var _locations_inbox_desc    = NSLocalizedString("Inbox", comment: "mail location desc")
    /// "Starred"
    lazy var _locations_starred_desc  = NSLocalizedString("Starred", comment: "mail location desc")
    /// "Draft"
    lazy var _locations_draft_desc    = NSLocalizedString("Draft", comment: "mail location desc")
    /// "Outbox"
    lazy var _locations_outbox_desc   = NSLocalizedString("Outbox", comment: "mail location desc")
    /// "Trash"
    lazy var _locations_trash_desc    = NSLocalizedString("Trash", comment: "mail location desc")
    /// "Archive"
    lazy var _locations_archive_desc  = NSLocalizedString("Archive", comment: "mail location desc")
    /// "Spam"
    lazy var _locations_spam_desc     = NSLocalizedString("Spam", comment: "mail location desc")
    /// "Deleted"
    lazy var _locations_deleted_desc  = NSLocalizedString("Deleted", comment: "mail location desc")

    /// "Trash"
    lazy var _locations_deleted_action      = NSLocalizedString("Trash", comment: "move action")
    /// "Move to Inbox"
    lazy var _locations_move_inbox_action   = NSLocalizedString("Move to Inbox", comment: "move action")
    /// "Move to Draft"
    lazy var _locations_move_draft_action   = NSLocalizedString("Move to Draft", comment: "move action")
    /// "Move to Outbox"
    lazy var _locations_move_outbox_action  = NSLocalizedString("Move to Outbox", comment: "move action")
    /// "Move to Spam"
    lazy var _locations_move_spam_action    = NSLocalizedString("Move to Spam", comment: "move action")
    /// "Add Star"
    lazy var _locations_add_star_action     = NSLocalizedString("Add Star",  comment: "mark message star")
    /// "Move to Archive"
    lazy var _locations_move_archive_action = NSLocalizedString("Move to Archive", comment: "move action")
    /// "Move to Trash"
    lazy var _locations_move_trash_action   = NSLocalizedString("Move to Trash", comment: "move action")
    /// "Move to AllMail"
    lazy var _locations_move_allmail_action = NSLocalizedString("Move to All Mail", comment: "move action")
    /// "Empty Folder"
    lazy var _empty_folder = NSLocalizedString("Empty Folder", comment: "empty folder, for spam and trash and drafts")
    /// "Empty label"
    lazy var _empty_label = NSLocalizedString("Empty Label", comment: "it is an option to empty the label")
    /// "Mark Read"
    lazy var _mark_read = NSLocalizedString("Mark Read", comment: "mark message as read action")
    /// "Remove Star"
    lazy var _remove_star = NSLocalizedString("Remove Star", comment: "un star message")
    /// "Delete all"
    lazy var _delete_all = NSLocalizedString("Delete all", comment: "emptify folder/label confirmation alert")
    /// "Are you sure? This can't be undone."
    lazy var _are_you_sure_this_cant_be_undone = NSLocalizedString("Are you sure? This can't be undone.", comment: "emptify folder/label confirmation alert")
    
    
    // Mark Messages

    /// "Message sent"
    lazy var _message_sent_ok_desc          = NSLocalizedString("Message sent", comment: "Description after message have been sent")
    /// "Sent Failed"
    lazy var _message_sent_failed_desc      = NSLocalizedString("Sent Failed", comment: "Description")
    /// "The draft cache is broken please try again"
    lazy var _message_draft_cache_is_broken = NSLocalizedString("The draft cache is broken. Please try again.", comment: "Description")
    /// "No Messages"
    lazy var _messages_no_messages = NSLocalizedString("No Messages", comment: "message when mailbox doesnt have emailsß")
    /// "Undo"
    lazy var _messages_undo_action = NSLocalizedString("Undo", comment: "Action")
    /// "Can't find the selected message. Please try again."
    lazy var _messages_cant_find_message = NSLocalizedString("Can't find the selected message. Please try again.", comment: "Description")
    /// "Message has been deleted."
    lazy var _messages_has_been_deleted = NSLocalizedString("Message has been deleted.", comment: "Title")
    /// "Message has been moved."
    lazy var _messages_has_been_moved = NSLocalizedString("Message has been moved.", comment: "Title")
    /// "You're going to delete the message irreversibly. Are you sure?"
    lazy var _messages_will_be_removed_irreversibly = NSLocalizedString("You're going to delete the message irreversibly. Are you sure?", comment: "Confirmation message before deleting a message")
    /// "Archived"
    lazy var _messages_archived = NSLocalizedString("Archived", comment: "Description")
    /// "Spammed"
    lazy var _messages_spammed = NSLocalizedString("Spammed", comment: "Description")
    /// "Message %@"
    lazy var _messages_with_title = NSLocalizedString("Message %@", comment: "Message with title")
    /// "Labels have been applied."
    lazy var _messages_labels_applied = NSLocalizedString("Labels have been applied.", comment: "Title")
    /// "You have a new email!"
    lazy var _messages_you_have_new_email = NSLocalizedString("You have a new email!", comment: "Title")
    /// "You have %d new emails!"
    lazy var _messages_you_have_new_emails_with = NSLocalizedString("You have %d new emails!", comment: "Message")



    // Mark Composer

    /// "Re:"
    lazy var _composer_short_reply   = NSLocalizedString("Re:", comment: "abbreviation of reply:")
    /// "Fwd:"
    lazy var _composer_short_forward = NSLocalizedString("Fwd:", comment: "abbreviation of forward:")
    /// "FW:"
    lazy var _composer_short_forward_shorter = NSLocalizedString("FW:", comment: "abbreviation of forward:")
    /// "On"
    lazy var _composer_on            = NSLocalizedString("On", comment: "Title")
    /// "wrote:"
    lazy var _composer_wrote         = NSLocalizedString("wrote:", comment: "Title")
    /// "On EE, MMM d, yyyy at %@"
    lazy var _composer_forward_header = NSLocalizedString("On EE, MMM d, yyyy at %@", comment: "forward email content header, EE,MMM d, yyyy change to your country local format. if you are not sure just keep it as it. %@ part is 12/24 hour format it will be loaded in code.")
    /// "On EE, MMM d, yyyy at %@, %@, wrote:"
    lazy var _composer_reply_header = NSLocalizedString("On EE, MMM d, yyyy at %@, %@, wrote:", comment: "reply email content header, EE,MMM d, yyyy change to your country local format. if you are not sure just keep it as it. first %@ is 12/24 hour format, second %@ will be the email hyper link, they will be loaded in code. ")
    
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
    lazy var _composer_eo_msg_pwd_placeholder     = NSLocalizedString("Message Password", comment: "Placeholder")
    /// "Password is required."
    lazy var _composer_eo_empty_pwd_desc          = NSLocalizedString("Password cannot be empty.", comment: "Description")
    /// "Please set a password."
    lazy var _composer_eo_pls_set_password = NSLocalizedString("Please set a password.", comment: "Description")
    /// "Confirm Password"
    lazy var _composer_eo_confirm_pwd_placeholder = NSLocalizedString("Confirm Password", comment: "Placeholder")
    /// "Message password does not match."
    lazy var _composer_eo_dismatch_pwd_desc       = NSLocalizedString("Message password does not match.", comment: "Description")
    /// "Compose"
    lazy var _composer_compose_action = NSLocalizedString("Compose", comment: "Action")
    /// "Send message without subject?"
    lazy var _composer_send_no_subject_desc = NSLocalizedString("Send message without subject?", comment: "Description")
    /// "You need at least one recipient to send"
    lazy var _composer_no_recipient_error = NSLocalizedString("You need at least one recipient to send", comment: "Description")
    /// "Save draft"
    lazy var _composer_save_draft_action = NSLocalizedString("Save draft", comment: "Action")
    /// "Discard draft"
    lazy var _composer_discard_draft_action = NSLocalizedString("Discard draft", comment: "Action")
    /// "Change sender address to .."
    lazy var _composer_change_sender_address_to = NSLocalizedString("Change sender address to ..", comment: "Title")
    /// "Upgrade to a paid plan to send from your %@ address"
    lazy var _composer_change_paid_plan_sender_error = NSLocalizedString("Upgrade to a paid plan to send from your %@ address", comment: "Error")
    /// "Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@"
    lazy var _composer_sending_messages_from_a_paid_feature = NSLocalizedString("Sending messages from %@ address is a paid feature. Your message will be sent from your default address %@", comment: "pm.me upgrade warning in composer")
    /// "days"
    lazy var _composer_eo_days_title = NSLocalizedString("days", comment: "Title")
    /// "Hours"
    lazy var _composer_eo_hours_title = NSLocalizedString("Hours", comment: "Title")
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
    /// "Define Expiration Date"
    lazy var _composer_define_expiration_placeholder = NSLocalizedString("Define Expiration Date", comment: "Placeholder")
    /// "Define Password"
    lazy var _composer_define_password = NSLocalizedString("Define Password", comment: "place holder")
    /// "Define Hint (Optional)"
    lazy var _define_hint_optional = NSLocalizedString("Define Hint (Optional)", comment: "Placeholder")
    /// "Too many recipients"
    lazy var _too_many_recipients_title = NSLocalizedString("Too many recipients", comment: "Alert title")
    /// "The maximum number of Recipients is 25."
    lazy var _max_number_of_recipients_is_number = NSLocalizedString("The maximum number of distinct recipients is %d", comment: "Alert message")
    /// "Clear Style"
    lazy var _clear_style = NSLocalizedString("Clear Style", comment: "Menu action to remove text formatting")
    
    // Mark Contacts

    /// "Add Organization"
    lazy var _contacts_add_org              = NSLocalizedString("Add Organization", comment: "new contacts add Organization ")
    /// "Add Nickname"
    lazy var _contacts_add_nickname         = NSLocalizedString("Add Nickname", comment: "new contacts add Nickname")
    /// "Add Title"
    lazy var _contacts_add_title            = NSLocalizedString("Add Title", comment: "new contacts add Title")
    /// "Add Birthday"
    lazy var _contacts_add_bd               = NSLocalizedString("Add Birthday", comment: "new contacts add Birthday")
    /// "Add Anniversary"
    lazy var _contacts_add_anniversary      = NSLocalizedString("Add Anniversary", comment: "new contacts add Anniversary")
    /// "Add Gender"
    lazy var _contacts_add_gender           = NSLocalizedString("Add Gender", comment: "new contacts add Gender")
    /// "Add Contact"
    lazy var _contacts_add_contact          = NSLocalizedString("Add Contact", comment: "Contacts add new contact")
    /// "Add Custom Label"
    lazy var _contacts_add_custom_label     = NSLocalizedString("Add Custom Label", comment: "add custom label type action")
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
    lazy var _contacts_vcard_url_placeholder = NSLocalizedString("Url", comment: "default vcard types")
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
    /// "Contact Details"
    lazy var _contacts_contact_details_title = NSLocalizedString("Contact Details", comment: "contact section title")
    lazy var _contacts_email_contact_title = NSLocalizedString("Email Contact", comment: "Send an email to the current contact (button title text)")
    lazy var _contacts_call_contact_title = NSLocalizedString("Call Contact", comment: "Call the contact (button title text)")
    /// "Email addresses"
    lazy var _contacts_email_addresses_title = NSLocalizedString("Email Addresses", comment: "contact detail view, email addresses section title")
    /// "Profile picture"
    lazy var _contacts_add_profile_picture = NSLocalizedString("Add Photo", comment: "The button text for add profile picture")
    lazy var _contacts_edit_profile_picture = NSLocalizedString("Edit Photo", comment: "The button text for edit profile picture")
    /// "Encrypted Contact Details"
    lazy var _contacts_encrypted_contact_details_title = NSLocalizedString("Encrypted Contact Details", comment: "contact section title")
    /// "Share Contact"
    lazy var _contacts_share_contact_action = NSLocalizedString("Share Contact", comment: "action")
    /// "Name"
    lazy var _contacts_name_title = NSLocalizedString("Name", comment: "title")
    /// "Notes"
    lazy var _contacts_info_notes = NSLocalizedString("Notes", comment: "title")
    /// "Upload Contacts"
    lazy var _contacts_upload_contacts = NSLocalizedString("Upload Contacts",  comment: "Action")


    // Mark Labels

    /// "Add Label"
    lazy var _labels_add_label_action     = NSLocalizedString("Add Label", comment: "add label action")
    /// "Add Folder"
    lazy var _labels_add_folder_action    = NSLocalizedString("Add Folder", comment: "Action")
    /// "Also Archive"
    lazy var _labels_apply_archive_check  = NSLocalizedString("Also Archive", comment: "archive when apply label")
    /// "Add New Folder"
    lazy var _labels_add_new_folder_title = NSLocalizedString("Add New Folder", comment: "add a new folder")
    /// "Add New Label"
    lazy var _labels_add_new_label_title  = NSLocalizedString("Add New Label", comment: "add a new folder")
    /// "Edit Label"
    lazy var _labels_edit_label_title     = NSLocalizedString("Edit Label", comment: "Title")
    /// "Folder Name"
    lazy var _labels_folder_name_text     = NSLocalizedString("Folder Name", comment: "place holder")
    /// "Label Name"
    lazy var _labels_label_name_text      = NSLocalizedString("Label Name", comment: "createing lable input place holder")
    /// "Manage Labels/Folders"
    lazy var _labels_manage_title         = NSLocalizedString("Manage Labels/Folders", comment: "Title")
    /// "Move to Folder"
    lazy var _labels_move_to_folder       = NSLocalizedString("Move to Folder", comment: "folder apply - title")
    /// "Edit Folder"
    lazy var _labels_edit_folder_title    = NSLocalizedString("Edit Folder", comment: "Title")

    // Mark General

    /// "API Server not reachable..."
    lazy var _general_api_server_not_reachable     =  NSLocalizedString("API Server not reachable...", comment: "when server not reachable")
    /// "Access to this account is disabled due to non-payment. Please log in through protonmail.com to pay your outstanding invoice(s)."
    lazy var _general_account_disabled_non_payment = NSLocalizedString("Access to this account is disabled due to non-payment. Please sign in through protonmail.com to pay your unpaid invoice.", comment: "error message")
    /// "Alert"
    lazy var _general_alert_title     = NSLocalizedString("Alert", comment: "Title")
    /// "Done"
    lazy var _general_done_button     = NSLocalizedString("Done", comment: "Done action")
    /// "Cancel"
    lazy var _general_cancel_button   = NSLocalizedString("Cancel", comment: "Cancel action")
    
    lazy var _general_yes_action = NSLocalizedString("Yes", comment: "Yes action")
    /// "Open"
    lazy var _general_open_button     = NSLocalizedString("Open", comment: "Open action")
    /// "Remove"
    lazy var _general_remove_button   = NSLocalizedString("Remove", comment: "remove action")
    /// "Apply"
    lazy var _general_apply_button    = NSLocalizedString("Apply", comment: "Apply action")
    /// "Reply"
    lazy var _general_reply_button    = NSLocalizedString("Reply", comment: "reply action")
    /// "Reply All"
    lazy var _general_replyall_button = NSLocalizedString("Reply All", comment: "reply all action")
    /// "Forward"
    lazy var _general_forward_button  = NSLocalizedString("Forward", comment: "forward action")
    /// "From:"
    lazy var _general_from_label      = NSLocalizedString("From:", comment: "message From: field text")
    /// "To:"
    lazy var _general_to_label        = NSLocalizedString("To:", comment: "message To: feild")
    /// "Cc:"
    lazy var _general_cc_label        = NSLocalizedString("Cc:", comment: "message Cc: feild")
    /// "Cc:"
    lazy var _general_bcc_label        = NSLocalizedString("Bcc:", comment: "message Bcc: feild")
    /// "at"
    lazy var _general_at_label        = NSLocalizedString("at", comment: "like at 10:00pm")
    /// "Delete"
    lazy var _general_delete_action   = NSLocalizedString("Delete", comment: "general delete action")
    /// "Close"
    lazy var _general_close_action    = NSLocalizedString("Close", comment: "general close action")
    /// "Update"
    lazy var _general_update_action   = NSLocalizedString("Update", comment: "like top right action text")
    /// "Invalid access token. Please try loging in again."
    lazy var _general_invalid_access_token = NSLocalizedString("Your session has expired because you have been inactive for a while or because it has been revoked. Please log back in.", comment: "Description")
    /// "A new version of ProtonMail app is available. Please update to the latest version."
    lazy var _general_force_upgrade_desc = NSLocalizedString("A new version of ProtonMail app is available. Please update to the latest version.", comment: "Description")
    /// "Search"
    lazy var _general_search_placeholder = NSLocalizedString("Search", comment: "Title")
    /// "Notice"
    lazy var _general_notice_alert_title = NSLocalizedString("Notice", comment: "Alert title")
    /// "Don't remind me again"
    lazy var _general_dont_remind_action = NSLocalizedString("Don't remind me again", comment: "Action")
    /// "Send"
    lazy var _general_send_action = NSLocalizedString("Send", comment: "Action")
    /// "You enabled message expiration, but not all recipients support this. Please add a password and/or disable PGP sending to use expiration for all recipients."
    lazy var _you_enabled_message_expiration_but_not_all_recipients_support_this_please_add = NSLocalizedString("You enabled message expiration, but not all recipients support this. Please add a password and/or disable PGP sending to use expiration for all recipients.", comment: "description")
    /// "Send anyway"
    lazy var _send_anyway = NSLocalizedString("Send anyway", comment: "Action")
    /// "Confirmation"
    lazy var _general_confirmation_title = NSLocalizedString("Confirmation", comment: "Title")
    /// "Draft"
    lazy var _general_draft_action = NSLocalizedString("Draft", comment: "Action")
    
    /// "ProtonMail encrypted emails"
    lazy var _general_enc_pm_emails = NSLocalizedString("ProtonMail encrypted emails", comment: "Title")
    /// "Encrypted from outside"
    lazy var _general_enc_from_outside = NSLocalizedString("Encrypted from outside", comment: "Title")
    /// "Encrypted for outside"
    lazy var _general_enc_for_outside = NSLocalizedString("Encrypted for outside", comment: "Title")
    /// "Send plain but stored enc"
    lazy var _general_send_plain_but_stored_enc = NSLocalizedString("Send plain but stored enc", comment: "Title")
    /// "Encrypted for outside reply"
    lazy var _general_encrypted_for_outside_reply = NSLocalizedString("Encrypted for outside reply", comment: "Title")
    /// "Encrypted from outside PGP inline"
    lazy var _general_enc_from_outside_pgp_inline = NSLocalizedString("Encrypted from outside PGP inline", comment: "Title")
    /// "Encrypted from outside PGP/MIME"
    lazy var _general_enc_from_outside_pgp_mime = NSLocalizedString("Encrypted from outside PGP/MIME", comment: "Title")
    /// "Encrypted from outside signed PGP/MIME"
    lazy var _general_enc_from_outside_signed_pgp_mime = NSLocalizedString("Encrypted from outside signed PGP/MIME", comment: "Title")
    /// "The request timed out."
    lazy var _general_request_timed_out = NSLocalizedString("The request timed out.", comment: "Title")
    /// "No connectivity detected..."
    lazy var _general_no_connectivity_detected = NSLocalizedString("No connectivity detected...", comment: "Title")
    /// "The ProtonMail current offline..."
    lazy var _general_pm_offline = NSLocalizedString("ProtonMail is currently offline...", comment: "Title")
    /// "Save"
    lazy var _general_save_action = NSLocalizedString("Save", comment: "Title")
    /// "Edit"
    lazy var _general_edit_action = NSLocalizedString("Edit", comment: "Action")
    /// "Create"
    lazy var _general_create_action = NSLocalizedString("Create", comment: "top right action text")
    
    lazy var _general_ignore_action = NSLocalizedString("Ignore", comment: "Alarm action")
    
    /// "iOS 10 update error title"
    lazy var _ios10_update_title = NSLocalizedString("OS compatibility", comment: "The title of the iOS 10 upgrate alert")
    /// "iOS 10 update error body"
    lazy var _ios10_update_body = NSLocalizedString("We will soon stop the support for iOS 10 devices. Please update your device's operating system to continue receiving updates in the future.", comment: "The body of the iOS 10 upgrate alert")


    /// Mark Error

    /// "Invalid UserName"
    lazy var _error_invalid_username = NSLocalizedString("Invalid UserName!", comment: "Error message")
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

    /// "ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail"
    lazy var _error_pm_is_offline = NSLocalizedString("ProtonMail is currently offline, check our twitter for the current status: https://twitter.com/protonmail", comment: "Description")

    /// "Sending Message"
    lazy var _messages_sending_message = NSLocalizedString("Sending Message", comment: "Description")

    /// "Message sending failed. Please try again."
    lazy var _messages_sending_failed_try_again = NSLocalizedString("Message sending failed. Please try again.", comment: "Description")

    /// "Importing Contacts"
    lazy var _contacts_import_title = NSLocalizedString("Importing Contacts", comment: "import contact title")

    /// "Reading contacts data from device..."
    lazy var _contacts_reading_contacts_data = NSLocalizedString("Reading device contacts data...", comment: "Title")

    /// "Contacts"
    lazy var _contacts_title = NSLocalizedString("Contacts", comment: "Action and title")

    /// "Do you want to cancel the process?"
    lazy var _contacts_import_cancel_wanring = NSLocalizedString("Do you want to cancel the process?", comment: "Description")

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

    /// "Email address"
    lazy var _contacts_email_address_placeholder = NSLocalizedString("Email address", comment: "contact placeholder")

    /// "Choose a Password"
    lazy var _signup_choose_password = NSLocalizedString("Choose a Password", comment: "place holder")

    /// "Back"
    lazy var _general_back_action = NSLocalizedString("Back", comment: "top left back button")

    /// "Set passwords"
    lazy var _signup_set_passwords_title = NSLocalizedString("Set passwords", comment: "Signup passwords top title")

    /// "Note: This is used to log you into your account."
    lazy var _signup_set_pwd_note_1 = NSLocalizedString("Note: This is used to log you into your account.", comment: "setup password notes")

    /// "Note: This is used to encrypt and decrypt your messages. Do not lose this password, we cannot recover it."
    lazy var _signup_set_pwd_note_2 = NSLocalizedString("Note: This is used to encrypt and decrypt your messages. Do not lose this password, we cannot recover it.", comment: "setup password notes")

    /// "Create Account"
    lazy var _signup_create_account_action = NSLocalizedString("Create Account", comment: "Create account button")

    /// "Login password doesn't match"
    lazy var _signup_pwd_doesnt_match = NSLocalizedString("Login password doesn't match", comment: "Error")

    /// "Human Check Warning"
    lazy var _signup_human_check_warning_title = NSLocalizedString("Human Check Warning", comment: "human check warning title")

    /// "Warning: Before you pass the human check you can't sent email!!!"
    lazy var _signup_human_check_warning = NSLocalizedString("Warning: Before you pass the human check you can't sent email!!!", comment: "human check warning description")

    /// "Check Again"
    lazy var _signup_check_again_action = NSLocalizedString("Check Again", comment: "Action")

    /// "Cancel Check"
    lazy var _signup_cancel_check_action = NSLocalizedString("Cancel Check", comment: "Action")

    /// "TouchID is not enrolled, enable it in the system Settings"
    lazy var _general_touchid_not_enrolled = NSLocalizedString("TouchID is not enrolled, enable it in the system Settings", comment: "settings touchid error")

    /// "A passcode hasn't been set. Please set one in the System Settings."
    lazy var _general_passcode_not_set = NSLocalizedString("A passcode has not been set, enable it in the system Settings", comment: "settings touchid error")

    /// "TouchID not available"
    lazy var _general_touchid_not_available = NSLocalizedString("TouchID not available", comment: "settings touchid/faceid error")

    /// "None"
    lazy var _general_none = NSLocalizedString("None", comment: "Title")

    /// "Every time the app is accessed"
    lazy var _settings_every_time_enter_app = NSLocalizedString("Every time enter app", comment: "lock app option")

    /// "Default"
    lazy var _general_default = NSLocalizedString("Default", comment: "Title")

    /// "Please use the web version of ProtonMail to change your passwords!"
    lazy var _general_use_web_reset_pwd = NSLocalizedString("Please use the web version of ProtonMail to change your passwords!", comment: "Alert")

    /// "Resetting message cache ..."
    lazy var _settings_resetting_cache = NSLocalizedString("Resetting message cache ...", comment: "Title")

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

    /// "Enter Verification Code"
    lazy var _enter_verification_code = NSLocalizedString("Enter Verification Code", comment: "Title")

    /// "Human Verification"
    lazy var _human_verification = NSLocalizedString("Human Verification", comment: "top title")

    /// "We will send a verification code to the email address above."
    lazy var _we_will_send_a_verification_code_to_the_email_address = NSLocalizedString("We will send a verification code to the email address above.", comment: "email field notes")
    /// "Enter your existing email address."
    lazy var _enter_your_existing_email_address = NSLocalizedString("Enter your existing email address.", comment: "top title")
    /// "Continue"
    lazy var _genernal_continue = NSLocalizedString("Continue", comment: "Action")
    /// "Continue and Don't ask again"
    lazy var _genernal_continue_and_dont_ask_again = NSLocalizedString("Continue and Don't ask again", comment: "Action")
    /// "Retry after %d seconds"
    lazy var _retry_after_seconds = NSLocalizedString("Retry after %d seconds", comment: "email verify code resend count down")
    /// "Send Verification Code"
    lazy var _send_verification_code = NSLocalizedString("Send Verification Code", comment: "Title")
    /// "Verification code request failed"
    lazy var _verification_code_request_failed = NSLocalizedString("Verification code request failed", comment: "Title")
    /// "Email address invalid"
    lazy var _email_address_invalid = NSLocalizedString("Email address invalid", comment: "Title")
    /// "Please input a valid email address."
    lazy var _please_input_a_valid_email_address = NSLocalizedString("Please input a valid email address.", comment: "error message")

    /// "Verification code sent"
    lazy var _verification_code_sent = NSLocalizedString("Verification code sent", comment: "Title")

    /// "Please check your email for the verification code."
    lazy var _please_check_email_for_code = NSLocalizedString("Please check your email for the verification code.", comment: "error message")

    /// "Create user failed"
    lazy var _create_user_failed = NSLocalizedString("Create user failed", comment: "error message title when create new user")

    /// "Default error, please try again."
    lazy var _default_error_please_try_again = NSLocalizedString("Default error. Please try again.", comment: "error message when create new user")

    /// "Enter your PIN to unlock your inbox."
    lazy var _enter_pin_to_unlock_inbox = NSLocalizedString("Enter your PIN to unlock your inbox.", comment: "Title")

    /// "attempt remaining until secure data wipe!"
    lazy var _attempt_remaining_until_secure_data_wipe = NSLocalizedString("attempt remaining until secure data wipe!", comment: "Error")

    /// "attempts remaining until secure data wipe!"
    lazy var _attempts_remaining_until_secure_data_wipe = NSLocalizedString("attempts remaining until secure data wipe!", comment: "Error")

    /// "Incorrect PIN,"
    lazy var _incorrect_pin = NSLocalizedString("Incorrect PIN,", comment: "Error")

    /// "attempts remaining"
    lazy var _attempts_remaining = NSLocalizedString("attempts remaining", comment: "Description")

    /// "Upload iOS contacts to ProtonMail?"
    lazy var _upload_ios_contacts_to_protonmail = NSLocalizedString("Upload iOS contacts to ProtonMail?", comment: "Description")

    /// "Delete Contact"
    lazy var _delete_contact = NSLocalizedString("Delete Contact", comment: "Title-Contacts")

    /// "Login"
    lazy var _general_login = NSLocalizedString("Login", comment: "Title")


    /// "Authentication was cancelled by the system"
    lazy var _authentication_was_cancelled_by_the_system = NSLocalizedString("Authentication was cancelled by the system", comment: "Description")

    /// "Authentication failed"
    lazy var _authentication_failed = NSLocalizedString("Authentication failed", comment: "Description")

    /// "PIN code is required."
    lazy var _pin_code_cant_be_empty = NSLocalizedString("Pin code can't be empty.", comment: "Description")

    /// "Enter your PIN"
    lazy var _enter_your_pin = NSLocalizedString("Enter your PIN", comment: "set pin title")

    /// "Re-Enter your PIN"
    lazy var _re_enter_your_pin = NSLocalizedString("Re-Enter your PIN", comment: "set pin title")




    /// "Key generation failed please try again"
    lazy var _key_generation_failed_please_try_again = NSLocalizedString("Key generation failed. Please try again.", comment: "Error")

    /// "Authentication failed please try to login again"
    lazy var _authentication_failed_pls_try_again = NSLocalizedString("Authentication failed. Please try to login again.", comment: "Error")

    /// "Unknown Error"
    lazy var _unknown_error = NSLocalizedString("Unknown Error", comment: "Error")

    /// "Fetching user’s data failed."
    lazy var _fetch_user_info_failed = NSLocalizedString("Fetch user info failed", comment: "Error")

    /// "Decrypt token failed please try again"
    lazy var _decrypt_token_failed_please_try_again = NSLocalizedString("Decrypt token failed. Please try again.", comment: "Description")

    /// "Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation."
    lazy var _account_creation_has_been_disabled_pls_go_to_https = NSLocalizedString("Instant ProtonMail account creation has been temporarily disabled. Please go to https://protonmail.com/invite to request an invitation.", comment: "Error")

    /// "Create User failed please try again"
    lazy var _create_user_failed_please_try_again = NSLocalizedString("Create User failed. Please try again.", comment: "Error")

    /// "Key invalid please go back try again"
    lazy var _key_invalid_please_go_back_try_again = NSLocalizedString("Key invalid. Please go back and try again.", comment: "Error")

    /// "Load remote content"
    lazy var _load_remote_content = NSLocalizedString("Load remote content", comment: "Action")

    /// "PASSWORD"
    lazy var _password = NSLocalizedString("Password", comment: "title")

    /// "Change Login Password"
    lazy var _change_login_password = NSLocalizedString("Change Login Password", comment: "change password input label")

    /// "Current login password"
    lazy var _current_login_password = NSLocalizedString("Current login password", comment: "Title")

    /// "New login password"
    lazy var _new_login_password = NSLocalizedString("New login password", comment: "Title")

    /// "Confirm new login password"
    lazy var _confirm_new_login_password = NSLocalizedString("Confirm new login password", comment: "Title")

    /// "Change Mailbox Password"
    lazy var _change_mailbox_password = NSLocalizedString("Change Mailbox Password", comment: "Title")

    /// "New mailbox password"
    lazy var _new_mailbox_password = NSLocalizedString("New mailbox password", comment: "Title")

    /// "Confirm new mailbox password"
    lazy var _confirm_new_mailbox_password = NSLocalizedString("Confirm new mailbox password", comment: "Title")

    /// "Change Single Password"
    lazy var _change_single_password = NSLocalizedString("Change Single Password", comment: "Title")

    /// "Unable to send the email"
    lazy var unable_to_send_the_email = NSLocalizedString("Unable to send the email", comment: "error when sending the message")

    /// "The draft format incorrectly sending failed!"
    lazy var _the_draft_incorrectly_sending_failed = NSLocalizedString("The draft format incorrectly sending failed!", comment: "error when sending the message")

    /// "Star"
    lazy var _star = NSLocalizedString("Star", comment: "Title")

    /// "ProtonMail"
    lazy var _protonmail = NSLocalizedString("ProtonMail", comment: "Title")

    /// "Remind Me Later"
    lazy var _remind_me_later = NSLocalizedString("Remind Me Later", comment: "Title")

    /// "Don't Show Again"
    lazy var _dont_show_again = NSLocalizedString("Don't Show Again", comment: "Title")

    /// "close tour"
    lazy var _close_tour = NSLocalizedString("close tour", comment: "Action")

    /// "Support ProtonMail"
    lazy var _support_protonmail = NSLocalizedString("Support ProtonMail", comment: "Action")


    // Mark : Onboarding

    /// "Your new encrypted email account has been set up and is ready to send and receive encrypted messages."
    lazy var _your_new_account_is_ready_to_send_and_receive_encrypted_messages = NSLocalizedString("Your new encrypted email account has been set up and is ready to send and receive encrypted messages.", comment: "Description")
    /// "You can customize swipe gestures in the ProtonMail App Settings."
    lazy var _you_can_customize_swipe_in_app_settings = NSLocalizedString("You can customize swipe gestures in the ProtonMail App Settings.", comment: "Description")
    /// "Create and add Labels to organize your inbox. Long press on a message for all options."
    lazy var _create_and_add_labels_to_organize_inbox_and_hold_down_on_a_message_for_all_options = NSLocalizedString("Create and add Labels to organize your inbox. Long press on a message for all options.", comment: "Description")
    /// "Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail."
    lazy var _your_inbox_is_now_protected_with_e2e_you_can_also_do_eo = NSLocalizedString("Your inbox is now protected with end-to-end encryption. To automatically securely email friends, have them get ProtonMail! You can also manually encrypt messages to them if they don't use ProtonMail.", comment: "Description")
    /// "Messages you send can be set to auto delete after a certain time period."
    lazy var _messages_you_send_can_be_set_to_auto_delete_after_a_certain_time_period = NSLocalizedString("Messages you send can be set to auto delete after a certain time period.", comment: "Description")
    /// "You can get help and support at protonmail.com/support. Bugs can also be reported with the app."
    lazy var _you_can_get_help_and_support_at_protonmail_support_and_bugs = NSLocalizedString("You can get help and support at protonmail.com/support. Bugs can also be reported with the app.", comment: "Description")
    /// "ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail."
    lazy var _protonmail_doesnt_sell_ads_or_abuse_your_privacy = NSLocalizedString("ProtonMail doesn't sell ads or abuse your privacy. Your support is essential to keeping ProtonMail running. You can upgrade to a paid account or donate to support ProtonMail.", comment: "Description")
    /// "Welcome to ProtonMail!"
    lazy var _welcome_to_protonmail = NSLocalizedString("Welcome to ProtonMail!", comment: "Title")
    /// "Quick swipe actions"
    lazy var _quick_swipe_actions = NSLocalizedString("Quick swipe actions", comment: "Title")
    /// "Label Management"
    lazy var _label_management = NSLocalizedString("Label Management", comment: "Title")
    /// "End-to-End Encryption"
    lazy var _end_to_end_encryption = NSLocalizedString("End-to-End Encryption", comment: "Title")
    /// "Expiring Messages"
    lazy var _expiring_messages = NSLocalizedString("Expiring Messages", comment: "Title")
    /// "Help & Support"
    lazy var _help_and_support = NSLocalizedString("Help & Support", comment: "Title")


    /// "Invalid credential"
    lazy var _invalid_credential = NSLocalizedString("Invalid credential", comment: "Error")

    /// "The authentication credentials are invalid."
    lazy var _the_authentication_credentials_are_invalid = NSLocalizedString("The authentication credentials are invalid.", comment: "Description")

    /// "Authentication Failed Wrong username or password"
    lazy var _authentication_failed_wrong_username_or_password = NSLocalizedString("Authentication Failed Wrong username or password", comment: "Description")

    /// "Unable to connect to the server"
    lazy var _unable_to_connect_to_the_server = NSLocalizedString("Unable to connect to the server", comment: "Description")
    
    /// "Unable to edit this message offline"
    lazy var _unable_to_edit_offline = NSLocalizedString("Unable to edit this message offline", comment: "Description")

    /// "Unable to parse token"
    lazy var _unable_to_parse_token = NSLocalizedString("Unable to parse token", comment: "Error")
    
    /// "Unable to parse token"
    lazy var _app_is_locked = NSLocalizedString("App is locked", comment: "Error")

    /// "Unable to parse authentication token!"
    lazy var _unable_to_parse_authentication_token = NSLocalizedString("Unable to parse authentication token!", comment: "Description")

    /// "Unable to parse authentication info!"
    lazy var _unable_to_parse_authentication_info = NSLocalizedString("Unable to parse authentication info!", comment: "Description")

    /// "Invalid Password"
    lazy var _invalid_password = NSLocalizedString("Invalid Password", comment: "Error")

    /// "Unable to generate hashed password!"
    lazy var _unable_to_generate_hash_password = NSLocalizedString("Unable to generate hashed password!", comment: "Description")

    /// "SRP Client"
    lazy var _srp_client = NSLocalizedString("SRP Client", comment: "Error")

    /// "Unable to create SRP Client!"
    lazy var _unable_to_create_srp_client = NSLocalizedString("Unable to create SRP Client!", comment: "Description")

    /// "SRP Server"
    lazy var _srp_server = NSLocalizedString("SRP Server", comment: "Error")

    /// "Server proofs not valid!"
    lazy var _server_proofs_not_valid = NSLocalizedString("Server proofs not valid!", comment: "Description")

    /// "Srp single password keyslat invalid!"
    lazy var _srp_single_password_keyslat_invalid = NSLocalizedString("Srp single password keyslat invalid!", comment: "Description")

    /// "Unable to parse cached authentication token!"
    lazy var _unable_to_parse_cased_authentication_token = NSLocalizedString("Unable to parse cached authentication token!", comment: "Description")
    
    /// "Authentication token is not accessible because the app is locked"
    lazy var _authentication_token_is_locked = NSLocalizedString("Authentication token is not accessible because the app is locked", comment: "Description")

    /// "Bad auth cache"
    lazy var _bad_auth_cache = NSLocalizedString("Bad auth cache", comment: "Error")

    /// "Local cache can't find mailbox password"
    lazy var _local_cache_cant_find_mailbox_password = NSLocalizedString("Local cache can't find mailbox password", comment: "Description")

    /// "Date: %@"
    lazy var _date = NSLocalizedString("Date: %@", comment: "like Date: 2017-10-10")

    /// "Details"
    lazy var _details = NSLocalizedString("Details", comment: "Title")

    /// "Hide Details"
    lazy var _hide_details = NSLocalizedString("Hide Details", comment: "Title")

    /// "Phone number"
    lazy var _phone_number = NSLocalizedString("Phone number", comment: "contact placeholder")

    /// "Username"
    lazy var _username = NSLocalizedString("Username", comment: "Title")




    /// "Create a new account"
    lazy var _create_a_new_account = NSLocalizedString("Create a new account", comment: "Signup top title")

    /// "Note: The Username is also your ProtonMail address."
    lazy var _notes_the_username_is_also_your_protonmail_address = NSLocalizedString("Note: The Username is also your ProtonMail address.", comment: "Signup user name notes")
    
    /// "By using ProtonMail, you agree to our (terms and conditions) and (privacy policy)."  -- for later
    lazy var _by_using_protonmail_you_agree_terms_ = NSLocalizedString("By using protonmail, you agree to our %@ and %@.", comment: "")

    /// "By using ProtonMail, you agree to our"
    lazy var _notes_by_using_protonmail_you_agree_to_our = NSLocalizedString("By using protonmail, you agree to our", comment: "agree check box first part words")

    /// "Terms and Conditions"
    lazy var _notes_terms_and_conditions = NSLocalizedString("terms and conditions", comment: "agree check box terms")

    /// "and"
    lazy var _and = NSLocalizedString("and", comment: "agree check box middle word")

    /// "Privacy Policy."
    lazy var _privacy_policy = NSLocalizedString("privacy policy.", comment: "agree check box privacy")

    /// "Checking ...."
    lazy var _checking_ = NSLocalizedString("Checking ....", comment: "loading message")

    /// "User is available!"
    lazy var _user_is_available = NSLocalizedString("User is available!", comment: "")
    
    /// "User already exist!"
    lazy var _user_already_exist = NSLocalizedString("User already exist!", comment: "error when user already exist")

    /// "Please pick a user name first!"
    lazy var _please_pick_a_user_name_first = NSLocalizedString("Please pick a user name first!", comment: "Error")

    /// "In order to use our services, you must agree to ProtonMail's Terms of Service."
    lazy var _in_order_to_use_our_services_you_must_agree_to_protonmails_terms_of_service = NSLocalizedString("In order to use our services, you must agree to ProtonMail's Terms of Service.", comment: "Error")

    /// "Update Contact"
    lazy var _update_contact = NSLocalizedString("Update Contact", comment: "Contacts Update contact")

    /// "Do you want to save the unsaved changes?"
    lazy var _do_you_want_to_save_the_unsaved_changes = NSLocalizedString("Do you want to save the unsaved changes?", comment: "Title")

    /// "Discard changes"
    lazy var _discard_changes = NSLocalizedString("Discard changes", comment: "Action")

    /// "Add new url"
    lazy var _add_new_url = NSLocalizedString("Add new URL", comment: "action")

    /// "Message Queue"
    lazy var _message_queue = NSLocalizedString("Message Queue", comment: "settings debug section title")
    /// "Error Logs"
    lazy var _error_logs = NSLocalizedString("Error Logs", comment: "settings debug section title")

    /// "Login Password"
    lazy var _login_password = NSLocalizedString("Login Password", comment: "settings general section title")
    /// "Mailbox Password"
    lazy var _mailbox_password = NSLocalizedString("Mailbox Password", comment: "settings general section title")
    /// "Single Password"
    lazy var _single_password = NSLocalizedString("Single Password", comment: "settings general section title")
    /// "Clear Local Message Cache"
    lazy var _clear_local_message_cache = NSLocalizedString("Clear Local Message Cache", comment: "settings general section title")
    /// "Auto Show Images"
    lazy var _auto_show_images = NSLocalizedString("Auto Show Images", comment: "settings general section title")
    /// "Swipe Left to Right"
    lazy var _swipe_left_to_right = NSLocalizedString("Swipe Left to Right", comment: "settings swipe actions section title")
    /// "Swipe Right to Left"
    lazy var _swipe_right_to_left = NSLocalizedString("Swipe Right to Left", comment: "settings swipe actions section title")
    /// "Change left swipe action"
    lazy var _change_left_swipe_action = NSLocalizedString("Change left swipe action", comment: "settings swipe actions section action description")
    /// "Change right swipe action"
    lazy var _change_right_swipe_action = NSLocalizedString("Change right swipe action", comment: "settings swipe actions section action description")
    /// "Enable TouchID"
    lazy var _enable_touchid = NSLocalizedString("Enable TouchID", comment: "settings protection section title")
    /// "Enable Pin Protection"
    lazy var _enable_pin_protection = NSLocalizedString("Enable Pin Protection", comment: "settings protection section title")
    /// "Change Pin"
    lazy var _change_pin = NSLocalizedString("Change Pin", comment: "settings protection section title")
    /// "Entire App Protection"
    lazy var _protection_entire_app = NSLocalizedString("Protection Entire App", comment: "settings protection section title")
    /// "Enable FaceID"
    lazy var _enable_faceid = NSLocalizedString("Enable FaceID", comment: "settings protection section title")
    
    lazy var _unlock_required = NSLocalizedString("Unlock required", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")
    
    lazy var _enable_faceid_in_settings = NSLocalizedString("You disabled FaceID in your system settings. FaceID has been used to protect important account information. To access your account, go to settings and reactivate FaceID, or log back in.", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")
    
    lazy var _lock_faceID_desc = NSLocalizedString("Turn this feature on to auto-lock your app and use a PIN code or FaceID to unlock it.", comment: "A description string in pin & faceID setting page")
    
    lazy var _lock_touchID_desc = NSLocalizedString("Turn this feature on to auto-lock your app and use a PIN code or fingerprint to unlock it.", comment: "A description string in pin & faceID setting page")
    
    lazy var _lock_wipe_desc = NSLocalizedString("All protection settings will be reset and wiped upon logging out of the app.", comment: "A description string in pin & faceID setting page")

    lazy var _go_to_settings = NSLocalizedString("Go to settings", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")
    
    lazy var _go_to_login = NSLocalizedString("Go to login", comment: "Alert when user enabled FaceID in app settings but restricted the use of FaceID in device settings")

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
    /// "Labels/Folders"
    lazy var _labels_folders = NSLocalizedString("Labels/Folders", comment: "Title")


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
    lazy var _space_all_used_warning = NSLocalizedString("You have used up all of your storage space (%@).", comment: "Content of space warning")
    lazy var _space_partial_used_warning = NSLocalizedString("You have used %d%% of your storage space (%@).", comment: "Content of space warning")

    /// "Warning"
    lazy var _warning = NSLocalizedString("Warning", comment: "Title")
    
    /// "Hide"
    lazy var _hide = NSLocalizedString("Hide", comment: "Action")

    /// "Change Password"
    lazy var _change_password = NSLocalizedString("Change Password", comment: "update password error title")

    /// "Can't get a Moduls ID!"
    lazy var _cant_get_a_moduls_id = NSLocalizedString("Can't get a Moduls ID!", comment: "update password error = typo:Modulus")

    /// "Can't get a Moduls!"
    lazy var _cant_get_a_moduls = NSLocalizedString("Can't get a Moduls!", comment: "update password error = typo:Modulus")

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

    /// "Unable to get contacts"
    lazy var _unable_to_get_contacts = NSLocalizedString("Unable to get contacts", comment: "Error")

    /// "Apply Labels"
    lazy var _apply_labels = NSLocalizedString("Apply Labels", comment: "Title")

    /// "Can't download message body, please try again."
    lazy var _cant_download_message_body_please_try_again = NSLocalizedString("Can't download message body. Please try again.", comment: "Error")

    /// "Print"
    lazy var _print = NSLocalizedString("Print", comment: "Action")

    /// "Report Phishing"
    lazy var _report_phishing = NSLocalizedString("Report Phishing", comment: "message details-> more action-> report phishing")

    /// "View headers"
    lazy var _view_message_headers = NSLocalizedString("View Headers", comment: "message details-> more action-> view headers")
    
    /// "View HTML"
    lazy var _view_message_html_body = NSLocalizedString("View HTML", comment: "message details-> more action-> view raw html of message body")

    /// "Confirm phishing report"
    lazy var _confirm_phishing_report = NSLocalizedString("Confirm phishing report", comment: "alert title")

    /// "Reporting a message as a phishing attempt will send the message to us, so we can analyze it and improve our filters. This means that we will be able to see the contents of the message in full."
    lazy var _reporting_a_message_as_a_phishing_ = NSLocalizedString("Reporting a message as a phishing attempt will send the message to us, so we can analyze it and improve our filters. This means that we will be able to see the contents of the message in full.", comment: "alert message")

    /// "Unable to decrypt message."
    lazy var _unable_to_decrypt_message = NSLocalizedString("Unable to decrypt message.", comment: "Error")

    /// "Loading..."
    lazy var _loading_ = NSLocalizedString("Loading...", comment: "")

    /// "Please wait until the email downloaded!"
    lazy var _please_wait_until_the_email_downloaded = NSLocalizedString("Please wait until the email downloaded!", comment: "The")

    /// "Can't decrypt this attachment!"
    lazy var _cant_decrypt_this_attachment = NSLocalizedString("Can't decrypt this attachment!", comment: "When quick look attachment but can't decrypt it!")

    /// "Can't find this attachment!"
    lazy var _cant_find_this_attachment = NSLocalizedString("Can't find this attachment!", comment: "when quick look attachment but can't find the data")

    /// "Encryption Setup"
    lazy var _encryption_setup = NSLocalizedString("Encryption Setup", comment: "key setup top title")

    /// "High Security"
    lazy var _high_security = NSLocalizedString("High Security", comment: "Key size checkbox")

    /// "Extreme Security"
    lazy var _extreme_security = NSLocalizedString("Extreme Security", comment: "Key size checkbox")

    /// "The current standard"
    lazy var _the_current_standard = NSLocalizedString("The current standard", comment: "key size notes")

    /// "The highest level of encryption available."
    lazy var _the_highest_level_of_encryption_available = NSLocalizedString("The highest level of encryption available.", comment: "key size note part 1")

    /// "Can take several minutes to setup."
    lazy var _can_take_several_minutes_to_setup = NSLocalizedString("Can take several minutes to setup.", comment: "key size note part 2")



    /// "Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer."
    lazy var _mobile_signups_are_disabled_pls_later_pm_com = NSLocalizedString("Mobile signups are temporarily disabled. Please try again later, or try signing up at protonmail.com using a desktop or laptop computer.", comment: "Description")

    /// "Key generation failed"
    lazy var _key_generation_failed = NSLocalizedString("Key generation failed", comment: "Error")

    /// "Your Country Code"
    lazy var _your_country_code = NSLocalizedString("Your Country Code", comment: "view top title")

    /// "DECRYPT MAILBOX"
    lazy var _decrypt_mailbox = NSLocalizedString("DECRYPT MAILBOX", comment: "Title")

    /// "Decrypt"
    lazy var _decrypt = NSLocalizedString("Decrypt", comment: "Action")

    /// "RESET MAILBOX PASSWORD"
    lazy var _reset_mailbox_password = NSLocalizedString("RESET MAILBOX PASSWORD", comment: "Action")

    /// "The mailbox password is incorrect."
    lazy var _the_mailbox_password_is_incorrect = NSLocalizedString("The mailbox password is incorrect.", comment: "Error")

    /// "Incorrect password"
    lazy var _incorrect_password = NSLocalizedString("Incorrect password", comment: "Title")


    /// "To reset your mailbox password, please use the web version of ProtonMail at protonmail.com"
    lazy var _to_reset_your_mailbox_password_please_use_the_web_version_of_protonmail = NSLocalizedString("To reset your mailbox password, please use the web version of ProtonMail at protonmail.com", comment: "Description")

    /// "Recovery Email"
    lazy var _recovery_email = NSLocalizedString("Recovery Email", comment: "Title")
    /// "Congratulations!"
    lazy var _congratulations = NSLocalizedString("Congratulations!", comment: "view top title")

    /// "Your new secure email\r\n account is ready."
    lazy var _your_new_secure_email_account_is_ready = NSLocalizedString("Your new secure email\r\n account is ready.", comment: "view top title")

    /// "When you send an email, this is the name that appears in the sender field."
    lazy var _send_an_email_this_name_that_appears_in_sender_field = NSLocalizedString("When you send an email, this is the name that appears in the sender field.", comment: "display name notes")

    /// "The optional recovery email address allows you to reset your login password if you forget it."
    lazy var _the_optional_recovery_email_address_allows_you_to_reset_your_login_password_if_you_forget_it = NSLocalizedString("The optional recovery email address allows you to reset your login password if you forget it.", comment: "recovery email notes")

    /// "Keep me updated about new features"
    lazy var _keep_me_updated_about_new_features = NSLocalizedString("Keep me updated about new features", comment: "Title")

    /// "Go to inbox"
    lazy var _go_to_inbox = NSLocalizedString("Go to inbox", comment: "Action")

    /// "Recovery Email Warning"
    lazy var _recovery_email_warning = NSLocalizedString("Recovery Email Warning", comment: "Title")

    /// "Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?"
    lazy var _warning_did_not_set_a_recovery_email_so_account_recovery_is_impossible = NSLocalizedString("Warning: You did not set a recovery email so account recovery is impossible if you forget your password. Proceed without recovery email?", comment: "Description")

    /// "To prevent abuse of ProtonMail,\r\n we need to verify that you are human."
    lazy var _to_prevent_abuse_of_protonmail_we_need_to_verify_that_you_are_human = NSLocalizedString("To prevent abuse of ProtonMail,\r\n we need to verify that you are human.", comment: "human verification notes")

    /// "Please select one of the following options:"
    lazy var _please_select_one_of_the_following_options = NSLocalizedString("Please select one of the following options:", comment: "human check select option title")

    /// "CAPTCHA"
    lazy var _captcha = NSLocalizedString("CAPTCHA", comment: "human check option button")

    /// "Email Verification"
    lazy var _email_verification = NSLocalizedString("Email Verification", comment: "human check option button")

    /// "Phone Verification"
    lazy var _phone_verification = NSLocalizedString("Phone Verification", comment: "human check option button")

    /// "Verification error"
    lazy var _verification_error = NSLocalizedString("Verification error", comment: "error title")

    /// "Verification of this content’s signature failed"
    lazy var _verification_of_this_contents_signature_failed = NSLocalizedString("Verification of this content’s signature failed", comment: "error details")

    /// "Decryption error"
    lazy var _decryption_error = NSLocalizedString("Decryption error", comment: "error title")

    /// "Decryption of this content failed"
    lazy var _decryption_of_this_content_failed = NSLocalizedString("Decryption of this content failed", comment: "error details")

    /// "Logs"
    lazy var _logs = NSLocalizedString("Logs", comment: "error title")

    /// "normal attachments"
    lazy var _normal_attachments = NSLocalizedString("normal attachments", comment: "Title")

    /// "in-line attachments"
    lazy var _inline_attachments = NSLocalizedString("inline attachments", comment: "Title")

    /// "Photo Library"
    lazy var _photo_library = NSLocalizedString("Photo Library", comment: "Title")

    /// "Take a Photo"
    lazy var _take_a_photo = NSLocalizedString("Take a Photo", comment: "Title")

    /// "Import File From..."
    lazy var _import_file_from_ = NSLocalizedString("Import File From...", comment: "Title")

    /// "The total attachment size cannot exceed 25MB"
    lazy var _the_total_attachment_size_cant_be_bigger_than_25mb = NSLocalizedString("The total attachment size cannot exceed 25MB", comment: "Description")

    /// "Can't load the file"
    lazy var _cant_load_the_file = NSLocalizedString("Can't load the file", comment: "Error")

    /// "Can't copy the file"
    lazy var _system_cant_copy_the_file = NSLocalizedString("System can't copy the file", comment: "Error")
    
    /// "Can't open the file"
    lazy var _cant_open_the_file = NSLocalizedString("Can't open the file", comment: "Error")


    /// "Cell phone number"
    lazy var _cell_phone_number = NSLocalizedString("Cell phone number", comment: "place holder")

    /// "Enter your cell phone number"
    lazy var _enter_your_cell_phone_number = NSLocalizedString("Enter your cell phone number", comment: "human verification top title")

    /// "We will send a verification code to the cell phone above."
    lazy var _we_will_send_a_verification_code_to_the_cell_phone_above = NSLocalizedString("We will send a verification code to the cell phone above.", comment: "text field notes")

    /// "Phone number invalid"
    lazy var _phone_number_invalid = NSLocalizedString("Phone number invalid", comment: "Title")

    /// "Please input a valid cell phone number."
    lazy var _please_input_a_valid_cell_phone_number = NSLocalizedString("Please input a valid cell phone number.", comment: "Description")

    /// "Please check your cell phone for the verification code."
    lazy var _please_check_your_cell_phone_for_the_verification_code = NSLocalizedString("Please check your cell phone for the verification code.", comment: "Description")

    lazy var _learn_more = NSLocalizedString("Learn More", comment: "Action")
    lazy var _not_now = NSLocalizedString("Not Now", comment: "Action")
    lazy var _view_plans = NSLocalizedString("View Plans", comment: "Action")

    /// "PREMIUM FEATURE"
    lazy var _premium_feature = NSLocalizedString("PREMIUM FEATURE", comment: "Upgrade warning title")

    /// "Looking to secure your contact's details?"
    lazy var _looking_to_secure_your_contacts_details = NSLocalizedString("Looking to secure your contact's details?", comment: "Upgrade warning title")

    /// "ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email."
    lazy var _protonmail_plus_enables_you_to_add_and_edit_contact_details_beyond_ = NSLocalizedString("ProtonMail Plus/Professional/Visionary enables you to add and edit contact details beyond just your contact’s name and email. By using ProtonMail, this data will be as secure as your end-to-end encrypted email.", comment: "Upgrade warning message")

    /// "The verification failed!"
    lazy var _the_verification_failed = NSLocalizedString("The verification failed!", comment: "Error")

    /// "Retry"
    lazy var _retry = NSLocalizedString("Retry", comment: "Action")

    /// "Unknow Error"
    lazy var _unknow_error = NSLocalizedString("Unknow Error", comment: "Description")


    /// "Message expired"
    lazy var _message_expired = NSLocalizedString("Message expired", comment: "")

    /// "Expires in %d days %d hours %d mins %d seconds"
    lazy var _expires_in_days_hours_mins_seconds = NSLocalizedString("Expires in %d days %d hours %d mins %d seconds", comment: "expiration time count down")

    /// "Sign Out"
    lazy var _sign_out = NSLocalizedString("Sign Out", comment: "Action")
    
    
    /// "Log  Out all"
    lazy var _sign_out_all = NSLocalizedString("Log Out All", comment: "Action")

    /// "Rate & Review"
    lazy var _rate_review = NSLocalizedString("Rate & Review", comment: "Title")

    /// "Tweet about ProtonMail"
    lazy var _tweet_about_protonmail = NSLocalizedString("Tweet about ProtonMail", comment: "Title")

    /// "Share it with your friends"
    lazy var _share_it_with_your_friends = NSLocalizedString("Share it with your friends", comment: "Title")

    /// "Contact the ProtonMail team"
    lazy var _contact_the_protonmail_team = NSLocalizedString("Contact the ProtonMail team", comment: "Title")

    /// "Trouble shooting guide"
    lazy var _trouble_shooting_guide = NSLocalizedString("Trouble shooting guide", comment: "Title")

    /// "Help us to make privacy the default on the web."
    lazy var _help_us_to_make_privacy_the_default_in_the_web = NSLocalizedString("Help us to make privacy the default in the web.", comment: "Title")

    /// "Help us to improve ProtonMail with your input."
    lazy var _help_us_to_improve_protonmail_with_your_input = NSLocalizedString("Help us to improve ProtonMail with your input.", comment: "Title")

    /// "We would like to know what we can do better."
    lazy var _we_would_like_to_know_what_we_can_do_better = NSLocalizedString("We would like to know what we can do better.", comment: "Title")


    /// "USER LOGIN"
    lazy var _user_login = NSLocalizedString("USER LOGIN", comment: "Title")

    /// "NEED AN ACCOUNT? SIGN UP."
    lazy var _need_an_account_sign_up = NSLocalizedString("NEED AN ACCOUNT? SIGN UP.", comment: "Action")

    /// "FORGOT PASSWORD?"
    lazy var _forgot_password = NSLocalizedString("FORGOT PASSWORD?", comment: "login page forgot pwd")
    
    /// "Create new account"
    lazy var _create_new_account = NSLocalizedString("Create new account", comment: "title of button in account connect page")

    // "Sending Message"
    lazy var _sending_message = NSLocalizedString("Sending message", comment: "Alert title")

    // "Closing"
    lazy var _closing_draft = NSLocalizedString("Closing", comment: "the message will show when closing a draft from the share extension")

    // "This can take a while, please do not dismiss the app"
    lazy var _please_wait_in_foreground = NSLocalizedString("This can take a while. Please do not dismiss the app.", comment: "Alert message")


    /// "Please use the web application to reset your password."
    lazy var _please_use_the_web_application_to_reset_your_password = NSLocalizedString("Please use the web application to reset your password.", comment: "Alert")

    /// "Bug Description"
    lazy var _bug_description = NSLocalizedString("Bug Description", comment: "Title")

    /// "Bug Report Received"
    lazy var _bug_report_received = NSLocalizedString("Bug Report Received", comment: "Title")

    /// "Thank you for submitting a bug report.  We have added your report to our bug tracking system."
    lazy var _thank_you_for_submitting_a_bug_report_we_have_added_your_report_to_our_bug_tracking_system = NSLocalizedString("Thank you for submitting a bug report.  We have added your report to our bug tracking system.", comment: "")

    /// "Label as..."
    lazy var _label_as_ = NSLocalizedString("Label as...", comment: "Title")

    /// "Move to..."
    lazy var _move_to_ = NSLocalizedString("Move to...", comment: "Title")

    /// "Mark as unread"
    lazy var _mark_as_unread = NSLocalizedString("Mark as unread", comment: "Action")
    lazy var _mark_as_unread_short = NSLocalizedString("Unread", comment: "The verb for describing the unread action")

    /// "Display Name Updated"
    lazy var _display_name_updated = NSLocalizedString("Display Name Updated", comment: "Title")

    /// "The display name is now %@."
    lazy var _the_display_name_is_now = NSLocalizedString("The display name is now %@.", comment: "Description")

    /// "Signature Updated"
    lazy var _signature_updated = NSLocalizedString("Signature Updated", comment: "Title")

    /// "Your signature has been updated."
    lazy var _your_signature_has_been_updated = NSLocalizedString("Your signature has been updated.", comment: "Description")

    /// "Password Mismatch"
    lazy var _password_mismatch = NSLocalizedString("Password Mismatch", comment: "Title")

    /// "The password you entered does not match the current password."
    lazy var _the_password_you_entered_does_not_match_the_current_password = NSLocalizedString("The password you entered does not match the current password.", comment: "Description")

    /// "Password Updated"
    lazy var _password_updated = NSLocalizedString("Password Updated", comment: "Title")

    /// "Please use your new password when signing in."
    lazy var _please_use_your_new_password_when_signing_in = NSLocalizedString("Please use your new password when signing in.", comment: "Description")

    /// "The passwords you entered do not match."
    lazy var _the_passwords_you_entered_do_not_match = NSLocalizedString("The passwords you entered do not match.", comment: "Description")

    /// "Can't load share content!"
    lazy var _cant_load_share_content = NSLocalizedString("Can't load share content!", comment: "This is a generic error when the user uses share feature. It is like when you share files from Dropbox but cant read the file correctly")

    /// "Share Alert"
    lazy var _share_alert = NSLocalizedString("Share Alert", comment: "Title")

    /// "Failed to determine type of file"
    lazy var _failed_to_determine_file_type = NSLocalizedString("Failed to determine type of file", comment: "Error message")

    /// "Unsupported file type"
    lazy var _unsupported_file = NSLocalizedString("Unsupported file type", comment: "Error message")

    /// "Please use ProtonMail App login first"
    lazy var _please_use_protonmail_app_login_first = NSLocalizedString("Please use ProtonMail App login first.", comment: "Description")

    /// "Can't copy the file"
    lazy var _cant_copy_the_file = NSLocalizedString("Can't copy the file", comment: "Error")

    /// "Copy address"
    lazy var _copy_address    = NSLocalizedString("Copy address", comment: "Title")
    /// "Copy name"
    lazy var _copy_name       = NSLocalizedString("Copy name", comment: "Title")
    /// "Compose to"
    lazy var _compose_to      = NSLocalizedString("Compose to", comment: "Title")
    /// "Add to contacts"
    lazy var _add_to_contacts = NSLocalizedString("Add to contacts", comment: "Title")


    ///"End-to-end encrypted"
    lazy var _end_to_end_encrypted = NSLocalizedString("End-to-end encrypted", comment: "encryption lock description")
    /// "PGP-encrypted"
    lazy var _pgp_encrypted = NSLocalizedString("PGP-encrypted", comment: "encryption lock description")
    /// "PGP-signed"
    lazy var _pgp_signed = NSLocalizedString("PGP-signed", comment: "encryption lock description")
    /// "End-to-end encrypted to verified address"
    lazy var _end_to_end_encrypted_to_verified_address = NSLocalizedString("End-to-end encrypted to verified address", comment: "encryption lock description")
    /// "Stored with zero access encryption"
    lazy var _stored_with_zero_access_encryption = NSLocalizedString("Stored with zero access encryption", comment: "encryption lock description")
    /// "Sent by you with end-to-end encryption"
    lazy var _sent_by_you_with_end_to_end_encryption = NSLocalizedString("Sent by you with end-to-end encryption", comment: "encryption lock description")
    /// "Sent by ProtonMail with zero access encryption"
    lazy var _sent_by_protonMail_with_zero_access_encryption  = NSLocalizedString("Sent by ProtonMail with zero access encryption", comment: "encryption lock description for auto reply")
    /// "PGP-encrypted message"
    lazy var _pgp_encrypted_message = NSLocalizedString("PGP-encrypted message", comment: "encryption lock description")
    /// "PGP-encrypted message from verified address"
    lazy var _pgp_encrypted_message_from_verified_address = NSLocalizedString("PGP-encrypted message from verified address", comment: "encryption lock description")
    /// "PGP-signed message from verified address"
    lazy var _pgp_signed_message_from_verified_address = NSLocalizedString("PGP-signed message from verified address", comment: "encryption lock description")
    /// "Sender Verification Failed"
    lazy var _sender_verification_failed = NSLocalizedString("Sender Verification Failed", comment: "encryption lock description")
    /// "End-to-end encrypted message"
    lazy var _end_to_end_encrypted_message = NSLocalizedString("End-to-end encrypted message", comment: "encryption lock description")
    /// "End-to-end encrypted message from verified address"
    lazy var _end_to_end_encrypted_message_from_verified_address = NSLocalizedString("End-to-end encrypted message from verified address", comment: "encryption lock description")

    /// "Edit mobile signature"
    lazy var _edit_mobile_signature = NSLocalizedString("Edit mobile signature", comment: "title")
    /// "Edit signature"
    lazy var _edit_signature = NSLocalizedString("Edit signature", comment: "title")
    
    // "A paid ProtonMail plan is required to use this feature"
    lazy var _a_paid_rotonMail_plan_is_required_to_use_this_feature = NSLocalizedString("A paid ProtonMail plan is required to use this feature", comment: "alert description")
    // "Upgrade to get all paid features."
    lazy var _upgrade_to_get_all_paid_features = NSLocalizedString("Upgrade to get all paid features.", comment: "alert description")



    // MARK: - Composer expiration warning

    ///"Tap Send anyway to send without expiration to these recipients"
    lazy var _tap_send_anyway_to_send_without_expiration_to_these_recipients = NSLocalizedString("Tap send anyway to send without expiration to these recipients", comment: "alert description")
    /// "Learn more here"
    lazy var _learn_more_here = NSLocalizedString("Learn more here", comment: "learn more button")
    /// "Not all recipients support message expiration"
    lazy var _not_all_recipients_support_message_expiration = NSLocalizedString("Not all recipients support message expiration", comment: "alert description")
    /// "Please add a password for the following recipients"
    lazy var _please_add_a_password_for_the_following_recipients = NSLocalizedString("Please add a password for the following recipients.", comment: "alert description")
    /// "Please disable PGP sending for following addresses"
    lazy var _please_disable_pgp_sending_for_following_addresses = NSLocalizedString("Please disable PGP Sending for following addresses.", comment: "alert description")


    // MARK: - Notifcations Snooze feature

    /// "Turn Off"
    lazy var _turn_off = NSLocalizedString("Turn Off", comment: "action sheet option")
    /// "Scheduled"
    lazy var _scheduled = NSLocalizedString("Scheduled", comment: "action sheet option")
    /// "Notification Snooze"
    lazy var _notification_snooze = NSLocalizedString("Notification Snooze", comment: "title of action sheet")
    /// "Snoozed for"
    lazy var _snoozed_for = NSLocalizedString("Snoozed for", comment: "title of action sheet when quick snooze is active (Snoozed for 30min)")
    /// "Snoozed till"
    lazy var _snoozed_till = NSLocalizedString("Snoozed till", comment: "title of action sheet when scheduled scoone is active (Snoozed till 8am)")
    /// "Notifications Are Snoozed"
    lazy var _notifications_are_snoozed = NSLocalizedString("Notifications Are Snoozed", comment: "VoiceOver description")
    /// "Notifications Snooze Off"
    lazy var _notifications_snooze_off = NSLocalizedString("Notifications Snooze Off", comment: "VoiceOver description")
    /// "Snooze Notifications"
    lazy var _snooze_notifications = NSLocalizedString("Snooze Notifications", comment: "settings option")
    /// "End Time"
    lazy var _end_time = NSLocalizedString("End Time", comment: "settings option (End Time: 8am)")
    /// "Start Time"
    lazy var _start_time = NSLocalizedString("Start Time", comment: "settings option (Start Time: 8am)")
    /// "Repeat"
    lazy var _repeat = NSLocalizedString("Repeat", comment: "settings option (Repeat: sun, mon, thu)")
    /// "Double tap to setup"
    lazy var _double_tap_to_setup = NSLocalizedString("Double tap to setup", comment: "VoiceOver action description")
    /// "Custom"
    lazy var _custom = NSLocalizedString("Custom", comment: "action sheet option")


    // Mark: - VoiceOver

    /// "Attachments"
    lazy var _attachments = NSLocalizedString("Attachments", comment: "VoiceOver: email has attachments")
    /// "Folder"
    lazy var _folder = NSLocalizedString("Folder", comment: "VoiceOver: email belongs to folder")
    /// "Labels"
    lazy var _labels = NSLocalizedString("Labels", comment: "VoiceOver: email has lables")
    /// "Starred"
    lazy var _starred = NSLocalizedString("Starred", comment: "VoiceOver: email is starred")
    /// "Expires"
    lazy var _expires = NSLocalizedString("Expires", comment: "VoiceOver: email can expire")
    /// "Unread"
    lazy var _unread = NSLocalizedString("Unread", comment: "VoiceOver: email is not read yet")


    // Mark: - IAP
    
    lazy var _iap_unavailable = NSLocalizedString("Subscription information temporarily unavailable. Please try again later.", comment: "Fetch subscription data failed")

    lazy var _unlimited_messages_sent = NSLocalizedString("Unlimited messages sent/day", comment: "Service plan capability;")

    lazy var _up_to_n_users = NSLocalizedString("Up to %i users", comment: "Service plan capability; i = 6")

    lazy var _n_email_address = NSLocalizedString("%i email address", comment: "Service plan capability; i = 1")
    lazy var _n_email_addresses = NSLocalizedString("%i email addresses", comment: "Service plan capability; i = 5 or 50")
    lazy var _total = NSLocalizedString("(total)", comment: "Service plan capability detail; like in '50 email addresses (total)'")
    lazy var _per_user = NSLocalizedString("/user", comment: "Service plan capability detail; like in '5 email addresses/user'")

    lazy var _storage_capacity = NSLocalizedString("%@ storage capacity", comment: "Service plan capability")

    lazy var _limited_to_150_messages = NSLocalizedString("Limited to 150 messages sent/day", comment: "Service plan capability")

    lazy var _bridge_support = NSLocalizedString("IMAP/SMTP Support via ProtonMail Bridge", comment: "Service plan capability")

    lazy var _labels_folders_filters = NSLocalizedString("Labels, Folders, Filters & More", comment: "Service plan capability")

    lazy var _support_n_domains = NSLocalizedString("Support for %i custom domains (e.g. user@yourdomain.com)", comment: "Service plan capability; i = 2")

    lazy var _vpn_included = NSLocalizedString("ProtonVPN included", comment: "Service plan capability")
    
    /// "It is not possible to switch to %@ within our iOS app."
    lazy var _migrate_plan = NSLocalizedString("It is not possible to switch to %@ within our iOS app.", comment: "It is not possible to switch to `plan` within our iOS app.")

    lazy var _upgrade_to_paid = NSLocalizedString("Upgrade to a paid plan to benefit from more features", comment: "Service plan description footer")

    lazy var _will_renew = NSLocalizedString("Your plan will automatically renew on", comment: "Service plan description footer")

    lazy var _active_until = NSLocalizedString("Your plan is currently active until", comment: "Service plan description footer")

    lazy var _buy_more_credits = NSLocalizedString("Buy More Credits", comment: "Link to More Credits screen")

    lazy var _cant_connect_to_store = NSLocalizedString("Could not connect to Store. Please try again later.", comment: "Error message")

    lazy var _for_one_year = NSLocalizedString("for one year", comment: "Buy button second line")

    lazy var _iap_fee = NSLocalizedString("Apple in-app purchase fee", comment: "Price breakdown")

    lazy var _iap_disclamer = NSLocalizedString(self._iap_disclamer_private, comment: "Terms of purchase")
    private lazy var _iap_disclamer_private = """
    Upon confirming your purchase, your iTunes account will be charged the amount displayed, which includes ProtonMail Plus, and Apple's in-app purchase fee (Apple charges a fee of approximately 30% on purchases made through your iPhone/iPad).
    After making the purchase, you will automatically be upgraded to ProtonMail Plus for one year period, after which time you can renew or cancel, either online or through our iOS app.
    """

    lazy var _more_credits = NSLocalizedString("More Credits", comment: "Screen header")

    lazy var _get_plan = NSLocalizedString("Get %@", comment: "Screen header, like 'Get VISIONARY'")

    lazy var _other_plans = NSLocalizedString("OTHER PLANS", comment: "Section header")

    lazy var _error_occured = NSLocalizedString("Error occured", comment: "Error alert title")

    lazy var _free_header = NSLocalizedString("For individuals looking to benefit from secure communication at no cost", comment: "Service Plan description")

    lazy var _plus_header = NSLocalizedString("For individuals that need more capacity, customization and advanced features", comment: "Service Plan description")
    
    lazy var _pro_header = NSLocalizedString("For organizations that need multi-user support and additional productivity features", comment: "Service Plan description")
    
    lazy var _vis_header = NSLocalizedString("For power users and groups of people that value full anonymity and privacy", comment: "Service Plan description")

    lazy var _yes_bypass_validation = NSLocalizedString("Yes, activate it for ", comment: "Warning message option to bypass validation and activate plan for current username")
    
    lazy var _no_dont_bypass_validation = NSLocalizedString("No, for another ProtonMail account", comment: "Warning message option when user want to relogin to another account")
    
    lazy var _iap_bugreport_title = NSLocalizedString("Is this bug report about an in-app purchase?", comment: "Error message")
    
    lazy var _iap_bugreport_user_agreement = NSLocalizedString("Our Customer Support team will try to activate your service plan manually if you agree to attach technical data that AppStore provided to the app at the moment of purchase. This data does not include any details about your iTunes account, Apple ID, linked credit cards, or any other user information. Technical data only helps us check and verify that the transaction was fulfilled on the AppStore's servers.", comment: "Error message")
    
    lazy var _iap_bugreport_yes = NSLocalizedString("Yes, attach details of payment", comment: "Error message")
    
    lazy var _iap_bugreport_no = NSLocalizedString("No, not related to in-app purchase", comment: "Error message")

    // Mark : Force Upgrade

    /// "Update Required"
    lazy var _update_required = NSLocalizedString("Update Required", comment: "title")
    /// "Update Now"
    lazy var _update_now = NSLocalizedString("Update Now", comment: "title")
    
    // contact group
    lazy var _contacts_action_select_an_option = NSLocalizedString("Select An Option",
                                                                   comment: "The title for the popup list, presenting a list of options for creating a contact or creating a contact group")
    
    lazy var _contact_groups_group_name_instruction_label = NSLocalizedString("Group Name",
                                                                              comment: "The instruction label for the group name textfield")
    lazy var _contact_groups_detail_view_title = NSLocalizedString("Group Details",
                                                                   comment: "The title for the contact group detail view")
    lazy var _contact_groups_add = NSLocalizedString("Add Group",
                                                     comment: "The title for the contact group creation view")
    lazy var _contact_groups_edit = NSLocalizedString("Edit Group",
                                                      comment: "The title for the contact group editing view")
    
    lazy var _contact_groups_manage_addresses = NSLocalizedString("Manage Addresses",
                                                                  comment: "The title for the view where user can manage emails in the contact group")
    
    lazy var _contact_groups_select_color = NSLocalizedString("Select Color",
                                                              comment: "The title for the view where user can select the color for the group")
    lazy var _contact_groups_delete = NSLocalizedString("Delete Contact Group",
                                                        comment: "The description of the button for deleting the contact group")
    
    lazy var _contact_groups_member_count_description = NSLocalizedString("%d Member",
                                                                          comment: "The string that describes whether there are 0 or 1 member in the contact group")
    lazy var _contact_groups_members_count_description = NSLocalizedString("%d Members",
                                                                           comment: "The string that describes whether there are 2 or more members in the contact group")
    lazy var _contact_groups_selected_group_count_description = NSLocalizedString("%d Selected",
                                                                                  comment: "The string that describes how many contact groups are currently selected")
    lazy var _contact_group_no_contact_group_associated_with_contact_email = NSLocalizedString("None",
                                                                                               comment: "A *short* description saying that there is no contact group associated with this contact email")
    
    // contact group errors
    lazy var _contact_groups_save_error = NSLocalizedString("Can't save contact group",
                                                            comment: "The error message title that will be shown when the contact group being created or edited can't be saved")
    lazy var _contact_groups_fetch_error = NSLocalizedString("Can't fetch contact groups",
                                                             comment: "The error message title that will be shown when the app attempts to fetch contact groups from the server but failed")
    lazy var _contact_groups_delete_error = NSLocalizedString("Can't delete contact group",
                                                              comment: "The error message title that will be shown when the deletion of the contact group failed")
    
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
    
    // Local notifications
    
    lazy var _message_not_sent_title = NSLocalizedString("Problem sending message", comment: "Local notification title")
    
    lazy var _message_not_sent_message = NSLocalizedString("We could not send your message, possibly because of a poor network connection. Your message was saved to Drafts and will be sent automatically the next time you open the app.", comment: "Local notification text")
    
    /// Logout
    lazy var _logout_title = NSLocalizedString("Logout", comment: "Alert title to confirm logout")
    lazy var _logout_confirmation = NSLocalizedString("You will be switched to %@", comment: "Alert to confirm logout")
    lazy var _logout_confirmation_in_bio = NSLocalizedString("Are you sure you want to logout?", comment: "Alert to confirm logout")
    lazy var _logout_confirmation_one_account = NSLocalizedString("Are you sure you want to logout %@?", comment: "Alert to confirm logout when only one account logged in")
    lazy var _logout_confirmation_having_pending_message = NSLocalizedString("There are unsent messages that will be lost if you log out", comment: "Alert to confirm logout with pending message in the queue")
    
    
    
    lazy var _message_list_no_email_selected = NSLocalizedString("Please select at least one email",
                                                                   comment: "The message will show up when the user attempts to apply label/folder in inbox without select any emails")
    
    lazy var _logout_account_switched_when_token_revoked = NSLocalizedString("Logged out from %@ and signed in with %@", comment: "Alert when auth token is revoked and switch to another")
    
    lazy var _logout_primary_account_from_manager_account_title = NSLocalizedString("Logout", comment: "Alert title when logout primary account from account manager")
    
    lazy var _logout_primary_account_from_manager_account = NSLocalizedString("You will be switched to %@", comment: "Alert when logout primary account from account manager")
    
    lazy var _logout_secondary_account_from_manager_account_title = NSLocalizedString("Log out %@?", comment: "Alert title when logout non-primary account from account manager")
    
    lazy var _logout_secondary_account_from_manager_account = NSLocalizedString("Are you sure you want to log out?", comment: "Alert when logout non-primary account from account manager")
    
    // Switch Account
    lazy var _switch_account_by_click_notification = NSLocalizedString("Switched to account '%@'", comment: "Alert when switched account by clicking notification of another account")
    
    // TrustKit
    
    lazy var _cert_validation_failed_title = NSLocalizedString("Insecure connection", comment: "Cert pinning failed alert title")
    lazy var _cert_validation_failed_message = NSLocalizedString("TLS certificate validation failed. Your connection may be monitored and the app is temporarily blocked for your safety.\n\nswitch  networks immediately", comment: "Cert pinning failed alert message")
    
    lazy var _cert_validation_hardfailed_message = NSLocalizedString("TLS certificate validation failed. Your connection may be monitored and the app is temporarily blocked for your safety.\n\n", comment: "Cert pinning failed alert message")

    
    lazy var _cert_validation_failed_continue = NSLocalizedString("Disable Validation", comment: "Cert pinning failed alert message")
    
    // Springboard shortcuts
    lazy var _springboard_shortcuts_search = NSLocalizedString("Search", comment: "Springboard (3D Touch) shortcuts action")
    lazy var _springboard_shortcuts_starred = NSLocalizedString("Starred", comment: "Springboard (3D Touch) shortcuts action")
    lazy var _springboard_shortcuts_composer = NSLocalizedString("Compose", comment: "Springboard (3D Touch) shortcuts action")
    
    
    lazy var _troubleshoot = NSLocalizedString("Troubleshoot", comment: "troubleshooting view button")
    
    /// Account Manger
    lazy var _account = NSLocalizedString("Account", comment: "Account manager title")
    
    lazy var _connect_account = NSLocalizedString("Connect Account", comment: "Account manager title")
    
    lazy var _login_to_pm_act = NSLocalizedString("Log in to your ProtonMail account", comment: "Account manager title")
    lazy var _duplicate_logged_in = NSLocalizedString("The user is already logged in", comment: "Alert when the account is already logged in")
    
    lazy var _free_account_limit_reached_title = NSLocalizedString("Limit reached", comment: "Title of alert when the free account limit is reached")
    lazy var _free_account_limit_reached = NSLocalizedString("Only one free account can be added", comment: "Alert when the free account limit is reached")
    
    
    lazy var _enter_your_mailbox_password = NSLocalizedString("Enter your mailbox password", comment: "Account manager title")
    
    
    /// New Settings
    lazy var _account_settings = NSLocalizedString("Account Settings", comment: "section title in settings")
    lazy var _app_settings = NSLocalizedString("App Settings", comment: "section title in settings")
    lazy var _app_information = NSLocalizedString("APP INFORMATION", comment: "section title in settings")
    
    lazy var _auto_lock = NSLocalizedString("Auto-lock", comment: "section title in settings")
    lazy var _app_language = NSLocalizedString("App Language", comment: "cell title in device settings")
    lazy var _combined_contacts = NSLocalizedString("Combined Contacts", comment: "cell title in device settings")
    lazy var _local_cache_management = NSLocalizedString("Local Cache Management", comment: "cell title in device settings")
    
    lazy var _password_management = NSLocalizedString("Password management", comment: "cell title in device settings")
    lazy var _mailbox_size = NSLocalizedString("Mailbox size", comment: "cell title in device settings")
    
    lazy var _addresses = NSLocalizedString("Addresses", comment: "cell title in device settings")
    lazy var _snooze = NSLocalizedString("Snooze", comment: "Cell title in device settings - mute notification until a later time.")
    lazy var _mailbox = NSLocalizedString("MAILBOX", comment: "cell title in device settings")
    
    lazy var _privacy = NSLocalizedString("Privacy", comment: "cell title in device settings")
    lazy var _label_and_folders = NSLocalizedString("Labels & Folders", comment: "cell title in device settings")
    
    lazy var _swiping_gestures = NSLocalizedString("Swiping gestures", comment: "cell title in device settings")
    lazy var _local_storage_limit = NSLocalizedString("Local storage limit", comment: "cell title in device settings")
    
    lazy var _push_notification = NSLocalizedString("Push Notifications", comment: "cell title in device settings")
    lazy var _remove_all = NSLocalizedString("Remove All", comment: "account right bar item title")
    lazy var _empty_cache = NSLocalizedString("Empty Cache", comment: "cell title in device setting")
    
    
    // Account Manager
    lazy var _logged_out = NSLocalizedString("(logged out)", comment: "Comment for disconnected account in Account Manager")
    
    lazy var _you_are_about_to_remove = NSLocalizedString("You are about to remove all accounts. You will not be able to access them from this device unless you add them again.\n\nDo you want to remove all your accounts anyway?", comment: "Alert of removing all accounts")
  
    
    lazy var _by_removing_this_account = NSLocalizedString("By removing this account, you will no longer be able to access it from this device unless you add it again.\n\nDo you want to remove this account anyway?", comment: "Alert for removing disconnected accounts")
    
    lazy var _allow_alternative_routing = NSLocalizedString("Allow alternative routing", comment: "network troubleshot cell title")
    lazy var _no_internet_connection = NSLocalizedString("No internet connection", comment: "network troubleshot cell title")
    lazy var _internet_service_provider_problem = NSLocalizedString("Internet Service Provider (ISP) problem", comment: "network troubleshot cell title")
    lazy var _government_block = NSLocalizedString("Government block", comment: "network troubleshot cell title")
    lazy var _antivirus_interference = NSLocalizedString("Antivirus interference", comment: "network troubleshot cell title")
    lazy var _proxy_firewall_interference = NSLocalizedString("Proxy/Firewall interference", comment: "network troubleshot cell title")
    lazy var _proton_is_down = NSLocalizedString("Proton is down", comment: "network troubleshot cell title")
    lazy var _still_cant_find_a_solution = NSLocalizedString("Still can't find a solution", comment: "network troubleshot cell title")
    lazy var _trouble_shooting = NSLocalizedString("TroubleShooting", comment: "network troubleshot view title")
    //lazy var _incase_proton_sites_are_blocked = NSLocalizedString("In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. [Learn more]", comment: "network troubleshot cell title")
    lazy var _incase_proton_sites_are_blocked = NSLocalizedString("In case Proton sites are blocked, this setting allows the app to try alternative network routing to reach Proton, which can be useful for bypassing firewalls or network issues. We recommend keeping this setting on for greater reliability. %1$@", comment: "network troubleshot cell title")
    lazy var _please_make_sure_that_your_internet_ = NSLocalizedString("Please make sure that your internet connection is working.", comment: "network troubleshot cell title")
    lazy var _try_connection_to_proton_from_ = NSLocalizedString( "Try connecting to Proton from a different network (or use ProtonVPN or Tor).", comment: "network troubleshot cell title")
    //    lazy var _your_country_may_be_blocking_ = NSLocalizedString( "Your country may be blocking access to Proton. Try using ProtonVPN (or any other VPN) or Tor to access Proton.", comment: "network troubleshot cell title")
    lazy var _your_country_may_be_blocking_ = NSLocalizedString("Your country may be blocking access to Proton. Try using %1$@ (or any other VPN) or %2$@ to access Proton.", comment: "network troubleshot cell title")
    lazy var _temporarily_disable_or_remove_your_ = NSLocalizedString( "Temporarily disable or remove your antivirus software.", comment: "network troubleshot cell title")
    lazy var _disable_any_proxies_or_firewalls_ = NSLocalizedString( "Disable any proxies or firewalls, or contact your network administrator.", comment: "network troubleshot cell title")
    lazy var _check_proton_status_for_our_ = NSLocalizedString("Check Proton Status for our system status.", comment: "network troubleshot cell title")
    lazy var _contact_us_dirrectly_through_our_support_ = NSLocalizedString( "Contact us directly through our support form, email (support@protonmail.com), or Twitter.", comment: "network troubleshot cell title")
    
    lazy var _learn_more_ = NSLocalizedString("Learn more", comment: "network troubleshot cell title")
    lazy var _protonvpn = NSLocalizedString("ProtonVPN", comment: "network troubleshot cell title")
    lazy var _tor = NSLocalizedString("Tor", comment: "network troubleshot cell title")

    lazy var _proton_status = NSLocalizedString("Proton Status", comment: "network troubleshot cell title")
    lazy var _support_form = NSLocalizedString("support form", comment: "network troubleshot cell title")
    //this used in n
    lazy var _emaile_ = NSLocalizedString("email", comment: "network troubleshot cell title")
    lazy var _twitter = NSLocalizedString("Twitter", comment: "network troubleshot cell title")
    
    lazy var _there_are_still_some_messages_in_queue_ = NSLocalizedString("There are still some messages in queue. If you log out, the draft will be deleted.", comment: "alert when logout user if in queue still have tasks")
    

    lazy var _pin = NSLocalizedString("PIN", comment: "device settings auto lock type title")
    lazy var _enable_pin = NSLocalizedString("Enable PIN", comment: "device settings auto lock type title toggle text")
    
    lazy var _pin_and_touch_id = NSLocalizedString("PIN & TouchID", comment: "device settings auto lock type title")
    lazy var _enable_pin_or_touch_id = NSLocalizedString("Enable PIN/TouchID", comment: "device settings auto lock type title toggle text")
    
    lazy var _pin_and_face_id = NSLocalizedString("PIN & FaceID", comment: "device settings auto lock type title")
    lazy var _enable_pin_or_face_id = NSLocalizedString("Enable PIN/FaceID", comment: "device settings auto lock type title toggle text")
    lazy var _recipient_not_found = NSLocalizedString("Recipient not found", comment: "The error message is shown in composer")
    lazy var _signle_address_invalid_error_content = NSLocalizedString("Email address is invalid", comment: "The error message is shown in composer")
    lazy var _address_invalid_error_content = NSLocalizedString("At least one recipient email address is improperly formatted, please double check them.", comment: "incorrect email format error in composer")
    lazy var _address_invalid_error_title = NSLocalizedString("Error sending", comment: "incorrect email format error in composer")
    
    lazy var _address_in_group_not_found_error = NSLocalizedString("At least one email address in the group could not be found", comment: "incorrect email format error while sending")
    lazy var _address_invalid_error_sending = NSLocalizedString("At least one recipient email address/domain doesn't exist or is badly formatted. Message moved to drafts.", comment: "incorrect email format error while sending")
    lazy var _address_invalid_error_sending_title = NSLocalizedString("Sending failed", comment: "title of incorrect email format error while sending")
    lazy var _address_invalid_error_to_draft_action_title = NSLocalizedString("Go to drafts", comment: "title of alert acton of incorrect email format error")
    
    lazy var _mailbox_draft_is_uploading = NSLocalizedString("Draft is still uploading...", comment: "title of toast message that user taps the message which is uploading")
    lazy var _mailbox_draft_is_sending = NSLocalizedString("Sending message...", comment: "content of the sending mesage that will display this text on the date label")
    lazy var _messages_validation_failed_try_again = NSLocalizedString("Message could not be sent. At least one recipient email address/domain doesn't exist or is badly formatted.", comment: "message shown in the notification when the recipient validation is failed while sending")
    lazy var _ignore_IAP_error_descrption = NSLocalizedString("Only ignore the purchase activation if you are sure that all your subscriptions are up to date. For further assistance, please contact customer support. \r\n\r\n Are you sure you want to ignore the activation?", comment: "Alert message")

    lazy var _message_of_unavailable_to_upgrade_account = NSLocalizedString("It's not possible to swicth to another plan within the app. %1$@", comment: "")
    lazy var _message_of_unavailable_to_upgrade_url = NSLocalizedString("Plans can be edited on the web version.", comment: "")
}
