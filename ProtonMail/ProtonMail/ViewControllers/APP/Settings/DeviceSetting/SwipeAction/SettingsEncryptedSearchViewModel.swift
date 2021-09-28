//
//  SettingsEncryptedSearchViewModel.swift
//  ProtonMail - Created on 2021/07/01
//
//
//  Copyright © 2021 ProtonMail. All rights reserved.
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

class Bindable<T> {
    var value: T? {
        didSet {
            observer?(value)
        }
    }
    
    var observer: ((T?) -> ())?
    
    func bind(observer: @escaping (T?) -> ()){
        self.observer = observer
    }
}

class SettingsEncryptedSearchViewModel {
    enum SettingSection: Int {
        case encryptedSearch = 0
        case downloadViaMobileData = 1
        case downloadedMessages = 2
        
        var title: String {
            switch self {
                case .encryptedSearch:
                    return LocalString._settings_title_of_encrypted_search
                case .downloadViaMobileData:
                    return LocalString._settings_title_of_download_via_mobile_data
                case .downloadedMessages:
                    return LocalString._settings_title_of_downloaded_messages
            }
        }
        
        var foot: String {
            switch self {
                case .encryptedSearch:
                    return LocalString._settings_footer_of_encrypted_search
                case .downloadViaMobileData:
                    return LocalString._settings_footer_of_download_via_mobile_data
                case .downloadedMessages:
                    return LocalString._settings_footer_of_downloaded_messages
            }
        }
    }
    
    private var encryptedSearchCache: EncryptedSearchCacheProtocol
    
    init(encryptedSearchCache: EncryptedSearchCacheProtocol) {
        self.encryptedSearchCache = encryptedSearchCache
        self.downloadViaMobileData = false
        self.pauseIndexing = false
        self.estimatedTimeRemaining.value = 0
        self.currentProgress.value = 0
        self.progressViewStatus.value = 0
    }
    
    var isEncryptedSearch: Bool {
        get {
            return encryptedSearchCache.isEncryptedSearchOn
        }
        set {
            encryptedSearchCache.isEncryptedSearchOn = newValue
        }
    }
    
    var downloadViaMobileData: Bool
    var pauseIndexing: Bool
    var progressViewStatus = Bindable<Float>()
    var currentProgress = Bindable<Int>()
    var estimatedTimeRemaining = Bindable<Int>()
    
    var sections: [SettingSection] = [.encryptedSearch, .downloadViaMobileData, .downloadedMessages]
}
