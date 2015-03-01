//
//  AppDelegate.swift
//  ProtonMail
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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    
    private let animationDuration: NSTimeInterval = 0.5
    
    var window: UIWindow?
    var rootViewController: UIViewController?
    
    func instantiateRootViewController() -> UIViewController {
        let storyboard = UIStoryboard.Storyboard.signIn
        return UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
    }

    func setupWindow() {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = instantiateRootViewController()
        window?.makeKeyAndVisible()
    }
    
    // MARK: - Snapshot methods

    func cleanUpAfterSnapshot() {
        window?.rootViewController = rootViewController
    }
    
    // create a view and overlay the screen
    func prepareForSnapshot() {
        rootViewController = window?.rootViewController
        
        let viewController =  UIViewController()
        viewController.view = NSBundle.mainBundle().loadNibNamed("LaunchScreen", owner: self, options: nil).first as? UIView ?? {
            let view = UIView(frame: self.window!.bounds)
            view.backgroundColor = UIColor.ProtonMail.Blue_85B1DE
            
            return view
            }()
        
        window?.rootViewController = viewController
        window?.snapshotViewAfterScreenUpdates(true)
    }
    
    // MARK: - Public methods
    
    func switchTo(#storyboard: UIStoryboard.Storyboard) {
        if let window = window {
            if let rootViewController = window.rootViewController {
                if rootViewController.restorationIdentifier != storyboard.restorationIdentifier {
                    UIView.transitionWithView(window, duration: animationDuration, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: { () -> Void in
                        window.rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: storyboard)
                        }, completion: nil)
                }
            }
        }
    }
    
}


// MARK: - UIApplicationDelegate

extension AppDelegate: UIApplicationDelegate {

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
        setupWindow()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        prepareForSnapshot()
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        cleanUpAfterSnapshot()
        
        if sharedUserDataService.isSignedIn {
            sharedUserDataService.fetchUserInfo()
            sharedContactDataService.fetchContacts({ (contacts, error) -> Void in
                if error != nil {
                    NSLog("\(error)")
                } else {
                    NSLog("Contacts count: \(contacts!.count)")
                }
            })
        }
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        sharedCoreDataService.mainManagedObjectContext?.saveUpstreamIfNeeded()
    }

}

