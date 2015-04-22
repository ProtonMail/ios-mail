//
//  MintUIWebView.h
//  Splunk-iOS
//
//  Created by Dharmalingam Madheswaran on 3/12/15.
//  Copyright (c) 2015 SLK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MintUIWebView : UIWebView

- (id) initWithCoder:(NSCoder *)aDecoder;
- (id) initWithFrame:(CGRect)frame;
- (void) setDelegate:(id<UIWebViewDelegate>)delegate;

@end
