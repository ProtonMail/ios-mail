//
//  ProtonMailAPIService+AuthenticationExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

extension ProtonMailAPIService {
    enum AuthErrorCode: Int {
        case InvalidGrant = 100
        case UnableToParseAuthenticationToken
    }
    
    func authAuth(#username: String, password: String, success: (() -> Void), failure: (NSError -> Void)) -> Void {
        let authenticationPath = "/auth/auth"
        
        // FIXME: These values would be obtainable by inspecting the binary code, but to make thins a little more difficult, we probably don't want to these values visible when the source code is distributed.  We will probably want to come up with a way to pass in these values as pre-compiler macros.  Swift doesn't support pre-compiler macros, but we have Objective-C and can still use them.  The values would be passed in by the build scripts at build time.  Or, these values could be cleared before publishing the code.
        let clientID = "demoapp"
        let clientSecret = "client_secret"
        
        let parameters = [
            "client_id" : "demoapp",
            "client_secret" : "demopass",
            "response_type" : "token",
            "username" : username,
            "password" : password,
            "hashedpassword" : "",
            "grant_type" : "password",
            "redirect_uri" : "https://protonmail.ch",
            "state" : "\(NSUUID().UUIDString)"]
        
        sessionManager.POST(authenticationPath, parameters: parameters, success: { (task, response) -> Void in
            NSLog("\(__FUNCTION__) response: \(response)")
            
            if let credential = AuthCredential(credential: response) {
                NSLog("\(__FUNCTION__) credential: \(credential)")
                
                credential.storeInKeychain()
                
                success()
                return
            }

            var error: NSError? = nil
            let description = NSLocalizedString("Unable to sign in")
            
            if self.isErrorResponse(response) {
                error = NSError.protonMailError(code: AuthErrorCode.InvalidGrant.rawValue, localizedDescription: description, localizedFailureReason: response["error_description"] as? String)
            } else {
                error = NSError.protonMailError(code: AuthErrorCode.UnableToParseAuthenticationToken.rawValue,
                    localizedDescription: description,
                    localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"),
                    localizedRecoverySuggestion: NSLocalizedString("Contact customer support."))
            }
            
            failure(error!)
            }) { (task, error) -> Void in
                failure(error)
        }
    }
}
