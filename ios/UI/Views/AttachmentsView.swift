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

import DesignSystem
import SwiftUI

struct AttachmentsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let uiModel: [AttachmentCapsuleUIModel]
    let isAttachmentHighlightEnabled: Bool
    let onTapEvent: ((PMLocalAttachmentId) -> Void)?

    /// Maximum number of attachment capsules to try to show for each horizontal size class
    private var maxNumberOfCapsules: CGFloat {
        horizontalSizeClass == .compact ? 3 : 5
    }

    init(
        uiModel: [AttachmentCapsuleUIModel],
        isAttachmentHighlightEnabled: Bool = false,
        onTapEvent: ((PMLocalAttachmentId) -> Void)? = nil
    ) {
        self.uiModel = uiModel
        self.isAttachmentHighlightEnabled = isAttachmentHighlightEnabled
        self.onTapEvent = onTapEvent
    }

    var body: some View {
        GeometryReader { geometry in
            let spaceForCapsules = geometry.size.width
            - (maxNumberOfCapsules*Layout.spacingBetweenCapsules) - Layout.extraAttachmentsViewWidth
            let capsuleMaxWidth = uiModel.count == 1 ? spaceForCapsules : spaceForCapsules/CGFloat(maxNumberOfCapsules)

            /**
             SwiftUI does not make it easy to calculate dynamically to fit the maximum number of capsules. After trying
             different approaches to compute the view, we end up with setting a maximum number of potential attachments and
             use `ViewThatFits` to decide which one to render. We default to just showing 1 if no other limit works.
             */
            ViewThatFits(in: .horizontal) {
                hStackWithAttachments(limit: Int(maxNumberOfCapsules), capsuleMaxWidth: capsuleMaxWidth)
                hStackWithAttachments(limit: Int(maxNumberOfCapsules) - 1, capsuleMaxWidth: capsuleMaxWidth)
                hStackWithAttachments(limit: 1, capsuleMaxWidth: spaceForCapsules)
            }
        }
        .frame(height: 32)
    }

    func hStackWithAttachments(limit: Int, capsuleMaxWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: Layout.spacingBetweenCapsules) {
                let items = uiModel.prefix(limit)
                ForEach(Array(items.enumerated()), id: \.1.id) { index, item in
                    AttachmentCapsuleView(
                        uiModel: item,
                        maxWidth: capsuleMaxWidth,
                        isAttachmentHighlightEnabled: isAttachmentHighlightEnabled,
                        onTapEvent: onTapEvent
                    )
                    .accessibilityIdentifier(AttachmentsViewIdentifiers.attachmentCapsule(forIndex: index))
                }
            }
            let extraAttachments = min(99, uiModel.count - limit)
            Text("+\(extraAttachments)".notLocalized)
                .frame(width: Layout.extraAttachmentsViewWidth, alignment: .leading)
                .fixedSize()
                .font(.caption2)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.Text.weak)
                .padding(.leading, DS.Spacing.small)
                .accessibilityIdentifier(AttachmentsViewIdentifiers.extraAttachments)
                .removeViewIf(extraAttachments < 1 )
        }
    }
}

struct AttachmentCapsuleUIModel: Identifiable, Hashable {
    var id: PMLocalAttachmentId {
        attachmentId
    }
    let attachmentId: PMLocalAttachmentId
    let icon: ImageResource
    let name: String
}

struct AttachmentCapsuleView: View {
    let uiModel: AttachmentCapsuleUIModel
    let maxWidth: CGFloat
    let isAttachmentHighlightEnabled: Bool
    let onTapEvent: ((PMLocalAttachmentId) -> Void)?

    private let padding = EdgeInsets(
        top: DS.Spacing.standard, leading: Layout.capsuleHPadding, bottom: DS.Spacing.standard, trailing: Layout.capsuleHPadding
    )

    var body: some View {
        Button(action: {
            onTapEvent?(uiModel.attachmentId)
        }) {
            HStack(spacing: Layout.capsuleSpacing) {
                Image(uiModel.icon)
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Layout.capsuleIconSideSize, height: Layout.capsuleIconSideSize)
                Text(uiModel.name)
                    .font(.caption)
                    .fontWeight(.regular)
                    .tint(DS.Color.Text.norm)
                    .lineLimit(1)
                    .frame(maxWidth: maxWidth)
                    .fixedSize()
                    .truncationMode(.middle)
            }
            .padding(padding)
            .background(
                ZStack {
                    Capsule()
                        .strokeBorder(DS.Color.Border.strong, lineWidth: 1)
                }
            )
        }
        .buttonStyle(AttachmentCapsuleStyle(isEnabled: isAttachmentHighlightEnabled))
    }
}

private struct AttachmentCapsuleStyle: ButtonStyle {
    private let isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        if isEnabled {
            configuration
                .label
                .background(
                    configuration.isPressed
                    ? Capsule().fill(DS.Color.Background.deep)
                    : Capsule().fill(DS.Color.Background.norm)
                )
        } else {
            configuration.label
        }
    }
}

fileprivate enum Layout {
    static let spacingBetweenCapsules = DS.Spacing.tiny
    static let extraAttachmentsViewWidth = 42.0
    static let capsuleHPadding = DS.Spacing.medium
    static let capsuleIconSideSize = 14.0
    static let capsuleSpacing = DS.Spacing.standard
}

#Preview {
    VStack {
        AttachmentsView(
            uiModel:[
                .init(attachmentId: 1, icon: DS.Icon.icFileTypePages, name: "single_attachment_super_long_title_that_goes_beyond_the_half_width_of_a_big_iphone_in_landscape.pdf")
            ]
        )
        .border(.red)

        AttachmentsView(
            uiModel:[
                .init(attachmentId: 1, icon: DS.Icon.icFileTypeIconPdf, name: "1.pdf"),
                .init(attachmentId: 2, icon: DS.Icon.icFileTypeIconImage, name: "2.png"),
                .init(attachmentId: 3, icon: DS.Icon.icFileTypeIconExcel, name: "3.xls"),
                .init(attachmentId: 4, icon: DS.Icon.icFileTypeIconWord, name: "4.doc"),
                .init(attachmentId: 5, icon: DS.Icon.icFileTypeIconCode, name: "5.bash"),
                .init(attachmentId: 6, icon: DS.Icon.icFileTypeIconWord, name: "6.pdf"),
                .init(attachmentId: 7, icon: DS.Icon.icFileTypeIconCode, name: "7.png"),
                .init(attachmentId: 8, icon: DS.Icon.icFileTypeIconWord, name: "8.xls"),
            ]
        )
        .border(.red)

        AttachmentsView(
            uiModel:[
                .init(attachmentId: 1, icon: DS.Icon.icFileTypeIconPdf, name: "super_long_title_that_goes_beyond_half.pdf"),
                .init(attachmentId: 2, icon: DS.Icon.icFileTypeIconImage, name: "quite.png"),
                .init(attachmentId: 3, icon: DS.Icon.icFileTypeIconExcel, name: "numebrs.xls"),
                .init(attachmentId: 4, icon: DS.Icon.icFileTypeIconWord, name: "words.doc"),
                .init(attachmentId: 5, icon: DS.Icon.icFileTypeIconCode, name: "scripts.bash"),
            ]
        )
        .frame(width: 300)
        .border(.red)
    }
}

private struct AttachmentsViewIdentifiers {
    static func attachmentCapsule(forIndex index: Int) -> String {
        "attachment.capsule#\(index)"
    }
    
    static let extraAttachments = "attachment.extraIndicator"
}
