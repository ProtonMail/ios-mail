//
//  UICollectionViewContactFlowLayout.h
//  MBContactPicker
//
//  Created by Matt Bowman on 12/1/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MBContactCollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView*)collectionView willChangeContentSizeTo:(CGSize)newSize;

@end

@interface MBContactCollectionViewFlowLayout : UICollectionViewFlowLayout

@end
