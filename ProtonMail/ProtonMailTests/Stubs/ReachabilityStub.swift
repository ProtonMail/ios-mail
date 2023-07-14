@testable import Reachability
import SystemConfiguration
@testable import ProtonMail

class ReachabilityStub: Reachability {
    private var mockNotificationCenter: NotificationCenter
    override var connection: Reachability.Connection { mockConnection ?? .cellular }
    var mockConnection: Reachability.Connection? {
        didSet {
            mockNotificationCenter.post(name: .reachabilityChanged, object: self)
        }
    }

    convenience init(notificationCenter: NotificationCenter) throws {
        var zeroAddress = sockaddr()
        zeroAddress.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zeroAddress.sa_family = sa_family_t(AF_INET)

        guard let ref = SCNetworkReachabilityCreateWithAddress(nil, &zeroAddress) else {
            throw ReachabilityError.failedToCreateWithAddress(zeroAddress, SCError())
        }

        self.init(reachabilityRef: ref)
        self.mockNotificationCenter = notificationCenter
    }

    required init(
        reachabilityRef: SCNetworkReachability,
        queueQoS: DispatchQoS = .default,
        targetQueue: DispatchQueue? = nil,
        notificationQueue: DispatchQueue? = .main
    ) {
        self.mockNotificationCenter = .default
        super.init(
            reachabilityRef: reachabilityRef,
            queueQoS: queueQoS,
            targetQueue: targetQueue,
            notificationQueue: notificationQueue
        )
    }
}
