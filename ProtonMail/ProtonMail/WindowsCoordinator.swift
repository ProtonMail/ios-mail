//
//  WindowsCoordinator.swift
//  ProtonMail - Created on 12/11/2018.
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
import Keymaker

class WindowsCoordinator: CoordinatorNew {
    private lazy var snapshot = Snapshot()
    private var upgradeView: ForceUpgradeView?
    private var appWindow: UIWindow?
    var currentWindow: UIWindow! {
        didSet {
            self.currentWindow.makeKeyAndVisible()
        }
    }
    
    enum Destination {
        case lockWindow, appWindow, signInWindow
    }
    
    init() {
        defer {
            NotificationCenter.default.addObserver(self, selector: #selector(performForceUpgrade), name: .forceUpgrade, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(lock), name: Keymaker.requestMainKey, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(unlock), name: Keymaker.obtainedMainKey, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(unlock), name: .didUnlock, object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
    }
    
    func start() {
        let placeholder = UIWindow(frame: UIScreen.main.bounds)
        placeholder.rootViewController = UIViewController() 
        self.snapshot.show(at: placeholder)
        self.currentWindow = placeholder
        UnlockManager.shared.isUnlocked()
    }
    
    @objc func willEnterForeground() {
        self.snapshot.remove()
    }
    
    @objc func didEnterBackground() {
        self.snapshot.show(at: self.currentWindow)
    }
    
    @objc func lock() {
        self.setupWindow(gotMainKey: false)
    }
    
    @objc func unlock() {
        self.setupWindow(gotMainKey: true)
    }
    
    private func setupWindow(gotMainKey: Bool) {
        guard SignInManager.shared.isSignedIn() else {
            self.go(dest: .signInWindow)
            return
        }
        
        switch gotMainKey {
        case true: self.go(dest: .appWindow)
        case false: self.go(dest: .lockWindow)
        }
    }
    
    func go(dest: Destination) {
        DispatchQueue.main.async { // cuz creating windows here
            switch dest {
            case .signInWindow:
                self.appWindow = nil
                self.navigate(from: self.currentWindow, to: UIWindow(storyboard: .signIn))
                
            case .lockWindow:
                self.navigate(from: self.currentWindow, to: UIWindow(storyboard: .signIn))
                
            case .appWindow:
                self.appWindow = self.appWindow ?? UIWindow(storyboard: .inbox)
                self.navigate(from: self.currentWindow, to: self.appWindow!)
            }
        }
    }
    
    @discardableResult func navigate(from source: UIWindow, to destination: UIWindow) -> Bool {
        guard source != destination,
            source.rootViewController?.restorationIdentifier != destination.rootViewController?.restorationIdentifier else
        {
            return false
        }
        
        let effectView = UIVisualEffectView(frame: UIScreen.main.bounds)
        source.addSubview(effectView)
        destination.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, animations: {
            effectView.effect = UIBlurEffect(style: .dark)
            destination.alpha = 1.0
        }, completion: { _ in
            let _ = source
            let _ = destination
            effectView.removeFromSuperview()
        })
        
        self.currentWindow = destination
        
        return true
    }
}

// This logic is taken from AppDelegate as-is, not refactored
extension WindowsCoordinator: ForceUpgradeViewDelegate {
    @objc func performForceUpgrade(_ notification: Notification) {
        guard let keywindow = UIApplication.shared.keyWindow else {
            return
        }
        
        if let exsitView = upgradeView {
            keywindow.bringSubviewToFront(exsitView)
            return
        }
        
        let view = ForceUpgradeView(frame: keywindow.bounds)
        self.upgradeView = view
        if let msg = notification.object as? String {
            view.messageLabel.text = msg
        }
        view.delegate = self
        UIView.transition(with: keywindow, duration: 0.25,
                          options: .transitionCrossDissolve, animations: {
                            keywindow.addSubview(view)
        }, completion: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func rotated() {
        if let view = self.upgradeView {
            guard let keywindow = UIApplication.shared.keyWindow else {
                return
            }
            
            UIView.animate(withDuration: 0.25, delay: 0.0,
                           options: UIView.AnimationOptions.layoutSubviews, animations: {
                            view.frame = keywindow.frame
                            view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func learnMore() {
        if UIApplication.shared.canOpenURL(.kbUpdateRequired) {
            UIApplication.shared.openURL(.kbUpdateRequired)
        }
    }
    func update() {
        if UIApplication.shared.canOpenURL(.appleStore) {
            UIApplication.shared.openURL(.appleStore)
        }
    }
}

extension UIWindow {
    convenience init(storyboard: UIStoryboard.Storyboard) {
        self.init(frame: UIScreen.main.bounds)
        self.rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
    }
}
