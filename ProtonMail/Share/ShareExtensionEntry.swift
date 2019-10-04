//
//  ShareExtensionEntry.swift
//  Share - Created on 6/28/17.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation
import UIKit
import AFNetworking

@objc(ShareExtensionEntry)
class ShareExtensionEntry : UINavigationController {
    var reachabilityManager: AFNetworkReachabilityManager = {
        let manager = AFNetworkReachabilityManager.shared()
        manager.startMonitoring()
        return manager
    }()
    var appCoordinator : ShareAppCoordinator?

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.setup()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.setup()
    }
    
    private func setup() {
        TrustKitWrapper.start(delegate: self)
        appCoordinator = ShareAppCoordinator(navigation: self)
        sharedAPIService.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appCoordinator?.start()
    }
}

extension ShareExtensionEntry: APIServiceDelegate {
    func onError(error: NSError) {
        // alert
        error.alertErrorToast()
    }
    
    func isReachable() -> Bool {
        return self.reachabilityManager.isReachable
    }
}

extension ShareExtensionEntry: TrustKitUIDelegate {
    func onTrustKitValidationError(_ alert: UIAlertController) {
        self.appCoordinator?.navigationController?.present(alert, animated: true, completion: nil)
    }
}
