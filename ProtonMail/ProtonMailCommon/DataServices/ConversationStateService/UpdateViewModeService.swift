import ProtonCore_Services
import PromiseKit

class UpdateViewModeService {

    private let apiService: APIService

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func update(viewMode: ViewMode) -> Promise<ViewMode?> {
        Promise { resolver in
            let request = UpdateViewModeRequest(viewMode: viewMode)
            apiService.exec(route: request) { (dataTask, response: UpdateViewModeResponse) in
                if let error = dataTask?.error {
                    resolver.reject(error)
                }
                resolver.fulfill(response.viewMode)
            }
        }
    }

}
