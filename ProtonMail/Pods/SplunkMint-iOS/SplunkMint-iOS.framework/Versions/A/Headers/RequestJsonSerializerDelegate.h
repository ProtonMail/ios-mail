//
//  IRequestJsonSerializer.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/13/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintEnums.h"
#import "LimitedExtraDataList.h"
#import "MintAppEnvironment.h"
#import "MintPerformance.h"
#import "SerializeResult.h"
#import "MintExceptionRequest.h"
#import "TrStart.h"
#import "TrStop.h"
#import "NetworkDataFixture.h"
#import "ScreenDataFixture.h"

@protocol RequestJsonSerializerDelegate <NSObject>

@required
    - (SerializeResult*) serializeEventToJsonForPingWithAppEnvironment: (MintAppEnvironment*)anAppEnvironment;
    - (SerializeResult*) serializeEventToJsonForGnipWithAppEnvironment: (MintAppEnvironment*)anAppEnvironment;
    - (SerializeResult*) serializeEventToJsonForEventTag: (NSString*)eventTag appEnvironment: (MintAppEnvironment*)anAppEnvironment;

    - (SerializeResult*) serializeEventToJsonForEventTag: (NSString*)eventTag limitedExtraDataList:(LimitedExtraDataList *)extraDataList appEnvironment: (MintAppEnvironment*)anAppEnvironment;

    - (SerializeResult*) serializeEventToJsonForName: (NSString*)name withLogLevel:(MintLogLevel)logLevel andAppEnvironment:(MintAppEnvironment*)anAppEnvironment;
    - (SerializeResult*) serializeEventToJsonForName:(NSString *)name withLogLevel:(MintLogLevel)logLevel limitedExtraDataList:(LimitedExtraDataList *)extraDataList andAppEnvironment:(MintAppEnvironment *)anAppEnvironment;

    - (SerializeResult*) serializeLogToJsonWithName:(NSString *)name logLevel:(MintLogLevel)logLevel andAppEnvironment:(MintAppEnvironment *)anAppEnvironment;
    - (SerializeResult*) serializeCrashToJson: (id)exception appEnvironment: (MintAppEnvironment*)anAppEnvironment performance: (MintPerformance*)aPerformance handled: (BOOL)isHandled crashExtraDataList: (LimitedExtraDataList*) extraData;
    - (NSString*) decodeEncodedCrashJson: (NSString*)encodedJson;
    - (NSString*) getErrorHash: (NSString*)jsonRequest;
    - (SerializeResult*) serializeCrashToJsonWithExceptionRequest:(MintExceptionRequest *)exceptionRequest andAppEnvironment: (MintAppEnvironment*)appEnvironment;
    - (SerializeResult*) serializeTransactionStart: (TrStart*)trStart;
    - (SerializeResult*) serializeTransactionStop: (TrStop*)trStop;
    - (SerializeResult*) serializeNetworkMonitor:(NetworkDataFixture*)networkDataFixture;
    - (SerializeResult*) serializeScreenMonitor:(ScreenDataFixture*)screenDataFixture;

@end
