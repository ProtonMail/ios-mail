//
//  UICollectionViewContactFlowLayout.m
//  MBContactPicker
//
//  Created by Matt Bowman on 12/1/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import "MBContactCollectionViewFlowLayout.h"

@interface MBContactCollectionViewFlowLayout()

@end

// This is using the answer provided in the stack overflow post: http://bit.ly/INr0ie

@implementation MBContactCollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray* attributesToReturn = [super layoutAttributesForElementsInRect:rect];

    for (UICollectionViewLayoutAttributes* attributes in attributesToReturn)
    {
        if (nil == attributes.representedElementKind)
        {
            NSIndexPath* indexPath = attributes.indexPath;
            attributes.frame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
        }
    }
    
    return attributesToReturn;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes* currentItemAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    UIEdgeInsets sectionInset = [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout sectionInset];
    
    NSInteger total = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0];
    
    if (indexPath.item == 0)
    {
        // first item of section
        CGRect frame = currentItemAttributes.frame;
        // first item of the section should always be left aligned
        frame.origin.x = sectionInset.left;
        currentItemAttributes.frame = frame;
        
        return currentItemAttributes;
    }
    
    NSIndexPath* previousIndexPath = [NSIndexPath indexPathForItem:indexPath.item-1 inSection:indexPath.section];
    CGRect previousFrame = [self layoutAttributesForItemAtIndexPath:previousIndexPath].frame;
    CGFloat previousFrameRightPoint = previousFrame.origin.x + previousFrame.size.width;// + self.minimumInteritemSpacing;
    
    CGRect currentFrame = currentItemAttributes.frame;
    CGRect stretchedCurrentFrame = CGRectMake(0,
                                              currentFrame.origin.y,
                                              self.collectionView.frame.size.width,
                                              currentFrame.size.height);
    
    if (!CGRectIntersectsRect(previousFrame, stretchedCurrentFrame))
    {
        // if current item is the first item on the line
        // the approach here is to take the current frame, left align it to the edge of the view
        // then stretch it the width of the collection view, if it intersects with the previous frame then that means it
        // is on the same line, otherwise it is on it's own new line
        CGRect frame = currentItemAttributes.frame;
        frame.origin.x = sectionInset.left; // first item on the line should always be left aligned
        if (indexPath.row == total - 1)
        {
            CGFloat newWidth = self.collectionView.frame.size.width - sectionInset.left - sectionInset.right;
            frame.size.width = MAX(MAX(50, ceilf(newWidth)), frame.size.width);
        }
        currentItemAttributes.frame = frame;
        return currentItemAttributes;
    }
    
    CGRect frame = currentItemAttributes.frame;
    frame.origin.x = previousFrameRightPoint;
    if (indexPath.row == total - 1)
    {
        CGFloat newWidth = self.collectionView.frame.size.width - previousFrameRightPoint - sectionInset.right;
        frame.size.width = MAX(MAX(50, ceilf(newWidth)), frame.size.width);
    }
    currentItemAttributes.frame = frame;
    return currentItemAttributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (void)finalizeCollectionViewUpdates
{
    if ([self.collectionView.delegate respondsToSelector:@selector(collectionView:willChangeContentSizeTo:)])
    {
        [(id)self.collectionView.delegate collectionView:self.collectionView willChangeContentSizeTo:self.collectionViewContentSize];
    }
}

@end
