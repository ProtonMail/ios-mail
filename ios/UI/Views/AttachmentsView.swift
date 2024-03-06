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
    let uiModel: [AttachmentCapsuleUIModel]
    let onTapEvent: ((String) -> Void)?

    init(uiModel: [AttachmentCapsuleUIModel], onTapEvent: ((String) -> Void)? = nil) {
        self.uiModel = uiModel
        self.onTapEvent = onTapEvent
    }

    var body: some View {
        GeometryReader { geometry in
            let maxCapsuleWidth = geometry.size.width/2

            /**
             We tried different approaches to compute the view but SwiftUI does not make it easy to
             implement the design specs. We also tried this ViewThatFits solution limiting the total number
             of preview attachments to a maximum of 3, but the scrolling was stuttering.
             Work on a performant solution that allows to show a dynamic number of attachments
             */
//            ViewThatFits(in: .horizontal) {
//                hStackWithAttachments(limit: 3, capsuleMaxWidth: maxCapsuleWidth)
//                hStackWithAttachments(limit: 2, capsuleMaxWidth: maxCapsuleWidth)
                hStackWithAttachments(limit: 1, capsuleMaxWidth: maxCapsuleWidth)
//            }
        }
        .frame(height: 32)
    }

    func hStackWithAttachments(limit: Int, capsuleMaxWidth: CGFloat) -> some View {
        HStack {
            HStack {
                let items = uiModel.prefix(limit)
                ForEach(items) { item in
                    AttachmentCapsuleView(uiModel: item, maxWidth: capsuleMaxWidth, onTapEvent: onTapEvent)
                }
            }
            let extraAttachments = uiModel.count - limit
            Text("+\(extraAttachments)")
                .fixedSize()
                .font(.caption2)
                .fontWeight(.regular)
                .foregroundStyle(DS.Color.textWeak)
                .padding(.trailing, 10)
                .layoutPriority(1)
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

    private let iconSide: CGFloat = 14.0
    private let padding = EdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0)

    var body: some View {
        Button(action: {
            onTapEvent?(uiModel.attachmentId)
        }) {
            HStack(spacing: 4) {
                Image(uiImage: uiModel.icon)
                    .resizable()
                    .renderingMode(.original)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: iconSide, height: iconSide)
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


#Preview {
    VStack {
        AttachmentsView(
            uiModel:[
                .init(attachmentId: "1", icon: DS.Icon.icFileTypeIconPdf, name: "1.pdf")
            ]
        )
        .frame(width: 300)
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
                .init(attachmentId: "9", icon: DS.Icon.icFileTypeIconCode, name: "9.doc"),
                .init(attachmentId: "10", icon: DS.Icon.icFileTypeIconCode, name: "10.bash"),
            ]
        )
        .frame(width: 300)
        .border(.red)
        AttachmentsView(
            uiModel:[
                .init(attachmentId: "1", icon: DS.Icon.icFileTypeIconPdf, name: "super_long_title_that_goes_beyond_half.pdf"),
                .init(attachmentId: "2", icon: DS.Icon.icFileTypeIconImage, name: "quite.png"),
                .init(attachmentId: "3", icon: DS.Icon.icFileTypeIconExcel, name: "3.xls"),
                .init(attachmentId: "4", icon: DS.Icon.icFileTypeIconWord, name: "4.doc"),
                .init(attachmentId: "5", icon: DS.Icon.icFileTypeIconCode, name: "5.bash"),
            ]
        )
        .frame(width: 300)
        .border(.red)
    }
}
