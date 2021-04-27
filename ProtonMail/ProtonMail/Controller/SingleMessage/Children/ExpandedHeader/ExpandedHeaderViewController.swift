//
//  ExpandedHeaderViewController.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail. If not, see <https://www.gnu.org/licenses/>.

import UIKit

class ExpandedHeaderViewController: UIViewController {

    private(set) lazy var customView = ExpandedHeaderView()

    private let viewModel: ExpandedHeaderViewModel
    private let tagsPresneter = TagsPresenter()

    var contactTapped: ((ExpandedHeaderContactContext) -> Void)?

    init(viewModel: ExpandedHeaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpViewModelObservation()
        setUpView()
    }

    private func setUpViewModelObservation() {
        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }
    }

    private func setUpView() {
        customView.contentStackView.clearAllViews()

        customView.initialsLabel.attributedText = viewModel.initials
        customView.initialsLabel.textAlignment = .center

        customView.senderNameLabel.attributedText = viewModel.sender

        customView.timeLabel.attributedText = viewModel.time

        customView.senderEmailControl.label.attributedText = viewModel.senderEmail

        customView.senderEmailControl.tap = { [weak self] in
            guard let sender = self?.viewModel.senderContact else { return }
            self?.contactTapped(sheetType: .sender, contact: sender)
        }

        if let toData = viewModel.toData {
            present(viewModel: toData)
        }

        if let ccData = viewModel.ccData {
            present(viewModel: ccData)
        }

        !viewModel.tags.isEmpty ? presentTags() : ()

        if let fullDate = viewModel.date {
            presentFullDateRow(stringDate: fullDate)
        }

        if let image = viewModel.originImage, let title = viewModel.originTitle {
            presentOriginRow(image: image, title: title)
        }
    }

    private func presentTags() {
        let tagsRow = ExpandedHeaderRowView()
        tagsRow.titleLabel.isHidden = true
        tagsRow.iconImageView.image = Asset.mailTagIcon.image
        let tagsView = MultiRowsTagsView()
        tagsPresneter.presentTags(tags: viewModel.tags, in: tagsView)
        tagsRow.contentStackView.addArrangedSubview(StackViewContainer(view: tagsView, top: 3, bottom: -6))
        customView.contentStackView.addArrangedSubview(StackViewContainer(view: tagsRow, top: 8))
    }
    
    private func present(viewModel: ExpandedHeaderRecipientsRowViewModel) {
        let row = ExpandedHeaderRowView()
        row.iconImageView.isHidden = true
        row.titleLabel.attributedText = viewModel.title
        row.titleLabel.lineBreakMode = .byTruncatingTail
        row.contentStackView.spacing = 5

        viewModel.recipients.map { recipient in
            let control = TextControl()
            control.label.attributedText = recipient.title
            control.tap = { [weak self] in
                self?.contactTapped(sheetType: .recipient, contact: recipient.contact)
            }
            return control
        }.forEach {
            row.contentStackView.addArrangedSubview($0)
        }
        customView.contentStackView.addArrangedSubview(row)
    }

    private func contactTapped(sheetType: MessageDetailsContactActionSheetType, contact: ContactVO) {
        let context = ExpandedHeaderContactContext(type: sheetType, contact: contact)
        contactTapped?(context)
    }

    private func presentFullDateRow(stringDate: NSAttributedString) {
        let row = ExpandedHeaderRowView()
        row.titleLabel.isHidden = true
        row.iconImageView.image = Asset.mailCalendarIcon.image
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

    required init?(coder: NSCoder) {
        nil
    }

}
