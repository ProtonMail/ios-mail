//
//  DKPhotoContentAnimationView.swift
//  DKPhotoGallery
//
//  Created by ZhangAo on 07/11/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//
//  Inspired by: https://github.com/patrickbdev/PBImageView/blob/master/PBImageView/Classes/PBImageView.swift
//

import UIKit

open class DKPhotoContentAnimationView: UIView {
    
    let contentView: UIView
    let contentSize: CGSize
    
    init(image: UIImage?) {
        self.contentView = UIImageView(image: image)
        if let image = image {
            self.contentSize = image.size
        } else {
            self.contentSize = CGSize.zero
        }
        
        super.init(frame: CGRect.zero)
        
        self.addSubview(self.contentView)
    }
    
    init(view: UIView, contentSize: CGSize = CGSize.zero) {
        self.contentView = view
        if contentSize == CGSize.zero {
            self.contentSize = view.bounds.size
        } else {
            self.contentSize = contentSize
        }
        
        super.init(frame: CGRect.zero)
        
        self.addSubview(self.contentView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    #if swift(>=4.2)
    open override var contentMode: UIView.ContentMode {
        didSet {
            self.layoutContentView()
        }
    }
    #else
    open override var contentMode: UIViewContentMode {
        didSet {
            self.layoutContentView()
        }
    }
    #endif
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        self.layoutContentView()
    }
    
    open override var backgroundColor: UIColor? {
        get { return self.contentView.backgroundColor }
        set { self.contentView.backgroundColor = newValue }
    }
    
    private func layoutContentView() {
        guard self.contentSize != CGSize.zero else { return }
        
        // MARK: - Layout Helpers
        func imageToBoundsWidthRatio(size: CGSize) -> CGFloat  { return size.width / bounds.size.width }
        func imageToBoundsHeightRatio(size: CGSize) -> CGFloat { return size.height / bounds.size.height }
        func centerImageViewToPoint(point: CGPoint)              { self.contentView.center = point }
        func imageViewBoundsToImageSize()                        { imageViewBoundsToSize(size: self.contentSize) }
        func imageViewBoundsToSize(size: CGSize)                 { self.contentView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height) }
        func centerImageView()                                   { self.contentView.center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2) }
        
        // MARK: - Layouts
        func layoutAspectFit() {
            let widthRatio = imageToBoundsWidthRatio(size: self.contentSize)
            let heightRatio = imageToBoundsHeightRatio(size: self.contentSize)
            imageViewBoundsToSize(size: CGSize(width: self.contentSize.width / max(widthRatio, heightRatio),
                                               height: self.contentSize.height / max(widthRatio, heightRatio)))
            centerImageView()
        }
        
        func layoutAspectFill() {
            let widthRatio = imageToBoundsWidthRatio(size: self.contentSize)
            let heightRatio = imageToBoundsHeightRatio(size: self.contentSize)
            imageViewBoundsToSize(size: CGSize(width: self.contentSize.width /  min(widthRatio, heightRatio),
                                               height: self.contentSize.height / min(widthRatio, heightRatio)))
            centerImageView()
        }
        
        func layoutFill() {
            imageViewBoundsToSize(size: CGSize(width: bounds.size.width, height: bounds.size.height))
        }
        
        func layoutCenter() {
            imageViewBoundsToImageSize()
            centerImageView()
        }
        
        func layoutTop() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: bounds.size.width / 2, y: self.contentSize.height / 2))
        }
        
        func layoutBottom() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: bounds.size.width / 2, y: bounds.size.height - self.contentSize.height / 2))
        }
        
        func layoutLeft() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: self.contentSize.width / 2, y: bounds.size.height / 2))
        }
        
        func layoutRight() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: bounds.size.width - self.contentSize.width / 2, y: bounds.size.height / 2))
        }
        
        func layoutTopLeft() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: self.contentSize.width / 2, y: self.contentSize.height / 2))
        }
        
        func layoutTopRight() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: bounds.size.width - self.contentSize.width / 2, y: self.contentSize.height / 2))
        }
        
        func layoutBottomLeft() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: self.contentSize.width / 2, y: bounds.size.height - self.contentSize.height / 2))
        }
        
        func layoutBottomRight() {
            imageViewBoundsToImageSize()
            centerImageViewToPoint(point: CGPoint(x: bounds.size.width - self.contentSize.width / 2, y: bounds.size.height - self.contentSize.height / 2))
        }
        
        switch contentMode {
        case .scaleAspectFit:  layoutAspectFit()
        case .scaleAspectFill: layoutAspectFill()
        case .scaleToFill:     layoutFill()
        case .redraw:          break
        case .center:          layoutCenter()
        case .top:             layoutTop()
        case .bottom:          layoutBottom()
        case .left:            layoutLeft()
        case .right:           layoutRight()
        case .topLeft:         layoutTopLeft()
        case .topRight:        layoutTopRight()
        case .bottomLeft:      layoutBottomLeft()
        case .bottomRight:     layoutBottomRight()
        @unknown default:
            break
        }
    }
}
