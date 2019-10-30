//
//  DKPhotoGalleryInteractiveTransition.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 09/09/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import UIKit

class DKPhotoGalleryInteractiveTransition: UIPercentDrivenInteractiveTransition, UIGestureRecognizerDelegate {

    private var gallery: DKPhotoGallery!
    
    private var fromContentView: UIView?
    private var fromRectInScreen: CGRect!
    private var fromRect: CGRect!
    private var toImageView: UIImageView?
    
    internal var isInteracting = false
    private var interactingBeginPoint = CGPoint.zero
    private var interactingLastPoint = CGPoint.zero
    private var interactingPercent: CGFloat = 0
    
    convenience init(gallery: DKPhotoGallery) {
        self.init()
        
        self.gallery = gallery
        self.setupGesture()
    }
    
    private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture))
        panGesture.delegate = self
        self.gallery.view.addGestureRecognizer(panGesture)
    }
    
    @objc private func handleGesture(_ recognizer: UIPanGestureRecognizer) {
        let offset = recognizer.translation(in: recognizer.view?.superview)
        
        switch recognizer.state {
        case .began:
            self.isInteracting = true
            self.interactingBeginPoint = offset
            self.interactingLastPoint = offset
            self.fromContentView = self.gallery.currentContentView()
            if let fromContentView = fromContentView {
                self.fromRect = fromContentView.frame
                self.fromRectInScreen = fromContentView.superview?.convert(fromContentView.frame, to: nil)
            } else {
                self.fromRect = CGRect.zero
                self.fromRectInScreen = CGRect.zero
            }
            
            let currentIndex = self.gallery.currentIndex()
            let currentItem = self.gallery.item(for: currentIndex)
            
            self.toImageView = self.gallery.finishedBlock?(currentIndex, currentItem)
            if let _ = self.toImageView?.image {
                self.toImageView?.isHidden = true
            }
        case .changed:
            let oldOrientation = self.interactingLastPoint.y - self.interactingBeginPoint.y >= 0
            let newOrientation = offset.y - self.interactingLastPoint.y >= 0
            if oldOrientation != newOrientation {
                self.interactingBeginPoint = offset
            }
            
            self.interactingLastPoint = offset
            let fraction = CGFloat(fabsf(Float(offset.y / 200)))
            self.interactingPercent = fmin(fraction, 1.0)
            
            if let fromContentView = self.fromContentView {
                let currentLocation = recognizer.location(in: nil)
                let originalLocation = CGPoint(x: currentLocation.x - offset.x, y: currentLocation.y - offset.y)
                var percent = CGFloat(1.0)
                percent = fmax(offset.y > 0 ? 1 - self.interactingPercent : 1.0, 0.5)
                let currentWidth = self.fromRectInScreen.width * percent
                let currentHeight = self.fromRectInScreen.height * percent
                
                let result = CGRect(x: currentLocation.x - (originalLocation.x - self.fromRectInScreen.origin.x) * percent,
                                    y: currentLocation.y - (originalLocation.y - self.fromRectInScreen.origin.y) * percent,
                                    width: currentWidth,
                                    height: currentHeight)
                fromContentView.frame = (fromContentView.superview?.convert(result, from: nil))!
                
                if offset.y < 0 {
                    self.interactingPercent = -self.interactingPercent
                }
                
                self.gallery.updateContextBackground(alpha: CGFloat(fabsf(Float(1.0 - self.interactingPercent))), animated: true)
            }
        case .ended,
             .cancelled:
            self.isInteracting = false
            let shouldComplete = self.interactingLastPoint.y - self.interactingBeginPoint.y > 10
            if !shouldComplete || recognizer.state == .cancelled {
                if let fromContentView = self.fromContentView {
                    let toImageView = self.toImageView
                    UIView.animate(withDuration: 0.3, animations: {
                        fromContentView.frame = self.fromRect
                        self.gallery.updateContextBackground(alpha: 1, animated: false)
                    }) { (finished) in
                        if let _ = toImageView?.image {
                            toImageView?.isHidden = false
                        }
                    }
                }
            } else {
                self.gallery.dismissGallery()
                self.finish()
            }
            self.fromContentView = nil
            self.interactingPercent = 0
            self.toImageView = nil
        default:
            break
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureView = gestureRecognizer.view else { return true }
        
        let location = gestureRecognizer.location(in: gestureView)
        
        if let hitTestingView = gestureView.hitTest(location, with: nil), hitTestingView.isKind(of: UISlider.self) {
            return false
        } else {
            return true
        }
    }

}
