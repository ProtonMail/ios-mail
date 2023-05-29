import ProtonCore_DataModel
import ProtonCore_Networking

struct SingleMessageContentViewContext {
    let labelId: LabelID
    let message: MessageEntity
    let viewMode: ViewMode
}

protocol SingleMessageContentUIProtocol: AnyObject {
    func updateContentBanner(
        shouldShowRemoteContentBanner: Bool,
        shouldShowEmbeddedContentBanner: Bool,
        shouldShowImageProxyFailedBanner: Bool,
        shouldShowSenderIsBlockedBanner: Bool
    )
    func setDecryptionErrorBanner(shouldShow: Bool)
    func update(hasStrippedVersion: Bool)
    func updateAttachmentBannerIfNeeded()
    func trackerProtectionSummaryChanged()
}

class SingleMessageContentViewModel {

    let messageInfoProvider: MessageInfoProvider

    private(set) var message: MessageEntity {
        didSet { propagateMessageData() }
    }
    private(set) weak var uiDelegate: SingleMessageContentUIProtocol?

    let linkOpener: LinkOpener = userCachedStatus.browser

    let messageBodyViewModel: NewMessageBodyViewModel
    let attachmentViewModel: AttachmentViewModel
    let bannerViewModel: BannerViewModel
    let dependencies: Dependencies

    var embedExpandedHeader: ((ExpandedHeaderViewModel) -> Void)?
    var embedNonExpandedHeader: ((NonExpandedHeaderViewModel) -> Void)?
    var messageHadChanged: (() -> Void)?
    var updateErrorBanner: ((NSError?) -> Void)?
    let goToDraft: ((MessageID, OriginalScheduleDate?) -> Void)
    var showProgressHub: (() -> Void)?
    var hideProgressHub: (() -> Void)?

    var isEmbedInConversationView: Bool {
        context.viewMode == .conversation
    }

    let context: SingleMessageContentViewContext
    let user: UserManager

    private let internetStatusProvider: InternetConnectionStatusProvider
    private let messageService: MessageDataService
    private let observerID = UUID()

    var isExpanded = false {
        didSet { isExpanded ? createExpandedHeaderViewModel() : createNonExpandedHeaderViewModel() }
    }

    var recalculateCellHeight: ((_ isLoaded: Bool) -> Void)? {
        didSet {
            messageBodyViewModel.recalculateCellHeight = { [weak self] in self?.recalculateCellHeight?($0) }
            bannerViewModel.recalculateCellHeight = { [weak self] in self?.recalculateCellHeight?($0) }
        }
    }

    var resetLoadedHeight: (() -> Void)? {
        didSet {
            bannerViewModel.resetLoadedHeight = { [weak self] in self?.resetLoadedHeight?() }
        }
    }

    private var nonExpandedHeaderViewModel: NonExpandedHeaderViewModel? {
        didSet {
            guard let viewModel = nonExpandedHeaderViewModel else { return }
            embedNonExpandedHeader?(viewModel)
            expandedHeaderViewModel = nil
        }
    }

    private var expandedHeaderViewModel: ExpandedHeaderViewModel? {
        didSet {
            guard let viewModel = expandedHeaderViewModel else { return }
            embedExpandedHeader?(viewModel)
        }
    }

    private var hasAlreadyFetchedMessageData = false

    var webContentIsUpdated: (() -> Void)?

    var isSenderCurrentlyBlocked: Bool {
        do {
            let incomingDefaultsForSenderEmail = try dependencies.incomingDefaultService.listLocal(
                query: .email(messageInfoProvider.senderEmail)
            )

            return incomingDefaultsForSenderEmail.map(\.location).contains(.blocked)
        } catch {
            assertionFailure("\(error)")
            return false
        }
    }

    init(context: SingleMessageContentViewContext,
         imageProxy: ImageProxy,
         childViewModels: SingleMessageChildViewModels,
         user: UserManager,
         internetStatusProvider: InternetConnectionStatusProvider,
         systemUpTime: SystemUpTimeProtocol,
         shouldOpenHistory: Bool = false,
         dependencies: Dependencies,
         goToDraft: @escaping (MessageID, OriginalScheduleDate?) -> Void) {
        self.context = context
        self.user = user
        self.message = context.message
        let messageInfoProviderDependencies = MessageInfoProvider.Dependencies(
            imageProxy: imageProxy,
            fetchAttachment: FetchAttachment(dependencies: .init(apiService: user.apiService)),
            fetchSenderImage: FetchSenderImage(
                dependencies: .init(
                    senderImageService: .init(
                        dependencies: .init(
                            apiService: user.apiService,
                            internetStatusProvider: internetStatusProvider
                        )
                    ),
                    senderImageStatusProvider: dependencies.senderImageStatusProvider,
                    mailSettings: user.mailSettings
                )
            )
        )

        self.messageInfoProvider = .init(
            message: context.message,
            user: user,
            systemUpTime: systemUpTime,
            labelID: context.labelId,
            shouldOpenHistory: shouldOpenHistory,
            dependencies: messageInfoProviderDependencies
        )
        imageProxy.set(delegate: messageInfoProvider)
        messageInfoProvider.initialize()
        self.messageBodyViewModel = childViewModels.messageBody
        self.bannerViewModel = childViewModels.bannerViewModel
        bannerViewModel.providerHasChanged(provider: messageInfoProvider)
        self.attachmentViewModel = childViewModels.attachments
        self.internetStatusProvider = internetStatusProvider
        self.messageService = user.messageService
        self.dependencies = dependencies
        self.goToDraft = goToDraft

        createNonExpandedHeaderViewModel()

        self.bannerViewModel.editScheduledMessage = { [weak self] in
            guard let self = self else {
                return
            }
            let msgID = self.message.messageID
            let originalScheduledTime = self.message.time
            self.showProgressHub?()
            self.user.messageService.undoSend(
                of: msgID) { [weak self] result in
                    self?.user.eventsService.fetchEvents(byLabel: Message.Location.allmail.labelID,
                                                         notificationMessageID: nil,
                                                         completion: { [weak self] _ in
                        self?.hideProgressHub?()
                        self?.goToDraft(msgID, .init(originalScheduledTime))
                    })
                }
        }

        messageInfoProvider.set(delegate: self)
        messageBodyViewModel.update(content: messageInfoProvider.contents)
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
        self.messageHadChanged?()
    }

    func propagateMessageData() {
        messageInfoProvider.update(message: message)
        nonExpandedHeaderViewModel?.providerHasChanged(provider: messageInfoProvider)
        expandedHeaderViewModel?.providerHasChanged(provider: messageInfoProvider)
        bannerViewModel.providerHasChanged(provider: messageInfoProvider)
        messageBodyViewModel.update(spam: message.spam)
        recalculateCellHeight?(false)
    }

    func viewDidLoad() {
        becomeBlockedSenderCacheUpdaterDelegate()
        downloadDetails()
    }

    func viewWillAppear() {
        becomeBlockedSenderCacheUpdaterDelegate()
    }

    private func becomeBlockedSenderCacheUpdaterDelegate() {
        dependencies.blockedSenderCacheUpdater.delegate = self
    }

    func downloadDetails() {
        let shouldLoadBody = message.body.isEmpty || !message.isDetailDownloaded
        // The parsedHeader is added in the MAILIOS-2335
        // the user update from the older app doesn't have the parsedHeader
        // have to call api again to fetch it
        let isDetailedDownloaded = !shouldLoadBody && !message.parsedHeaders.isEmpty
        guard !isDetailedDownloaded else {
            if !isEmbedInConversationView {
                markReadIfNeeded()
            }
            return
        }
        guard internetStatusProvider.currentStatus != .notConnected else {
            messageBodyViewModel.errorHappens()
            return
        }
        hasAlreadyFetchedMessageData = true
        let params: FetchMessageDetail.Params = .init(userID: user.userID, message: message)
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.updateErrorBanner?(nil)
                case .failure(let error):
                    self.updateErrorBanner?(error as NSError)
                    self.messageBodyViewModel.errorHappens()
                }
            }
        }
    }

    /// - param blocked: whether to block or unblock the sender
    /// - returns: true if action was successful (errors are handled by the view model)
    func updateSenderBlockedStatus(blocked: Bool) -> Bool {
        let senderEmail = messageInfoProvider.senderEmail

        defer {
            updateBannerStatus()
        }

        do {
            if blocked {
                let parameters = BlockSender.Parameters(emailAddress: senderEmail)
                try dependencies.blockSender.execute(parameters: parameters)
            } else {
                let parameters = UnblockSender.Parameters(emailAddress: senderEmail)
                try dependencies.unblockSender.execute(parameters: parameters)
            }

            updateErrorBanner?(nil)
            return true
        } catch {
            updateErrorBanner?(error as NSError)
            return false
        }
    }

    func deleteExpiredMessages() {
        messageService.deleteExpiredMessage(completion: nil)
    }

    func markReadIfNeeded() {
        guard message.unRead else { return }
        messageService.mark(messageObjectIDs: [message.objectID.rawValue], labelID: context.labelId, unRead: false)
    }

    func markUnreadIfNeeded() {
        guard !message.unRead else { return }
        messageService.mark(messageObjectIDs: [message.objectID.rawValue], labelID: context.labelId, unRead: true)
    }

    func getCypherURL() -> URL? {
        let filename = UUID().uuidString
        return try? self.writeToTemporaryUrl(message.body, filename: filename)
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename, isDirectory: false).appendingPathExtension("txt")
        try? FileManager.default.removeItem(at: tempFileUri)
        try content.write(to: tempFileUri, atomically: true, encoding: .utf8)
        return tempFileUri
    }

    func sendDarkModeMetric(isApply: Bool) {
        let request = MetricDarkMode(applyDarkStyle: isApply)
        self.user.apiService.perform(request: request, response: Response()) { _, _ in

        }
    }

    private func createExpandedHeaderViewModel() {
        let newVM = ExpandedHeaderViewModel(infoProvider: messageInfoProvider)
        expandedHeaderViewModel = newVM
    }

    private func createNonExpandedHeaderViewModel() {
        nonExpandedHeaderViewModel = NonExpandedHeaderViewModel(infoProvider: messageInfoProvider)
    }

    func startMonitorConnectionStatus(isApplicationActive: @escaping () -> Bool,
                                      reloadWhenAppIsActive: @escaping (Bool) -> Void) {
        internetStatusProvider.registerConnectionStatus(observerID: observerID) { [weak self] networkStatus in
            guard self?.message.body.isEmpty == true else {
                return
            }
            guard self?.hasAlreadyFetchedMessageData == true else {
                return
            }
            let isApplicationActive = isApplicationActive()
            switch isApplicationActive {
            case true where networkStatus == .notConnected:
                break
            case true:
                self?.downloadDetails()
            default:
                reloadWhenAppIsActive(true)
            }
        }
    }

    func set(uiDelegate: SingleMessageContentUIProtocol) {
        self.uiDelegate = uiDelegate
    }

    func sendMetricAPIIfNeeded(isDarkModeStyle: Bool) {
        guard isDarkModeStyle,
              messageInfoProvider.contents?.supplementCSS != nil,
              messageInfoProvider.contents?.renderStyle == .dark else { return }
        sendDarkModeMetric(isApply: true)
    }
}

extension SingleMessageContentViewModel: BlockedSenderCacheUpdaterDelegate {
    func blockedSenderCacheUpdater(_ blockedSenderCacheUpdater: BlockedSenderCacheUpdater, didEnter newState: BlockedSenderCacheUpdater.State) {
        if newState == .idle {
            updateBannerStatus()
        }
    }
}

extension SingleMessageContentViewModel: MessageInfoProviderDelegate {
    func update(renderStyle: MessageRenderStyle) {
        DispatchQueue.main.async {
            self.messageBodyViewModel.update(renderStyle: renderStyle)
        }
    }

    func updateBannerStatus() {
        DispatchQueue.main.async {
            self.uiDelegate?.updateContentBanner(
                shouldShowRemoteContentBanner: self.messageInfoProvider.shouldShowRemoteBanner,
                shouldShowEmbeddedContentBanner: self.messageInfoProvider.shouldShowEmbeddedBanner,
                shouldShowImageProxyFailedBanner: self.messageInfoProvider.shouldShowImageProxyFailedBanner,
                shouldShowSenderIsBlockedBanner: self.isSenderCurrentlyBlocked
            )
        }
    }

    func update(content: WebContents?) {
        DispatchQueue.main.async {
            self.messageBodyViewModel.update(content: content)
            self.webContentIsUpdated?()
        }
    }

    func hideDecryptionErrorBanner() {
        DispatchQueue.main.async {
            self.uiDelegate?.setDecryptionErrorBanner(shouldShow: false)
        }
    }

    func showDecryptionErrorBanner() {
        DispatchQueue.main.async {
            self.uiDelegate?.setDecryptionErrorBanner(shouldShow: true)
        }
    }

    func providerHasChanged() {
        DispatchQueue.main.async {
            self.nonExpandedHeaderViewModel?.providerHasChanged(provider: self.messageInfoProvider)
            self.expandedHeaderViewModel?.providerHasChanged(provider: self.messageInfoProvider)
            self.bannerViewModel.providerHasChanged(provider: self.messageInfoProvider)
        }
    }

    func update(hasStrippedVersion: Bool) {
        DispatchQueue.main.async {
            self.uiDelegate?.update(hasStrippedVersion: hasStrippedVersion)
        }
    }

    func updateAttachments() {
        DispatchQueue.main.async {
            self.attachmentViewModel.attachmentHasChanged(
                attachments: self.messageInfoProvider.nonInlineAttachments.map(AttachmentNormal.init),
                mimeAttachments: self.messageInfoProvider.mimeAttachments
            )
            self.uiDelegate?.updateAttachmentBannerIfNeeded()
        }
    }

    func trackerProtectionSummaryChanged() {
        DispatchQueue.main.async {
            self.uiDelegate?.trackerProtectionSummaryChanged()
        }
    }
}

extension SingleMessageContentViewModel {
    struct Dependencies {
        let blockSender: BlockSender
        let blockedSenderCacheUpdater: BlockedSenderCacheUpdater
        let fetchMessageDetail: FetchMessageDetailUseCase
        let incomingDefaultService: IncomingDefaultService
        let senderImageStatusProvider: SenderImageStatusProvider
        let unblockSender: UnblockSender
    }
}
