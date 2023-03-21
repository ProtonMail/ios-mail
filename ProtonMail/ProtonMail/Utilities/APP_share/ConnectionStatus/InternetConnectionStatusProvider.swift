import Foundation
import Network

enum ConnectionStatus: Int {
    case connected,
         connectedViaCellular,
         connectedViaCellularWithoutInternet,
         connectedViaEthernet,
         connectedViaEthernetWithoutInternet,
         connectedViaWiFi,
         connectedViaWiFiWithoutInternet,
         notConnected

    var isConnected: Bool {
        switch self {
        case .connected, .connectedViaCellular, .connectedViaEthernet, .connectedViaWiFi:
            return true
        case .notConnected, .connectedViaWiFiWithoutInternet, .connectedViaCellularWithoutInternet, .connectedViaEthernetWithoutInternet:
            return false
        }
    }
    
    var desc: String {
        switch self {
        case .connected:
            return "connected"
        case .connectedViaCellular:
            return "connectedViaCellular"
        case .connectedViaCellularWithoutInternet:
            return "connectedViaCellularWithoutInternet"
        case .connectedViaEthernet:
            return "connectedViaEthernet"
        case .connectedViaEthernetWithoutInternet:
            return "connectedViaEthernetWithoutInternet"
        case .connectedViaWiFi:
            return "connectedViaWiFi"
        case .connectedViaWiFiWithoutInternet:
            return "connectedViaWiFiWithoutInternet"
        case .notConnected:
            return "notConnected"
        }
    }
}

// sourcery: mock
protocol InternetConnectionStatusProviderProtocol {
    var currentStatus: ConnectionStatus { get }

    func registerConnectionStatus(observerID: UUID, callback: @escaping (ConnectionStatus) -> Void)
    func unregisterObserver(observerID: UUID)
}

class InternetConnectionStatusProvider: InternetConnectionStatusProviderProtocol, Service {

    private let notificationCenter: NotificationCenter
    private var reachability: Reachability
    private var callbacksToNotify: [UUID: (ConnectionStatus) -> Void] = [:]
    // Stores the reference of NWPathMonitor
    var pathMonitor: ConnectionMonitor?
    private var isPathMonitorUpdated = false

    init(notificationCenter: NotificationCenter = .default,
         reachability: Reachability = .forInternetConnection(),
         connectionMonitor: ConnectionMonitor? = ConnectionMonitorFactory.makeMonitor()) {
        self.notificationCenter = notificationCenter
        self.reachability = reachability
        self.pathMonitor = connectionMonitor
        startObservation()
    }

    deinit {
        if #available(iOS 12, *), let monitor = pathMonitor {
            monitor.pathUpdateHandler = nil
            monitor.cancel()
        }
        stopInternetConnectionStatusObservation()
    }

    /**
     Observe connectivity status changes.

    - parameter observerID: Each observing object should store its own UUID to avoid accidentally registering multiple times and to allow unregistering.
     */
    func registerConnectionStatus(observerID: UUID, callback: @escaping ((ConnectionStatus) -> Void)) {
        callbacksToNotify[observerID] = callback
        callback(currentStatus)
    }

    func unregisterObserver(observerID: UUID) {
        callbacksToNotify.removeValue(forKey: observerID)
    }

    func startObservation() {
        if #available(iOS 12, *), let monitor = pathMonitor {
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                self.isPathMonitorUpdated = true
                let status = self.status(from: path)
                self.callbacksToNotify.values.forEach { callback in
                    callback(status)
                }
            }
            monitor.start(queue: .main)
        } else {
            startReachabilityStatusObservation()
        }
    }

    func stopInternetConnectionStatusObservation() {
        if #available(iOS 12, *), let monitor = pathMonitor {
            monitor.pathUpdateHandler = nil
            monitor.cancel()
        }
        notificationCenter.removeObserver(self)
    }

    var currentStatus: ConnectionStatus {
        /* When the NWMonitor is initialized, the status of the network is not correct.
            It will update after a short period of time.
            When that happens, use the status of the Reachability.
         */
        if #available(iOS 12, *),
           let monitor = pathMonitor,
           let path = monitor.currentNWPath,
           isPathMonitorUpdated {
            return self.status(from: path)
        } else {
            let status = reachability.currentReachabilityStatus()
            return self.status(from: status)
        }
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
        self.reachability = reachability
        let currentStatus = reachability.currentReachabilityStatus()
        let result = self.status(from: currentStatus)
        self.callbacksToNotify.values.forEach { callback in
            callback(result)
        }
    }

}

extension InternetConnectionStatusProvider {
    func status(from networkStatus: NetworkStatus) -> ConnectionStatus {
        switch networkStatus {
        case .NotReachable:
            return .notConnected
        case .ReachableViaWiFi:
            return .connectedViaWiFi
        case .ReachableViaWWAN:
            return .connectedViaCellular
        @unknown default:
            return .notConnected
        }
    }

    @available(iOS 12.0, *)
    func status(from path: NWPath) -> ConnectionStatus {
        guard path.status == .satisfied else {
            return .notConnected
        }
        if path.usesInterfaceType(.wifi) {
            return .connectedViaWiFi
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .connectedViaEthernet
        } else if path.usesInterfaceType(.cellular) {
            return .connectedViaCellular
        } else {
            return .connected
        }
    }

    #if DEBUG
    func updateNewStatusToAll(_ status: ConnectionStatus) {
        self.callbacksToNotify.values.forEach { callback in
            callback(status)
        }
    }
    #endif
}
