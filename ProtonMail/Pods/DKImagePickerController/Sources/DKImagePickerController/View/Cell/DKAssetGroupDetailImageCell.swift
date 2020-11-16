//
//  DKAssetGroupDetailImageCell.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 07/12/2016.
//  Copyright © 2016 ZhangAo. All rights reserved.
//

import UIKit

@objcMembers
public class DKAssetGroupDetailImageCell: DKAssetGroupDetailBaseCell {
    
    public class override func cellReuseIdentifier() -> String {
        return "DKImageAssetIdentifier"
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.thumbnailImageView.frame = self.bounds
        self.thumbnailImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.contentView.addSubview(self.thumbnailImageView)
        
        self.checkView.frame = self.bounds
        self.checkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.checkView.checkImageView.tintColor = nil
        self.checkView.checkLabel.font = UIFont.boldSystemFont(ofSize: 14)
        self.checkView.checkLabel.textColor = UIColor.white
        self.contentView.addSubview(self.checkView)
        self.contentView.accessibilityIdentifier = "DKImageAssetAccessibilityIdentifier"
        self.contentView.isAccessibilityElement = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open class DKImageCheckView: UIView {
        
        internal lazy var checkImageView: UIImageView = {
            let imageView = UIImageView(image: DKImagePickerControllerResource.checkedImage())
            return imageView
        }()
        
        internal lazy var checkLabel: UILabel = {
            let label = UILabel()
            label.textAlignment = .right
            
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.addSubview(self.checkImageView)
            self.addSubview(self.checkLabel)
        }
        
        required public init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override open func layoutSubviews() {
            super.layoutSubviews()
            
            self.checkImageView.frame = self.bounds
            self.checkLabel.frame = CGRect(x: 0, y: 5, width: self.bounds.width - 5, height: 20)
        }
        
    } /* DKImageCheckView */
    
    override public var thumbnailImage: UIImage? {
        didSet {
            self.thumbnailImageView.image = self.thumbnailImage
        }
    }
    override public var selectedIndex: Int {
        didSet {
            self.checkView.checkLabel.text =  "\(self.selectedIndex + 1)"
        }
    }
    
    internal lazy var _thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        
        return thumbnailImageView
    }()
    
    override public var thumbnailImageView: UIImageView {
        get {
            return _thumbnailImageView
        }
    }
    
    public let checkView = DKImageCheckView()
    
    override public var isSelected: Bool {
        didSet {
            self.checkView.isHidden = !super.isSelected
        }
    }
    
} /* DKAssetGroupDetailCell */
