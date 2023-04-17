// Copyright (c) 2023. Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

struct MailScenario: Hashable {
    public let name: String
    public let description: String
    public let subject: String

    public init(name: String, description: String, subject: String = "") {
        self.name = name
        self.description = description
        self.subject = subject
    }
}

extension MailScenario {
    
    static let qaMail001 = MailScenario(name: "qa-mail-web-001", description: "1 message with remote content in Inbox", subject: "001_message_with_remote_content_in_inbox")
    static let qaMail002 = MailScenario(name: "qa-mail-web-002", description: "1 message with rich text in Inbox", subject: "002_message_with_rich_text_in_inbox")
    static let qaMail003 = MailScenario(name: "qa-mail-web-003", description: "1 message with empty body in Inbox", subject: "003_message_with_empty_body_in_inbox")
    static let qaMail004 = MailScenario(name: "qa-mail-web-004", description: "1 message with BCC in Sent", subject: "004_message_with_BCC_in_inbox")
    static let qaMail005 = MailScenario(name: "qa-mail-web-005", description: "1 message with Unsubscribe in Inbox", subject: "005_message_with_subscription_in_inbox")
    static let qaMail006 = MailScenario(name: "qa-mail-web-006", description: "3 messages in Inbox", subject: "006_3_messages_in_inbox")
    static let qaMail007 = MailScenario(name: "qa-mail-web-007", description: "1 messages with remote content and 1 message with tracked content in Inbox", subject: "007_message_with_remote_content")
    static let qaMail008 = MailScenario(name: "qa-mail-web-008", description: "3 messages with remote content in Sent")
    static let qaMail009 = MailScenario(name: "qa-mail-web-009", description: "1 message with rich text in Archive", subject: "009_message_with_rich_text_in_archive")
    static let qaMail010 = MailScenario(name: "qa-mail-web-010", description: "3 messages with remote content in Inbox", subject: "010_3_messages_with_remote_content_in_inbox_")
    static let qaMail011 = MailScenario(name: "qa-mail-web-011", description: "3 messages in Sent", subject: "011_3_messages_in_sent_")
    static let qaMail012 = MailScenario(name: "qa-mail-web-012", description: "2 conversations with remote content in Inbox", subject: "012_2_conversations_with_remote_content_in_inbox")
    static let qaMail013 = MailScenario(name: "qa-mail-web-013", description: "1 message with rich text in Archive", subject: "013_message_with_rich_text_in_archive")
    static let qaMail014 = MailScenario(name: "qa-mail-web-014", description: "2 messages with remote content and 1 message with tracked content in Inbox", subject: "014_2_messages_with_remote_content_1_message_with_tracking_in_inbox_1")
    static let qaMail015 = MailScenario(name: "qa-mail-web-015", description: "1 message with rich text in Trash", subject: "015_message_with_rich_text_in_trash")
    static let qaMail016 = MailScenario(name: "qa-mail-web-016", description: "100 messages in Scheduled", subject: "018_100_emails_in_archive_folder_")
    static let qaMail017 = MailScenario(name: "qa-mail-web-017", description: "7 messages in Archive", subject: "017_7_emails_in_archive_")
    static let qaMail018 = MailScenario(name: "qa-mail-web-018", description: "100 messages in Archive", subject: "018_100_emails_in_archive_folder_")
    static let qaMail019 = MailScenario(name: "qa-mail-web-019", description: "1 message with rich text in Spam", subject: "019_message_with_rich_text_in_spam")
    static let qaMail020 = MailScenario(name: "qa-mail-web-020", description: "1 message with rich text in Starred", subject: "020_message_with_rich_text_in_starred")
    static let qaMail021 = MailScenario(name: "qa-mail-web-021", description: "1 message with Unsubscribe in Inbox", subject: "021_messages_with_one_click_list_unsubscribe_mailto")
    static let qaMail022 = MailScenario(name: "qa-mail-web-022", description: "1 message with BCC in Inbox", subject: "022_message_with_BCC_in_inbox")
}
