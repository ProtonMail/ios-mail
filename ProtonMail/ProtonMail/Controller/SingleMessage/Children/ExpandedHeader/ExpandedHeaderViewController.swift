//
//  ExpandedHeaderViewController.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class ExpandedHeaderViewController: UIViewController {

    private(set) lazy var customView = ExpandedHeaderView()

    private let viewModel: ExpandedHeaderViewModel
    private var hideDetailsAction: (() -> Void)?

    var contactTapped: ((MessageHeaderContactContext) -> Void)?

    init(viewModel: ExpandedHeaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpLockTapAction()
        setUpViewModelObservation()
        setUpView()
    }

    func observeHideDetails(action: @escaping (() -> Void)) {
        self.hideDetailsAction = action
    }

    private func setUpViewModelObservation() {
        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }
    }

    private func setUpView() {
        customView.contentStackView.clearAllViews()

        customView.initialsLabel.text = viewModel.initials.string
        customView.initialsLabel.textAlignment = .center

        customView.senderNameLabel.attributedText = viewModel.sender

        customView.timeLabel.attributedText = viewModel.time

        customView.senderEmailControl.label.attributedText = viewModel.senderEmail

        customView.starImageView.isHidden = !viewModel.message.isStarred

        customView.senderEmailControl.tap = { [weak self] in
            guard let sender = self?.viewModel.senderContact else { return }
            self?.contactTapped(sheetType: .sender, contact: sender)
        }

        var contactRow: ExpandedHeaderRowView?
        if let toData = viewModel.toData {
            contactRow = present(viewModel: toData, isToContacts: true)
        }

        if let ccData = viewModel.ccData {
            contactRow = present(viewModel: ccData)
        }

        if viewModel.toData == nil && viewModel.ccData == nil {
            contactRow = present(viewModel: .undisclosedRecipients)
        }

        if let rowView = contactRow {
            customView.contentStackView.setCustomSpacing(18, after: rowView)
        }

        !viewModel.tags.isEmpty ? presentTags() : ()

        if let fullDate = viewModel.date {
            presentFullDateRow(stringDate: fullDate)
        }

        if let image = viewModel.originImage, let title = viewModel.originTitle {
            presentOriginRow(image: image, title: title)
        }

        if let size = viewModel.size {
            presentSizeRow(size: size)
        }

        if let icon = viewModel.senderContact?.encryptionIconStatus?.iconWithColor,
           let reason = viewModel.senderContact?.encryptionIconStatus?.text {
            presentLockIconRow(icon: icon, reason: reason)
        }
        presentHideDetailButton()
        setUpLock()
    }

    private func setUpLock() {
        guard customView.lockImageView.image == nil,
              viewModel.message.isDetailDownloaded,
              let contact = viewModel.senderContact else { return }

        if let iconStatus = contact.encryptionIconStatus {
            self.customView.lockImageView.tintColor = iconStatus.iconColor.color
            self.customView.lockImageView.image = iconStatus.icon
            self.customView.lockContainer.isHidden = false
        }
    }

    private func presentTags() {
        let tagViews = ExpandedHeaderTagView(frame: .zero)
        tagViews.setUp(tags: viewModel.tags)
        customView.contentStackView.addArrangedSubview(tagViews)
    }

    @discardableResult
    private func present(viewModel: ExpandedHeaderRecipientsRowViewModel, isToContacts: Bool = false) -> ExpandedHeaderRowView {
        let row = ExpandedHeaderRowView()
        row.iconImageView.isHidden = true
        row.titleLabel.attributedText = viewModel.title
        row.titleLabel.lineBreakMode = .byTruncatingTail
        row.contentStackView.spacing = 5

        viewModel.recipients.enumerated().map { dataSet -> UIStackView in
            let recipient = dataSet.element
            let control = TextControl()
            control.label.attributedText = recipient.name
            control.label.setContentCompressionResistancePriority(.required, for: .horizontal)
            let addressController = TextControl()
            addressController.label.attributedText = recipient.address
            addressController.label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
            if let contact = recipient.contact {
                control.tap = { [weak self] in
                    self?.contactTapped(sheetType: .recipient, contact: contact)
                }
                addressController.tap = { [weak self] in
                    self?.contactTapped(sheetType: .recipient, contact: contact)
                }
            }
            let stack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center, spacing: 4)
            stack.addArrangedSubview(control)
            stack.addArrangedSubview(addressController)
            if dataSet.offset == 0 && isToContacts {
                // 32 reply button + 8 * 2 spacing + 32 more button
                stack.setCustomSpacing(80, after: addressController)
                stack.addArrangedSubview(UIView())
            }
            return stack
        }.forEach {
            row.contentStackView.addArrangedSubview($0)
        }
        customView.contentStackView.addArrangedSubview(row)
        return row
    }

    private func contactTapped(sheetType: MessageDetailsContactActionSheetType, contact: ContactVO) {
        let context = MessageHeaderContactContext(type: sheetType, contact: contact)
        contactTapped?(context)
    }

    private func presentFullDateRow(stringDate: NSAttributedString) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = IconProvider.calendarToday
        let dateLabel = UILabel(frame: .zero)
        dateLabel.attributedText = stringDate
        row.contentStackView.addArrangedSubview(dateLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentOriginRow(image: UIImage, title: NSAttributedString) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = image
        let titleLabel = UILabel()
        titleLabel.attributedText = title
        row.contentStackView.addArrangedSubview(titleLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentSizeRow(size: NSAttributedString) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = IconProvider.filingCabinet
        let titleLabel = UILabel()
        titleLabel.attributedText = size
        row.contentStackView.addArrangedSubview(titleLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentLockIconRow(icon: UIImage, reason: String) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = icon
        let titleLabel = UILabel()
        titleLabel.attributedText = reason.apply(style: .CaptionWeak)
        row.contentStackView.addArrangedSubview(titleLabel)
        customView.contentStackView.addArrangedSubview(row)
    }

    private func presentHideDetailButton() {
        let button = UIButton()
        button.setTitle(LocalString._hide_details, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(ColorProvider.InteractionNorm, for: .normal)
        button.setContentCompressionResistancePriority(.required, for: .vertical)
        let stack = UIStackView.stackView(axis: .horizontal, distribution: .fill, alignment: .center)
        let padding = UIView(frame: .zero)
        stack.addArrangedSubview(padding)
        stack.addArrangedSubview(button)
        stack.addArrangedSubview(UIView())
        [
            padding.widthAnchor.constraint(equalToConstant: 38)
        ].activate()
        customView.contentStackView.addArrangedSubview(stack)
        button.addTarget(self, action: #selector(self.clickHideDetailsButton), for: .touchUpInside)
    }

    private func setUpLockTapAction() {
        customView.lockImageControl.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
    }

    @objc
    private func lockTapped() {
        viewModel.senderContact?.encryptionIconStatus?.text.alertToastBottom()
    }

    @objc
    func clickHideDetailsButton() {
        self.hideDetailsAction?()
    }

    required init?(coder: NSCoder) {
        nil
    }

}
