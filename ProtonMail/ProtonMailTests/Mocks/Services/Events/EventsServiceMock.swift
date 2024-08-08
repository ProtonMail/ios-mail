import ProtonCoreServices
import ProtonCoreTestingToolkitUnitTestsCore
@testable import ProtonMail

class EventsServiceMock: EventsFetching {
    var status: EventsFetchingStatus { .idle }
    func start() {}
    func pause() {}
    func resume() {}
    func stop() {}

    @FuncStub(EventsServiceMock.call) var callStub
    func call() { callStub() }

    func begin(subscriber: EventsConsumer) {}

    @FuncStub(EventsServiceMock.fetchEvents(byLabel:notificationMessageID:discardContactsMetadata:completion:)) var callFetchEvents
    func fetchEvents(
        byLabel labelID: LabelID,
        notificationMessageID: MessageID?,
        discardContactsMetadata: Bool = true,
        completion: ((Swift.Result<[String: Any], Error>) -> Void)?
    ) {
        callFetchEvents(labelID, notificationMessageID, discardContactsMetadata, completion)
    }

    @FuncStub(EventsServiceMock.fetchEvents(labelID:)) var callFetchEventsByLabelID
    func fetchEvents(labelID: LabelID) { callFetchEventsByLabelID(labelID) }

    func processEvents(messageCounts: [[String: Any]]?) {}
    func processEvents(conversationCounts: [[String: Any]]?) {}
    func processEvents(mailSettings: [String: Any]?) {}
    func processEvents(space usedSpace: Int64?) {}

    // MARK: Belong to EventsServiceProtocol
    @FuncStub(EventsServiceMock.fetchLatestEventID(completion:)) var callFetchLatestEventID
    func fetchLatestEventID(completion: ((EventLatestIDResponse) -> Void)?) {
        callFetchLatestEventID(completion)
    }
}
