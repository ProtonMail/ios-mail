import ProtonCore_Doh
import ProtonCore_Networking
import ProtonCore_Services

public struct APIServiceMock: APIService {

    public init() {}

    @FuncStub(APIServiceMock.setSessionUID) public var setSessionUIDStub
    public func setSessionUID(uid: String) { setSessionUIDStub(uid) }

    @PropertyStub(\APIServiceMock.serviceDelegate, initialGet: .crash) public var serviceDelegateStub
    public var serviceDelegate: APIServiceDelegate? { get { serviceDelegateStub() } set { serviceDelegateStub(newValue) } }

    @PropertyStub(\APIServiceMock.authDelegate, initialGet: .crash) public var authDelegateStub
    public var authDelegate: AuthDelegate? { get { authDelegateStub() } set { authDelegateStub(newValue) } }

    @PropertyStub(\APIServiceMock.humanDelegate, initialGet: .crash) public var humanDelegateStub
    public var humanDelegate: HumanVerifyDelegate? { get { humanDelegateStub() } set { humanDelegateStub(newValue) } }

    @PropertyStub(\APIServiceMock.doh, initialGet: .crash) public var dohStub
    public var doh: DoH { get { dohStub() } set { dohStub(newValue) } }

    @PropertyStub(\APIServiceMock.signUpDomain, initialGet: .crash) public var signUpDomainStub
    public var signUpDomain: String { signUpDomainStub() }

    @FuncStub(APIServiceMock.request) public var requestStub
    public func request(method: HTTPMethod, path: String, parameters: Any?, headers: [String : Any]?, authenticated: Bool, autoRetry: Bool, customAuthCredential: AuthCredential?, completion: CompletionBlock?) {
        requestStub(method, path, parameters, headers, authenticated, autoRetry, customAuthCredential, completion)
    }

    @FuncStub(APIServiceMock.download) public var downloadStub
    public func download(byUrl url: String, destinationDirectoryURL: URL, headers: [String : Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, downloadTask: ((URLSessionDownloadTask) -> Void)?, completion: @escaping ((URLResponse?, URL?, NSError?) -> Void)) {
        downloadStub(url, destinationDirectoryURL, headers, authenticated, customAuthCredential, downloadTask, completion)
    }

    @FuncStub(APIServiceMock.upload) public var uploadStub
    public func upload(byPath path: String, parameters: [String : String], keyPackets: Data, dataPacket: Data, signature: Data?, headers: [String : Any]?, authenticated: Bool, customAuthCredential: AuthCredential?, completion: @escaping CompletionBlock) {
        uploadStub(path, parameters, keyPackets, dataPacket, signature, headers, authenticated, customAuthCredential, completion)
    }
}
