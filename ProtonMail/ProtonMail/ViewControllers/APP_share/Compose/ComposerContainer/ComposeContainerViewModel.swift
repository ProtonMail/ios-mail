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

protocol ComposeContainerViewModelDelegate: AnyObject {
    func getAttachmentController() -> AttachmentController
}

class ComposeContainerViewModel: TableContainerViewModel {
    typealias Dependencies = HasFeatureFlagCache
    & HasKeychain
    & HasLastUpdatedStoreProtocol
    & HasUserIntroductionProgressProvider
    & HasUsersManager

    var childViewModel: ComposeViewModel

    private let dependencies: Dependencies

    // for FileImporter
    lazy var documentAttachmentProvider = {
        guard let delegate = self.delegate else {
            fatalError("Delegate should be set")
        }
        return DocumentAttachmentProvider(for: delegate.getAttachmentController())
    }()
    lazy var imageAttachmentProvider = {
        guard let delegate = self.delegate else {
            fatalError("Delegate should be set")
        }
        return PhotoAttachmentProvider(for: delegate.getAttachmentController())
    }()
    private var contactChanged: NSKeyValueObservation?
    weak var uiDelegate: ComposeContainerUIProtocol?
    weak var delegate: ComposeContainerViewModelDelegate?
    var user: UserManager { self.childViewModel.user }

    var isScheduleSendIntroViewShown: Bool {
        !dependencies.userIntroductionProgressProvider.shouldShowSpotlight(for: .scheduledSend, toUserWith: user.userID)
    }

    private let router: ComposerRouter
    var isSendButtonTapped: Bool = false
    var currentAttachmentSize = 0

    var isScheduleSendEnable: Bool {
        dependencies.featureFlagCache.featureFlags(for: user.userID)[.scheduleSend]
    }

    var shouldStripAttachmentMetadata: Bool {
        dependencies.keychain[.metadataStripping] == .stripMetadata
    }

    init(
        router: ComposerRouter,
        dependencies: Dependencies,
        editorViewModel: ComposeViewModel
    ) {
        self.dependencies = dependencies
        self.router = router
        self.childViewModel = editorViewModel
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
        let usersManager = dependencies.usersManager
        guard let currentUser = usersManager.firstUser else { return }
        currentUser.messageService.syncMailSetting()
    }

    func filesAreSupported(from itemProviders: [NSItemProvider]) -> Bool {
        return itemProviders.reduce(true) { $0 && $1.hasItem(types: FileImporterConstants.fileTypes) != nil }
    }

    func importFiles(
        from itemProviders: [NSItemProvider],
        errorHandler: @escaping (String) -> Void,
        successHandler: @escaping () -> Void
    ) {
        for itemProvider in itemProviders {
            guard let type = itemProvider.hasItem(types: FileImporterConstants.fileTypes) else { return }
            self.importFile(itemProvider, type: type, errorHandler: errorHandler, handler: successHandler)
        }
    }

    func hasRecipients() -> Bool {
        let count = self.childViewModel.toSelectedContacts.count + self.childViewModel.ccSelectedContacts.count + self.childViewModel.bccSelectedContacts.count
        return count > 0
    }

    func userHasSeenScheduledSendSpotlight() {
        dependencies.userIntroductionProgressProvider.markSpotlight(for: .scheduledSend, asSeen: true, byUserWith: user.userID)
    }

    private func observeRecipients() -> NSKeyValueObservation {
        return self.childViewModel.observe(\.contactsChange, options: [.new, .old]) { [weak self] _, _ in
            self?.uiDelegate?.updateSendButton()
        }
    }

    func allowScheduledSend(completion: @escaping (Bool) -> Void) {
        let connectionStatusProvider = InternetConnectionStatusProvider.shared
        let status = connectionStatusProvider.status
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
        let lastUpdatedStore = dependencies.lastUpdatedStore
        let labelID = LabelLocation.scheduled.labelID
        let userID = user.userID
        let entity: LabelCountEntity? = lastUpdatedStore.lastUpdate(by: labelID, userID: userID, type: .singleMessage)
        // Don't have data usually means no scheduled message
        let total = entity?.total ?? 0
        completion(total < offlineSchedulingLimit)
    }
}

extension ComposeContainerViewModel: FileImporter {
    func fileSuccessfullyImported(as fileData: FileData) -> PromiseKit.Promise<Void> {
        fatalError("Should not call this method")
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
