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
    func fetchEvents(byLabel labelID: String, notificationMessageID: String?, completion: CompletionBlock?) {}
    func fetchEvents(labelID: String) {}
    func processEvents(counts: [[String : Any]]?) {}
    func processEvents(conversationCounts: [[String : Any]]?) {}
    func processEvents(mailSettings: [String : Any]?) {}
    func processEvents(space usedSpace : Int64?) {}
}
