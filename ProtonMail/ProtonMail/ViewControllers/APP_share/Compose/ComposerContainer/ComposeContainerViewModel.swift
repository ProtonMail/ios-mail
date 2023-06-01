//
//  ComposeContainerViewModel.swift
//  Proton Mail - Created on 15/04/2019.
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation
import PromiseKit

protocol ComposeContainerUIProtocol: AnyObject {
    func updateSendButton()
}

class ComposeContainerViewModel: TableContainerViewModel {
    var childViewModel: ComposeViewModel

    // for FileImporter
    lazy var documentAttachmentProvider = DocumentAttachmentProvider(for: self)
    lazy var imageAttachmentProvider = PhotoAttachmentProvider(for: self)
    private var contactChanged: NSKeyValueObservation?
    weak var uiDelegate: ComposeContainerUIProtocol?
    var user: UserManager { self.childViewModel.user }
    var coreDataContextProvider: CoreDataContextProviderProtocol {
        self.childViewModel.coreDataContextProvider
    }

    private var userIntroductionProgressProvider: UserIntroductionProgressProvider
    private let scheduleSendStatusProvider: ScheduleSendEnableStatusProvider

    var isScheduleSendIntroViewShown: Bool {
        !userIntroductionProgressProvider.shouldShowSpotlight(for: .scheduledSend, toUserWith: user.userID)
    }

    private let router: ComposerRouter
    var isSendButtonTapped: Bool = false
    var currentAttachmentSize = 0
    var isScheduleSendEnable: Bool {
        scheduleSendStatusProvider.isScheduleSendEnabled(userID: user.userID) == .enabled
    }

    init(
        router: ComposerRouter,
        editorViewModel: ComposeViewModel,
        userIntroductionProgressProvider: UserIntroductionProgressProvider,
        scheduleSendStatusProvider: ScheduleSendEnableStatusProvider
    ) {
        self.router = router
        self.childViewModel = editorViewModel
        self.userIntroductionProgressProvider = userIntroductionProgressProvider
        self.scheduleSendStatusProvider = scheduleSendStatusProvider
        super.init()
        self.contactChanged = observeRecipients()
    }

    override var numberOfSections: Int {
        return 1
    }

    override func numberOfRows(in section: Int) -> Int {
        return 3
    }

    func syncMailSetting() {
        let usersManager = sharedServices.get(by: UsersManager.self)
        guard let currentUser = usersManager.firstUser else { return }
        currentUser.messageService.syncMailSetting()
    }

    func filesAreSupported(from itemProviders: [NSItemProvider]) -> Bool {
        return itemProviders.reduce(true) { $0 && $1.hasItem(types: self.filetypes) != nil }
    }

    func importFiles(
        from itemProviders: [NSItemProvider],
        errorHandler: @escaping (String) -> Void,
        successHandler: @escaping () -> Void
    ) {
        for itemProvider in itemProviders {
            guard let type = itemProvider.hasItem(types: self.filetypes) else { return }
            self.importFile(itemProvider, type: type, errorHandler: errorHandler, handler: successHandler)
        }
    }

    func hasRecipients() -> Bool {
        let count = self.childViewModel.toSelectedContacts.count + self.childViewModel.ccSelectedContacts.count + self.childViewModel.bccSelectedContacts.count
        return count > 0
    }

    func userHasSeenScheduledSendSpotlight() {
        userIntroductionProgressProvider.markSpotlight(for: .scheduledSend, asSeen: true, byUserWith: user.userID)
    }

    private func observeRecipients() -> NSKeyValueObservation {
        return self.childViewModel.observe(\.contactsChange, options: [.new, .old]) { [weak self] _, _ in
            self?.uiDelegate?.updateSendButton()
        }
    }

    func allowScheduledSend(completion: @escaping (Bool) -> Void) {
        let connectionStatusProvider = InternetConnectionStatusProvider()
        let status = connectionStatusProvider.currentStatus
        guard status.isConnected else {
            checkLocalScheduledMessage(completion: completion)
            return
        }
        let scheduledLimit = 100
        let countRequest = MessageCountRequest()
        self.user.apiService.perform(request: countRequest, response: MessageCountResponse()) { _, response in
            if response.error == nil,
               let scheduledLabel = response.counts?.first(where: { $0["LabelID"] as? String == LabelLocation.scheduled.rawLabelID }) {
                let total = (scheduledLabel["Total"] as? Int) ?? 101
                completion(total < scheduledLimit)
            } else {
                completion(true)
            }
        }
    }

    private func checkLocalScheduledMessage(completion: @escaping (Bool) -> Void) {
        let offlineSchedulingLimit = 70
        let lastUpdatedStore = sharedServices.get(by: LastUpdatedStore.self)
        let labelID = LabelLocation.scheduled.labelID
        let userID = user.userID
        let entity: LabelCountEntity? = lastUpdatedStore.lastUpdate(by: labelID, userID: userID, type: .singleMessage)
        // Don't have data usually means no scheduled message
        let total = entity?.total ?? 0
        completion(total < offlineSchedulingLimit)
    }
}

extension ComposeContainerViewModel: FileImporter, AttachmentController {
    func error(title: String, description: String) {
        self.showErrorBanner(description)
    }

    func present(_ controller: UIViewController, animated: Bool, completion: (() -> Void)?) {
        fatalError()
    }

    func error(_ description: String) {
        self.showErrorBanner(description)
    }

    func fileSuccessfullyImported(as fileData: FileData) -> Promise<Void> {
        guard self.childViewModel.currentAttachmentsSize + fileData.contents.dataSize < Constants.kDefaultAttachmentFileSize else {
            self.showErrorBanner(LocalString._the_total_attachment_size_cant_be_bigger_than_25mb)
            return Promise()
        }
        let stripMetadata = userCachedStatus.metadataStripping == .stripMetadata
        return Promise { seal in
            self.childViewModel.composerMessageHelper.addAttachment(fileData, shouldStripMetaData: stripMetadata) { _ in
                self.childViewModel.updateDraft()
                seal.fulfill_()
            }
        }
    }

    func addAttachment(_ attachmentObjectID: ObjectID) {
        childViewModel.composerMessageHelper.addAttachment(attachmentObjectID)
    }

    func updateAttachmentOrders(completion: @escaping ([AttachmentEntity]) -> Void) {
        childViewModel.composerMessageHelper.updateAttachmentOrders(completion: completion)
    }

    func navigateToPassword(password: String, confirmPassword: String, passwordHint: String, delegate: ComposePasswordDelegate) {
        router.navigateToPasswordSetupView(
            password: password,
            confirmPassword: confirmPassword,
            passwordHint: passwordHint,
            delegate: delegate
        )
    }

    func navigateToExpiration(expiration: TimeInterval, delegate: ComposeExpirationDelegate) {
        router.navigateToExpirationSetupView(
            expirationTimeInterval: expiration,
            delegate: delegate
        )
    }

    func sendAction(deliveryTime: Date?) {
        childViewModel.deliveryTime = deliveryTime
        // TODO: handle sending message here.
    }
}
