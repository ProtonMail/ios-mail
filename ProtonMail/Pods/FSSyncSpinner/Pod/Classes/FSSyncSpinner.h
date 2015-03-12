//
//  FSSyncSpinner.h
//  Pods
//
//  Created by Wenchao Ding on 3/8/15.
//
//

#import <UIKit/UIKit.h>

@interface FSSyncSpinner : UIView

@property (assign, nonatomic) BOOL hidesWhenFinished;

- (void)startAnimating;
- (void)finish;

@end
