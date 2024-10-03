import Combine
import ProtonCoreDataModel
import ProtonCoreKeymaker
import ProtonCoreNetworking

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
    func didUnSnooze()
}

class SingleMessageContentViewModel {

    var messageInfoProvider: MessageInfoProvider {
        dependencies.messageInfoProvider
    }

    private(set) var message: MessageEntity {
        didSet { propagateMessageData() }
    }
    private(set) weak var uiDelegate: SingleMessageContentUIProtocol?

    private(set) lazy var linkOpener: LinkOpener = {
        dependencies.keychain[.browser]
    }()

    let messageBodyViewModel: NewMessageBodyViewModel
    let attachmentViewModel: AttachmentViewModel
    let bannerViewModel: BannerViewModel
    let dependencies: Dependencies

    var embedExpandedHeader: ((ExpandedHeaderViewModel) -> Void)?
    var embedNonExpandedHeader: ((NonExpandedHeaderViewModel) -> Void)?
    var messageHadChanged: (() -> Void)?
    var updateErrorBanner: ((NSError?) -> Void)?
    let goToDraft: ((MessageID, Date?) -> Void)
    var showProgressHub: (() -> Void)?
    var hideProgressHub: (() -> Void)?
    private var isApplicationActive: (() -> Bool)?
    private var reloadWhenAppIsActive: (() -> Void)?
    private var hasCalledMarkAsRead = false

    var isEmbedInConversationView: Bool {
        context.viewMode == .conversation
    }
    // Is view has shown to user 
    var viewHasAppeared = false {
        didSet {
            if !isEmbedInConversationView && message.isDetailDownloaded {
                markReadIfNeeded()
            }
        }
    }

    let context: SingleMessageContentViewContext
    let user: UserManager

    private let internetStatusProvider: InternetConnectionStatusProviderProtocol
    private let messageService: MessageDataService

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

    private(set) var isSenderCurrentlyBlocked = false {
        didSet {
            updateBannerStatus()
        }
    }

    private var cancellables = Set<AnyCancellable>()

    init(context: SingleMessageContentViewContext,
         childViewModels: SingleMessageChildViewModels,
         user: UserManager,
         internetStatusProvider: InternetConnectionStatusProviderProtocol,
         dependencies: Dependencies,
         goToDraft: @escaping (MessageID, Date?) -> Void) {
        self.context = context
        self.user = user
        self.message = context.message
        self.messageBodyViewModel = childViewModels.messageBody
        self.bannerViewModel = childViewModels.bannerViewModel
        self.attachmentViewModel = childViewModels.attachments
        self.messageService = user.messageService
        self.internetStatusProvider = internetStatusProvider
        self.dependencies = dependencies
        self.goToDraft = goToDraft

        messageInfoProvider.initialize()
        bannerViewModel.providerHasChanged(provider: messageInfoProvider)

        createNonExpandedHeaderViewModel()

        bindBannerClosure()
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
        setupBinding()
        downloadDetails()
    }

    private func setupBinding() {
        dependencies.isSenderBlockedPublisher.isBlocked(senderEmailAddress: messageInfoProvider.senderEmail.string)
            .sink(receiveValue: { [weak self] value in
                if self?.isSenderCurrentlyBlocked != value {
                    self?.isSenderCurrentlyBlocked = value
                }
            })
            .store(in: &cancellables)

        dependencies.isSenderBlockedPublisher.start()
    }

    func downloadDetails() {
        let shouldLoadBody = message.body.isEmpty || !message.isDetailDownloaded
        // The parsedHeader is added in the MAILIOS-2335
        // the user update from the older app doesn't have the parsedHeader
        // have to call api again to fetch it
        let isDetailedDownloaded = !shouldLoadBody && !message.parsedHeaders.isEmpty
        guard !isDetailedDownloaded else {
            if !isEmbedInConversationView && viewHasAppeared {
                markReadIfNeeded()
            }
            return
        }
        guard internetStatusProvider.status != .notConnected else {
            messageBodyViewModel.errorHappens()
            return
        }
        hasAlreadyFetchedMessageData = true
        let params: FetchMessageDetail.Params = .init(message: message)
        dependencies.fetchMessageDetail
            .callbackOn(.main)
            .execute(params: params) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    if !self.isEmbedInConversationView && viewHasAppeared {
                        // To prevent detail response override the unread status
                        // markRead must be done after getting response
                        self.markReadIfNeeded()
                    }
                    self.updateErrorBanner?(nil)
                case .failure(let error):
                    self.updateErrorBanner?(error as NSError)
                    self.messageBodyViewModel.errorHappens()
                }
        }
    }

    /// - param blocked: whether to block or unblock the sender
    /// - returns: true if action was successful (errors are handled by the view model)
    func updateSenderBlockedStatus(blocked: Bool) -> Bool {
        let senderEmail = messageInfoProvider.senderEmail.string

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
        DispatchQueue.global().async {
            self.user.cacheService.deleteExpiredMessages()
        }
    }

    func markReadIfNeeded() {
        if hasCalledMarkAsRead { return }
        guard message.unRead || message.showReminder else { return }
        // To remove snooze time highlight, client needs to call /read API to sync with other device
        // But before reaching final state, this function will be called couple times
        // That means /read API will be called duplicated
        // Introduce `hasCalledMarkedRead` as workaround to prevent duplicated call
        hasCalledMarkAsRead = true
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
                                      reloadWhenAppIsActive: @escaping () -> Void) {
        self.isApplicationActive = isApplicationActive
        self.reloadWhenAppIsActive = reloadWhenAppIsActive
        internetStatusProvider.register(receiver: self, fireWhenRegister: true)
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

    func isProtonUnreachable(completion: @escaping (Bool) -> Void) {
        guard
            dependencies.featureFlagCache.isFeatureFlag(.protonUnreachableBanner, enabledForUserWithID: user.userID)
        else {
            completion(false)
            return
        }
        Task { [weak self] in
            let status = await self?.dependencies.checkProtonServerStatus.execute()
            await MainActor.run {
                completion(status == .serverDown)
            }
        }
    }

    private func bindBannerClosure() {
        bannerViewModel.editScheduledMessage = { [weak self] in
            guard let self = self else {
                return
            }
            let msgID = self.message.messageID
            let originalScheduledTime = self.message.time
            self.showProgressHub?()
            self.user.messageService.undoSend(of: msgID) { [weak self] result in
                self?.user.eventsService.fetchEvents(
                    byLabel: Message.Location.allmail.labelID,
                    notificationMessageID: nil,
                    discardContactsMetadata: EventCheckRequest.isNoMetaDataForContactsEnabled,
                    completion: { [weak self] _ in
                        DispatchQueue.main.async {
                            self?.hideProgressHub?()
                            self?.goToDraft(msgID, originalScheduledTime)
                        }
                    })
            }
        }

        bannerViewModel.unSnoozeMessage = { [weak self] in
            guard let self = self else { return }
            self.user.conversationService.unSnooze(conversationID: self.message.conversationID)
            self.uiDelegate?.didUnSnooze()
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
        let messageHeaders = messageInfoProvider.message.parsedHeaders

        DispatchQueue.main.async {
            self.attachmentViewModel.basicEventInfoSourcedFromHeaders = .init(messageHeaders: messageHeaders)

            self.attachmentViewModel.attachmentHasChanged(
                nonInlineAttachments: self.messageInfoProvider.nonInlineAttachments.map(AttachmentNormal.init),
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

extension SingleMessageContentViewModel: ConnectionStatusReceiver {
    func connectionStatusHasChanged(newStatus: ConnectionStatus) {
        guard message.body.isEmpty == true else {
            return
        }
        guard hasAlreadyFetchedMessageData == true,
              let isApplicationActiveClosure = isApplicationActive,
              let reloadWhenAppIsActiveClosure = reloadWhenAppIsActive else {
            return
        }
        let isApplicationActive = isApplicationActiveClosure()
        switch isApplicationActive {
        case true where newStatus == .notConnected:
            break
        case true:
            downloadDetails()
        default:
            reloadWhenAppIsActiveClosure()
        }
    }
}

extension SingleMessageContentViewModel {
    struct Dependencies {
        let blockSender: BlockSender
        let fetchMessageDetail: FetchMessageDetailUseCase
        let isSenderBlockedPublisher: IsSenderBlockedPublisher
        let keychain: Keychain
        let messageInfoProvider: MessageInfoProvider
        let unblockSender: UnblockSender
        let checkProtonServerStatus: CheckProtonServerStatusUseCase
        let featureFlagCache: FeatureFlagCache
    }
}
