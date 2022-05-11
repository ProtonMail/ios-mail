import Foundation
import ProtonCore_Networking

struct SingleMessageContentViewContext {
    let labelId: LabelID
    let message: MessageEntity
    let viewMode: ViewMode
}

class SingleMessageContentViewModel {

    private(set) var message: MessageEntity {
        didSet { propagateMessageData() }
    }

    let linkOpener: LinkOpener = userCachedStatus.browser

    let messageBodyViewModel: NewMessageBodyViewModel
    let attachmentViewModel: AttachmentViewModel
    let bannerViewModel: BannerViewModel

    var embedExpandedHeader: ((ExpandedHeaderViewModel) -> Void)?
    var embedNonExpandedHeader: ((NonExpandedHeaderViewModel) -> Void)?
    var messageHadChanged: (() -> Void)?
    var updateErrorBanner: ((NSError?) -> Void)?

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
            embedNonExpandedHeader?(viewModel)
            expandedHeaderViewModel = nil
        }
    }

    var expandedHeaderViewModel: ExpandedHeaderViewModel? {
        didSet {
            guard let viewModel = expandedHeaderViewModel else { return }
            if viewModel.senderContact == nil {
                guard let nonExpandedVM = nonExapndedHeaderViewModel else { return }
                viewModel.setUp(senderContact: nonExpandedVM.senderContact)
            }
            embedExpandedHeader?(viewModel)
        }
    }

    init(context: SingleMessageContentViewContext,
         childViewModels: SingleMessageChildViewModels,
         user: UserManager,
         internetStatusProvider: InternetConnectionStatusProvider) {
        self.context = context
        self.user = user
        self.message = context.message
        self.messageBodyViewModel = childViewModels.messageBody
        self.nonExapndedHeaderViewModel = childViewModels.nonExpandedHeader
        self.bannerViewModel = childViewModels.bannerViewModel
        self.attachmentViewModel = childViewModels.attachments
        self.internetStatusProvider = internetStatusProvider
        self.messageService = user.messageService
    }

    func messageHasChanged(message: MessageEntity) {
        self.message = message
        self.messageHadChanged?()
    }

    func propagateMessageData() {
        if self.isDetailedDownloaded != message.isDetailDownloaded && message.isDetailDownloaded {
            self.isDetailedDownloaded = true
            self.messageBodyViewModel.messageHasChanged(message: self.message)
        }
        nonExapndedHeaderViewModel?.messageHasChanged(message: message)
        expandedHeaderViewModel?.messageHasChanged(message: message)
        attachmentViewModel.messageHasChanged(message: message)
        bannerViewModel.messageHasChanged(message: message)
        recalculateCellHeight?(false)
    }

    func viewDidLoad() {
        messageBodyViewModel.messageHasChanged(message: self.message, isError: false)
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
            self.messageBodyViewModel.messageHasChanged(message: self.message, isError: true)
            return
        }
        messageService.fetchMessageDetailForMessage(message, labelID: context.labelId, runInQueue: false) { [weak self] _, _, _, error in
            guard let self = self else { return }
            self.updateErrorBanner?(error)
            if error != nil && !self.message.isDetailDownloaded {
                self.messageBodyViewModel.messageHasChanged(message: self.message, isError: true)
            } else if shouldLoadBody {
                self.messageBodyViewModel.messageHasChanged(message: self.message)
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
        messageService.mark(messages: [message], labelID: context.labelId, unRead: false)
    }

    func markUnreadIfNeeded() {
        messageService.mark(messages: [message], labelID: context.labelId, unRead: true)
    }

    func getCypherURL() -> URL? {
        let filename = UUID().uuidString
        return try? self.writeToTemporaryUrl(message.body, filename: filename)
    }

    private func writeToTemporaryUrl(_ content: String, filename: String) throws -> URL {
        let tempFileUri = FileManager.default.temporaryDirectoryUrl
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
        let newVM = ExpandedHeaderViewModel(labelId: context.labelId,
                                            message: message,
                                            user: user)
        // This will happen when scroll a long conversation
        if let vm = expandedHeaderViewModel,
           let contact = vm.senderContact {
            newVM.setUp(senderContact: contact)
        }
        expandedHeaderViewModel = newVM
    }

    private func createNonExpandedHeaderViewModel() {
        nonExapndedHeaderViewModel = NonExpandedHeaderViewModel(labelId: context.labelId, message: message, user: user)
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

}
