import ProtonCore_Services
import PromiseKit

class ConversationFeatureFlagService {

    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func getConversationFlag() -> Promise<Bool> {
        let request = ConversationFeatureFlagRequest()
        return Promise { resolver in
            apiService.exec(route: request) { (dataTask, response: ConversationFeatureFlagResponse) in
                if let error = dataTask?.error {
                    resolver.reject(error)
                }
                resolver.fulfill(response.isConversationModeEnabled == true)
            }
        }
    }

}
