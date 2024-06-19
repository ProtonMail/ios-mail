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
import ProtonInboxRSVP
import UIKit

final class InvitationView: UIView {
    private let container = SubviewFactory.container
    private let widgetBackground = SubviewFactory.widgetBackground
    private let widgetContainer = SubviewFactory.widgetContainer
    private let widgetDetailsBackground = SubviewFactory.widgetDetailsBackground
    private let widgetDetailsContainer = SubviewFactory.widgetDetailsContainer
    private let titleLabel = SubviewFactory.titleLabel
    private let timeLabel = SubviewFactory.timeLabel
    private let optionalAttendanceLabel = SubviewFactory.optionalAttendanceLabel
    private let statusContainer = SubviewFactory.statusContainer
    private let statusLabel = SubviewFactory.statusLabel
    private let respondingViewContainer = SubviewFactory.respondingViewContainer
    private let respondingViewStackView = SubviewFactory.respondingViewStackView
    private let widgetSeparator = SubviewFactory.widgetSeparator
    private let openInCalendarButton = SubviewFactory.openInCalendarButton
    private let detailsContainer = SubviewFactory.detailsContainer
    private let participantsRow = SubviewFactory.participantsRow

    var onIntrinsicHeightChanged: (() -> Void)?
    var onParticipantTapped: ((String) -> Void)?
    var onInvitationAnswered: ((AttendeeStatusDisplay) -> Void)?
    var onOpenInCalendarTapped: ((URL) -> Void)?

    private var viewModel: InvitationViewModel? {
        didSet {
            updateParticipantsList()
        }
    }

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

        widgetContainer.addArrangedSubview(widgetDetailsBackground)
        widgetContainer.addArrangedSubview(statusContainer)
        widgetContainer.addArrangedSubview(respondingViewContainer)
        widgetContainer.addArrangedSubview(widgetSeparator)
        widgetContainer.addArrangedSubview(openInCalendarButton)

        widgetDetailsBackground.addSubviews(widgetDetailsContainer)

        widgetDetailsContainer.addArrangedSubview(titleLabel)
        widgetDetailsContainer.addArrangedSubview(timeLabel)
        widgetDetailsContainer.addArrangedSubview(optionalAttendanceLabel)

        statusContainer.addSubview(statusLabel)
        respondingViewContainer.addSubviews(respondingViewStackView)

        // needed to avoid autolayout warnings raised by adding an empty UIStackView
        detailsContainer.isHidden = true
        container.addArrangedSubview(detailsContainer)
    }

    private func setUpLayout() {
        container.centerXInSuperview()
        widgetContainer.fillSuperview()
        widgetDetailsContainer.centerInSuperview()
        statusLabel.centerInSuperview()
        respondingViewStackView.centerInSuperview()

        [
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leftAnchor.constraint(equalTo: leftAnchor, constant: 16),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            widgetDetailsContainer.topAnchor.constraint(equalTo: widgetDetailsBackground.topAnchor, constant: 20),
            widgetDetailsContainer.leftAnchor.constraint(equalTo: widgetDetailsBackground.leftAnchor, constant: 16),

            statusLabel.topAnchor.constraint(equalTo: statusContainer.topAnchor, constant: 23),
            statusLabel.leftAnchor.constraint(equalTo: statusContainer.leftAnchor, constant: 20),

            respondingViewContainer.heightAnchor.constraint(equalToConstant: 100),

            respondingViewStackView.leftAnchor.constraint(equalTo: respondingViewContainer.leftAnchor, constant: 20),

            widgetSeparator.heightAnchor.constraint(equalToConstant: 1),

            openInCalendarButton.heightAnchor.constraint(equalToConstant: 48)
        ].activate()
    }

    func populate(with eventDetails: EventDetails) {
        let viewModel = InvitationViewModel(eventDetails: eventDetails)

        titleLabel.set(text: viewModel.title, preferredFont: .body, weight: .bold, textColor: viewModel.titleColor)
        timeLabel.set(text: viewModel.durationString, preferredFont: .subheadline, textColor: viewModel.titleColor)
        optionalAttendanceLabel.isHidden = viewModel.isOptionalAttendanceLabelHidden
        statusLabel.set(text: viewModel.statusString, preferredFont: .subheadline, textColor: viewModel.titleColor)
        statusContainer.isHidden = viewModel.isStatusViewHidden

        openInCalendarButton.addAction(
            UIAction(identifier: .openInCalendar, handler: { [weak self] _ in
                self?.onOpenInCalendarTapped?(eventDetails.calendarAppDeepLink)
            }),
            for: .touchUpInside
        )

        detailsContainer.clearAllViews()

        if let recurrence = eventDetails.recurrence {
            detailsContainer.addArrangedSubview(SubviewFactory.recurrenceRow(recurrence: recurrence))
        }

        detailsContainer.addArrangedSubview(SubviewFactory.calendarRow(calendar: eventDetails.calendar))

        if let location = eventDetails.location {
            detailsContainer.addArrangedSubview(SubviewFactory.locationRow(location: location))
        }

        if eventDetails.organizer != nil || !eventDetails.invitees.isEmpty {
            detailsContainer.addArrangedSubview(participantsRow)
        }

        detailsContainer.isHidden = false

        self.viewModel = viewModel
    }

    func displayAnsweringStatus(_ status: AttachmentViewModel.RespondingStatus) {
        respondingViewStackView.clearAllViews()

        switch status {
        case .respondingUnavailable:
            break
        case .awaitingUserInput:
            respondingViewStackView.addArrangedSubview(SubviewFactory.attendingPromptLabel)

            let respondingButtonsStackView = SubviewFactory.respondingButtonsStackView

            for action in respondingActions() {
                let button = SubviewFactory.respondingButton(action: action)
                respondingButtonsStackView.addArrangedSubview(button)
            }

            respondingViewStackView.addArrangedSubview(respondingButtonsStackView)
        case .responseIsBeingProcessed:
            let activityIndicator = InCellActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            respondingViewStackView.addArrangedSubview(activityIndicator)
        case .alreadyResponded(let currentAnswer):
            respondingViewStackView.addArrangedSubview(SubviewFactory.attendingPromptLabel)

            let button = SubviewFactory.currentlySelectedAnswerButton
            button.menu = UIMenu(children: respondingActions(except: currentAnswer))
            button.setTitle(currentAnswer.longTitle, for: .normal)
            respondingViewStackView.addArrangedSubview(button)
        }

        respondingViewContainer.isHidden = respondingViewStackView.arrangedSubviews.isEmpty
        onIntrinsicHeightChanged?()
    }

    private func respondingActions(except answerToExclude: AttendeeStatusDisplay? = nil) -> [UIAction] {
        let orderedOptions: [AttendeeStatusDisplay] = [.yes, .no, .maybe]

        return orderedOptions.filter { $0 != answerToExclude }.map { option in
            UIAction(title: option.shortTitle) { [weak self] _ in
                self?.onInvitationAnswered?(option)
            }
        }
    }

    private func updateParticipantsList() {
        guard let viewModel else {
            return
        }

        participantsRow.contentStackView.clearAllViews()

        if let organizer = viewModel.organizer {
            // use UIButton subtitle property once we drop iOS 14
            let titleColorAttribute: [NSAttributedString.Key: UIColor] = [.foregroundColor: ColorProvider.TextNorm]
            let subtitleColorAttribute: [NSAttributedString.Key: UIColor] = [.foregroundColor: ColorProvider.TextWeak]
            let title = NSMutableAttributedString(string: "\(organizer.email)\n", attributes: titleColorAttribute)
            let subtitle = NSAttributedString(string: L10n.Event.organizer, attributes: subtitleColorAttribute)
            title.append(subtitle)

            let organizerButton = makeParticipantButton(participant: organizer)
            organizerButton.setAttributedTitle(title, for: .normal)

            participantsRow.contentStackView.addArrangedSubview(organizerButton)
        }

        for invitee in viewModel.visibleInvitees {
            let participantButton = makeParticipantButton(participant: invitee)
            participantButton.setTitle(invitee.email, for: .normal)
            participantsRow.contentStackView.addArrangedSubview(participantButton)
        }

        if let expansionButtonTitle = viewModel.expansionButtonTitle {
            let action = UIAction { [weak self] _ in
                self?.toggleParticipantListExpansion()
            }

            let button = SubviewFactory.participantListButton(
                titleColor: ColorProvider.TextAccent,
                primaryAction: action
            )

            button.setTitle(expansionButtonTitle, for: .normal)

            participantsRow.contentStackView.addArrangedSubview(button)
        }

        onIntrinsicHeightChanged?()
    }

    private func makeParticipantButton(participant: EventDetails.Participant) -> UIButton {
        let action = UIAction { [weak self] _ in
            self?.onParticipantTapped?(participant.email)
        }

        return SubviewFactory.participantListButton(
            titleColor: ColorProvider.TextNorm,
            primaryAction: action
        )
    }

    private func toggleParticipantListExpansion() {
        viewModel?.toggleParticipantListExpansion()
    }
}

private struct SubviewFactory {
    static var container: UIStackView {
        let view = genericStackView
        view.spacing = 16
        return view
    }

    static var widgetBackground: UIView {
        let view = UIView()
        view.setCornerRadius(radius: 24)
        view.layer.borderColor = ColorProvider.SeparatorNorm
        view.layer.borderWidth = 1
        return view
    }

    static var widgetContainer: UIStackView {
        genericStackView
    }

    static var widgetDetailsBackground: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        return view
    }

    static var widgetDetailsContainer: UIStackView {
        genericStackView
    }

    static var titleLabel: UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }

    static var timeLabel: UILabel {
        let view = UILabel()
        view.adjustsFontSizeToFitWidth = true
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }

    static var optionalAttendanceLabel: UILabel {
        let view = UILabel()
        view.adjustsFontSizeToFitWidth = true
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.set(text: L10n.Event.attendanceOptional, preferredFont: .footnote, textColor: ColorProvider.TextWeak)
        return view
    }

    static var statusContainer: UIView {
        UIView()
    }

    static var statusLabel: UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }

    static var respondingViewContainer: UIView {
        UIView()
    }

    static var respondingViewStackView: UIStackView {
        let view = genericStackView
        view.spacing = 8
        return view
    }

    static var attendingPromptLabel: UILabel {
        let view = UILabel()
        view.set(
            text: L10n.Event.attendingPrompt,
            preferredFont: .footnote,
            weight: .bold,
            textColor: ColorProvider.TextNorm
        )
        return view
    }

    static var respondingButtonsStackView: UIStackView {
        let view = UIStackView()
        view.distribution = .fillEqually
        view.spacing = 4
        return view
    }

    static func respondingButton(action: UIAction?) -> UIButton {
        let view = UIButton(primaryAction: action)
        let height = 40.0
        view.layer.borderColor = ColorProvider.SeparatorNorm
        view.layer.borderWidth = 1
        view.layer.cornerRadius = height / 2
        view.setTitleColor(ColorProvider.TextNorm, for: .normal)
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    static var currentlySelectedAnswerButton: UIButton {
        let view = respondingButton(action: nil)
        // TODO: this is not the best way to do this - move to UIButton.Configuration once we drop iOS 14
        view.semanticContentAttribute = .forceRightToLeft
        view.setImage(IconProvider.chevronDownFilled, for: .normal)
        view.showsMenuAsPrimaryAction = true
        view.tintColor = ColorProvider.IconNorm
        return view
    }

    static var widgetSeparator: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.SeparatorNorm
        return view
    }

    static var openInCalendarButton: UIButton {
        let view = UIButton()
        view.titleLabel?.set(text: nil, preferredFont: .footnote)
        view.setTitle(L10n.ProtonCalendarIntegration.openInCalendar, for: .normal)
        view.setTitleColor(ColorProvider.TextAccent, for: .normal)
        return view
    }

    static var detailsContainer: UIStackView {
        let view = genericStackView
        view.spacing = 8
        return view
    }

    static func recurrenceRow(recurrence: String) -> UIView {
        let row = row(icon: \.arrowsRotate)

        let label = detailsLabel(text: recurrence)
        row.contentStackView.addArrangedSubview(label)

        return row
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

    static var participantsRow: ExpandedHeaderRowView {
        row(icon: \.users)
    }

    static func participantListButton(titleColor: UIColor, primaryAction: UIAction) -> UIButton {
        let view = UIButton(primaryAction: primaryAction)
        view.contentHorizontalAlignment = .leading
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setTitleColor(titleColor, for: .normal)

        if let titleLabel = view.titleLabel {
           titleLabel.font = .adjustedFont(forTextStyle: .footnote)
           titleLabel.lineBreakMode = .byWordWrapping
           titleLabel.numberOfLines = 0

            NSLayoutConstraint.activate([
                view.heightAnchor.constraint(equalTo: titleLabel.heightAnchor)
            ])
        }

        return view
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
        return row
    }

    static func detailsLabel(text: String, textColor: UIColor = ColorProvider.TextNorm) -> UILabel {
        let view = UILabel()
        view.numberOfLines = 0
        view.set(text: text, preferredFont: .footnote, textColor: textColor)
        return view
    }
}

private extension UIAction.Identifier {
    static let openInCalendar = Self(rawValue: "ch.protonmail.protonmail.action.openInCalendar")
}

private extension AttendeeStatusDisplay {
    var shortTitle: String {
        switch self {
        case .yes:
            return L10n.Event.yesShort
        case .no:
            return L10n.Event.noShort
        case .maybe:
            return L10n.Event.maybeShort
        }
    }

    var longTitle: String {
        switch self {
        case .yes:
            return L10n.Event.yesLong
        case .no:
            return L10n.Event.noLong
        case .maybe:
            return L10n.Event.maybeLong
        }
    }
}
