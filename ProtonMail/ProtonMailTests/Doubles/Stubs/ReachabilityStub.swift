class ReachabilityStub: Reachability {

    var currentReachabilityStatusStub = NetworkStatus.NotReachable

    // MARK: - Reachability

    override func currentReachabilityStatus() -> NetworkStatus {
        return currentReachabilityStatusStub
    }

}
