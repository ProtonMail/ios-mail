import Foundation
import Network
import ProtonCore_Doh
import ProtonCore_Services

// sourcery: mock
protocol ConnectionStatusReceiver: AnyObject {
    func connectionStatusHasChanged(newStatus: ConnectionStatus)
}

// sourcery: mock
protocol URLSessionProtocol {
    func dataTask(
        withRequest: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol

    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
extension URLSession: URLSessionProtocol {
    func dataTask(
        withRequest: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTaskProtocol {
        let task = dataTask(with: withRequest, completionHandler: completionHandler)
        return task
    }
}

// sourcery: mock
protocol URLSessionDataTaskProtocol {
    func resume()
}
extension URLSessionDataTask: URLSessionDataTaskProtocol {}

// sourcery: mock
protocol InternetConnectionStatusProviderProtocol {
    var status: ConnectionStatus { get }

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
    private let doh: DoHInterface
    private let session: URLSessionProtocol
    private let monitorQueue = DispatchQueue(label: "me.proton.mail.connection.status.monitor", qos: .userInitiated)

    private let delegatesStore: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    private(set) var status: ConnectionStatus = .initialize {
        didSet {
            if oldValue == status { return }
            if !status.isConnected {
                doubleCheckConnectionStatus(after: 2)
            }
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
        doh: DoHInterface = BackendConfiguration.shared.doh,
        session: URLSessionProtocol? = nil
    ) {
        self.pathMonitor = connectionMonitor
        self.doh = doh
        if let session = session {
            self.session = session
        } else {
            let urlSession = URLSession(
                configuration: .default,
                delegate: URLSessionCertificateValidator(),
                delegateQueue: nil
            )
            self.session = urlSession
        }
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
            return
        }

        let status: ConnectionStatus
        if path.isPossiblyConnectedThroughVPN {
            // Connection status detection has problem when VPN is enabled
            // The reliable way to detect connection status is calling API
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                self.status = self.hasConnectionWhenVPNISEnabled() ? .connected : .notConnected
            }
            return
        } else if path.usesInterfaceType(.wifi) {
            status = .connectedViaWiFi
        } else if path.usesInterfaceType(.wiredEthernet) {
            status = .connectedViaEthernet
        } else if path.usesInterfaceType(.cellular) {
            status = .connectedViaCellular
        } else {
            status = .connected
        }
        self.status = status
    }

    private func doubleCheckConnectionStatus(after seconds: TimeInterval) {
        DispatchQueue.main.async {
            self.doubleCheckTimer?.invalidate()
            self.doubleCheckTimer = nil
            self.doubleCheckTimer = Timer.scheduledTimer(
                withTimeInterval: seconds,
                repeats: false,
                block: { [weak self] _ in
                    self?.monitorQueue.async {
                        guard let path = self?.pathMonitor.currentPathProtocol else { return }
                        self?.updateStatusFrom(path: path)
                    }
                }
            )
        }
    }

}

extension InternetConnectionStatusProvider {
    private func startObservation() {
        startPathMonitor(pathMonitor)
    }

    private func stopInternetConnectionStatusObservation() {
        pathMonitor.pathUpdateClosure = nil
        pathMonitor.cancel()
    }

    private func hasConnectionWhenVPNISEnabled() -> Bool {
        let baseURL = doh.getCurrentlyUsedHostUrl()
        let link = "\(baseURL)/core/v4/tests/ping"
        guard let url = URL(string: link) else {
            let errorMessage = "Ping URL is wrong \(link)"
            PMAssertionFailure(errorMessage)
            return false
        }
        let request = URLRequest(url: url, timeoutInterval: 30)
        let semaphore = DispatchSemaphore(value: 0)
        var isSuccess = true
        session.dataTask(withRequest: request) { _, _, error in
            if error != nil {
                isSuccess = false
            }
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return isSuccess
    }

    #if DEBUG
    func updateNewStatusToAll(_ newStatus: ConnectionStatus) {
        status = newStatus
    }
    #endif
}

final class URLSessionCertificateValidator: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if PMAPIService.noTrustKit {
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        } else if let validator = PMAPIService.trustKit?.pinningValidator {
            if !validator.handle(challenge, completionHandler: completionHandler) {
                completionHandler(.performDefaultHandling, challenge.proposedCredential)
            }
        } else {
            assert(false, "TrustKit was not correctly initialized")
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }
}
