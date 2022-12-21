// Generated using Sourcery 1.9.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
import ProtonCore_TestingToolkit
@testable import ProtonMail

class MockReceiptActionHandler: ReceiptActionHandler {
    @FuncStub(MockReceiptActionHandler.sendReceipt) var sendReceiptStub
    func sendReceipt(messageID: MessageID) {
        sendReceiptStub(messageID)
    }
}
