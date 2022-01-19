import PromiseKit
import ProtonCore_Networking
import ProtonCore_Services

final class UnsubscribeService {

    private let labelId: String
    private let apiService: APIService
    private let messageDataService: MessageDataService
    private let eventsService: EventsFetching

    init(labelId: String,
         apiService: APIService,
         messageDataService: MessageDataService,
         eventsService: EventsFetching) {
        self.labelId = labelId
        self.apiService = apiService
        self.messageDataService = messageDataService
        self.eventsService = eventsService
    }

    func oneClickUnsubscribe(messageId: String) {
        let request = OneClickUnsubscribe(messageId: messageId)
        apiService.exec(route: request) { [weak self, labelId] _, _ in
            self?.markAsUnsubscribed(messageId: messageId, finish: {
                self?.eventsService.fetchEvents(labelID: labelId)
            })
        }
    }

    func markAsUnsubscribed(messageId: String, finish: @escaping (() -> Void)) {
        let request = MarkAsUnsubscribed(messageId: messageId)
        apiService.exec(route: request) { _ in
            finish()
        }
    }

}
