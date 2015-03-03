//
//  SplunkAppEnvironment.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/6/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface MintAppEnvironment : SPLJSONModel

- (BOOL) isEqualToSplunkAppEnvironment: (MintAppEnvironment*)aSplunkAppEnvironment;

@property (nonatomic, strong) NSString* uid;
@property (nonatomic, strong) NSString* phoneModel;
@property (nonatomic, strong) NSString* manufacturer;
@property (nonatomic, strong) NSString* internalVersion;
@property (nonatomic, strong) NSString* appVersion;
@property (nonatomic, strong) NSString* brand;
@property (nonatomic, strong) NSString* appName;
@property (nonatomic, strong) NSString* osVersion;
@property (nonatomic, assign) NSInteger wifiOn;
@property (nonatomic, assign) NSNumber* gpsOn;
@property (nonatomic, strong) NSString* cellularData;
@property (nonatomic, strong) NSString* carrier;
@property (nonatomic, strong) NSNumber* screenWidth;
@property (nonatomic, strong) NSNumber* screenHeight;
@property (nonatomic, strong) NSString* screenOrientation;
@property (nonatomic, strong) NSString* screenDpi;
@property (nonatomic, assign) BOOL rooted;
@property (nonatomic, strong) NSString* locale;
@property (nonatomic, strong) NSString* geoRegion;
@property (nonatomic, strong) NSString* cpuModel;
@property (nonatomic, strong) NSString* cpuBitness;
@property (nonatomic, strong) NSString* build_uuid;
@property (nonatomic, strong) NSString* image_base_address;
@property (nonatomic, strong) NSString* architecture;
@property (nonatomic, strong) NSMutableDictionary* registers;
@property (nonatomic, strong) NSString* execName;
@property (nonatomic, strong) NSString* imageSize;
@property (nonatomic, strong) NSMutableDictionary* log_data;

@end
