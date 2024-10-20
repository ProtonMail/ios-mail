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

struct AttachmentsCarouselView: View {

    private let attachments: [AttachmentDisplayModel]

    init(attachments: [AttachmentDisplayModel]) {
        self.attachments = attachments
    }

    var body: some View {
        VStack(spacing: DS.Spacing.standard) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Spacing.standard) {
                    ForEach(attachments, id: \.self) { attachment in
                        attachmentView(attachment: attachment)
                    }
                }
            }
        }
    }

    func attachmentView(attachment: AttachmentDisplayModel) -> some View {
        HStack(spacing: DS.Spacing.standard) {
            Image(attachment.mimeType.category.icon)
                .resizable()
                .square(size: 32)
            VStack(alignment: .leading, spacing: DS.Spacing.tiny) {
                Text(attachment.name)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundStyle(DS.Color.Text.weak)
                Text(attachment.mimeType.mime)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(DS.Color.Text.hint)
            }
        }
        .padding(.all, DS.Spacing.medium)
        .frame(width: 155, alignment: .leading)
        .background(DS.Color.InteractionWeak.norm)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.extraLarge))
        .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .strokeBorder(DS.Color.Border.strong, lineWidth: 1)
        }
    }

}


#Preview {
    AttachmentsCarouselView(attachments:
        [
            .init(id: .init(value: 1), mimeType: .init(mime: "pdf", category: .pdf), name: "CV", size: 1200),
            .init(id: .init(value: 2), mimeType: .init(mime: "img", category: .image), name: "My photo", size: 12000),
            .init(id: .init(value: 3), mimeType: .init(mime: "doc", category: .pages), name: "Covering letter", size: 120000),
        ]
    )
}
