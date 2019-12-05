//
//  File.swift
//  ProtonMail - Created on 07/03/2019.
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

class MessageBodyViewModel: NSObject {
    @objc internal dynamic var contents: WebContents?
    private(set) var parentViewModel: MessageViewModel
    private var bodyObservation: NSKeyValueObservation!
    private var remoteContentModeObservation: NSKeyValueObservation!
    @objc internal dynamic var contentHeight: CGFloat = 0.0
    
    internal lazy var placeholderContent: String = {
        let meta = "<meta name=\"viewport\" content=\"width=device-width\">"
        let htmlString = "<html><head>\(meta)<style type='text/css'>\(WebContents.css)</style></head><body>\(LocalString._loading_)</body></html>"
        return htmlString
    }()
    
    init(parentViewModel: MessageViewModel) {
        self.parentViewModel = parentViewModel
        
        super.init()
        
        self.bodyObservation = parentViewModel.observe(\.body, options: [.new, .old, .initial]) { [weak self] standalone, change in
            guard let self = self else { return }
            guard change.newValue != change.oldValue, let body = standalone.body else { return }
            self.contents = WebContents(body: body, remoteContentMode: standalone.remoteContentMode)
        }
        self.remoteContentModeObservation = parentViewModel.observe(\.remoteContentModeObservable, options: [.new, .old]) { [weak self] standalone, change in
            guard let self = self else { return }
            guard change.newValue != change.oldValue, let body = standalone.body else { return }
            self.contents = WebContents(body: body, remoteContentMode: standalone.remoteContentMode)
        }
    }
    
    deinit {
        self.bodyObservation = nil
        self.remoteContentModeObservation = nil
    }
}
