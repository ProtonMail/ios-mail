//
//  CrashOnLastRun.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface CrashOnLastRun : SPLJSONModel

@property (nonatomic, strong) NSNumber* errorId;
@property (nonatomic, assign) NSInteger totalCrashes;

@end
