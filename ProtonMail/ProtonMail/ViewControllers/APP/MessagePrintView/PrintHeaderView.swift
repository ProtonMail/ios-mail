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

import UIKit

final class PrintHeaderView: UIView {
    weak var recipientDelegate: RecipientViewDelegate?

    init(headerData: HeaderData, recipientDelegate: RecipientViewDelegate?) {
        self.recipientDelegate = recipientDelegate
        super.init(frame: .zero)
        backgroundColor = .white
        overrideUserInterfaceStyle = .light

        [
            heightAnchor.constraint(equalToConstant: 0).setPriority(as: .defaultLow),
            widthAnchor.constraint(equalToConstant: 560)
        ].activate()
        setComponents(headerData: headerData)
        layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func using12hClockFormat() -> Bool {

        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)

        return !(pmRange == nil && amRange == nil)
    }
}

extension PrintHeaderView {
    struct Constants {
        static let margin: CGFloat = 6
        static let titleTopMargin: CGFloat = 12
        static let recipientLeftMargin: CGFloat = 40
        static let recipientRowHeight: CGFloat = 30
        static let separatorBetweenHeaderAndBodyMarginTop: CGFloat = 16
        static let k12HourMinuteFormat = "h:mm a"
        static let k24HourMinuteFormat = "HH:mm"
    }

    private func setComponents(headerData: HeaderData) {
        let titleLabel = setTitleLabel(title: headerData.title)
        let fromRow = setRecipientRow(
            prompt: LocalString._general_from_label,
            contacts: [headerData.sender],
            under: titleLabel
        )
        var lowestElement: UIView = fromRow
        if let to = headerData.to, !to.isEmpty {
            lowestElement = setRecipientRow(
                prompt: "\(LocalString._general_to_label):",
                contacts: to,
                under: lowestElement
            )
        }
        if let cc = headerData.cc, !cc.isEmpty {
            lowestElement = setRecipientRow(
                prompt: "\(LocalString._general_cc_label):",
                contacts: cc,
                under: lowestElement
            )
        }
        if let bcc = headerData.bcc, !bcc.isEmpty {
            lowestElement = setRecipientRow(
                prompt: "\(LocalString._general_bcc_label)",
                contacts: bcc,
                under: lowestElement
            )
        }
        if let time = headerData.time {
            lowestElement = setTimeLabel(date: time, under: lowestElement)
        }
        if let labels = headerData.labels {
            let validLabels = labels.filter { $0.type == .messageLabel && !($0.name.isEmpty || $0.color.isEmpty) }
            lowestElement = setLabelsView(labels: validLabels, under: lowestElement)
        }
        lowestElement = setSeparator(under: lowestElement)
    }

    private func setTitleLabel(title: String) -> UILabel {
        let label = SubviewsFactory.messageTitleLabel()
        label.text = title
        addSubviews(label)

        [
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: Constants.titleTopMargin),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ].activate()
        return label
    }

    private func setRecipientRow(prompt: String, contacts: [ContactVO], under aboveElement: UIView) -> UIView {
        let container = UIView(frame: .zero)

        let promptLabel = SubviewsFactory.promptLabel(title: prompt)

        addSubview(container)
        [
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.topAnchor.constraint(equalTo: aboveElement.bottomAnchor, constant: Constants.margin)
        ].activate()

        container.addSubview(promptLabel)
        [
            promptLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            promptLabel.topAnchor.constraint(equalTo: container.topAnchor)
        ].activate()

        let recipientsTable = SubviewsFactory.recipientsTable(contacts: contacts)
        recipientsTable.delegate = recipientDelegate
        container.addSubviews(recipientsTable)

        [
            recipientsTable.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: Constants.recipientLeftMargin
            ),
            recipientsTable.trailingAnchor.constraint(equalTo: trailingAnchor),
            recipientsTable.topAnchor.constraint(equalTo: container.topAnchor),
            recipientsTable.heightAnchor.constraint(
                equalToConstant: CGFloat(contacts.count) * Constants.recipientRowHeight
            ),
            recipientsTable.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ].activate()
        _ = recipientsTable.getContentSize()
        return container
    }

    private func setTimeLabel(date: Date, under element: UIView) -> UILabel {
        let timeFormat = using12hClockFormat() ? Constants.k12HourMinuteFormat : Constants.k24HourMinuteFormat
        let timeString = String(
            format: LocalString._composer_forward_header_on_detail,
            date.formattedWith("E, MMM d, yyyy"),
            date.formattedWith(timeFormat)
        )

        let dateLabel = SubviewsFactory.dateLabel()
        dateLabel.text = String(format: LocalString._date, timeString)

        addSubview(dateLabel)
        [
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            dateLabel.topAnchor.constraint(equalTo: element.bottomAnchor, constant: Constants.margin)
        ].activate()
        return dateLabel
    }

    private func setLabelsView(labels: [LabelEntity], under element: UIView) -> LabelsCollectionView {
        let labelsView = SubviewsFactory.labelsView()
        labelsView.update(labels)

        addSubviews(labelsView)
        [
            labelsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelsView.topAnchor.constraint(equalTo: element.bottomAnchor, constant: Constants.margin)
        ].activate()
        let height = labelsView.getContentSize().height
        [
            labelsView.heightAnchor.constraint(equalToConstant: height)
        ].activate()
        return labelsView
    }

    private func setSeparator(under element: UIView) -> UIView {
        let separator = SubviewsFactory.separator()
        addSubview(separator)

        [
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            separator.topAnchor.constraint(
                equalTo: element.bottomAnchor,
                constant: Constants.separatorBetweenHeaderAndBodyMarginTop
            ),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor)
        ].activate()
        return separator
    }
}

private struct SubviewsFactory {

    static func messageTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = Fonts.h4.medium
        label.adjustsFontForContentSizeCategory = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = UIColor(RRGGBB: UInt(0x505061))
        return label
    }

    static func promptLabel(title: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = Fonts.h6.medium
        label.textColor = UIColor(hexColorCode: "#C0C4CE")
        label.text = title
        return label
    }

    static func recipientsTable(contacts: [ContactVO]) -> RecipientView {
        let table = RecipientView(frame: .zero)
        table.contacts = contacts
        return table
    }

    static func dateLabel() -> UILabel {
        let label = UILabel()
        label.font = Fonts.h6.medium
        label.numberOfLines = 1
        label.textColor = UIColor(RRGGBB: UInt(0x838897))
        return label
    }

    static func labelsView() -> LabelsCollectionView {
        let view = LabelsCollectionView(frame: .zero)
        return view
    }

    static func separator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = UIColor(RRGGBB: UInt(0xC9CED4))
        return separator
    }
}
