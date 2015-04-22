//
//  CrashDataFixture.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/6/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "DataFixture.h"
#import "MintAppEnvironment.h"
#import "MintPerformance.h"
#import "LimitedExtraDataList.h"
#import "MintExceptionRequest.h"

@interface ExceptionDataFixture : DataFixture

+ (ExceptionDataFixture*) getInstanceWithException: (id)exception appEnvironment: (MintAppEnvironment*)anAppEnvironment performance: (MintPerformance*)aPerformance handled: (BOOL)isHandled extraData: (LimitedExtraDataList*)limitedCrashExtraData;
+ (ExceptionDataFixture*) getInstanceWithExceptionRequest: (MintExceptionRequest*)exceptionRequest andAppEnvironment: (MintAppEnvironment*)appEnvironment;

@property (nonatomic, strong) NSString* stacktrace;
@property (nonatomic, assign) BOOL handled;
@property (nonatomic, strong) NSString* klass;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* errorHash;
@property (nonatomic, strong) NSString* where;
@property (nonatomic, assign) BOOL rooted;
@property (nonatomic, strong) NSString* gpsStatus;
@property (nonatomic, strong) NSString* msFromStart;
@property (nonatomic, strong) NSString* memAppTotal;
@property (nonatomic, strong) NSString* memSysLow;
@property (nonatomic, strong) NSString* memSysAvailable;
@property (nonatomic, strong) NSString* memSysThreshold;
@property (nonatomic, strong) NSString* memAppMax;
@property (nonatomic, strong) NSString* memAppAvailable;
@property (nonatomic, strong) NSArray<SPLOptional>* breadcrumbs;

@property (nonatomic, strong) NSString<SPLOptional>* log;

@property (nonatomic, strong) NSNumber<SPLOptional>* threadCrashed;
@property (nonatomic, strong) NSString* architecture;
@property (nonatomic, strong) NSString* buildUuid;
@property (nonatomic, strong) NSString* imageBaseAddress;
@property (nonatomic, strong) NSString<SPLOptional>* imageSize;

@property (nonatomic, strong) NSString<SPLOptional>* crashReport;
@property (nonatomic, strong) NSString<SPLOptional>* slide;
@property (nonatomic, strong) NSString<SPLOptional>* loadAddress;

@end
