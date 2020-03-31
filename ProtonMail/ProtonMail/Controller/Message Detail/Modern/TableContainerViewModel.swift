//
//  EmbeddingViewModel.swift
//  ProtonMail - Created on 11/04/2019.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

class TableContainerViewModel: NSObject {
    private var latestErrorBanner: BannerView?
    
    var numberOfSections: Int {
        fatalError()
    }
    
    func numberOfRows(in section: Int) -> Int {
        fatalError()
    }
}

extension TableContainerViewModel: BannerRequester {
    internal func errorBannerToPresent() -> BannerView? {
        return self.latestErrorBanner
    }
    
    internal func showErrorBanner(_ title: String,
                                  action: (()->Void)? = nil,
                                  secondConfig: BannerView.ButtonConfiguration? = nil) {
        DispatchQueue.main.async {
            let config = action == nil ? nil : BannerView.ButtonConfiguration(title: LocalString._retry, action: action)
            self.latestErrorBanner?.remove(animated: true)
            self.latestErrorBanner = BannerView(appearance: .red, message: title, buttons: config, button2: secondConfig, offset: 8.0)
            
            #if !APP_EXTENSION
            UIApplication.shared.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
            #else
            // FIXME: send message via window
            #endif
        }
    }
    
//    internal func showErrorBanner(_ title: String, action: (()->Void)? = nil) {
//        DispatchQueue.main.async {
//            let config = action == nil ? nil : BannerView.ButtonConfiguration(title: LocalString._retry, action: action)
//            self.latestErrorBanner?.remove(animated: true)
//            self.latestErrorBanner = BannerView(appearance: .red, message: title, buttons: config, offset: 8.0)
//
//            #if !APP_EXTENSION
//            UIApplication.shared.sendAction(#selector(BannerPresenting.presentBanner(_:)), to: nil, from: self, for: nil)
//            #else
//            // FIXME: send message via window
//            #endif
//        }
//    }
}

@objc protocol BannerPresenting {
    @objc func presentBanner(_ sender: BannerRequester)
}
@objc protocol BannerRequester {
    @objc func errorBannerToPresent() -> BannerView?
}
