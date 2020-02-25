//
//  DoHMail.swift
//  Created by ProtonMail on 2/24/20.
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

class DoHMail : DoH {
    //defind the domain
    /// let 
    override func getHostUrl() -> String {
        if let url = Google().fetch(sync: "dmfygsltqojxxi33onvqws3bomnua.protonpro.xyz")?.url {
            let newurl = URL(string: "https://dmfygsltqojxxi33onvqws3bomnua.protonpro.xyz")!
            let host = newurl.host
            let hostUrl = newurl.absoluteString.replacingOccurrences(of: host!, with: (url.preg_replace("\"", replaceto: "")))
            return hostUrl
        }
        return URL_Protocol + URL_HOST
    }
    
    //singleton
    static let `default` = DoHMail()

    let URL_Protocol : String = Constants.App.URL_Protocol
    let URL_HOST : String = Constants.App.URL_HOST
    let API_PATH : String = Constants.App.API_PATH
    
    private override init() {
        // inital default protonmail DNS record in TXT type
    }
    
}
