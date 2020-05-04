//
//  Endpoint.swift
//  PMAuthentication
//
//  Created by Anatoly Rosencrantz on 20/02/2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

protocol Endpoint {
    associatedtype Response: Codable
    var request: URLRequest { get }
}

struct ErrorResponse: Codable {
    var code: Int
    var error: String
    var errorDescription: String
}

extension NSError {
    convenience init(_ serverError: ErrorResponse) {
        let userInfo = [NSLocalizedDescriptionKey: serverError.error,
                        NSLocalizedFailureReasonErrorKey: serverError.errorDescription]
        
        self.init(domain: "PMAuthentication", code: serverError.code, userInfo: userInfo)
    }
}
