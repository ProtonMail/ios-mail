//
//  DataErrorResponse.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/7/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface DataErrorResponse : SPLJSONModel

@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* contentText;
@property (nonatomic, strong) NSString* eid;
@property (nonatomic, strong) NSString* tickerText;
@property (nonatomic, strong) NSString* contentTitle;

@end
