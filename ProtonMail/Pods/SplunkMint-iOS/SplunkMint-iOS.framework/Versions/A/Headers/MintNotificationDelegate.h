//
//  SplunkNotificationDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/16/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UnhandledCrashReportArgs.h"
#import "LoggedRequestEventArgs.h"
#import "NetworkDataFixture.h"
#import "ScreenDataFixture.h"

/**
 *  A protocol to conform and be notified when certain actions occur.
 */
@protocol MintNotificationDelegate <NSObject>

@optional

    /**
     *  Notifies you when cached requests are sent to the server.
     *
     *  @param args A LoggedRequestEventArgs instance with information about the request.
     */
    - (void) loggedRequestHandled: (LoggedRequestEventArgs*)args;

    /**
     *  Notifies you when the network interceptor caches network data.
     *
     *  @param networkData The NetworkDataFixture instance.
     */
    - (void) networkDataLogged: (NetworkDataFixture*)networkData;

    /**
     * Notifies you when the screen changes.
     * @param screenData The ScreenDataFixture instance.
     */
    - (void) screenDataLogged: (ScreenDataFixture*)screenData;
@end
