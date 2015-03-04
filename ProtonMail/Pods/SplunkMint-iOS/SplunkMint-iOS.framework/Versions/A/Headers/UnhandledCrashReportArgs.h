//
//  UnhandledCrashReportArgs.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/16/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UnhandledCrashReportArgs : NSObject

@property (nonatomic, strong) NSString* clientJsonRequest;
@property (nonatomic, strong) NSString* crashReport;
@property (nonatomic, assign) BOOL handledSuccessfully;

@end
