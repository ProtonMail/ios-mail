//
//  Created on 13/5/24.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import Foundation
import ProtonCoreServices
import ProtonCoreLog

extension SecurityKeysView { 
    public class ViewModel: ObservableObject {

        let apiService: APIService!
        @Published var viewState: SecurityKeysViewState = SecurityKeysViewState.initial
        let productName: String

        public init(apiService: APIService, productName: String) {
            self.apiService = apiService
            self.productName = productName
        }

#if DEBUG
        // API-less model only for Previews
        public init() {
            self.apiService = nil
            self.productName = "Core"
        }
#endif

        public func loadKeys() {
            viewState = .loading
            Task {
                do {
                    let keys = try await fetchKeys()
                    await MainActor.run { viewState = .loaded(keys) }
                } catch {
                    PMLog.error("Error occurred while fetching security keys: \(error.localizedDescription)", sendToExternal: true)
                    await MainActor.run { viewState = .error }
                }
            }
        }

        private func fetchKeys() async throws -> [RegisteredKey] {
            guard let apiService else { // Preview
                return (0..<13).map(RegisteredKey.init)
            }
            let request = SettingsEndpoint()
            let (_, response): (_, SettingsResponse) = try await apiService.perform(request: request)
            return response.userSettings._2FA.registeredKeys
        }
    }

}

public enum SecurityKeysViewState {
    case initial
    case loading
    case loaded([RegisteredKey])
    case error
}

#endif
