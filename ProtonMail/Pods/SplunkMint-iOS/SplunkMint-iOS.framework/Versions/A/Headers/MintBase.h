//
//  SplunkEnterpriseBase.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/23/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugSense.h"
#import "MintEnums.h"

@interface MintBase : BugSense

//@property (nonatomic, strong) NSString* url;
//@property (nonatomic, strong) NSString* analyticsUrl;
//@property (nonatomic, strong) NSString* debugTestUrl;

/**
 *  Use this method to disable network monitoring before initAndStartSession
 */
- (void) disableNetworkMonitoring;

/**
 *  Gets the developer's remote settings as key-value pairs.
 *
 *  @return A dictionary of key-value pairs.
 */
- (NSDictionary*) getDevSettings;

/**
 *  Indicates whether to enable logging. When YES, NSLog console messages are cached and sent with the exception.
 *
 *  @param enable Indicates whether to enable logging. 
 */
- (void) enableMintLoggingCache:(BOOL)enable;

/**
 *  Set if device logs are attached to the crash.
 *
 *  @param enable YES to enable logging.
 */
- (void) enableLogging:(BOOL)enable;

/**
 *  Sets the maximum number of lines to cache from the console log.
 *
 *  @param lines The number of lines.
 */
- (void) setLogging:(NSInteger)linesCount;

/**
 *  Starts a transaction with a unique name.
 *
 *  @param transactionName The unique transaction name.
 *  @param resultBlock     The block to invoke with additional information when complete.
 */
- (void) transactionStart:(NSString*)transactionName andResultBlock:(TransactionStartResultBlock)resultBlock;

/**
 *  Stops a transaction.
 *
 *  @param transactionName The name of the transaction.
 *  @param resultBlock     The block to invoke with additional information when complete.
 */
- (void) transactionStop:(NSString*)transactionName andResultBlock:(TransactionStopResultBlock)resultBlock;

/**
 *  Cancels a transaction.
 *
 *  @param transactionName The name of the transaction.
 *  @param aReason         The reason for cancelling the transaction.
 *  @param resultBlock     The block to invoke with additional information when complete.
 */
- (void) transactionCancel:(NSString*)transactionName reason:(NSString*)aReason andResultBlock:(TransactionStopResultBlock)resultBlock;

/**
 *  Adds a URL to the network monitoring blacklist.
 *
 *  @param url The URL to ignore. This can be a partial URL.
 */
- (void) addURLToBlackList:(NSString*)url;

/**
 *  The URLs blacklisted from network interception.
 *
 *  @return NSMutableArray of NSString
 */
- (NSMutableArray*) blacklistUrls;

/**
 *  Logs an event with a log level, sends the log entry to the console window, and caches a request to send to the server.
 *
 *  @param name      The name of the event (up to 256 characters).
 *  @param logLevel  The MintLogLevel enumeration value for the log level.
 *  @param completed The block to invoke with additional information when complete.
 */
- (void) logEventAsyncWithName:(NSString*)name logLevel:(MintLogLevel)logLevel andCompletionBlock:(LogResultBlock)completed;

/**
 *  Helper Xamarin method for logging exceptions as unhandled.
 *
 *  @param exception The NSException thrown.
 *
 */
- (void) xamarinLogException:(NSException*)exception andCompletionBlock:(LogResultBlock)completed;

/**
 *  Helper Xamarin method for logging exceptions as unhandled.
 *
 *  @param exception The NSException thrown.
 *
 */
- (MintLogResult*) xamarinLogException:(NSException*)exception;

/**
 *  Get an ExceptionDataFixture from a NSException
 *
 *  @param exception The NSException
 *
 *  @return The ExceptionDataFixture JSON string model.
 */
- (NSString*) exceptionFixtureFrom:(NSException*)exception;

@end
