//
//  FeatureFlagsRepository.swift
//  ProtonCore-FeatureFlags - Created on 29.09.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import ProtonCoreLog
import ProtonCoreServices
import ProtonCoreUtilities

/**
 The FeatureFlagsRepository class is responsible for managing feature flags and their state.
 It conforms to the FeatureFlagsRepositoryProtocol.
 */
public class FeatureFlagsRepository: FeatureFlagsRepositoryProtocol {
    /// The local data source for feature flags.
    private(set) var localDataSource: Atomic<LocalFeatureFlagsDataSourceProtocol>

    /// The remote data source for feature flags.
    private(set) var remoteDataSource: Atomic<RemoteFeatureFlagsDataSourceProtocol?>

    /// The configuration for feature flags.
    private(set) var userId: String {
        get {
            return _userId ?? ""
        }
        set {
            _userId = newValue
            localDataSource.value.setUserIdForActiveSession(newValue)
        }
    }

    private var _userId: String?

    public internal(set) static var shared: FeatureFlagsRepository = .init(
        localDataSource: Atomic<LocalFeatureFlagsDataSourceProtocol>(DefaultLocalFeatureFlagsDatasource()),
        remoteDataSource: Atomic<RemoteFeatureFlagsDataSourceProtocol?>(nil)
    )

    /**
     Private initialization of the shared FeatureFlagsRepository instance.

     - Parameters:
       - localDataSource: The local data source for feature flags.
       - remoteDataSource: The remote data source for feature flags.
     */
    init(localDataSource: Atomic<LocalFeatureFlagsDataSourceProtocol>,
         remoteDataSource: Atomic<RemoteFeatureFlagsDataSourceProtocol?>) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self._userId = localDataSource.value.userIdForActiveSession
    }

    // Internal func for testing
    func updateRemoteDataSource(with remoteDataSource: Atomic<RemoteFeatureFlagsDataSourceProtocol?>) {
        self.remoteDataSource = remoteDataSource
    }
}

// MARK: - For single-user clients

public extension FeatureFlagsRepository {

    /**
     Updates the local data source conforming to the `LocalFeatureFlagsProtocol` protocol
     */
    func updateLocalDataSource(_ localDataSource: Atomic<LocalFeatureFlagsDataSourceProtocol>) {
        self.localDataSource = localDataSource
    }

    /**
     Sets the FeatureFlagsRepository configuration with the given user id.

     - Parameters:
       - userId: The user id used to initialize the configuration for feature flags.
     */
    func setUserId(_ userId: String) {
        self.userId = userId
    }

    /**
     Sets the FeatureFlagsRepository remote data source with the given api service.

     - Parameters:
       - apiService: The api service used to initialize the remote data source for feature flags.
     */
    func setApiService(_ apiService: APIService) {
        self.remoteDataSource = Atomic<RemoteFeatureFlagsDataSourceProtocol?>(DefaultRemoteFeatureFlagsDataSource(apiService: apiService))
    }

    /**
     Asynchronously fetches the feature flags from the remote data source and updates the local data source.

     - Parameters:
        - userId: The user ID to fetch flags for.  If `nil`, uses the previously set user ID, if available.  See ``setUserId(_)``.
        - apiService: A specific apiService tied to a userId, for multiple users app.

     - Throws: An error if the operation fails.
     */
    func fetchFlags(for userId: String? = nil, using apiService: APIService? = nil) async throws {
        let remoteDataSource: RemoteFeatureFlagsDataSourceProtocol?

        if let apiService {
            remoteDataSource = DefaultRemoteFeatureFlagsDataSource(apiService: apiService)
        } else {
            remoteDataSource = self.remoteDataSource.value
        }

        guard let remoteDataSource = remoteDataSource else {
            assertionFailure("No apiService was set. You need to set the apiService of the remoteDataSource by calling `setApiService`, or pass an apiService as an argument in order to fetch the feature flags.")
            return
        }
        let flags = try await remoteDataSource.getFlags()

        // Fetch flags for the supplied userId parameter, if non-nil, otherwise fetch flags
        // for self.userId.
        localDataSource.value.upsertFlags(.init(flags: flags), userId: userId ?? self.userId)
    }

    /**
     A Boolean function indicating if a feature flag is enabled or not.
     The flag is fetched from the local data source and is intended for use in a single-user context.

     - Parameters:
       - flag: The flag we want to know the state of.
       - reloadValue: Pass `true` if you want the latest stored value for the flag. Pass `false` if  you want the "static" value, which is always the same as the first returned.
     */
    func isEnabled(_ flag: any FeatureFlagTypeProtocol, reloadValue: Bool) -> Bool {
        let flags = localDataSource.value.getFeatureFlags(
            userId: self.userId,
            reloadFromLocalDataSource: reloadValue
        )
        return flags?.getFlag(for: flag)?.enabled ?? false
    }

    /**
     A Boolean function indicating if a feature flag is enabled or not.
     The flag is fetched from the local data source and is intended for use in multi-user contexts.

     - Parameters:
       - flag: The flag we want to know the state of.
       - userId: The user id for which we want to check the flag value. If the userId is `nil`, the first-set userId will be used.  See ``setUserId(_)``.
       - reloadValue: Pass `true` if you want the latest stored value for the flag. Pass `false` if  you want the "static" value, which is always the same as the first returned.
     */
    func isEnabled(_ flag: any FeatureFlagTypeProtocol, for userId: String?, reloadValue: Bool) -> Bool {
        let flags: FeatureFlags?

        if let userId {
            flags = localDataSource.value.getFeatureFlags(
                userId: userId,
                reloadFromLocalDataSource: reloadValue
            )
        } else {
            flags = localDataSource.value.getFeatureFlags(
                userId: self.userId,
                reloadFromLocalDataSource: reloadValue
            )
        }

        return flags?.getFlag(for: flag)?.enabled ?? false
    }
}

// MARK: - Reset

public extension FeatureFlagsRepository {
    /**
     Resets all feature flags.
     */
    func resetFlags() {
        localDataSource.value.cleanAllFlags()
    }

    /**
     Resets feature flags for a specific user.

     - Parameters:
        - userId: The ID of the user whose feature flags need to be reset.
     */
    func resetFlags(for userId: String) {
        localDataSource.value.cleanFlags(for: userId)
    }

    /**
     Resets userId.
     */
    func clearUserId() {
        localDataSource.value.clearUserId()
        _userId = ""
    }
}
