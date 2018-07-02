//
//  DKPhotoGalleryTransitionPresent.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 16/6/22.
//  Copyright © 2016年 ZhangAo. All rights reserved.
//

import UIKit
import AVFoundation

@objc
open class DKPhotoGalleryTransitionPresent: NSObject, UIViewControllerAnimatedTransitioning {
    
    var gallery: DKPhotoGallery!
    
    // MARK: - UIViewControllerAnimatedTransitioning
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let transitionDuration = self.transitionDuration(using: transitionContext)
        
        let containerView = transitionContext.containerView
        let toViewController = transitionContext.viewController(forKey: .to)!
        let toView = transitionContext.view(forKey: .to)!
        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
        
        if let fromImageView = self.gallery.presentingFromImageView, let fromImage = fromImageView.image {
            let fromImageViewFrameInScreen = fromImageView.superview?.convert(fromImageView.frame, to: nil)
            let snapshotImageView = DKPhotoContentAnimationView(image: fromImage)
            snapshotImageView.frame = fromImageViewFrameInScreen!
            snapshotImageView.contentMode = fromImageView.contentMode
            snapshotImageView.backgroundColor = fromImageView.backgroundColor
            snapshotImageView.clipsToBounds = fromImageView.clipsToBounds
            snapshotImageView.layer.cornerRadius = fromImageView.layer.cornerRadius
            
            containerView.addSubview(snapshotImageView)
            
            UIView.animate(withDuration: transitionDuration, animations: {
                let frame = AVMakeRect(aspectRatio: fromImage.size, insideRect: toViewFinalFrame)
                snapshotImageView.frame = frame
                snapshotImageView.contentMode = toView.contentMode
                snapshotImageView.clipsToBounds = toView.clipsToBounds
                snapshotImageView.layer.cornerRadius = toView.layer.cornerRadius
                containerView.backgroundColor = UIColor.black
            }) { (finished) in
                let wasCanceled = transitionContext.transitionWasCancelled
                if !wasCanceled {
                    toView.frame = toViewFinalFrame
                    containerView.addSubview(toView)
                    snapshotImageView.removeFromSuperview()
                    containerView.backgroundColor = UIColor.clear
                }
                transitionContext.completeTransition(!wasCanceled)
            }
        } else {
            containerView.addSubview(toView)
            
            toView.alpha = 0
            UIView.animate(withDuration: transitionDuration, animations: {
                toView.alpha = 1
            }, completion: { (finished) in
                let wasCanceled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!wasCanceled)
            })
        }
    }
    
}
