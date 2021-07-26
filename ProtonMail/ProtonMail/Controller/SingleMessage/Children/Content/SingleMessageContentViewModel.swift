struct SingleMessageContentViewContext {
    let labelId: String
    let message: Message
    let viewMode: ViewMode
}

class SingleMessageContentViewModel {

    private(set) var message: Message {
        didSet { propagateMessageData() }
    }

    let linkOpener: LinkOpener = userCachedStatus.browser
    let shouldAutoLoadRemoteImage: Bool

    let messageBodyViewModel: NewMessageBodyViewModel
    let attachmentViewModel: AttachmentViewModel
    let bannerViewModel: BannerViewModel

    var embedExpandedHeader: ((ExpandedHeaderViewModel) -> Void)?
    var embedNonExpandedHeader: ((NonExpandedHeaderViewModel) -> Void)?
    var updateErrorBanner: ((NSError?) -> Void)?

    let context: SingleMessageContentViewContext

    private let internetStatusProvider: InternetConnectionStatusProvider
    private let messageService: MessageDataService
    private let user: UserManager
    private var isDetailedDownloaded: Bool?

    var isExpanded = false {
        didSet { isExpanded ? createExpandedHeaderViewModel() : createNonExpandedHeaderViewModel() }
    }

    var recalcualteCellHeight: (() -> Void)? {
        didSet {
            messageBodyViewModel.recalculateCellHeight = { [weak self] in self?.recalcualteCellHeight?() }
            bannerViewModel.recalculateCellHeight = { [weak self] in self?.recalcualteCellHeight?() }
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
            embedExpandedHeader?(viewModel)
            nonExapndedHeaderViewModel = nil
        }
    }


    init(context: SingleMessageContentViewContext,
         childViewModels: SingleMessageChildViewModels,
         user: UserManager,
         internetStatusProvider: InternetConnectionStatusProvider) {
        self.context = context
        self.user = user
        self.shouldAutoLoadRemoteImage = user.autoLoadRemoteImages
        self.message = context.message
        self.messageBodyViewModel = childViewModels.messageBody
        self.nonExapndedHeaderViewModel = childViewModels.nonExpandedHeader
        self.bannerViewModel = childViewModels.bannerViewModel
        self.attachmentViewModel = childViewModels.attachments
        self.internetStatusProvider = internetStatusProvider
        self.messageService = user.messageService
    }

    func messageHasChanged(message: Message) {
        self.message = message
    }

    func propagateMessageData() {
        nonExapndedHeaderViewModel?.messageHasChanged(message: message)
        expandedHeaderViewModel?.messageHasChanged(message: message)
        attachmentViewModel.messageHasChanged(message: message)
        bannerViewModel.messageHasChanged(message: message)

        if self.isDetailedDownloaded != message.isDetailDownloaded && message.isDetailDownloaded {
            self.isDetailedDownloaded = true
            self.messageBodyViewModel.messageHasChanged(message: self.message)
        }
        recalcualteCellHeight?()
    }

    func viewDidLoad() {
        markReadIfNeeded()
        messageBodyViewModel.messageHasChanged(message: self.message, isError: false)
        downloadDetails()
    }

    func downloadDetails() {
        let shouldLoadBody = message.body.isEmpty || !message.isDetailDownloaded
        self.isDetailedDownloaded = !shouldLoadBody
        guard internetStatusProvider.currentStatus != .NotReachable else {
            self.messageBodyViewModel.messageHasChanged(message: self.message, isError: true)
            return
        }
        guard !(self.isDetailedDownloaded ?? false) else {
            self.messageBodyViewModel.messageHasChanged(message: self.message)
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
        }
    }

    private func markReadIfNeeded() {
        guard message.unRead else { return }
        messageService.mark(messages: [message], labelID: context.labelId, unRead: false)
    }

    private func createExpandedHeaderViewModel() {
        expandedHeaderViewModel = ExpandedHeaderViewModel(labelId: context.labelId, message: message, user: user)
    }

    private func createNonExpandedHeaderViewModel() {
        nonExapndedHeaderViewModel = NonExpandedHeaderViewModel(labelId: context.labelId, message: message, user: user)
    }

}
