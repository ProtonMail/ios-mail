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

public struct MailScenario: Hashable {
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
    
    static let list = [
        MailScenario(name: "qa-mail-001", description: "1 message with remote content in Inbox", subject: "001_message_with_remote_content_in_inbox"),
        MailScenario(name: "qa-mail-002", description: "1 message with rich text in Inbox", subject: "002_message_with_rich_text_in_inbox"),
        MailScenario(name: "qa-mail-003", description: "1 message with empty body in Inbox", subject: "003_message_with_empty_body_in_inbox"),
        MailScenario(name: "qa-mail-004", description: "1 message with BCC in Sent", subject: "004_message_with_BCC_in_inbox"),
        MailScenario(name: "qa-mail-005", description: "1 message with Unsubscribe in Inbox", subject: "005_message_with_subscription_in_inbox"),
        MailScenario(name: "qa-mail-006", description: "3 messages in Inbox", subject: "006_3_messages_in_inbox"),
        MailScenario(name: "qa-mail-007", description: "1 messages with remote content and 1 message with tracked content in Inbox", subject: "007_message_with_remote_content"),
        MailScenario(name: "qa-mail-008", description: "3 messages with remote content in Sent"),
        MailScenario(name: "qa-mail-009", description: "1 message with rich text in Archive", subject: "009_message_with_rich_text_in_archive"),
        MailScenario(name: "qa-mail-010", description: "3 messages with remote content in Inbox", subject: "010_3_messages_with_remote_content_in_inbox_"),
        MailScenario(name: "qa-mail-011", description: "3 messages in Sent", subject: "011_3_messages_in_sent_"),
        MailScenario(name: "qa-mail-012", description: "2 conversations with remote content in Inbox", subject: "012_2_conversations_with_remote_content_in_inbox"),
        MailScenario(name: "qa-mail-013", description: "1 message with rich text in Archive", subject: "013_message_with_rich_text_in_archive"),
        MailScenario(name: "qa-mail-014", description: "2 messages with remote content and 1 message with tracked content in Inbox", subject: "014_2_messages_with_remote_content_1_message_with_tracking_in_inbox_1"),
        MailScenario(name: "qa-mail-015", description: "1 message with rich text in Trash", subject: "015_message_with_rich_text_in_trash"),
        MailScenario(name: "qa-mail-016", description: "100 messages in Scheduled", subject: "018_100_emails_in_archive_folder_"),
        MailScenario(name: "qa-mail-017", description: "7 messages in Archive", subject: "017_7_emails_in_archive_"),
        MailScenario(name: "qa-mail-018", description: "100 messages in Archive", subject: "018_100_emails_in_archive_folder_"),
        MailScenario(name: "qa-mail-019", description: "1 message with rich text in Spam", subject: "019_message_with_rich_text_in_spam"),
        MailScenario(name: "qa-mail-020", description: "1 message with rich text in Starred", subject: "020_message_with_rich_text_in_starred"),
        MailScenario(name: "qa-mail-021", description: "1 message with Unsubscribe in Inbox", subject: "021_messages_with_one_click_list_unsubscribe_mailto"),
        MailScenario(name: "qa-mail-022", description: "1 message with BCC in Inbox", subject: "022_message_with_BCC_in_inbox"),
    ]
}
