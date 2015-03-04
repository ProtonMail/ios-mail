//
//  EnumStringHelper.h
//  Splunk-iOS
//
//  Created by G.Tas on 2/26/14.
//  Copyright (c) 2014 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintEnums.h"

@interface EnumStringHelper : NSObject

+ (NSString*) deviceConnectionState: (DeviceConnectionState) aConnectionState;
+ (NSString*) dataType: (DataType) aDataType;
+ (NSString*) connectionType: (ConnectionType) aConnectionType;
+ (NSString*) mintResultStateType:(MintResultState)resultState;
+ (NSString*) logLevelString:(MintLogLevel)logLevel;
+ (NSNumber*) logLevelNumber:(MintLogLevel)logLevel;
+ (NSString*) logLevelCapitalFirstLetter:(MintLogLevel)logLevel;
+ (NSString*) transactionStatus:(TransactionStatus)transactionStatus;

@end
