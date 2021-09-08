//
//  NonExpandedHeaderViewController.swift
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
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class NonExpandedHeaderViewController: UIViewController {

    private(set) lazy var customView = NonExpandedHeaderView()
    private let viewModel: NonExpandedHeaderViewModel
    private let tagsPresenter = TagsPresenter()
    private var showDetailsAction: (() -> Void)?
    var contactTapped: ((MessageHeaderContactContext) -> Void)?

    init(viewModel: NonExpandedHeaderViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpLockTapAction()
        setUpViewModelObservations()
        setUpView()
    }

    func observeShowDetails(action: @escaping (() -> Void)) {
        self.showDetailsAction = action
    }

    private func setUpView() {
        customView.initialsLabel.text = viewModel.initials.string
        customView.initialsLabel.textAlignment = .center
        customView.originImageView.image = viewModel.originImage
        customView.senderLabel.attributedText = viewModel.sender
        customView.senderLabel.lineBreakMode = .byTruncatingTail
        customView.senderAddressLabel.label.attributedText = viewModel.senderEmail
        customView.senderAddressLabel.tap = { [weak self] in
            guard let sender = self?.viewModel.senderContact else { return }
            self?.contactTapped(sheetType: .sender, contact: sender)
        }
        customView.timeLabel.attributedText = viewModel.time
        customView.recipientLabel.attributedText = viewModel.recipient
        customView.showDetailsButton.setTitleColor(UIColorManager.InteractionNorm, for: .normal)
        customView.showDetailsButton.addTarget(self,
                                               action: #selector(self.clickShowDetailsButton),
                                               for: .touchUpInside)
        customView.starImageView.isHidden = !viewModel.message.starred
        tagsPresenter.presentTags(tags: viewModel.tags, in: customView.tagsView)
        setUpLock()
    }

    private func setUpLock() {
        guard customView.lockImageView.image == nil, viewModel.message.isDetailDownloaded else { return }
        viewModel.lockIcon { [weak self] image, _ in
            self?.customView.lockImageView.image = image
            self?.customView.lockContainer.isHidden = image == nil
        }
    }

    private func setUpLockTapAction() {
        customView.lockImageControl.addTarget(self, action: #selector(lockTapped), for: .touchUpInside)
    }

    @objc
    private func lockTapped() {
        viewModel.senderContact?.inboxNotes.alertToastBottom()
    }

    @objc
    private func clickShowDetailsButton() {
        self.showDetailsAction?()
    }

    private func setUpViewModelObservations() {
        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }
    }

    private func contactTapped(sheetType: MessageDetailsContactActionSheetType, contact: ContactVO) {
        let context = MessageHeaderContactContext(type: sheetType, contact: contact)
        contactTapped?(context)
    }

    required init?(coder: NSCoder) {
        nil
    }

}
