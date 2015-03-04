//
//  SplunkProperties.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScreenProperties.h"
#import "TypeBlocks.h"
#import "MintEnums.h"

@interface MintProperties : NSObject

extern BOOL IsSplunkPlugin;

+ (MintProperties*) sharedInstance;

- (NSString*) newFileNameForType: (FileNameType)fileNameType;
- (NSString*) createUrlWithErrorsCount: (NSInteger)errorsCount andEventsCount: (NSInteger)eventsCount;

@property (nonatomic, assign) BOOL isSessionActive;
@property (nonatomic, assign) BOOL isInitialized;
@property (nonatomic, strong) NSString* apiKey;
@property (nonatomic, assign) BOOL proxyEnabled;
@property (nonatomic, strong) NSString* debugTestUrl;
@property (nonatomic, strong) NSString* uid;@property (nonatomic, strong) NSString* carrier;
@property (nonatomic, strong) NSString* appName;
@property (nonatomic, assign) BOOL rooted;
@property (nonatomic, strong) NSString* userIdentifier;
@property (nonatomic, assign) BOOL handleWhileDebugging;
@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* analyticsUrl;
@property (nonatomic, assign) NSUInteger maxExceptions;
@property (nonatomic, strong) NSString* exceptionsFolderName;
@property (nonatomic, strong) NSString* generalFolderName;
@property (nonatomic, strong) NSString* crashOnLastRunFileName;
@property (nonatomic, strong) NSString* remoteSettingsFileName;
@property (nonatomic, strong) NSString* globalExtraDataFileName;
@property (nonatomic, strong) NSString* nsLogMessagedFileName;
@property (nonatomic, strong) NSString* breadcrumbsFileName;
@property (nonatomic, strong) NSString* unhandledCrashExtraFileName;
@property (nonatomic, strong) NSString* splunkVersion;
@property (nonatomic, strong) NSString* splunkName;
@property (nonatomic, strong) NSString* userAgent;
@property (nonatomic, assign) NSUInteger totalCrashes;
@property (nonatomic, strong) NSString* appVersion;
@property (nonatomic, strong) NSString* tag;
@property (nonatomic, strong) NSString* osVersion;
@property (nonatomic, strong) NSString* phoneModel;
@property (nonatomic, strong) NSString* phoneBrand;
@property (nonatomic, assign) NSUInteger timestamp;
@property (nonatomic, assign) NSUInteger wifiOn;
@property (nonatomic, assign) NSUInteger mobileNetOn;
@property (nonatomic, assign) NSUInteger gpsOn;
@property (nonatomic, strong) ScreenProperties* deviceScreenProperties;
@property (nonatomic, strong) NSString* locale;
@property (nonatomic, strong) NSString* appsRunning;
@property (nonatomic, strong) NSString* rotation;
@property (nonatomic, strong) NSString* orientation;
@property (nonatomic, strong) NSString* flavor;
@property (nonatomic, assign) ConnectionType connection;
@property (nonatomic, strong) NSNumber* logMessagesCount;
@property (nonatomic, strong) NSNumber* logMessagesLevel;
@property (nonatomic, assign) BOOL enableMintLoggingCache;
@property (nonatomic, assign) BOOL enableLogging;
@property (nonatomic, strong) NSNumber* loggingLines;
@property (nonatomic, assign) BOOL isCrashReportingEnabled;
@property (nonatomic, strong) NSString* xamarinArchitecture;
@property (nonatomic, strong) NSString* xamarinVersion;

@end
