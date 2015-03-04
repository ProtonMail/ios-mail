//
//  RemoteSettingsData.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/23/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "SPLJSONModel.h"

@interface RemoteSettingsData : SPLJSONModel

@property (nonatomic, strong) NSNumber* logLevel;
@property (nonatomic, strong) NSNumber* eventLevel;
@property (nonatomic, assign) BOOL netMonitoring;
@property (nonatomic, strong) NSString* hashCode;
@property (nonatomic, strong) NSMutableDictionary* devSettings;

+ (RemoteSettingsData*) sharedInstance;

@end
