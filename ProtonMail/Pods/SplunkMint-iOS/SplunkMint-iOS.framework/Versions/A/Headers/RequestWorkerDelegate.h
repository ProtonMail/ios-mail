//
//  RequestWorkerDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/23/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintResponseResult.h"
#import "LoggedRequestEventArgs.h"
#import "NetworkDataFixture.h"

@protocol RequestWorkerDelegate <NSObject>

@required
    - (void) loggedRequestHandledWithEventArgs: (LoggedRequestEventArgs*)args;
    - (void) pingEventCompletedWithResponse: (MintResponseResult*)splunkResponseResult;
    - (void) networkDataLogged: (NetworkDataFixture*)networkData;

@end
