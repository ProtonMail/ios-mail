import PromiseKit
import ProtonCore_Networking
import ProtonCore_Services

class UnsubscribeService {

    private let labelId: String
    private let apiService: APIService
    private let messageDataService: MessageDataService
    private let eventsService: EventsFetching
    
    init(labelId: String, apiService: APIService, messageDataService: MessageDataService, eventsService: EventsFetching) {
        self.labelId = labelId
        self.apiService = apiService
        self.messageDataService = messageDataService
        self.eventsService = eventsService
    }

    func oneClickUnsubscribe(messageId: String) {
        apiService.exec(route: OneClickUnsubscribe(messageId: messageId))
            .then { [weak self] _ in self?.markAsUnsubscribed(messageId: messageId) ?? .brokenPromise() }
            .done { [weak self, labelId] _ in self?.eventsService.fetchEvents(labelID: labelId) }
            .catch { _ in }
    }

    func markAsUnsubscribed(messageId: String) -> Promise<Void> {
        apiService.exec(route: MarkAsUnsubscribed(messageId: messageId))
            .asVoid()
    }

}
