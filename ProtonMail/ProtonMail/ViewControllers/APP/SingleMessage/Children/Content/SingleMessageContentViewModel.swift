import Foundation
import ProtonCore_Networking

struct SingleMessageContentViewContext {
    let labelId: LabelID
    let message: MessageEntity
    let viewMode: ViewMode
}

protocol SingleMessageContentUIProtocol: AnyObject {
    func updateContentBanner(shouldShowRemoteContentBanner: Bool,
                             shouldShowEmbeddedContentBanner: Bool)
    func setDecryptionErrorBanner(shouldShow: Bool)
    func update(hasStrippedVersion: Bool)
}

class SingleMessageContentViewModel {

    private(set) var messageInfoProvider: MessageInfoProvider
    private(set) var message: MessageEntity {
        didSet { propagateMessageData() }
    }
    private(set) weak var uiDelegate: SingleMessageContentUIProtocol?

    let linkOpener: LinkOpener = userCachedStatus.browser

    let messageBodyViewModel: NewMessageBodyViewModel
    let attachmentViewModel: AttachmentViewModel
    let bannerViewModel: BannerViewModel

    var embedExpandedHeader: ((ExpandedHeaderViewModel) -> Void)?
    var embedNonExpandedHeader: ((NonExpandedHeaderViewModel) -> Void)?
    var messageHadChanged: (() -> Void)?
    var updateErrorBanner: ((NSError?) -> Void)?
    let goToDraft: ((MessageID) -> Void)
    var showProgressHub: (() -> Void)?
    var hideProgressHub: (() -> Void)?

    var isEmbedInConversationView: Bool {
        context.viewMode == .conversation
    }

    let context: SingleMessageContentViewContext
    let user: UserManager

    private let internetStatusProvider: InternetConnectionStatusProvider
    private let messageService: MessageDataService
    private var isDetailedDownloaded: Bool?

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

    var nonExapndedHeaderViewModel: NonExpandedHeaderViewModel? {
        didSet {
            guard let viewModel = nonExapndedHeaderViewModel else { return }
            viewModel.providerHasChanged(provider: messageInfoProvider)
            embedNonExpandedHeader?(viewModel)
            expandedHeaderViewModel = nil
        }
    }

    var expandedHeaderViewModel: ExpandedHeaderViewModel? {
        didSet {
            guard let viewModel = expandedHeaderViewModel else { return }
            embedExpandedHeader?(viewModel)
        }
    }

    init(context: SingleMessageContentViewContext,
         childViewModels: SingleMessageChildViewModels,
         user: UserManager,
         internetStatusProvider: InternetConnectionStatusProvider,
         systemUpTime: SystemUpTimeProtocol,
         isDarkModeEnableClosure: @escaping () -> Bool,
         goToDraft: @escaping (MessageID) -> Void) {
        self.context = context
        self.user = user
        self.message = context.message
        self.messageInfoProvider = .init(message: context.message, user: user, systemUpTime: systemUpTime, labelID: context.labelId, isDarkModeEnableClosure: isDarkModeEnableClosure)
        self.messageBodyViewModel = childViewModels.messageBody
        self.nonExapndedHeaderViewModel = childViewModels.nonExpandedHeader
        self.bannerViewModel = childViewModels.bannerViewModel
        bannerViewModel.providerHasChanged(provider: messageInfoProvider)
        self.attachmentViewModel = childViewModels.attachments
        self.internetStatusProvider = internetStatusProvider
        self.messageService = user.messageService
        self.goToDraft = goToDraft

        self.bannerViewModel.editScheduledMessage = { [weak self] in
            guard let self = self else {
                return
            }
            let msgID = self.message.messageID
            self.showProgressHub?()
            let request = UndoSendRequest(messageID: self.message.messageID)
            self.user.apiService.exec(route: request) { [weak self] (result: Result<UndoSendResponse, ResponseError>) in
                self?.user.eventsService.fetchEvents(byLabel: Message.Location.allmail.labelID,
                                                     notificationMessageID: nil,
                                                     completion: { [weak self] _, _, _ in
                    self?.hideProgressHub?()
                    self?.goToDraft(msgID)
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
        if self.isDetailedDownloaded != message.isDetailDownloaded && message.isDetailDownloaded {
            self.isDetailedDownloaded = true
        }

        messageInfoProvider.update(message: message)
        nonExapndedHeaderViewModel?.providerHasChanged(provider: messageInfoProvider)
        expandedHeaderViewModel?.providerHasChanged(provider: messageInfoProvider)
        bannerViewModel.providerHasChanged(provider: messageInfoProvider)
        messageBodyViewModel.update(spam: message.spam)
        recalculateCellHeight?(false)
    }

    func viewDidLoad() {
        downloadDetails()
    }

    func downloadDetails() {
        let shouldLoadBody = message.body.isEmpty || !message.isDetailDownloaded
        // The parsedHeader is added in the MAILIOS-2335
        // the user update from the older app doesn't have the parsedHeader
        // have to call api again to fetch it
        self.isDetailedDownloaded = !shouldLoadBody && !message.parsedHeaders.isEmpty
        guard !(self.isDetailedDownloaded ?? false) else {
            if !isEmbedInConversationView {
                markReadIfNeeded()
            }
            return
        }
        guard internetStatusProvider.currentStatus != .notConnected else {
            messageBodyViewModel.errorHappens()
            return
        }
        messageService.fetchMessageDetailForMessage(message, labelID: context.labelId, runInQueue: false) { [weak self] _, _, _, error in
            guard let self = self else { return }
            self.updateErrorBanner?(error)
            if error != nil && !self.message.isDetailDownloaded {
                self.messageBodyViewModel.errorHappens()
            }

            if !self.isEmbedInConversationView {
                self.markReadIfNeeded()
            }
        }
    }

    func deleteExpiredMessages() {
        messageService.deleteExpiredMessage(completion: nil)
    }

    func markReadIfNeeded() {
        guard message.unRead else { return }
        messageService.mark(messages: [message], labelID: context.labelId, unRead: false)
    }

    func markUnreadIfNeeded() {
        guard !message.unRead else { return }
        messageService.mark(messages: [message], labelID: context.labelId, unRead: true)
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
        self.user.apiService.exec(route: request, responseObject: Response()) { _ in

        }
    }

    private func createExpandedHeaderViewModel() {
        let newVM = ExpandedHeaderViewModel(infoProvider: messageInfoProvider)
        expandedHeaderViewModel = newVM
    }

    private func createNonExpandedHeaderViewModel() {
        nonExapndedHeaderViewModel = NonExpandedHeaderViewModel(isScheduledSend: messageInfoProvider.message.isScheduledSend)
    }

    func startMonitorConnectionStatus(isApplicationActive: @escaping () -> Bool,
                                      reloadWhenAppIsActive: @escaping (Bool) -> Void) {
        internetStatusProvider.registerConnectionStatus { [weak self] networkStatus in
            guard self?.message.body.isEmpty == true else {
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
                shouldShowEmbeddedContentBanner: self.messageInfoProvider.shouldShowEmbeddedBanner
            )
        }
    }

    func update(content: WebContents?) {
        DispatchQueue.main.async {
            self.messageBodyViewModel.update(content: content)
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

    func update(senderContact: ContactVO?) {
        DispatchQueue.main.async {
            self.nonExapndedHeaderViewModel?.providerHasChanged(provider: self.messageInfoProvider)
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
                inlines: (self.messageInfoProvider.inlineAttachments ?? []).map(AttachmentNormal.init),
                mimeAttachments: self.messageInfoProvider.mimeAttachments
            )
        }
    }
}
