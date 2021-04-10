extension Array {

    @discardableResult
    mutating func removeLastSafe() -> Element? {
        guard !isEmpty else { return nil }
        return removeLast()
    }

}
