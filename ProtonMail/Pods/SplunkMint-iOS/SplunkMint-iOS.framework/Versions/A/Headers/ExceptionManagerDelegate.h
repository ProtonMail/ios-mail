//
//  ExceptionManagerDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/16/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintNotificationDelegate.h"

@protocol ExceptionManagerDelegate <NSObject>

@required
    - (void) startCrashManager;
    - (void) setNotificationDelegate: (id<MintNotificationDelegate>)notificationDelegate;

@end
