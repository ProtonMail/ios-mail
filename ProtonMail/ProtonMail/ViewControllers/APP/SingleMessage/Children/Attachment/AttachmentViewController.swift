//
//  AttachmentViewController.swift
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
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Combine
import UIKit

protocol AttachmentViewControllerDelegate: AnyObject {
    func openAttachmentList(with attachments: [AttachmentInfo])
    func invitationViewWasChanged()
}

class AttachmentViewController: UIViewController {
    private let viewModel: AttachmentViewModel
    private var subscriptions = Set<AnyCancellable>()

    private let invitationProcessingView = InCellActivityIndicatorView(style: .medium)
    private let invitationView = InvitationView()
    private let attachmentView = AttachmentView()

    private lazy var customView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [invitationProcessingView, invitationView, attachmentView])
        view.axis = .vertical
        view.distribution = .equalSpacing
        return view
    }()

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
            guard let self = self else { return }
            self.setup(view: self.attachmentView, with: self.viewModel)
        }

        setup(view: attachmentView, with: viewModel)
        setUpTapGesture()
        setUpBindings()
    }

    private func setup(view: AttachmentView, with data: AttachmentViewModel) {
        var text = String(format: LocalString._attachment, data.numberOfAttachments)

        let byteCountFormatter = ByteCountFormatter()
        let sizeString = "(\(byteCountFormatter.string(fromByteCount: Int64(data.totalSizeOfAllAttachments))))"

        text += sizeString
        view.titleLabel.set(text: text,
                            preferredFont: .footnote)
    }

    private func setUpTapGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        attachmentView.addGestureRecognizer(gesture)
    }

    private func setUpBindings() {
        invitationView.onIntrinsicHeightChanged = { [weak self] in
            self?.delegate?.invitationViewWasChanged()
        }

        viewModel.invitationViewState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] invitationViewState in
                guard let self else { return }

                switch invitationViewState {
                case .noInvitationFound:
                    self.invitationProcessingView.customStopAnimating()
                    self.invitationView.isHidden = true
                case .invitationFoundAndProcessing:
                    self.invitationProcessingView.startAnimating()
                    self.invitationView.isHidden = true
                case .invitationProcessed(let eventDetails):
                    self.invitationProcessingView.customStopAnimating()
                    self.invitationView.populate(with: eventDetails)
                    self.invitationView.isHidden = false
                }

                self.delegate?.invitationViewWasChanged()
            }
            .store(in: &subscriptions)
    }

    @objc
    private func handleTap() {
        delegate?.openAttachmentList(with: Array(viewModel.attachments).sorted(by: { $0.order < $1.order }))
    }
}

extension AttachmentViewController: CustomViewPrintable {
    func printPageRenderer() -> CustomViewPrintRenderer {
        let newView = AttachmentView()
            newView.overrideUserInterfaceStyle = .light
        self.setup(view: newView, with: viewModel)
        newView.backgroundColor = .white
        return CustomViewPrintRenderer(newView)
    }

    func printingWillStart(renderer: CustomViewPrintRenderer) {
        guard let newView = renderer.view as? AttachmentView else { return }

        newView.widthAnchor.constraint(equalToConstant: 560).isActive = true
        newView.layoutIfNeeded()

        renderer.updateImage(in: newView.frame)
    }
}

private class InCellActivityIndicatorView: UIActivityIndicatorView {
    @available(*, unavailable, message: "This method does nothing, use `customStopAnimating` instead.")
    override func stopAnimating() {
        /*
         This method is called by the OS as a part of `prepareForReuse`.
         However, the animation is never restarted.
         The result is that the spinner is gone too soon, before the processing is complete.
         */
    }

    func customStopAnimating() {
        super.stopAnimating()
    }
}
