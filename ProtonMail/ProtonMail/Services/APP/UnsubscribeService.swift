import PromiseKit
import ProtonCore_Networking
import ProtonCore_Services

protocol UnsubscribeActionHandler: AnyObject {
    func oneClickUnsubscribe(messageId: MessageID)
    func markAsUnsubscribed(messageId: MessageID, finish: @escaping (() -> Void))
}

final class UnsubscribeService: UnsubscribeActionHandler {

    private let labelId: LabelID
    private let apiService: APIService
    private let eventsService: EventsFetching

    init(labelId: LabelID,
         apiService: APIService,
         eventsService: EventsFetching) {
        self.labelId = labelId
        self.apiService = apiService
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
