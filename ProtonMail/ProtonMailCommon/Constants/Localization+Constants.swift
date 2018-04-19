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
    
    
    /// "(2048 bit)"
    static let _signup_key_2048_size   = NSLocalizedString("(2048 bit)", comment: "Key size text when setup key")
    /// "(4096 bit)"
    static let _signup_key_4096_size   = NSLocalizedString("(4096 bit)", comment: "Key size text when setup key")
    /// "*OPTIONAL"
    static let _signup_optional_text   = NSLocalizedString("*OPTIONAL", comment: "optional text field")
    /// "2fa Authentication failed please try to login again"
    static let _signup_2fa_auth_failed = NSLocalizedString("2fa Authentication failed please try to login again", comment: "2fa verification failed")
    
    
    /// "%d Minute"
    static let _settings_auto_lock_minute  = NSLocalizedString("%d Minute", comment: "auto lock time format")
    /// "%d Minutes"
    static let _settings_auto_lock_minutes = NSLocalizedString("%d Minutes", comment: "auto lock time format")
    /// "**********"
    static let _settings_secret_x_string   = NSLocalizedString("**********", comment: "secret")
    

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
    

}
