//
//  EventDataFixture.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/6/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "DataFixture.h"
#import "MintAppEnvironment.h"
#import "MintEnums.h"
#import "LimitedExtraDataList.h"

@interface EventDataFixture : DataFixture

@property (nonatomic, strong) NSString<SPLOptional>* name;
@property (nonatomic, strong) NSNumber<SPLOptional>* level;
@property (nonatomic, strong) NSString<SPLOptional>* sessionId;

+ (EventDataFixture*) getInstanceForEventTag:(NSString*)eventTag andAppEnvironment:(MintAppEnvironment*)anAppEnvironment;
+ (EventDataFixture*) getInstanceForName:(NSString *)name withLogLevel:(MintLogLevel)logLevel andAppEnvironment:(MintAppEnvironment *)anAppEnvironment;

@end
