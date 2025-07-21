// Copyright (c) 2024 Proton Technologies AG
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

import InboxDesignSystem
import SwiftUI

struct PrintHeaderView: View {
    let subject: String
    let messageDetails: MessageDetailsUIModel

    private var participantGroups: [LabeledParticipantGroup] {
        [
            .init(label: \.from, participants: [messageDetails.sender]),
            .init(label: \.to, participants: messageDetails.recipientsTo),
            .init(label: \.cc, participants: messageDetails.recipientsCc),
            .init(label: \.bcc, participants: messageDetails.recipientsBcc),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            Text(subject)
                .font(.headline)
                .foregroundStyle(DS.Color.Text.weak)

            Grid(alignment: .topLeading, verticalSpacing: DS.Spacing.standard) {
                ForEach(participantGroups, id: \.label) { group in
                    participantsRow(group: group)
                }

                timeRow(date: messageDetails.date)
            }
            .font(.footnote)

            Divider()
        }
    }

    @ViewBuilder
    private func participantsRow(group: LabeledParticipantGroup) -> some View {
        if !group.participants.isEmpty {
            gridRow(title: L10n.MessageDetails.self[keyPath: group.label]) {
                VStack(alignment: .leading) {
                    ForEach(Array(group.participants.enumerated()), id: \.offset) { index, contact in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(contact.name)
                                .foregroundStyle(DS.Color.Text.weak)
                                .fontWeight(.medium)

                            Text(contact.address)
                                .foregroundStyle(DS.Color.Text.hint)
                        }
                    }
                }
            }
        }
    }

    private func timeRow(date: Date) -> some View {
        gridRow(title: L10n.MessageDetails.on) {
            Text(date.formatted(date: .complete, time: .standard))
                .foregroundStyle(DS.Color.Text.weak)
                .fontWeight(.medium)
        }
    }

    private func gridRow<Content: View>(title: LocalizedStringResource, content: () -> Content) -> GridRow<TupleView<(Text, Content)>> {
        GridRow {
            Text(title)
                .foregroundStyle(DS.Color.Text.hint)

            content()
        }
    }
}

private struct LabeledParticipantGroup {
    let label: KeyPath<L10n.MessageDetails.Type, LocalizedStringResource>
    let participants: [Participant]
}

private protocol Participant {
    var name: String { get }
    var address: String { get }
}

extension MessageDetail.Recipient: Participant {}
extension MessageDetail.Sender: Participant {}

#Preview {
    let messageDetails = MessageDetailsPreviewProvider.testData(
        location: .system(name: .inbox, id: 0),
        labels: [
            .init(labelId: 0, text: "foo", color: .red),
            .init(labelId: 0, text: "bar", color: .blue),
        ]
    )

    PrintHeaderView(subject: "Some very very long subject that will totally get carried to a new line", messageDetails: messageDetails)
}
