extension NetworkStatus {

    var isConnected: Bool {
        self != .NotReachable
    }

}
