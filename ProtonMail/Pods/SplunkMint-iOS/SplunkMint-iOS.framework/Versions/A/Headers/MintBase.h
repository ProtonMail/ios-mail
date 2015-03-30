//
//  MintBase.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LimitedExtraDataList.h"
#import "TypeBlocks.h"
#import "RequestWorkerFacadeDelegate.h"
#import "MintNotificationDelegate.h"


#import "MintEnums.h"
#import "ContentTypeDelegate.h"
#import "ServiceClientDelegate.h"

/**
 *  The MintBase base class.
 */
@interface MintBase : NSObject<RequestWorkerDelegate>

/**
 *  Used internally for derived classes.
 */
@property (nonatomic, strong) id<RequestWorkerFacadeDelegate> splunkRequestWorker;

/**
 *  Indicates whether the plugin is initialized and operating properly.
 */
@property (nonatomic, assign) BOOL isInitialized;

/**
 *  Indicates whether there is an active session. You can close the current session and start a new one as needed.
 */
@property (nonatomic, assign) BOOL isSessionActive;

/**
 *  Sets a user identifier such as a random ID, an email address, or a username for the current user.
 */
@property (nonatomic, strong) NSString* userIdentifier;

/**
 * A value that is set internally and used only by the SDK plugin. 
 * Set this value to NO when you don't want requests to be logged and sent to the server. The default value is YES.
 */
@property (nonatomic, assign) BOOL handleWhileDebugging;

///**
// *  Deprecated for Splunk MINT. This value is used only by the BugSense plugin.
// */
//@property (nonatomic, assign) BOOL useProxy;

/**
 *  A LimitedExtraDataList instance where you can set global extra data (ExtraData instances) and attach them to the handled exception requests.
 */
@property (nonatomic, strong) LimitedExtraDataList* extraDataList;

/**
 *  Sends messages to the delegate and notifies you when any actions are taken by the plugin.
 *  This value is not set by the developer.
 */
@property (nonatomic, weak) id<MintNotificationDelegate> notificationDelegate;


///**
// *  Deprecated for Splunk MINT. This method is used only by the BugSense plugin.
// */
//@property (nonatomic, strong) NSNumber* logMessagesCount;
//
///**
// *  Deprecated for Splunk MINT. This method is used only by the BugSense plugin.
// */
//@property (nonatomic, strong) NSNumber* logMessagesLevel;

/**
 *  This method is for internal SDK initialization and should never used by the developer.
 *
 *  @param requestWorker A RequestWorkerFacadeDelegate instance.
 *
 *  @return A MintBase instance.
 */
- (id) initWithRequestWorker: (id<RequestWorkerFacadeDelegate>)requestWorker;

- (void) disableCrashReporter;

/**
 *  Sends all cached requests to the server.
 *
 *  @param resultBlock A block that you get from a MintResponseResult instance to examine related information.
 */
- (void) flushAsyncWithBlock: (ResponseResultBlock)resultBlock;

/**
 *  Initializes the plugin and starts a session.
 *
 *  @param apiKey Your Splunk MINT API key.
 */
- (void) initAndStartSession: (NSString*)apiKey;

///**
// *  Deprecated for Splunk MINT. This method is used only by the BugSense plugin.
// *
// *  @param success A block that is invoked when the request finishes successfully, providing the last crash ID of the server.
// *  @param failure A failure block that is invoked when something goes wrong with the request.
// */
//- (void) getLastCrashIdWithBlock: (void (^)(NSNumber* lastCrashId))success failure: (FailureBlock)failure;
//
///**
// *  Deprecated for Splunk MINT. This method is used only by the BugSense plugin.
// *
// *  @param success A block that is invoked when the request finishes with successfully, providing the total number of crashes of the app since the last reset.
// *  @param failure A failure block that is invoked when something goes wrong with the request.
// */
//- (void) getTotalCrashesNumWithBlock: (void (^)(NSNumber* totalCrashes))success failure: (FailureBlock)failure;
//
///**
// *  Deprecated for Splunk MINT. This method is used only by the BugSense plugin.
// *
// *  @param success A Boolean value indicating whether the request was successful. 
// *  @param failure A failure block that is invoked when something goes wrong with the request.
// */
//- (void) clearTotalCrashesNumWithBlock:(void (^)(BOOL))success failure:(FailureBlock)failure;

/**
 *  Adds an ExtraData instance to the global extra data list.
 *
 *  @param extraData The ExtraData instance.
 */
- (void) addExtraData:(ExtraData*)extraData;

/**
 *  Appends a LimitedExtraData instance list to the global extra data list.
 *
 *  @param limitedExtraDataList The LimitedExtraDataList instance.
 */
- (void) addExtraDataList:(LimitedExtraDataList*)limitedExtraDataList;

/**
 *  Removes an ExtraData instance from the global extra data list.
 *
 *  @param key The key of the ExtraData instance.
 *
 *  @return A Boolean that indicates whether the instance was removed successfully. If NO, an ExtraData instance with the specified key does not exist. 
 */
- (BOOL) removeExtraDataWithKey: (NSString*)key;

/**
 *  Clears the LimitedExtraDataList instances from the global extra data list.
 */
- (void) clearExtraData;

/**
 *  Adds a breadcrumb description to the global breadcrumb list.
 *
 *  @param crumb The breadcrumb description.
 */
- (void) leaveBreadcrumb: (NSString*)crumb;

/**
 *  Clears the global breadcrumb list.
 */
- (void) clearBreadcrumbs;

//- (void) lastActionBeforeTerminate: (LastActionBlock)lastActionBlock;

/**
 *  Logs an event request with a tag description.
 *
 *  @param tag       The tag description.
 *  @param completed A block that is invoked upon completion with additional information.
 */
- (void) logEventAsyncWithTag: (NSString*)tag completionBlock: (LogResultBlock)completed;
- (void) logEventAsyncWithTag: (NSString*)tag extraDataKey: (NSString*)key extraDataValue: (NSString*)value completionBlock: (LogResultBlock)completed;
- (void) logEventAsyncWithTag: (NSString*)tag limitedExtraDataList: (LimitedExtraDataList*)extraDataList completionBlock: (LogResultBlock)completed;
/**
 *  Starts a new session. If a previous session was initialized less than one minute earlier, this call is ignored. 
 *
 *  @param completed A block that is invoked upon completion with additional information.
 */
- (void) startSessionAsyncWithCompletionBlock: (ResponseResultBlock)completed;

/**
 *  Closes a session. All requests and crash reporting will continue to work properly, but the session is no longer logically active.
 *
 *  @param completed A block that is invoked upon completion with additional information.
 */
- (void) closeSessionAsyncWithCompletionBlock: (LogResultBlock)completed;

/**
 *  Logs a handled exception in your try/catch block.
 *
 *  @param exception The NSException instance.
 *  @param key       The key for the additional extra data to attach to the request.
 *  @param value     The value of the additional extra data to attach to the request.
 *  @param completed A block that is invoked upon completion with additional information.
 */
- (void) logExceptionAsync: (NSException*)exception extraDataKey: (NSString*)key extraDataValue: (NSString*)value completionBlock: (LogResultBlock)completed;

/**
 *  Logs a handled exception in your try/catch block.
 *
 *  @param exception              The NSException instance.
 *  @param limitedExtraDataList   A LimitedExtraDataList instance to attach to the request.
 *  @param completed              A block that is invoked upon completion with additional information.
 */
- (void) logExceptionAsync: (NSException*)exception limitedExtraDataList: (LimitedExtraDataList*)extraDataList completionBlock: (LogResultBlock)completed;


- (id) initWithRequestJsonSerializer: (id<RequestJsonSerializerDelegate>)jsonSerializer contentTypeResolver: (id<ContentTypeDelegate>)contentTypeResolver requestWorker:(id<RequestWorkerFacadeDelegate>)requestWorker andServiceRepository:(id<ServiceClientDelegate>)serviceRepository;


//@property (nonatomic, strong) NSString* url;
//@property (nonatomic, strong) NSString* analyticsUrl;
//@property (nonatomic, strong) NSString* debugTestUrl;

/**
 *  Disables network monitoring. Call this method before calling initAndStartSession.
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
 *  Indicates whether to attach device logs to the crash.
 *
 *  @param enable YES to attach device logs.
 */
- (void) enableLogging:(BOOL)enable;

/**
 *  Indicates whether to only send data over a WiFi connection.
 *  @param enable YES to send data only over WiFi.
 */
- (void) enableFlushOnlyOverWiFi:(BOOL)enable;

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
- (void) transactionStart:(NSString*)transactionName extraDataKey: (NSString*)key extraDataValue: (NSString*)value andResultBlock:(TransactionStartResultBlock)resultBlock;
- (void) transactionStart:(NSString*)transactionName limitedExtraDataList: (LimitedExtraDataList*)extraDataList andResultBlock:(TransactionStartResultBlock)resultBlock;

/**
 *  Stops a transaction.
 *
 *  @param transactionName The name of the transaction.
 *  @param resultBlock     The block to invoke with additional information when complete.
 */
- (void) transactionStop:(NSString*)transactionName andResultBlock:(TransactionStopResultBlock)resultBlock;
- (void) transactionStop:(NSString*)transactionName extraDataKey: (NSString*)key extraDataValue: (NSString*)value andResultBlock:(TransactionStopResultBlock)resultBlock;
- (void) transactionStop:(NSString*)transactionName limitedExtraDataList: (LimitedExtraDataList*)extraDataList andResultBlock:(TransactionStopResultBlock)resultBlock;

/**
 *  Cancels a transaction.
 *
 *  @param transactionName The name of the transaction.
 *  @param aReason         The reason for cancelling the transaction.
 *  @param resultBlock     The block to invoke with additional information when complete.
 */

- (void) transactionCancel:(NSString*)transactionName reason:(NSString*)aReason andResultBlock:(TransactionStopResultBlock)resultBlock;
- (void) transactionCancel:(NSString*)transactionName extraDataKey: (NSString*)key extraDataValue: (NSString*)value reason:(NSString*)aReason andResultBlock:(TransactionStopResultBlock)resultBlock;
- (void) transactionCancel:(NSString*)transactionName limitedExtraDataList: (LimitedExtraDataList*)extraDataList reason:(NSString*)aReason andResultBlock:(TransactionStopResultBlock)resultBlock;


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

- (void) logEventAsyncWithName:(NSString *)name logLevel:(MintLogLevel)logLevel extraDataKey: (NSString*)key extraDataValue: (NSString*)value andCompletionBlock:(LogResultBlock)completed;

- (void) logEventAsyncWithName:(NSString*)name logLevel:(MintLogLevel)logLevel limitedExtraDataList: (LimitedExtraDataList*)extraDataList andCompletionBlock:(LogResultBlock)completed;


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
 *  Gets an ExceptionDataFixture from an NSException.
 *
 *  @param exception The NSException.
 *
 *  @return The ExceptionDataFixture JSON string model.
 */
- (NSString*) exceptionFixtureFrom:(NSException*)exception;

/**
 *Sets the GPS coordinates
 */

//- (void)setGPSCoordinatesWithLatitude:(double)latitude longitude:(double)longitude accuracy:(double)accuracy;


- (void)setUserOptOut:(BOOL)setUserOptOut;

/**
 * @returns UUID
 */
- (NSString*)getMintUUID;

/**
 *@returns session ID
 */
- (NSString*)getSessionID;

/**
 *Log current view with extraData
 *@param viewName name of the current view
 */
- (void)logViewWithCurrentViewName:(NSString*)currentViewName limitedExtraDataList:(LimitedExtraDataList*)extraDataList;

@end
