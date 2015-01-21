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
        case UnableToParseAuthenticationToken
    }
    
    func authAuth(#username: String, password: String, success: (AnyObject! -> Void), failure: (NSError -> Void)) -> Void {
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
        
        sessionManager.POST(authenticationPath, parameters: parameters, success: { (task, credential) -> Void in
            var error: NSError? = nil
            
            NSLog("\(__FUNCTION__) credential: \(credential)")
            
            if let credential = AuthCredential(credential: credential) {
                credential.storeInKeychain()
                
                success(credential)
            } else {
                error = NSError.protonMailError(code: AuthErrorCode.UnableToParseAuthenticationToken.rawValue,
                    localizedDescription: NSLocalizedString("Unable to authenticate"),
                    localizedFailureReason: NSLocalizedString("Unable to parse authentication token!"),
                    localizedRecoverySuggestion: NSLocalizedString("Contact customer support."))
 
                failure(error!)
            }
            
            }) { (task, error) -> Void in
                failure(error)
        }
    }
}
