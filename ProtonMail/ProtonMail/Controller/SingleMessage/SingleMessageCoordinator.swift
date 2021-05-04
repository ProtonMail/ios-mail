//
//  SingleMessageCoordinator.swift
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

import QuickLook
import SafariServices
import UIKit

class SingleMessageCoordinator: NSObject {

    weak var viewController: SingleMessageViewController?

    private let labelId: String
    private let message: Message
    private let user: UserManager
    private let navigationController: UINavigationController
    private var tempClearFileURL: URL?

    init(navigationController: UINavigationController, labelId: String, message: Message, user: UserManager) {
        self.navigationController = navigationController
        self.labelId = labelId
        self.message = message
        self.user = user
    }

    func start() {
        let viewModel = SingleMessageViewModel(
            labelId: labelId,
            message: message,
            user: user,
            linkOpenerCache: userCachedStatus
        )
        let viewController = SingleMessageViewController(coordinator: self, viewModel: viewModel)
        self.viewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func navigate(to navigationAction: SingleMessageNavigationAction) {
        switch navigationAction {
        case .compose(let contact):
            presentCompose(with: contact)
        case .contacts(let contact):
            presentAddContacts(with: contact)
        case .viewData(let url):
            presentQuickLookView(url: url)
        case .reply, .replyAll, .forward:
            presentCompose(action: navigationAction)
        case .attachmentList:
            presentAttachmnetListView()
        case .url(url: let url):
            presentWebView(url: url)
        case .mailToUrl(let url):
            presentCompose(mailToURL: url)
        case .inAppSafari(url: let url):
            presentInAppSafari(url: url)
        }
    }

    private func presentCompose(with contact: ContactVO) {
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
    }

    private func presentAddContacts(with contact: ContactVO) {
        let board = UIStoryboard.Storyboard.contact.storyboard
        guard let destination = board.instantiateViewController(
                withIdentifier: "UINavigationController-d3P-H0-xNt") as? UINavigationController,
              let viewController = destination.viewControllers.first as? ContactEditViewController else {
            return
        }
        sharedVMService.contactAddViewModel(viewController, user: user, contactVO: contact)
        self.viewController?.present(destination, animated: true)
    }

    private func presentQuickLookView(url: URL?) {
        guard let fileUrl = url else { return }
        self.tempClearFileURL = fileUrl
        let previewQL = QuickViewViewController()
        previewQL.dataSource = self
        previewQL.delegate = self
        self.navigationController.present(previewQL, animated: true, completion: nil)
    }

    private func presentCompose(action: SingleMessageNavigationAction) {
        let allowedActions: [SingleMessageNavigationAction] = [.reply, .replyAll, .forward]
        guard allowedActions.contains(action) else {
            return
        }

        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }

        let composeAction: ComposeMessageAction
        switch action {
        case .reply:
            composeAction = .reply
        case .replyAll:
            composeAction = .replyAll
        case .forward:
            composeAction = .forward
        default:
            return
        }

        let viewModel = ContainableComposeViewModel(
            msg: message,
            action: composeAction,
            msgService: user.messageService,
            user: user,
            coreDataService: sharedServices.get(by: CoreDataService.self)
        )

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)

    }

    private func presentAttachmnetListView() {
        let attachments: [AttachmentInfo] = message.attachments.compactMap { $0 as? Attachment }
            .map(AttachmentNormal.init) + (message.tempAtts ?? [])

        let viewModel = AttachmentListViewModel(attachments: attachments,
                                                user: user)
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController.pushViewController(viewController, animated: true)
    }

    private func presentWebView(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url,
                                      options: [:],
                                      completionHandler: nil)
        }
    }

    private func presentInAppSafari(url: URL) {
        let safari = SFSafariViewController(url: url)
        self.viewController?.present(safari, animated: true, completion: nil)
    }

    private func presentCompose(mailToURL: URL) {
        guard let mailToData = mailToURL.parseMailtoLink() else { return }
        let board = UIStoryboard.Storyboard.composer.storyboard
        guard let destination = board.instantiateInitialViewController() as? ComposerNavigationController,
              let viewController = destination.viewControllers.first as? ComposeContainerViewController else {
            return
        }

        let viewModel = ContainableComposeViewModel(msg: nil,
                                                    action: .newDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataService: sharedServices.get(by: CoreDataService.self))

        mailToData.to.forEach { receipient in
            viewModel.addToContacts(ContactVO(name: receipient, email: receipient))
        }

        mailToData.cc.forEach { receipient in
            viewModel.addCcContacts(ContactVO(name: receipient, email: receipient))
        }

        mailToData.bcc.forEach { receipient in
            viewModel.addBccContacts(ContactVO(name: receipient, email: receipient))
        }

        if let subject = mailToData.subject {
            viewModel.setSubject(subject)
        }

        if let body = mailToData.body {
            viewModel.setBody(body)
        }

        viewController.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel, uiDelegate: viewController))
        viewController.set(coordinator: ComposeContainerViewCoordinator(controller: viewController))
        self.viewController?.present(destination, animated: true)
    }
}

extension SingleMessageCoordinator: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        if let url = self.tempClearFileURL {
            return url as QLPreviewItem
        } else {
            return NSURL() as QLPreviewItem
        }
    }

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        if let url = self.tempClearFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        self.tempClearFileURL = nil
    }
}
