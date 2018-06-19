//
//  ContactCollectionViewFlowLayout.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/27/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

@objc protocol ContactCollectionViewDelegateFlowLayout : NSObjectProtocol {
    @objc func collectionView(collectionView : UICollectionView?, willChangeContentSizeTo newSize: CGSize)
}

class ContactCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributesToReturn = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        for attributes in attributesToReturn {
            if (nil == attributes.representedElementKind) {
                let indexPath = attributes.indexPath
                if let f = self.layoutAttributesForItem(at: indexPath)?.frame {
                    attributes.frame = f
                }
            }
        }
        
        return attributesToReturn
    }
    
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        /// supper item attributes at indexPath
        guard let currentItemAttributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }
        
        /// current collection view
        guard let collectionView = self.collectionView else {
            return currentItemAttributes
        }
        
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return currentItemAttributes
        }
        
        guard let cv_dataSource = collectionView.dataSource else {
            return currentItemAttributes
        }
        
        let sectionInset = flowLayout.sectionInset
        
        let total = cv_dataSource.collectionView(collectionView, numberOfItemsInSection: 0)
        let sections = cv_dataSource.numberOfSections!(in: collectionView)
        
        if indexPath.section >= sections {
            return currentItemAttributes
        }
        
        if indexPath.item == 0 {
            // first item of section
            var frame = currentItemAttributes.frame
            // first item of the section should always be left aligned
            frame.origin.x = sectionInset.left
            currentItemAttributes.frame = frame
            
            return currentItemAttributes
        }
        
        let previousIndexPath = IndexPath(item:indexPath.item - 1, section:indexPath.section)
        
        guard let previousFrame = self.layoutAttributesForItem(at: previousIndexPath)?.frame else {
            return currentItemAttributes
        }
        
        let previousFrameRightPoint = previousFrame.origin.x + previousFrame.width
        
        let currentFrame = currentItemAttributes.frame
        let stretchedCurrentFrame = CGRect(x: 0, y: currentFrame.origin.y,
                                              width: collectionView.frame.width,
                                              height: currentFrame.height)
        if !previousFrame.intersects(stretchedCurrentFrame) {
            // if current item is the first item on the line
            // the approach here is to take the current frame, left align it to the edge of the view
            // then stretch it the width of the collection view, if it intersects with the previous frame then that means it
            // is on the same line, otherwise it is on it's own new line
            var frame = currentItemAttributes.frame

            //TODO:: later
//            if collectionView.frame.width - previousFrame.origin.x >  collectionView.frame.width / 2 {
//                frame.origin.y = previousFrame.origin.y
//                frame.origin.x = previousFrameRightPoint
//                frame.size.width =  collectionView.frame.width - previousFrameRightPoint - sectionInset.right
//            } else {
//                frame.origin.x = sectionInset.left // first item on the line should always be left aligned
//            }
            
            frame.origin.x = sectionInset.left // first item on the line should always be left aligned
            if indexPath.row == total - 1 {
                let newWidth = collectionView.frame.width - sectionInset.left - sectionInset.right
                frame.size.width = max(max(50, newWidth.rounded(.up)), frame.width)
            }
            currentItemAttributes.frame = frame
            return currentItemAttributes
        }

        var frame = currentItemAttributes.frame
        frame.origin.x = previousFrameRightPoint
        if indexPath.row == total - 1 {
            let newWidth = collectionView.frame.width - previousFrameRightPoint - sectionInset.right
            frame.size.width = max(max(50, newWidth.rounded(.up)), frame.width)
        }
        currentItemAttributes.frame = frame
        return currentItemAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
    
    override func finalizeCollectionViewUpdates() {
        if let delegate = self.collectionView?.delegate as? ContactCollectionViewDelegateFlowLayout {
            if delegate.responds(to: #selector(ContactCollectionViewDelegateFlowLayout.collectionView(collectionView:willChangeContentSizeTo:))) {
                delegate.collectionView(collectionView: self.collectionView, willChangeContentSizeTo: self.collectionViewContentSize)
            }
        }
    }
}
