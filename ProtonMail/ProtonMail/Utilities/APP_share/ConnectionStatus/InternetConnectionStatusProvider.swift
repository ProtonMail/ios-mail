import Foundation
import Network
import ProtonCoreDoh
import ProtonCoreServices

// sourcery: mock
protocol ConnectionStatusReceiver: AnyObject {
    func connectionStatusHasChanged(newStatus: ConnectionStatus)
}

// sourcery: mock
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
extension URLSession: URLSessionProtocol {
}

// sourcery: mock
protocol InternetConnectionStatusProviderProtocol {
    var status: ConnectionStatus { get }

    func apiCallIsSucceeded()
    func register(receiver: ConnectionStatusReceiver, fireWhenRegister: Bool)
    func unRegister(receiver: ConnectionStatusReceiver)
#if DEBUG
    func updateNewStatusToAll(_ newStatus: ConnectionStatus)
#endif
}

final class InternetConnectionStatusProvider: InternetConnectionStatusProviderProtocol {
    static let shared = InternetConnectionStatusProvider()
    // Stores the reference of NWPathMonitor
    private let pathMonitor: ConnectionMonitor
    private let session: URLSessionProtocol
    private let notificationCenter: NotificationCenter
    private let doh: DoHInterface
    private let monitorQueue = DispatchQueue(label: "me.proton.mail.connection.status.monitor", qos: .userInitiated)

    private let delegatesStore: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    private(set) var status: ConnectionStatus = .initialize {
        didSet {
            if !status.isConnected {
                doubleCheckConnectionStatus(after: 2)
            } else {
                invalidateTimer()
            }

            if oldValue == status { return }
            let receivers = delegatesStore
                .allObjects
                .compactMap { $0 as? ConnectionStatusReceiver }
            if Thread.isMainThread {
                receivers.forEach { $0.connectionStatusHasChanged(newStatus: self.status) }
            } else {
                DispatchQueue.main.async {
                    receivers.forEach { $0.connectionStatusHasChanged(newStatus: self.status) }
                }
            }
        }
    }
    private var doubleCheckTimer: Timer?

    init(
        connectionMonitor: ConnectionMonitor = NWPathMonitor(),
        session: URLSessionProtocol = URLSession.shared,
        notificationCenter: NotificationCenter = NotificationCenter.default,
        doh: DoHInterface = BackendConfiguration.shared.doh
    ) {
        self.pathMonitor = connectionMonitor
        self.notificationCenter = notificationCenter
        self.session = session
        self.doh = doh
        startObservation()
    }

    deinit {
        stopInternetConnectionStatusObservation()
    }

    func register(receiver: ConnectionStatusReceiver, fireWhenRegister: Bool = true) {
        if Thread.isMainThread {
            delegatesStore.add(receiver)
            if fireWhenRegister {
                receiver.connectionStatusHasChanged(newStatus: status)
            }
        } else {
            DispatchQueue.main.async {
                self.delegatesStore.add(receiver)
                if fireWhenRegister {
                    receiver.connectionStatusHasChanged(newStatus: self.status)
                }
            }
        }
    }

    func unRegister(receiver: ConnectionStatusReceiver) {
        delegatesStore.remove(receiver)
    }

    func apiCallIsSucceeded() {
        guard !status.isConnected else { return }
        monitorQueue.async {
            self.log(message: "API call is succeeded when status is disconnected \(self.status)")
            self.status = .connected
        }
    }

    private func log(message: String) {
        SystemLogger.log(message: message, category: .connectionStatus)
    }

    private func log(error: String) {
        SystemLogger.log(message: error, category: .connectionStatus, isError: true)
    }
}

// MARK: - NWPathMonitor
extension InternetConnectionStatusProvider {
    private func startPathMonitor(_ monitor: ConnectionMonitor) {
        monitor.pathUpdateClosure = { [weak self] path in
            self?.updateStatusFrom(path: path)
        }
        monitor.start(queue: monitorQueue)
    }

    private func updateStatusFrom(path: NWPathProtocol) {
        guard let pathStatus = path.pathStatus,
              pathStatus == .satisfied else {
            self.status = .notConnected
            log(message: "Disconnection due to unsatisfied")
            return
        }
        invalidateTimer()

        let status: ConnectionStatus
        if path.isPossiblyConnectedThroughVPN {
            // Connection status detection has problem when VPN is enabled
            // The reliable way to detect connection status is calling API
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.log(message: "Check connection when vpn is enabled")
                self.checkConnectionWhenVPNIsEnabled()
            }
            return
        } else if path.usesInterfaceType(.wifi) {
            log(message: "Connected with wifi")
            status = .connectedViaWiFi
        } else if path.usesInterfaceType(.wiredEthernet) {
            log(message: "Connected with ethernet")
            status = .connectedViaEthernet
        } else if path.usesInterfaceType(.cellular) {
            log(message: "Connected with cellular")
            status = .connectedViaCellular
        } else {
            log(message: "Connected with unknown method")
            status = .connected
        }
        self.status = status
    }

    private func doubleCheckConnectionStatus(after seconds: TimeInterval) {
        if doubleCheckTimer != nil { return }
        DispatchQueue.main.async {
            self.log(message: "Schedule double check timer")
            self.doubleCheckTimer?.invalidate()
            self.doubleCheckTimer = nil
            self.doubleCheckTimer = Timer.scheduledTimer(
                withTimeInterval: seconds,
                repeats: false,
                block: { [weak self] _ in
                    self?.monitorQueue.async {
                        guard let path = self?.pathMonitor.currentPathProtocol else { return }
                        self?.log(message: "Double check timer is fired")
                        self?.updateStatusFrom(path: path)
                    }
                }
            )
        }
    }

    private func invalidateTimer() {
        DispatchQueue.main.async {
            guard self.doubleCheckTimer != nil else { return }
            self.log(message: "Invalid double check timer")
            self.doubleCheckTimer?.invalidate()
            self.doubleCheckTimer = nil
        }
    }
}

// MARK: - API
extension InternetConnectionStatusProvider {
    private func observeAPINetworkError() {
        notificationCenter.addObserver(
            self,
            selector: #selector(self.receiveAPINetworkError),
            name: .tempNetworkError,
            object: nil
        )
    }

    @objc
    private func receiveAPINetworkError() {
        log(message: "Receive api network error")
        monitorQueue.async {
            self.status = .notConnected
        }
    }
}

extension InternetConnectionStatusProvider {
    private func startObservation() {
        startPathMonitor(pathMonitor)
        observeAPINetworkError()
    }

    private func stopInternetConnectionStatusObservation() {
        pathMonitor.pathUpdateClosure = nil
        pathMonitor.cancel()
    }

    private func checkConnectionWhenVPNIsEnabled() {
        Task {
            let hasConnection: Bool

            defer {
                monitorQueue.async {
                    self.status = hasConnection ? .connected : .notConnected
                    self.log(message: "Update status to \(self.status) according to ping result")
                }
            }
            let tooManyRedirectionsError = -1_007
            do {

                _ = try await session.data(for: PingRequestHelper.protonServer.urlRequest(timeout: 40, doh: doh))
                hasConnection = true
                return
            } catch {
                log(error: "Ping proton server failed: \(error)")
                if error.bestShotAtReasonableErrorCode == tooManyRedirectionsError {
                    hasConnection = true
                    return
                }
            }

            do {
                _ = try await session.data(for: PingRequestHelper.protonStatus.urlRequest(timeout: 40, doh: doh))
                hasConnection = true
                return
            } catch {
                log(error: "Ping proton status page failed: \(error)")
                if error.bestShotAtReasonableErrorCode == tooManyRedirectionsError {
                    hasConnection = true
                    return
                }
            }
            hasConnection = false
        }
    }

    #if DEBUG
    func updateNewStatusToAll(_ newStatus: ConnectionStatus) {
        status = newStatus
    }
    #endif
}
