//
//  SplunkErrorResponse.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataErrorResponse.h"
#import "SPLJSONModel.h"

@interface MintErrorResponse : SPLJSONModel

@property (nonatomic, strong) NSString* error;
@property (nonatomic, strong) DataErrorResponse* data;

@end
