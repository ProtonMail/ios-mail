//
//  SingleMessageCoordinator.swift
//  ProtonMail
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

import QuickLook
import SafariServices
import UIKit

class SingleMessageCoordinator: NSObject, CoordinatorDismissalObserver {

    weak var viewController: SingleMessageViewController?

    private let labelId: String
    let message: Message
    private let coreDataService: CoreDataService
    private let user: UserManager
    private let navigationController: UINavigationController
    var pendingActionAfterDismissal: (() -> Void)?

    init(navigationController: UINavigationController,
         labelId: String,
         message: Message,
         user: UserManager,
         coreDataService: CoreDataService = sharedServices.get(by: CoreDataService.self)) {
        self.navigationController = navigationController
        self.labelId = labelId
        self.message = message
        self.user = user
        self.coreDataService = coreDataService
    }

    func start() {
        let singleMessageViewModelFactory = SingleMessageViewModelFactory()
        let viewModel = singleMessageViewModelFactory.createViewModel(labelId: labelId,
                                                                      message: message,
                                                                      user: user,
                                                                      isDarkModeEnableClosure: { [weak self] in
            if #available(iOS 12.0, *) {
                return self?.viewController?.traitCollection.userInterfaceStyle == .dark
            } else {
                return false
            }
        })
        let viewController = SingleMessageViewController(coordinator: self, viewModel: viewModel)
        self.viewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    func follow(_ deeplink: DeepLink) {
        guard let node = deeplink.popFirst,
              let messageID = node.value else { return }
        self.presentExistedCompose(messageID: messageID)
    }

    func navigate(to navigationAction: SingleMessageNavigationAction) {
        switch navigationAction {
        case .compose(let contact):
            presentCompose(with: contact)
        case .contacts(let contact):
            presentAddContacts(with: contact)
        case .viewHeaders(let url):
            presentQuickLookView(url: url, subType: .headers)
        case .viewHTML(let url):
            presentQuickLookView(url: url, subType: .html)
        case .reply, .replyAll, .forward:
            presentCompose(action: navigationAction)
        case .attachmentList(_, let decryptedBody):
            presentAttachmentListView(decryptedBody: decryptedBody)
        case .url(url: let url):
            presentWebView(url: url)
        case .mailToUrl(let url):
            presentCompose(mailToURL: url)
        case .inAppSafari(url: let url):
            presentInAppSafari(url: url)
        case .addNewFolder:
            presentCreateFolder(type: .folder)
        case .addNewLabel:
            presentCreateFolder(type: .label)
        case .more:
            viewController?.moreButtonTapped()
        case .viewCypher(url: let url):
            presentQuickLookView(url: url, subType: .cypher)
        }
    }

    private func presentCompose(with contact: ContactVO) {
        let viewModel = ContainableComposeViewModel(
            msg: nil,
            action: .newDraft,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: sharedServices.get(by: CoreDataService.self)
        )
        viewModel.addToContacts(contact)

        presentCompose(viewModel: viewModel)
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

    private func presentQuickLookView(url: URL?, subType: PlainTextViewerViewController.ViewerSubType) {
        guard let fileUrl = url, let text = try? String(contentsOf: fileUrl) else { return }
        let viewer = PlainTextViewerViewController(text: text, subType: subType)
        try? FileManager.default.removeItem(at: fileUrl)
        self.navigationController.pushViewController(viewer, animated: true)
    }

    private func presentCompose(action: SingleMessageNavigationAction) {
        guard action.isReplyAllAction || action.isReplyAction || action.isForwardAction else { return }

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
            coreDataContextProvider: sharedServices.get(by: CoreDataService.self)
        )

        presentCompose(viewModel: viewModel)
    }

    private func presentExistedCompose(messageID: String) {
        let context = coreDataService.mainContext
        guard let message = user.messageService.fetchMessages(withIDs: [messageID], in: context).first else {
            return
        }

        let viewModel = ContainableComposeViewModel(
            msg: message,
            action: .openDraft,
            msgService: user.messageService,
            user: user,
            coreDataContextProvider: sharedServices.get(by: CoreDataService.self)
        )

        delay(1) {
            self.presentCompose(viewModel: viewModel)
        }
    }

    private func presentAttachmentListView(decryptedBody: String?) {
        let attachments: [AttachmentInfo] = message.attachments.compactMap { $0 as? Attachment }
            .map(AttachmentNormal.init) + (message.tempAtts ?? [])
        let inlineCIDS = message.getCIDOfInlineAttachment(decryptedBody: decryptedBody)
        let viewModel = AttachmentListViewModel(attachments: attachments,
                                                user: user,
                                                inlineCIDS: inlineCIDS)
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

        let coreDataService = sharedServices.get(by: CoreDataService.self)
        let viewModel = ContainableComposeViewModel(msg: nil,
                                                    action: .newDraft,
                                                    msgService: user.messageService,
                                                    user: user,
                                                    coreDataContextProvider: coreDataService)

        mailToData.to.forEach { recipient in
            viewModel.addToContacts(ContactVO(name: recipient, email: recipient))
        }

        mailToData.cc.forEach { recipient in
            viewModel.addCcContacts(ContactVO(name: recipient, email: recipient))
        }

        mailToData.bcc.forEach { recipient in
            viewModel.addBccContacts(ContactVO(name: recipient, email: recipient))
        }

        if let subject = mailToData.subject {
            viewModel.setSubject(subject)
        }

        if let body = mailToData.body {
            viewModel.setBody(body)
        }

        presentCompose(viewModel: viewModel)
    }

    private func presentCompose(viewModel: ContainableComposeViewModel) {
        let coordinator = ComposeContainerViewCoordinator(presentingViewController: self.viewController,
                                                          editorViewModel: viewModel)
        coordinator.start()
    }

    private func presentCreateFolder(type: PMLabelType) {
        let folderLabels = user.labelService.getMenuFolderLabels(context: coreDataService.mainContext)
        let viewModel = LabelEditViewModel(user: user, label: nil, type: type, labels: folderLabels)
        let viewController = LabelEditViewController.instance()
        let coordinator = LabelEditCoordinator(services: sharedServices,
                                               viewController: viewController,
                                               viewModel: viewModel,
                                               coordinatorDismissalObserver: self)
        coordinator.start()
        if let navigation = viewController.navigationController {
            self.viewController?.navigationController?.present(navigation, animated: true, completion: nil)
        }
    }
}
