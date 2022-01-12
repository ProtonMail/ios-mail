//
//  Analytics.swift
//  ProtonMail - Created on 30/11/2018.
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
import ProtonMailAnalytics
import UIKit

class Analytics {
    static var shared = Analytics()
    
    enum ENV: String {
        case production = "production"
        case enterprise = "enterprise"
    }
    
    private(set) var isEnabled = false
    
    private static var sentryEndpoint: String {
        return "https://cb78ae0c2ede43539c8ea95653847634@api.protonmail.ch/core/v4/reports/sentry/13"
    }
    
    private var analytics: ProtonMailAnalyticsProtocol?
    
    init(analytics: ProtonMailAnalyticsProtocol = ProtonMailAnalytics(endPoint: Analytics.sentryEndpoint)) {
        self.analytics = analytics
    }
    
    func setup(isInDebug: Bool, isProduction: Bool) {
        if isInDebug {
            isEnabled = false
            analytics = nil
        } else {
            if isProduction {
                analytics?.setup(environment: ENV.production.rawValue, debug: false)
            } else {
                analytics?.setup(environment: ENV.enterprise.rawValue, debug: false)
            }
            isEnabled = true
        }
    }
    
    func debug(message: ProtonMailAnalytics.Events,
               extra: [String: Any],
               file: String = #file,
               function: String = #function,
               line: Int = #line,
               column: Int = #column) {
        guard isEnabled else {
            return
        }
        analytics?.debug(event: message,
                         extra: extra,
                         file: file,
                         function: function,
                         line: line,
                         colum: column)
    }
    
    func error(message: ProtonMailAnalytics.Events,
               error: Error,
               extra: [String: Any] = [:],
               file: String = #file,
               function: String = #function,
               line: Int = #line,
               column: Int = #column) {
        guard isEnabled else {
            return
        }
        analytics?.error(event: message,
                         error: error,
                         extra: extra,
                         file: file,
                         function: function,
                         line: line,
                         colum: column)
    }
}
