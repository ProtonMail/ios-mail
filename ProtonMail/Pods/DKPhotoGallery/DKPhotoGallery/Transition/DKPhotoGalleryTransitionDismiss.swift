//
//  DKPhotoGalleryTransitionDismiss.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 16/6/22.
//  Copyright © 2016年 ZhangAo. All rights reserved.
//

import UIKit

@objc
open class DKPhotoGalleryTransitionDismiss: NSObject, UIViewControllerAnimatedTransitioning {
    
    var gallery: DKPhotoGallery!
    
    // UIViewControllerAnimatedTransitioning
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let transitionDuration = self.transitionDuration(using: transitionContext)
        
        let containerView = transitionContext.containerView
        
        var fromContentView: UIView!
        if self.gallery.currentContentVC().previewType == .photo {
            fromContentView = DKPhotoContentAnimationView(image: self.gallery.currentContentVC().snapshotImage())
            fromContentView.frame = self.gallery.currentContentView().superview!.convert(self.gallery.currentContentView().frame, to: nil)
            fromContentView.contentMode = self.gallery.currentContentView().contentMode
            fromContentView.layer.cornerRadius = self.gallery.currentContentView().layer.cornerRadius
            fromContentView.clipsToBounds = self.gallery.currentContentView().clipsToBounds
            
            self.gallery.currentContentView().isHidden = true
        } else if (self.gallery.currentContentVC().previewType == .video) {
            let playerView = self.gallery.currentContentView() as! DKPlayerView
            playerView.autoresizingMask = []
            let frame = self.gallery.currentContentView().superview!.convert(playerView.frame, to: nil)
            
            fromContentView = DKPhotoContentAnimationView(view: playerView)
            fromContentView.frame = frame
            fromContentView.contentMode = playerView.contentMode
            fromContentView.layer.cornerRadius = playerView.layer.cornerRadius
            fromContentView.clipsToBounds = playerView.clipsToBounds
        } else if #available(iOS 11.0, *), self.gallery.currentContentVC().previewType == .pdf {
            let pdfView = self.gallery.currentContentView() as! DKPDFView
            pdfView.autoresizingMask = []
            let frame = self.gallery.currentContentView().superview!.convert(pdfView.frame, to: nil)
            
            fromContentView = DKPhotoContentAnimationView(view: pdfView)
            fromContentView.frame = frame
            fromContentView.contentMode = pdfView.contentMode
            fromContentView.layer.cornerRadius = pdfView.layer.cornerRadius
            fromContentView.clipsToBounds = pdfView.clipsToBounds
        }
        
        containerView.addSubview(fromContentView)
        
        self.gallery.setNavigationBarHidden(true, animated: true)
        self.gallery.setFooterViewHidden(true, animated: true)
        
        let currentIndex = self.gallery.contentVC!.currentIndex
        let currentItem = self.gallery.item(for: currentIndex)
        
        if let toImageView = self.gallery.finishedBlock?(currentIndex, currentItem), let _ = toImageView.image {
            fromContentView.clipsToBounds = toImageView.clipsToBounds
            toImageView.isHidden = true
            UIView.animate(withDuration: transitionDuration, animations: {
                let toImageViewFrameInScreen = toImageView.superview!.convert(toImageView.frame, to: nil)
                fromContentView.frame = toImageViewFrameInScreen
                fromContentView.contentMode = toImageView.contentMode
                fromContentView.backgroundColor = toImageView.backgroundColor
                fromContentView.layer.cornerRadius = toImageView.layer.cornerRadius
                fromContentView.clipsToBounds = toImageView.clipsToBounds
                self.gallery.updateContextBackground(alpha: 0, animated: false)
            }) { (finished) in
                toImageView.isHidden = false
                
                let wasCanceled = transitionContext.transitionWasCancelled
                if wasCanceled {
                    self.gallery.updateContextBackground(alpha: 1, animated: false)
                }
                
                transitionContext.completeTransition(!wasCanceled)
            }
        } else {
            UIView.animate(withDuration: transitionDuration, animations: { 
                containerView.alpha = 0
                fromContentView.alpha = 0
                self.gallery.updateContextBackground(alpha: 0, animated: false)
            }, completion: { (finished) in
                let wasCanceled = transitionContext.transitionWasCancelled
                transitionContext.completeTransition(!wasCanceled)
            })
        }
    }
    
}
