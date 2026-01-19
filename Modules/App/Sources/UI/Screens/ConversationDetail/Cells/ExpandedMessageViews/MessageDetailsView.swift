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

import InboxCore
import InboxCoreUI
import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI
import proton_app_uniffi

struct MessageDetailsView: View {
    enum ActionButtonsState {
        case enabled
        case disabled
        case hidden

        var isDisabled: Bool { self == .disabled }
        var isHidden: Bool { self == .hidden }
    }

    @Environment(\.messageAppearanceOverrideStore) var messageAppearanceOverrideStore
    @State private(set) var isHeaderCollapsed: Bool = true
    let uiModel: MessageDetailsUIModel
    let trackers: Loadable<TrackersUIModel>
    let mailbox: Mailbox
    let actionButtonsState: ActionButtonsState
    let onEvent: (MessageDetailsEvent) async -> Void

    private let detailedContentLeadingSpacing: CGFloat = DS.Spacing.jumbo + DS.Spacing.large

    var body: some View {
        VStack(alignment: .leading, spacing: isHeaderCollapsed ? DS.Spacing.standard : 0) {
            headerViewWithTapGesture
            detailedContent
        }
        .background(DS.Color.Background.norm)
        .clipped()
        .padding([.horizontal, .bottom], DS.Spacing.large)
    }

    // MARK: - Private

    @ViewBuilder
    private var headerViewWithTapGesture: some View {
        if #available(iOS 18, *) {
            headerView
                .background(DS.Color.Background.norm)
                .contentShape(Rectangle())
                .onTapGesture { Task { await onEvent(.onTap) } }
                .zIndex(1)
        } else {
            // iOS 17: Tap gesture on the background layer fixes a tap-through bug
            headerView
                .background {
                    DS.Color.Background.norm
                        .onTapGesture { Task { await onEvent(.onTap) } }
                }
                .contentShape(Rectangle())
                .zIndex(1)
        }
    }

    private var headerView: some View {
        HStack(alignment: .top, spacing: DS.Spacing.large) {
            let senderTapAction: () -> Void = { Task { await onEvent(.onSenderTap) } }

            Button(action: senderTapAction) {
                AvatarView(avatar: uiModel.avatar)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large, style: .continuous))
            }
            .square(size: 40)
            .zIndex(1)

            HStack(alignment: .top, spacing: .zero) {
                VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                    senderView
                    Button(action: senderTapAction) {
                        senderAddressView
                    }
                    .disabled(isHeaderCollapsed)

                    if isHeaderCollapsed {
                        recipientsView
                            .transition(.opacity)
                    } else if let firstRecipient = uiModel.recipientsTo.first {
                        recipientButton(recipient: firstRecipient, group: .to, prefixed: true, index: 0)
                            .transition(.opacity)
                    }
                }

                Spacer(minLength: DS.Spacing.moderatelyLarge)
                VStack(alignment: .trailing, spacing: DS.Spacing.standard) {
                    HStack(alignment: .center, spacing: DS.Spacing.compact) {
                        if uiModel.showPaperClip {
                            PaperClipImage()
                        }
                        if uiModel.isStarred {
                            StarImage(isStarred: uiModel.isStarred, size: 14)
                        }
                        Text(uiModel.date.mailboxFormat())
                            .font(.caption)
                            .foregroundColor(DS.Color.Text.weak)
                            .accessibilityIdentifier(MessageDetailsViewIdentifiers.messageDate)
                            .padding(.top, DS.Spacing.tiny)
                    }
                    if !actionButtonsState.isHidden {
                        headerActionsView
                    }
                }
            }
        }
    }

    private var detailedContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            if !isHeaderCollapsed {
                expandedHeaderView
            }

            labelRow
                .removeViewIf(uiModel.labels.isEmpty)

            if !isHeaderCollapsed {
                hideDetailsButton
                    .padding(.top, DS.Spacing.large)
            }
        }
        .padding(.leading, detailedContentLeadingSpacing)
    }

    private var expandedHeaderView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.large) {
            recipientRow(.to, recipients: uiModel.recipientsToExcludingFirst)
                .removeViewIf(uiModel.recipientsToExcludingFirst.isEmpty)
            recipientRow(.cc, recipients: uiModel.recipientsCc)
                .removeViewIf(uiModel.recipientsCc.isEmpty)
            recipientRow(.bcc, recipients: uiModel.recipientsBcc)
                .removeViewIf(uiModel.recipientsBcc.isEmpty)

            VStack(alignment: .leading, spacing: DS.Spacing.standard) {
                trackersRow
                dateRow
                locationRow
            }
        }
        .padding(.top, uiModel.recipientsToExcludingFirst.isEmpty ? DS.Spacing.large : DS.Spacing.compact)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var hideDetailsButton: some View {
        Button(action: {
            withAnimation {
                isHeaderCollapsed.toggle()
            }
        }) {
            HStack(alignment: .center, spacing: DS.Spacing.compact) {
                Text(L10n.MessageDetails.hideDetails)
                    .foregroundStyle(DS.Color.Text.accent)
                    .font(.footnote)

                Image(DS.Icon.icChevronUpFilled)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .square(size: 16)
                    .foregroundColor(DS.Color.Text.accent)
            }
        }
    }

    var senderNameText: some View {
        HStack(alignment: .firstTextBaseline, spacing: .zero) {
            if !isHeaderCollapsed {
                Text(L10n.MessageDetails.from)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.Text.norm)
                    .transition(
                        .move(edge: .leading)
                            .combined(with: .opacity)
                    )
            }
            Text(uiModel.sender.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
                .foregroundColor(DS.Color.Text.norm)
                .accessibilityIdentifier(MessageDetailsViewIdentifiers.senderName)
        }
    }

    private var senderView: some View {
        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.compact) {
            senderNameText
            ProtonOfficialBadgeView()
                .removeViewIf(!uiModel.isSenderProtonOfficial)
                .accessibilityIdentifier(MessageDetailsViewIdentifiers.officialBadge)
        }
    }

    private var senderAddressView: some View {
        Text(uiModel.sender.address)
            .font(.caption)
            .multilineTextAlignment(.leading)
            .foregroundColor(isHeaderCollapsed ? DS.Color.Text.weak : DS.Color.Text.accent)
            .accessibilityIdentifier(MessageDetailsViewIdentifiers.senderAddress)
    }

    private var recipientsView: some View {
        Button {
            withAnimation {
                isHeaderCollapsed.toggle()
            }
        } label: {
            HStack(spacing: DS.Spacing.small) {
                Text(uiModel.recipients.recipientsUIRepresentation)
                    .foregroundColor(DS.Color.Text.weak)
                    .font(.caption)
                    .lineLimit(1)
                    .accessibilityIdentifier(MessageDetailsViewIdentifiers.recipientsSummary)
                if isHeaderCollapsed {
                    Image(DS.Icon.icChevronDownFilled)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .square(size: 16)
                        .foregroundColor(DS.Color.Icon.weak)
                }
            }
        }
    }

    private var headerActionsView: some View {
        HStack(alignment: .top, spacing: DS.Spacing.small) {
            headerActionButton(
                action: { await onEvent(.onMessageAction(uiModel.isSingleRecipient ? .reply : .replyAll)) },
                image: Image(symbol: uiModel.isSingleRecipient ? .reply : .replyAll)
            )
            MessageActionsMenu(
                state: .initial(messageID: uiModel.id, showEditToolbar: false),
                mailbox: mailbox,
                messageAppearanceOverrideStore: messageAppearanceOverrideStore!,
                actionTapped: { action in await onEvent(.onMessageAction(action)) },
                editToolbarTapped: { Task { await onEvent(.onEditToolbar) } }
            ) {
                DS.Icon.icThreeDotsHorizontal.image
                    .square(size: 20)
                    .foregroundStyle(actionButtonsState.isDisabled ? DS.Color.Text.disabled : DS.Color.Text.weak)
                    .square(size: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.mediumLarge)
                            .stroke(DS.Color.Border.norm, lineWidth: 1)
                    )
            }
            .disabled(actionButtonsState.isDisabled)
            .id(uiModel)
        }
        .foregroundColor(DS.Color.Icon.weak)
    }

    private func headerActionButton(action: @escaping () async -> Void, image: Image) -> some View {
        Button(action: { Task { await action() } }) {
            image
                .square(size: 20)
                .foregroundStyle(actionButtonsState.isDisabled ? DS.Color.Icon.disabled : DS.Color.Icon.weak)
        }
        .square(size: 36)
        .disabled(actionButtonsState.isDisabled)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.mediumLarge)
                .stroke(DS.Color.Border.norm, lineWidth: 1)
        )
    }

    private func recipientRow(_ group: RecipientGroup, recipients: [MessageDetail.Recipient]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.standard) {
            ForEachEnumerated(recipients, id: \.element) { recipient, index in
                recipientButton(
                    recipient: recipient,
                    group: group,
                    prefixed: group != .to && index == 0,
                    index: index
                )
            }
        }
    }

    private func recipientButton(
        recipient: MessageDetail.Recipient,
        group: RecipientGroup,
        prefixed: Bool,
        index: Int
    ) -> some View {
        Button {
            Task {
                await onEvent(.onRecipientTap(recipient))
            }
        } label: {
            VStack(alignment: .leading, spacing: DS.Spacing.compact) {
                recipientName(recipient: recipient, group: group, prefixed: prefixed)
                    .accessibilityIdentifier(MessageDetailsViewIdentifiers.expandedHeaderRecipientName(group: group, index: index))
                Text(recipient.address)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.accent)
                    .accessibilityIdentifier(MessageDetailsViewIdentifiers.expandedHeaderRecipientValue(group: group, index: index))
            }
            .multilineTextAlignment(.leading)
        }
    }

    private func recipientName(
        recipient: MessageDetail.Recipient,
        group: RecipientGroup,
        prefixed: Bool,
    ) -> some View {
        let name: Text = Text(recipient.name)
            .font(.caption)
            .foregroundStyle(DS.Color.Text.weak)

        if prefixed {
            let prefix = Text(group.humanReadable)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(DS.Color.Text.norm)
            return prefix + name
        } else {
            return name
        }
    }

    @ViewBuilder
    private var trackersRow: some View {
        InfoRowWithLearnMore(
            title: trackers.loadedValue?.fullTitle ?? .randomPlaceholder(length: 24),
            iconView: {
                Image(symbol: .checkmarkShieldFill)
            },
            iconColor: DS.Color.Text.norm,
            redactIcon: false,
            action: { Task { await onEvent(.onTrackersTap) } }
        )
        .if(trackers.isLoading) { view in
            view.redacted(true)
                .fadingEffect()
                .transition(.opacity)
        }
    }

    private var dateRow: some View {
        HStack(alignment: .center, spacing: DS.Spacing.small) {
            Image(DS.Images.calendarToday)
                .resizable()
                .square(size: 14)

            Text(MessageDetailsDateFormatter.string(from: uiModel.date))
                .font(.caption)
                .foregroundStyle(DS.Color.Text.norm)
                .accessibilityIdentifier(MessageDetailsViewIdentifiers.expandedHeaderDateValue)
            Spacer()
        }
    }

    @ViewBuilder
    private var locationRow: some View {
        if let model = uiModel.location {
            HStack(alignment: .center, spacing: DS.Spacing.small) {
                model.icon
                    .resizable()
                    .square(size: 14)

                Text(model.name)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.norm)
                Spacer()
            }
        }
    }

    private var labelRow: some View {
        HStack(alignment: .center, spacing: DS.Spacing.small) {
            BadgesView(
                badges: uiModel.labels.map { label in Badge(text: label.text, color: label.color) }
            )
            Spacer()
        }
    }
}

private enum RecipientGroup {
    case to
    case cc
    case bcc

    var humanReadable: LocalizedStringResource {
        switch self {
        case .to:
            L10n.MessageDetails.to
        case .cc:
            L10n.MessageDetails.cc
        case .bcc:
            L10n.MessageDetails.bcc
        }
    }

    var accessibilityValue: String {
        switch self {
        case .to:
            "to"
        case .cc:
            "cc"
        case .bcc:
            "bcc"
        }
    }
}

struct MessageDetailsUIModel: Hashable {
    let id: ID
    let avatar: AvatarUIModel
    let sender: MessageDetail.Sender
    let isSenderProtonOfficial: Bool
    var recipients: [MessageDetail.Recipient] {
        recipientsTo + recipientsCc + recipientsBcc
    }
    let recipientsTo: [MessageDetail.Recipient]
    let recipientsCc: [MessageDetail.Recipient]
    let recipientsBcc: [MessageDetail.Recipient]
    var isSingleRecipient: Bool {
        recipientsTo.count + recipientsCc.count + recipientsBcc.count == 1
    }
    let date: Date
    let location: MessageDetail.Location?
    let labels: [LabelUIModel]
    let isStarred: Bool
    let showPaperClip: Bool
}

extension MessageDetailsUIModel {
    var recipientsToExcludingFirst: [MessageDetail.Recipient] {
        Array(recipientsTo.dropFirst())
    }
}

enum MessageDetail {
    struct Sender: Hashable {
        let name: String
        let address: String
        let encryptionInfo: String
    }

    struct Recipient: Identifiable, Hashable {
        var id: String { address }  // Identifiable needed to present the action sheet
        let name: String
        let address: String
        let avatarInfo: AvatarInfo
    }

    struct Location: Hashable {
        let id: ID
        let name: LocalizedStringResource
        let icon: Image
        let iconColor: Color?

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

enum MessageDetailsEvent {
    case onTap
    case onMessageAction(MessageAction)
    case onEditToolbar
    case onSenderTap
    case onRecipientTap(MessageDetail.Recipient)
    case onTrackersTap
}

extension Array where Element == MessageDetail.Recipient {
    var recipientsUIRepresentation: String {
        let recipients = map(\.name).joined(separator: ", ")
        return L10n.MessageDetails.to.string + recipients
    }
}

#Preview {
    let model = MessageDetailsPreviewProvider.testData(
        location: .custom(name: "Online shopping", id: .init(value: 1), color: .init(value: "FFA500")),
        labels: [
            .init(labelId: .init(value: 1), text: "Friends and Holidays", color: .blue),
            .init(labelId: .init(value: 2), text: "Work", color: .green),
            .init(labelId: .init(value: 3), text: "Summer trip", color: .pink),
        ])

    MessageDetailsView(
        isHeaderCollapsed: false,
        uiModel: model,
        trackers: .loaded(MessageDetailsPreviewProvider.testTrackers),
        mailbox: .dummy,
        actionButtonsState: .enabled,
        onEvent: { _ in }
    )
}

enum MessageDetailsPreviewProvider {
    static var recipientsTo: [MessageDetail.Recipient] {
        [
            .init(
                name: "⭐ veryVeryLongEmailAddress1234567890123456@pm.me", address: "veryVeryLongEmailAddress1234567890123456@pm.me",
                avatarInfo: .init(initials: "E", color: .red)
            ),
            .init(
                name: "James Hayes", address: "james@proton.me",
                avatarInfo: .init(initials: "J", color: .red)
            ),
        ]
    }

    static var recipientsCc: [MessageDetail.Recipient] {
        [
            .init(name: "James Hayes", address: "james@proton.me", avatarInfo: .init(initials: "J", color: .red)),
            .init(name: "Riley Scott", address: "scott375@gmail.com", avatarInfo: .init(initials: "R", color: .red)),
            .init(name: "Layla Robinson", address: "layla.rob@protonmail.ch", avatarInfo: .init(initials: "L", color: .red)),
        ]
    }

    static var recipientsBcc: [MessageDetail.Recipient] {
        [
            .init(name: "Isabella Coleman", address: "isa_coleman@protonmail.com", avatarInfo: .init(initials: "I", color: .red))
        ]
    }

    static func testData(
        sender: MessageDetail.Sender = .init(
            name: "Camila Hall",
            address: "camila.hall@protonmail.ch",
            encryptionInfo: "End to end encrypted and signed"
        ),
        location: ExclusiveLocation?,
        labels: [LabelUIModel],
        recipientsTo: [MessageDetail.Recipient] = recipientsTo,
        recipientsCc: [MessageDetail.Recipient] = recipientsCc,
        recipientsBcc: [MessageDetail.Recipient] = recipientsBcc
    ) -> MessageDetailsUIModel {
        .init(
            id: ID.random(),
            avatar: .init(
                info: .init(initials: "", color: DS.Color.Background.secondary),
                type: .sender(.init(params: .init(), blocked: .yes))
            ),
            sender: sender,
            isSenderProtonOfficial: true,
            recipientsTo: recipientsTo,
            recipientsCc: recipientsCc,
            recipientsBcc: recipientsBcc,
            date: Date(timeIntervalSince1970: 1_724_347_300),
            location: location?.model,
            labels: labels,
            isStarred: false,
            showPaperClip: false
        )
    }

    static var testTrackers: TrackersUIModel {
        .init(
            blockedTrackers: [
                TrackerDomain(name: "example.com", urls: ["https://example.com/1"])
            ],
            cleanedLinks: [
                CleanedLink(original: "https://example.com?utm=1", cleaned: "https://example.com"),
                CleanedLink(original: "https://example.com?utm=2", cleaned: "https://example.com"),
            ]
        )
    }
}

private struct MessageDetailsViewIdentifiers {
    static let senderName = "detail.header.sender.name"
    static let officialBadge = "detail.header.icon.badge"
    static let messageDate = "detail.header.date"
    static let senderAddress = "detail.header.sender.address"
    static let recipientsSummary = "detail.header.recipients.summary"

    static func expandedHeaderRecipientName(group: RecipientGroup, index: Int) -> String {
        "details.header.expanded.\(group.accessibilityValue).name#\(index)"
    }

    static func expandedHeaderRecipientValue(group: RecipientGroup, index: Int) -> String {
        "details.header.expanded.\(group.accessibilityValue).value#\(index)"
    }

    static let expandedHeaderDateValue = "detail.header.expanded.date.value"
}

private extension TrackersUIModel {
    var title: LocalizedStringResource {
        blockedTrackers.isEmpty ? L10n.MessageDetails.noTrackersDetected : L10n.MessageDetails.trackerProtection
    }

    var count: String {
        var values: [String] = []

        if totalTrackersCount > 0 {
            values.append(L10n.MessageDetails.trackersBlocked(count: totalTrackersCount).string)
        }
        if totalLinksCount > 0 {
            values.append(L10n.MessageDetails.linksCleaned(count: totalLinksCount).string)
        }
        let formatter = ListFormatter()
        return formatter.string(from: values) ?? .empty
    }

    var fullTitle: String {
        if isEmpty {
            return title.string
        } else {
            return title.string + "\n" + count
        }
    }
}
