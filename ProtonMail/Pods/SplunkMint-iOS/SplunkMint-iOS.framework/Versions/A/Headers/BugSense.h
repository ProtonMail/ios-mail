//
//  BugSense.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/22/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugSenseBase.h"
#import "ServiceClientDelegate.h"
#import "ContentTypeDelegate.h"

#define BUGSENSE_LOG(exception, extradata) [[BugSense sharedInstance] logExceptionAsync:exception limitedCrashExtraDataList:extradata completionBlock:nil];

@interface BugSense : BugSenseBase

@property (nonatomic, weak) id<MintNotificationDelegate> notificationDelegate;

+ (BugSense*) sharedInstance;

- (id) initWithRequestJsonSerializer: (id<RequestJsonSerializerDelegate>)jsonSerializer contentTypeResolver: (id<ContentTypeDelegate>)contentTypeResolver requestWorker:(id<RequestWorkerFacadeDelegate>)requestWorker andServiceRepository:(id<ServiceClientDelegate>)serviceRepository;

//- (void) initAndStartSessionWithCrashManager:(CrashManagerType)crashManagerType andApiKey:(NSString *)apiKey;

@end
