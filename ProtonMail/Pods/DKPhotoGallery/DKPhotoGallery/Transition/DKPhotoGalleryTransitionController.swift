//
//  DKPhotoGalleryTransitionController.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 09/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

open class DKPhotoGalleryTransitionController: UIPresentationController, UIViewControllerTransitioningDelegate {

    open var gallery: DKPhotoGallery!
    
    internal var interactiveController: DKPhotoGalleryInteractiveTransition?
    
    init(gallery: DKPhotoGallery, presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        self.gallery = gallery
    }
    
    internal func prepareInteractiveGesture() {
        self.interactiveController = DKPhotoGalleryInteractiveTransition(gallery: self.gallery)
    }
        
    // MARK: - UIViewControllerTransitioningDelegate
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let presentAnimator = DKPhotoGalleryTransitionPresent()
        presentAnimator.gallery = self.gallery
        return presentAnimator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let dismissAnimator = DKPhotoGalleryTransitionDismiss()
        dismissAnimator.gallery = self.gallery
        return dismissAnimator
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let interactiveController = self.interactiveController, interactiveController.isInteracting {
            return interactiveController
        } else {
            return nil
        }
    }
    
    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
}
