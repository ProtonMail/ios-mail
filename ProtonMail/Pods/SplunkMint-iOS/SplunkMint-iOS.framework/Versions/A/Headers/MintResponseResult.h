//
//  SplunkResponseResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "MintResult.h"

@interface MintResponseResult : MintResult

@property (nonatomic, strong) NSNumber* errorId;
@property (nonatomic, strong) NSString* serverResponse;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* contentText;
@property (nonatomic, strong) NSString* tickerText;
@property (nonatomic, strong) NSString* contentTitle;
@property (nonatomic, assign) BOOL isResolved;

@end
