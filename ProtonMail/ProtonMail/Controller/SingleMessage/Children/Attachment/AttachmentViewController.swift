//
//  AttachmentViewController.swift
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

import UIKit

protocol AttachmentViewControllerDelegate: class {
    func openAttachmentList()
}

class AttachmentViewController: UIViewController {
    private let viewModel: AttachmentViewModel
    private(set) lazy var customView = AttachmentView()

    weak var delegate: AttachmentViewControllerDelegate?

    init(viewModel: AttachmentViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.reloadView = { [weak self] in
            self?.setUpView()
        }

        setUpView()
        setUpTapGesture()
    }

    private func setUpView() {
        var text = "\(viewModel.numberOfAttachments) "
        if viewModel.numberOfAttachments <= 1 {
            text += "\(LocalString._one_attachment_title) "
        } else {
            text += "\(LocalString._attachments_title) "
        }

        let byteCountFormatter = ByteCountFormatter()
        let sizeString = "(\(byteCountFormatter.string(fromByteCount: Int64(viewModel.totalSizeOfAllAttachments))))"

        text += sizeString
        customView.titleLabel.attributedText = text.apply(style: FontManager.DefaultSmall)
    }

    private func setUpTapGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        customView.addGestureRecognizer(gesture)
    }

    @objc
    private func handleTap() {
        delegate?.openAttachmentList()
    }
}
