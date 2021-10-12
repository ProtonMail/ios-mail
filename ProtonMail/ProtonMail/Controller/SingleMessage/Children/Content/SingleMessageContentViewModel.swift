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
        recalculateCellHeight?(false)
    }

    func viewDidLoad() {
        messageBodyViewModel.messageHasChanged(message: self.message, isError: false)
        downloadDetails()
    }

    func downloadDetails() {
        let shouldLoadBody = message.body.isEmpty || !message.isDetailDownloaded
        self.isDetailedDownloaded = !shouldLoadBody
        guard !(self.isDetailedDownloaded ?? false) else {
            if !isEmbedInConversationView {
                markReadIfNeeded()
            }
            return
        }
        guard internetStatusProvider.currentStatus != .NotReachable else {
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
        guard message.unRead else { return }
        messageService.mark(messages: [message], labelID: context.labelId, unRead: false)
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

}
