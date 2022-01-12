// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonMailAnalytics

class MockProtonMailAnalytics: ProtonMailAnalyticsProtocol {
    let endPoint: String
    var environment: String?
    var debug: Bool?
    
    var debugEvent: ProtonMailAnalytics.Events?
    var debugExtra: [String: Any]?
    var debugFile: String?
    var debugFunction: String?
    var debugLine: Int?
    var debugColum: Int?
    
    var errorEvent: ProtonMailAnalytics.Events?
    var errorError: Error?
    var errorExtra: [String: Any]?
    var errorFile: String?
    var errorFunction: String?
    var errorLine: Int?
    var errorColum: Int?
    
    required init(endPoint: String) {
        self.endPoint = endPoint
    }
    
    func setup(environment: String?, debug: Bool) {
        self.environment = environment
        self.debug = debug
    }
    
    func debug(event: ProtonMailAnalytics.Events,
               extra: [String : Any],
               file: String,
               function: String,
               line: Int,
               colum: Int) {
        self.debugEvent = event
        self.debugExtra = extra
        self.debugFile = file
        self.debugFunction = function
        self.debugLine = line
        self.debugColum = colum
    }
    
    func error(event: ProtonMailAnalytics.Events,
               error: Error,
               extra: [String : Any],
               file: String,
               function: String,
               line: Int,
               colum: Int) {
        self.errorEvent = event
        self.errorError = error
        self.errorExtra = extra
        self.errorFile = file
        self.errorFunction = function
        self.errorLine = line
        self.errorColum = colum
    }
    
    
}
