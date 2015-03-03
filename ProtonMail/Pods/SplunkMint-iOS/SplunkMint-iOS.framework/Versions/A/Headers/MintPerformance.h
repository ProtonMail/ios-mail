//
//  SplunkPerformance.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/7/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface MintPerformance : SPLJSONModel

@property (nonatomic, strong) NSString* appMemAvail;
@property (nonatomic, strong) NSString* appMemMax;
@property (nonatomic, strong) NSString* appMemTotal;
@property (nonatomic, strong) NSString* sysMemAvail;
@property (nonatomic, strong) NSString* sysMemLow;
@property (nonatomic, strong) NSString* sysMemThreshold;

@end
