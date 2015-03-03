//
//  DeviceInfoDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/14/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintAppEnvironment.h"
#import "MintPerformance.h"

@protocol DeviceInfoDelegate <NSObject>

@required
    - (void) appendBugSenseInfo;
    - (void) getDeviceConnectionInfo;
    - (void) getScreenInfo;
    - (MintAppEnvironment*) getAppEnvironment;
    - (MintPerformance*) getSplunkPerformance;
    - (BOOL) isLowMemDevice;

@end
