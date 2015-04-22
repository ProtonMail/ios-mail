//
//  MintWKWebView.h
//  Splunk-iOS
//
//  Created by Dharmalingam Madheswaran on 3/23/15.
//  Copyright (c) 2015 SLK. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface MintWKWebView : WKWebView
- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration;
- (instancetype)initWithFrame:(CGRect)frame;
@end
