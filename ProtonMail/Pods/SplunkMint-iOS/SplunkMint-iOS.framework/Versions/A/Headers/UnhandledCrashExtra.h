//
//  UnhandledCrashExtra.h
//  Splunk-iOS
//
//  Created by George Taskos on 10/2/14.
//  Copyright (c) 2014 SLK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface UnhandledCrashExtra : SPLJSONModel

@property (nonatomic, strong) NSString* connection;
@property (nonatomic, strong) NSString* state;
@property (nonatomic, strong) NSDate* sessionStartDate;
@property (nonatomic, strong) NSString* msFromStart;
@property (nonatomic, strong) NSArray<SPLIgnore>* breadcrumbs;
@property (nonatomic, strong) NSArray<SPLIgnore>* extraData;
@property (nonatomic, strong) UnhandledCrashExtra<SPLIgnore>* latestUnhandledCrashExtra;

+ (instancetype) sharedInstance;
+ (void) crashReportDate:(NSDate*)crashDate;
- (UnhandledCrashExtra*) loadUnhandledCrashExtra;
- (void) loadLatestUnhandledExtraData;
- (void) saveUnhandledCrashExtra;

@end
