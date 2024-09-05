//
//  SingleMessageCoordinator.swift
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

import ProtonMailUI
import QuickLook
import SafariServices
import UIKit

class SingleMessageCoordinator: NSObject, CoordinatorDismissalObserver {
    typealias Dependencies = HasComposerViewFactory
    & HasContactViewsFactory
    & HasPaymentsUIFactory
    & HasToolbarSettingViewFactory
    & AttachmentListViewModel.Dependencies
    & SingleMessageViewModelFactory.Dependencies

    weak var viewController: SingleMessageViewController?

    private let labelId: LabelID
    private let user: UserManager
    private let highlightedKeywords: [String]
    private weak var navigationController: UINavigationController?
    var pendingActionAfterDismissal: (() -> Void)?
    var goToDraft: ((MessageID, Date?) -> Void)?
    private let dependencies: Dependencies
    @MainActor private var upsellCoordinator: UpsellCoordinator?

    init(
        navigationController: UINavigationController,
        labelId: LabelID,
        dependencies: Dependencies,
        highlightedKeywords: [String] = []
    ) {
        self.navigationController = navigationController
        self.labelId = labelId
        self.user = dependencies.user
        self.highlightedKeywords = highlightedKeywords
        self.dependencies = dependencies

        super.init()
    }

    func start(message: MessageEntity) {
        let viewController = makeSingleMessageVC(message: message)
        self.viewController = viewController
        if navigationController?.viewControllers.last is MessagePlaceholderVC,
           var viewControllers = navigationController?.viewControllers {
            viewControllers.removeAll(where: { $0 is MessagePlaceholderVC })
            viewControllers.append(viewController)
            navigationController?.setViewControllers(viewControllers, animated: false)
        } else {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func makeSingleMessageVC(message: MessageEntity) -> SingleMessageViewController {
        let singleMessageViewModelFactory = SingleMessageViewModelFactory(dependencies: dependencies)
        let viewModel = singleMessageViewModelFactory.createViewModel(
            labelId: labelId,
            message: message,
            highlightedKeywords: highlightedKeywords,
            coordinator: self,
            goToDraft: { [weak self] msgID, originalScheduleTime in
                self?.navigationController?.popViewController(animated: false)
                self?.goToDraft?(msgID, originalScheduleTime)
            }
        )
        let viewController = SingleMessageViewController(viewModel: viewModel, dependencies: dependencies)
        self.viewController = viewController
        return viewController
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
        case let .attachmentList(_, decryptedBody, attachments):
            presentAttachmentListView(decryptedBody: decryptedBody, attachments: attachments)
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
        case let .toolbarCustomization(currentActions: currentActions,
                                       allActions: allActions):
            presentToolbarCustomization(allActions: allActions,
                                        currentActions: currentActions)
        case .toolbarSettingView:
            presentToolbarCustomizationSettingView()
        case .upsellPage(let entryPoint):
            presentUpsellPage(entryPoint: entryPoint)
        }
    }
}

// MARK: - Private functions
extension SingleMessageCoordinator {
    private func presentCompose(with contact: ContactVO) {
        let composer = dependencies.composerViewFactory.makeComposer(
            msg: nil,
            action: .newDraft,
            toContact: contact
        )
        viewController?.present(composer, animated: true)
    }

    private func presentAddContacts(with contact: ContactVO) {
        let newView = dependencies.contactViewsFactory.makeEditView(contact: contact)
        let nav = UINavigationController(rootViewController: newView)
        self.viewController?.present(nav, animated: true)
    }

    private func presentQuickLookView(url: URL?, subType: PlainTextViewerViewController.ViewerSubType) {
        guard let fileUrl = url, let text = try? String(contentsOf: fileUrl) else { return }
        let viewer = PlainTextViewerViewController(text: text, subType: subType)
        try? FileManager.default.removeItem(at: fileUrl)
        self.navigationController?.pushViewController(viewer, animated: true)
    }

    private func presentCompose(action: SingleMessageNavigationAction) {
        guard action.isReplyAllAction || action.isReplyAction || action.isForwardAction else { return }
        guard
            let infoProvider = viewController?.viewModel.contentViewModel.messageInfoProvider,
            let message = viewController?.viewModel.message,
            message.isDetailDownloaded
        else { return }

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

        let composer = dependencies.composerViewFactory.makeComposer(
            msg: message,
            action: composeAction,
            remoteContentPolicy: infoProvider.remoteContentPolicy,
            embeddedContentPolicy: infoProvider.embeddedContentPolicy
        )
        viewController?.present(composer, animated: true)
    }

    private func presentAttachmentListView(decryptedBody: String?, attachments: [AttachmentInfo]) {
        guard let message = viewController?.viewModel.message else { return }
        let inlineCIDS = message.getCIDOfInlineAttachment(decryptedBody: decryptedBody)
        let viewModel = AttachmentListViewModel(
            attachments: attachments,
            inlineCIDS: inlineCIDS,
            dependencies: dependencies
        )
        let viewController = AttachmentListViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
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
        let composer = dependencies.composerViewFactory.makeComposer(msg: nil, action: .newDraft, mailToUrl: mailToURL)
        viewController?.present(composer, animated: true)
    }

    private func presentCreateFolder(type: PMLabelType) {
        let folderLabels = user.labelService.getMenuFolderLabels()
        let dependencies = LabelEditViewModel.Dependencies(userManager: user)
        let labelEditNavigationController = LabelEditStackBuilder.make(
            editMode: .creation,
            type: type,
            labels: folderLabels,
            dependencies: dependencies,
            coordinatorDismissalObserver: self
        )
        viewController?.navigationController?.present(labelEditNavigationController, animated: true, completion: nil)
    }

    private func presentToolbarCustomization(
        allActions: [MessageViewActionSheetAction],
        currentActions: [MessageViewActionSheetAction]
    ) {
        let viewController = dependencies.toolbarSettingViewFactory.makeCustomizeView(
            currentActions: currentActions,
            allActions: allActions
        )
        viewController.customizationIsDone = { [weak self] result in
            self?.viewController?.showProgressHud()
            self?.viewController?.viewModel.updateToolbarActions(
                actions: result,
                completion: { error in
                    if let error = error {
                        error.alertErrorToast()
                    }
                    self?.viewController?.setUpToolBarIfNeeded()
                    self?.viewController?.hideProgressHud()
                })
        }
        let nav = UINavigationController(rootViewController: viewController)
        self.viewController?.navigationController?.present(nav, animated: true)
    }

    private func presentToolbarCustomizationSettingView() {
        let settingView = dependencies.toolbarSettingViewFactory.makeSettingView()
        self.viewController?.navigationController?.pushViewController(settingView, animated: true)
    }

    private func presentUpsellPage(entryPoint: UpsellPageEntryPoint) {
        guard let viewController else {
            return
        }

        Task { @MainActor in
            upsellCoordinator = dependencies.paymentsUIFactory.makeUpsellCoordinator(rootViewController: viewController)
            upsellCoordinator?.start(entryPoint: entryPoint)
        }
    }
}
