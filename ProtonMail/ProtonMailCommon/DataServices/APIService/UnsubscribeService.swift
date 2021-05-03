import PMCommon
import PromiseKit

class UnsubscribeService {

    private let labelId: String
    private let apiService: APIService
    private let messageDataService: MessageDataService

    init(labelId: String, apiService: APIService, messageDataService: MessageDataService) {
        self.labelId = labelId
        self.apiService = apiService
        self.messageDataService = messageDataService
    }

    func oneClickUnsubscribe(messageId: String) {
        let request = OneClickUnsubscribe(messageId: messageId)
        Promise { resolver in
            apiService.exec(route: request) { dataTask, _ in
                if let error = dataTask?.error {
                    resolver.reject(error)
                }
                resolver.fulfill(())
            }
        }.then { [weak self] in
            self?.markAsUnsubscribed(messageId: messageId) ?? brokenPromise()
        }.done { [weak self, labelId] _ in
            self?.messageDataService.fetchEvents(labelID: labelId)
        }.catch { _ in }
    }

    func markAsUnsubscribed(messageId: String) -> Promise<Void> {
        let request = MarkAsUnsubscribed(messageId: messageId)
        return Promise { resolver in
            apiService.exec(route: request) { dataTask, _ in
                if let error = dataTask?.error {
                    resolver.reject(error)
                }
                resolver.fulfill(())
            }
        }
    }

}

private func brokenPromise<T>(method: String = #function) -> Promise<T> {
    return Promise<T>() { resolver in
        let error = NSError(domain: "broken_promise", code: 999, userInfo: nil)
        resolver.reject(error)
    }
}
