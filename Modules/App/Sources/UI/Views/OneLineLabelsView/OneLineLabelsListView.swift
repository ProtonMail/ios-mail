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

import Foundation
import SwiftUI
import InboxDesignSystem

struct OneLineLabelsListView: View {
    let labels: [LabelUIModel]
    private let labelsSpacing: CGFloat = DS.Spacing.small
    private let horizontalPadding: CGFloat = DS.Spacing.compact
    private let minimalLabelWidth: CGFloat = DS.Spacing.extraLarge
    private let height: CGFloat = 20
    private let font = UIFont.caption2Semibold()

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: labelsSpacing) {
                ForEach(labelsFittingSpace(labels: labels, availableWidth: geometry.size.width), id: \.self) { label in
                    switch label {
                    case .regular(let viewModel):
                        Text(viewModel.text)
                            .font(.from(uiFont: .caption2Semibold()))
                            .foregroundColor(DS.Color.Global.white)
                            .lineLimit(1)
                            .frame(height: height)
                            .frame(minWidth: minimalLabelWidth)
                            .padding(.horizontal, horizontalPadding)
                            .background(viewModel.color)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                    case .count(let count):
                        Text("+\(count)".notLocalized) // FIXME: - Reuse
                            .foregroundStyle(DS.Color.Text.weak)
                            .font(.caption)
                    }
                }
            }
        }.frame(height: height)
    }

    // MARK: - Private

    private enum Label: Hashable {
        case regular(model: LabelUIModel)
        case count(Int)
    }

    @MainActor
    private func labelsFittingSpace(labels: [LabelUIModel], availableWidth: CGFloat) -> [Label] {
        let padding = 2 * horizontalPadding

        var availableWidth: CGFloat = availableWidth
        var labelsToDisplay: [Label] = []

        for label in labels {
            let labelWidth = calculateLabel(label.text, font: font) + padding
            let requiredSpace = labelWidth + labelsSpacing

            if requiredSpace < availableWidth || labelsToDisplay.isEmpty {
                availableWidth -= requiredSpace
                labelsToDisplay.append(.regular(model: label))
            } else {
                labelsToDisplay.append(.count(labels.count - labelsToDisplay.count))
                break
            }
        }

        return labelsToDisplay
    }

    @MainActor
    private func calculateLabel(_ text: String, font: UIFont) -> CGFloat {
        let label = UILabel()
        label.text = text
        label.font = font
        label.numberOfLines = 1
        label.sizeToFit()
        return max(label.frame.width, minimalLabelWidth)
    }
}

private extension UIFont {
    static func caption2Semibold() -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption2)

        let semiboldDescriptor = descriptor.addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold
            ]
        ])

        return UIFont(descriptor: semiboldDescriptor, size: .zero)
    }
}

private extension Font {
    static func from(uiFont: UIFont) -> Font {
        return Font(uiFont as CTFont)
    }
}

#Preview {
    VStack {
        ForEach(OneLineLabelsListViewPreviewDataProvider.labels, id: \.self) { labels in
            OneLineLabelsListView(labels: labels)
        }
        Spacer()
    }.padding()
}
