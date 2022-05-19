@testable import ProtonMail
import ProtonCore_TestingToolkit
import ProtonCore_Services

class EventsServiceMock: EventsFetching {

    var status: EventsFetchingStatus { .idle }
    func start() {}
    func pause() {}
    func resume() {}
    func stop() {}

    @FuncStub(EventsServiceMock.call) var callStub
    func call() { callStub() }

    func begin(subscriber: EventsConsumer) {}

    @FuncStub(EventsServiceMock.fetchEvents(byLabel:notificationMessageID:completion:)) var callFetchEvents
    func fetchEvents(
        byLabel labelID: LabelID,
        notificationMessageID: MessageID?,
        completion: CompletionBlock?
    ) {
        callFetchEvents(labelID, notificationMessageID, completion)
    }

    @FuncStub(EventsServiceMock.fetchEvents(labelID:)) var callFetchEventsByLabelID
    func fetchEvents(labelID: LabelID) { callFetchEventsByLabelID(labelID) }

    func processEvents(counts: [[String : Any]]?) {}
    func processEvents(conversationCounts: [[String : Any]]?) {}
    func processEvents(mailSettings: [String : Any]?) {}
    func processEvents(space usedSpace : Int64?) {}

    // MARK: Belong to EventsServiceProtocol
    
    func fetchLatestEventID(completion: ((EventLatestIDResponse) -> Void)?) { }
}
