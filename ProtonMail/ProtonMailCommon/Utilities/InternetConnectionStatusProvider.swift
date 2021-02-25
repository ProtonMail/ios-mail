class InternetConnectionStatusProvider {

    private let notificationCenter: NotificationCenter
    private let reachability: Reachability
    private var currentStatusHasChanged: ((NetworkStatus) -> Void)?

    init(notificationCenter: NotificationCenter = .default,
         reachability: Reachability = .forInternetConnection()) {
        self.notificationCenter = notificationCenter
        self.reachability = reachability
    }

    func getConnectionStatuses(currentStatus: @escaping (NetworkStatus) -> Void) {
        currentStatusHasChanged = currentStatus
        currentStatus(reachability.currentReachabilityStatus())
        startReachabilityStatusObservation()
    }

    func stopInternetConnectionStatusObservation() {
        notificationCenter.removeObserver(self)
    }

    var currentStatus: NetworkStatus {
        reachability.currentReachabilityStatus()
    }

    // MARK: - Private

    private func startReachabilityStatusObservation() {
        notificationCenter.addObserver(
            self,
            selector: #selector(connectionStatusHasChanged(notification:)),
            name: .reachabilityChanged,
            object: nil
        )
    }

    @objc private func connectionStatusHasChanged(notification: Notification) {
        guard let reachability = notification.object as? Reachability else { return }
        let currentStatus = reachability.currentReachabilityStatus()
        currentStatusHasChanged?(currentStatus)
    }

}
