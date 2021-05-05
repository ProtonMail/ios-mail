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
        apiService.exec(route: OneClickUnsubscribe(messageId: messageId))
            .then { [weak self] _ in self?.markAsUnsubscribed(messageId: messageId) ?? .brokenPromise() }
            .done { [weak self, labelId] _ in self?.messageDataService.fetchEvents(labelID: labelId) }
            .catch { _ in }
    }

    func markAsUnsubscribed(messageId: String) -> Promise<Void> {
        apiService.exec(route: MarkAsUnsubscribed(messageId: messageId))
            .asVoid()
    }

}
