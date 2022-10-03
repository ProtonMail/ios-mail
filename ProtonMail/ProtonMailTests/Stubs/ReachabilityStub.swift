@testable import ProtonMail

class ReachabilityStub: Reachability {

    var currentReachabilityStatusStub = NetworkStatus.ReachableViaWWAN

    // MARK: - Reachability

    override func currentReachabilityStatus() -> NetworkStatus {
        return currentReachabilityStatusStub
    }

}
