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
import ProtonCoreUIFoundations
import ProtonMailUI
import UIKit

protocol AttachmentViewControllerDelegate: AnyObject {
    func openAttachmentList(with attachments: [AttachmentInfo])
    func invitationViewWasChanged()
    func participantTapped(emailAddress: String)
    func showError(error: Error)
}

class AttachmentViewController: UIViewController {
    private let viewModel: AttachmentViewModel
    private var subscriptions = Set<AnyCancellable>()

    private let invitationProcessingView: InCellActivityIndicatorView = {
        let view = InCellActivityIndicatorView(style: .medium)
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return view
    }()

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
        view.isHidden = data.numberOfAttachments == 0

        var text = String(format: LocalString._attachment, data.numberOfAttachments)

        let byteCountFormatter = ByteCountFormatter()
        let sizeString = "(\(byteCountFormatter.string(fromByteCount: Int64(data.totalSizeOfAllAttachments))))"

        text += sizeString
        if overrideUserInterfaceStyle == .unspecified {
            view.titleLabel.set(text: text, preferredFont: .subheadline)
        } else {
            // To show correct text color in print
            let trait = UITraitCollection(userInterfaceStyle: overrideUserInterfaceStyle)
            let resolvedColor: UIColor = ColorProvider.TextNorm.resolvedColor(with: trait)
            view.titleLabel.set(
                text: text,
                preferredFont: .subheadline,
                textColor: resolvedColor
            )
        }
    }

    private func setUpTapGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        attachmentView.addGestureRecognizer(gesture)
    }

    private func setUpBindings() {
        invitationView.onIntrinsicHeightChanged = { [weak self] in
            self?.delegate?.invitationViewWasChanged()
        }

        invitationView.onParticipantTapped = { [weak self] emailAddress in
            self?.delegate?.participantTapped(emailAddress: emailAddress)
        }

        invitationView.onOpenInCalendarTapped = { [weak self] deepLink in
            self?.onOpenInCalendarTapped(deepLink: deepLink)
        }

        invitationView.onInvitationAnswered = { [weak self] answer in
            self?.viewModel.respondToInvitation(with: answer)
        }

        viewModel.error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.delegate?.showError(error: error)
            }
            .store(in: &subscriptions)

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

        viewModel.respondingStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] respondingStatus in
                self?.invitationView.displayAnsweringStatus(respondingStatus)
            }
            .store(in: &subscriptions)
    }

    @objc
    private func handleTap() {
        delegate?.openAttachmentList(with: Array(viewModel.attachments).sorted(by: { $0.order < $1.order }))
    }

    private func onOpenInCalendarTapped(deepLink: URL) {
        let instruction = viewModel.instructionToHandle(deepLink: deepLink)

        switch instruction {
        case .openDeepLink(let url):
            UIApplication.shared.open(url, options: [:])
        case .promptToUpdateCalendarApp:
            let alert = UIAlertController(
                title: "Proton Calendar",
                message: L10n.ProtonCalendarIntegration.downloadCalendarAlert,
                preferredStyle: .actionSheet
            )

            alert.addURLAction(title: L10n.ProtonCalendarIntegration.downloadInAppStore, url: .AppStore.calendar)
            alert.addCancelAction()
            present(alert, animated: true)
        case .goToAppStoreDirectly:
            UIApplication.shared.open(.AppStore.calendar, options: [:])
        case .presentCalendarLandingPage:
            let landingPage = CalendarLandingPage()
            let hostingController = SheetLikeSpotlightViewController(rootView: landingPage)
            hostingController.modalTransitionStyle = .crossDissolve
            present(hostingController, animated: false)
        }
    }
}

extension AttachmentViewController: CustomViewPrintable {
    func printPageRenderer() -> CustomViewPrintRenderer {
        let style = overrideUserInterfaceStyle
        overrideUserInterfaceStyle = .light
        let newView = AttachmentView()
        newView.overrideUserInterfaceStyle = .light
        self.setup(view: newView, with: viewModel)
        newView.backgroundColor = .white
        overrideUserInterfaceStyle = style
        return CustomViewPrintRenderer(newView)
    }

    func printingWillStart(renderer: CustomViewPrintRenderer) {
        guard let newView = renderer.view as? AttachmentView else { return }

        newView.widthAnchor.constraint(equalToConstant: 560).isActive = true
        newView.layoutIfNeeded()

        renderer.updateImage(in: newView.frame)
    }
}
