import PromiseKit
import ProtonCore_Networking
import ProtonCore_Services

final class UnsubscribeService {

    private let labelId: LabelID
    private let apiService: APIService
    private let messageDataService: MessageDataService
    private let eventsService: EventsFetching

    init(labelId: LabelID,
         apiService: APIService,
         messageDataService: MessageDataService,
         eventsService: EventsFetching) {
        self.labelId = labelId
        self.apiService = apiService
        self.messageDataService = messageDataService
        self.eventsService = eventsService
    }

    func oneClickUnsubscribe(messageId: MessageID) {
        let request = OneClickUnsubscribe(messageId: messageId)
        apiService.exec(route: request, responseObject: VoidResponse()) { [weak self, labelId] _, _ in
            self?.markAsUnsubscribed(messageId: messageId, finish: {
                self?.eventsService.fetchEvents(labelID: labelId)
            })
        }
    }

    func markAsUnsubscribed(messageId: MessageID, finish: @escaping (() -> Void)) {
        let request = MarkAsUnsubscribed(messageId: messageId)
        apiService.exec(route: request, responseObject: VoidResponse()) { _ in
            finish()
        }
    }

}
