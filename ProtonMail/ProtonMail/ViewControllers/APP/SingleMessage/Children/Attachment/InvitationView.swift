// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreUIFoundations

final class InvitationView: UIView {
    private let container = SubviewFactory.container
    private let widgetBackground = SubviewFactory.widgetBackground
    private let widgetContainer = SubviewFactory.widgetContainer
    private let titleLabel = SubviewFactory.titleLabel
    private let timeLabel = SubviewFactory.timeLabel
    private let detailsContainer = SubviewFactory.detailsContainer

    private static let eventDurationFormatter: DateIntervalFormatter = {
        let dateFormatter = DateIntervalFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    init() {
        super.init(frame: .zero)

        addSubviews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(container)

        container.addArrangedSubview(widgetBackground)

        widgetBackground.addSubview(widgetContainer)

        widgetContainer.addArrangedSubview(titleLabel)
        widgetContainer.addArrangedSubview(timeLabel)

        container.addArrangedSubview(detailsContainer)
    }

    private func setUpLayout() {
        container.centerInSuperview()
        widgetContainer.centerInSuperview()

        [
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            widgetContainer.topAnchor.constraint(equalTo: widgetBackground.topAnchor, constant: 20),
            widgetContainer.leftAnchor.constraint(equalTo: widgetBackground.leftAnchor, constant: 16)
        ].activate()
    }

    func populate(with eventDetails: EventDetails) {
        titleLabel.set(text: eventDetails.title, preferredFont: .body, weight: .bold, textColor: ColorProvider.TextNorm)

        let durationString = Self.eventDurationFormatter.string(from: eventDetails.startDate, to: eventDetails.endDate)
        timeLabel.set(text: durationString, preferredFont: .subheadline, textColor: ColorProvider.TextNorm)

        detailsContainer.arrangedSubviews.forEach(detailsContainer.removeArrangedSubview)
        detailsContainer.addArrangedSubview(SubviewFactory.calendarRow(calendar: eventDetails.calendar))
        detailsContainer.addArrangedSubview(SubviewFactory.locationRow(location: eventDetails.location))
        detailsContainer.addArrangedSubview(SubviewFactory.participantsRow(participants: eventDetails.participants))
    }
}

private struct SubviewFactory {
    static var container: UIStackView {
        let view = genericStackView
        view.spacing = 8
        return view
    }

    static var widgetBackground: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.setCornerRadius(radius: 24)
        return view
    }

    static var widgetContainer: UIStackView {
        genericStackView
    }

    static var titleLabel: UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        return view
    }

    static var timeLabel: UILabel {
        let view = UILabel()
        view.adjustsFontSizeToFitWidth = true
        return view
    }

    static var detailsContainer: UIStackView {
        let view = genericStackView
        view.spacing = 8
        return view
    }

    static func calendarRow(calendar: EventDetails.Calendar) -> UIView {
        let row = row(icon: \.circleFilled)
        row.iconImageView.tintColor = UIColor(hexColorCode: calendar.iconColor)

        let label = detailsLabel(text: calendar.name)
        row.contentStackView.addArrangedSubview(label)

        return row
    }

    static func locationRow(location: EventDetails.Location) -> UIView {
        let row = row(icon: \.mapPin)

        let label = detailsLabel(text: location.name)
        row.contentStackView.addArrangedSubview(label)

        return row
    }

    static func participantsRow(participants: [EventDetails.Participant]) -> UIView {
        let row = row(icon: \.users)

        for participant in participants {
            let participantStackView = genericStackView
            let label = detailsLabel(text: participant.email)
            participantStackView.addArrangedSubview(label)

            if participant.isOrganizer {
                let organizerLabel = detailsLabel(text: L11n.Event.organizer, textColor: ColorProvider.TextWeak)
                participantStackView.addArrangedSubview(organizerLabel)
            }

            row.contentStackView.addArrangedSubview(participantStackView)
        }

        return row
    }

    private static var genericStackView: UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .equalSpacing
        return view
    }

    private static func row(icon: KeyPath<ProtonIconSet, ProtonIcon>) -> ExpandedHeaderRowView {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = IconProvider[dynamicMember: icon]
        row.contentStackView.spacing = 8
        return row
    }

    private static func detailsLabel(text: String, textColor: UIColor = ColorProvider.TextNorm) -> UILabel {
        let view = UILabel()
        view.set(text: text, preferredFont: .footnote, textColor: textColor)
        return view
    }
}
