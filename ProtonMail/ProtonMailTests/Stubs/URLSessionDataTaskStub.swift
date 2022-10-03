import Foundation

class URLSessionDataTaskStub: URLSessionDataTask {

    var stubbedError: Error?

    override var error: Error? {
        stubbedError
    }

}
