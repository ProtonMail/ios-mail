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
    let onTapEvent: ((String) -> Void)?
    
    /// Maximum number of attachment capsules to try to show for each horizontal size class
    private var maxNumberOfCapsules: CGFloat {
        horizontalSizeClass == .compact ? 3 : 5
    }

    init(uiModel: [AttachmentCapsuleUIModel], onTapEvent: ((String) -> Void)? = nil) {
        self.uiModel = uiModel
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
                ForEach(items) { item in
                    AttachmentCapsuleView(uiModel: item, maxWidth: capsuleMaxWidth, onTapEvent: onTapEvent)
                }
            }
            let extraAttachments = min(99, uiModel.count - limit)
            Text("+\(extraAttachments)")
                .frame(width: Layout.extraAttachmentsViewWidth)
                .fixedSize()
                .font(.caption2)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.textWeak)
                .padding(.trailing, 10)
                .removeViewIf(extraAttachments < 1 )
        }
    }
}

struct AttachmentCapsuleUIModel: Identifiable, Hashable {
    var id: String {
        attachmentId
    }
    let attachmentId: String
    let icon: UIImage
    let name: String
}

struct AttachmentCapsuleView: View {
    let uiModel: AttachmentCapsuleUIModel
    let maxWidth: CGFloat
    let onTapEvent: ((String) -> Void)?

    private let padding = EdgeInsets(
        top: 8.0, leading: Layout.capsuleHPadding, bottom: 8.0, trailing: Layout.capsuleHPadding
    )

    var body: some View {
        Button(action: {
            onTapEvent?(uiModel.attachmentId)
        }) {
            HStack(spacing: Layout.capsuleSpacing) {
                Image(uiImage: uiModel.icon)
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Layout.capsuleIconSideSize, height: Layout.capsuleIconSideSize)
                Text(uiModel.name)
                    .font(.caption2)
                    .fontWeight(.regular)
                    .tint(DS.Color.textNorm)
                    .lineLimit(1)
                    .frame(maxWidth: maxWidth)
                    .fixedSize()
                    .truncationMode(.middle)
            }
            .padding(padding)
            .background(
                ZStack {
                    Capsule()
                        .strokeBorder(DS.Color.backgroundDeep, lineWidth: 1)
                }
            )
        }
        .buttonStyle(AttachmentCapsuleStyle())
    }
}

private struct AttachmentCapsuleStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration
          .label
          .background(configuration.isPressed ? Capsule().fill(DS.Color.backgroundSecondary) : Capsule().fill(DS.Color.backgroundNorm))
  }

}

fileprivate enum Layout {
    static let spacingBetweenCapsules = 10.0
    static let extraAttachmentsViewWidth = 22.0
    static let capsuleHPadding = 12.0
    static let capsuleIconSideSize = 14.0
    static let capsuleSpacing = 4.0
}

#Preview {
    VStack {
        AttachmentsView(
            uiModel:[
                .init(attachmentId: "1", icon: DS.Icon.icFileTypePages, name: "single_attachment_super_long_title_that_goes_beyond_the_half_width_of_a_big_iphone_in_landscape.pdf")
            ]
        )
        .border(.red)

        AttachmentsView(
            uiModel:[
                .init(attachmentId: "1", icon: DS.Icon.icFileTypeIconPdf, name: "1.pdf"),
                .init(attachmentId: "2", icon: DS.Icon.icFileTypeIconImage, name: "2.png"),
                .init(attachmentId: "3", icon: DS.Icon.icFileTypeIconExcel, name: "3.xls"),
                .init(attachmentId: "4", icon: DS.Icon.icFileTypeIconWord, name: "4.doc"),
                .init(attachmentId: "5", icon: DS.Icon.icFileTypeIconCode, name: "5.bash"),
                .init(attachmentId: "6", icon: DS.Icon.icFileTypeIconWord, name: "6.pdf"),
                .init(attachmentId: "7", icon: DS.Icon.icFileTypeIconCode, name: "7.png"),
                .init(attachmentId: "8", icon: DS.Icon.icFileTypeIconWord, name: "8.xls"),
            ]
        )
        .border(.red)

        AttachmentsView(
            uiModel:[
                .init(attachmentId: "1", icon: DS.Icon.icFileTypeIconPdf, name: "super_long_title_that_goes_beyond_half.pdf"),
                .init(attachmentId: "2", icon: DS.Icon.icFileTypeIconImage, name: "quite.png"),
                .init(attachmentId: "3", icon: DS.Icon.icFileTypeIconExcel, name: "numebrs.xls"),
                .init(attachmentId: "4", icon: DS.Icon.icFileTypeIconWord, name: "words.doc"),
                .init(attachmentId: "5", icon: DS.Icon.icFileTypeIconCode, name: "scripts.bash"),
            ]
        )
        .frame(width: 300)
        .border(.red)
    }
}
