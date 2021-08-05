import ProtonCore_Doh
import ProtonCore_Networking
import ProtonCore_Services

class APIServiceSpy: APIService {

    private(set) var invokedRequestWithMethod: [HTTPMethod] = []
    private(set) var invokedRequestWithPath: [String] = []
    private(set) var invokedRequestWithParameters: [Any?] = []
    private(set) var invokedRequestWithHeaders: [[String: Any]?] = []
    private(set) var invokedRequestWithCompletion: [((URLSessionDataTask?, [String : Any]?, NSError?) -> Void)?] = []

    var serviceDelegate: APIServiceDelegate?
    var authDelegate: AuthDelegate?
    var humanDelegate: HumanVerifyDelegate?

    var doh: DoH & ServerConfig {
        get { fatalError() }
        set {  }
    }

    var signUpDomain: String = ""

    func setSessionUID(uid: String) {}

    func request(
        method: HTTPMethod,
        path: String,
        parameters: Any?,
        headers: [String : Any]?,
        authenticated: Bool,
        autoRetry: Bool,
        customAuthCredential: AuthCredential?,
        completion: CompletionBlock?
    ) {
        invokedRequestWithMethod.append(method)
        invokedRequestWithPath.append(path)
        invokedRequestWithParameters.append(parameters)
        invokedRequestWithHeaders.append(headers)
        invokedRequestWithCompletion.append(completion)
    }

    func download(
        byUrl url: String,
        destinationDirectoryURL: URL,
        headers: [String : Any]?,
        authenticated: Bool,
        customAuthCredential: AuthCredential?,
        downloadTask: ((URLSessionDownloadTask) -> Void)?,
        completion: @escaping ((URLResponse?, URL?, NSError?) -> Void))
    {}

    func upload(
        byPath path: String,
        parameters: [String : String],
        keyPackets: Data,
        dataPacket: Data,
        signature: Data?,
        headers: [String : Any]?,
        authenticated: Bool,
        customAuthCredential: AuthCredential?,
        completion: @escaping CompletionBlock
    ) {}

    func uploadFromFile(byPath path: String,
                        parameters: [String : String],
                        keyPackets: Data,
                        dataPacketSourceFileURL: URL,
                        signature: Data?,
                        headers: [String : Any]?,
                        authenticated: Bool,
                        customAuthCredential: AuthCredential?,
                        completion: @escaping CompletionBlock
    ) {}
}
