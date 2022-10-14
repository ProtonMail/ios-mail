/*
 File:       Instabug/IBGAPM.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.
 
 Version:    11.3.0
 */

#import <Foundation/Foundation.h>
#import "IBGTypes.h"
#import "IBGNetworkTrace.h"

@class IBGExecutionTrace;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(APM)
/// Instabug APM
@interface IBGAPM : NSObject

/// Disables/Enables APM.
///
/// Defaults to true if APM is included in your Instabug account's plan.
@property (class, atomic, assign) BOOL enabled;

/// Disables/Enables App Launch tracking.
///
/// Defaults to true if APM is enabled. If APM is disabled, App Launch time will not be captured.
@property (class, atomic, assign) BOOL appLaunchEnabled DEPRECATED_MSG_ATTRIBUTE("Please use coldAppLaunchEnabled instead.");

/// Disables/Enables Cold App Launch tracking.
///
/// Defaults to true if APM is enabled. If APM is disabled, Cold App Launch time will not be captured.
@property (class, atomic, assign) BOOL coldAppLaunchEnabled;

/// Disables/Enables Hot App Launch tracking.
///
/// Defaults to true if APM is enabled. If APM is disabled, Hot App Launch time will not be captured.
@property (class, atomic, assign) BOOL hotAppLaunchEnabled;

/// Disables/Enables Automatic UI Traces.
///
/// Defaults to true if APM is enabled. If APM is disabled, no Automatic UI Traces will be captured.
///
/// When disabled, Automatic UI Hangs and Screen Loading are not captured, even if one of them is enabled.
@property (class, atomic, assign) BOOL autoUITraceEnabled;

/// Disables/Enables Automatic UI Hangs capturing.
///
/// Defaults to true if APM is enabled. If APM is disabled, no Automatic UI Hangs will be captured.
@property (class, atomic, assign) BOOL UIHangsEnabled;

/// Disables/Enables Automatic Screen Loading details capturing.
///
/// Defaults to true if APM is enabled. If APM is disabled, no Automatic Screen Loading details will be captured.
@property (class, atomic, assign) BOOL screenLoadingEnabled;

/// Creates and starts a new Execution Trace with the given name.
///
/// Creates and starts an Execution trace with the specified name, returns nil in case APM is disabled.
///
/// Multiple traces can start in parallel, including those with identical names.
///
/// If the Execution Trace is not ended, it will be discarded.
///
/// Execution Trace name cannot exceed 150 characters otherwise it's trimmed, leading and trailing whitespaces are also ignored.
///
/// This API is thread safe.
///
/// @param name Execution Trace name.
+ (IBGExecutionTrace *_Nullable)startExecutionTraceWithName:(NSString *)name;

/// Starts a Custom UI Trace with the given name.
///
/// Starts a Custom UI Trace with the specified name. If APM is disabled, Custom UI Traces are not captured.
///
/// Custom UI Traces cannot run in parallel, one must be ended before the other is started.
///
/// Custom UI Trace name cannot exceed 150 characters otherwise it's trimmed, leading and trailing whitespaces are also ignored.
///
/// This API should be called from the main thread.
///
/// @param name Custom UI Trace name.
+ (void)startUITraceWithName:(NSString *)name;

/// Ends the current running Custom UI Trace.
+ (void)endUITrace;


/// Ends the current view's Screen Loading occurence. Calling this API is optional, Screen Loadings will still be captured and ended automatically by the SDK;
/// this API just allows you to change when a Screen Loading actually ends.
/// @param viewController The view controller whose loading you want to mark as ended. This view has to still be visible on screen.
+ (void)endScreenLoadingForViewController:(UIViewController * _Nullable)viewController;

/// Ends the current session’s App Launch. Calling this API is optional, App Launches will still be captured and ended automatically by the SDK;
/// this API just allows you to change when an App Launch actually ends.
+ (void)endAppLaunch;

/// Sets the printed logs priority. Filter to one of the following levels.
///
/// Sets the printed logs priority. Filter to one of the following levels:
///
/// - IBGLogLevelNone disables all APM SDK console logs.
///
/// - IBGLogLevelError prints errors only, we use this level to let you know if something goes wrong.
///
/// - IBGLogLevelWarning displays warnings that will not necessarily lead to errors but should be addressed nonetheless.
///
/// - IBGLogLevelInfo (default) logs information that we think is useful without being too verbose.
///
/// - IBGLogLevelDebug use this in case you are debugging an issue. Not recommended for production use.
///
/// - IBGLogLevelVerbose use this only if IBGLogLevelDEBUG was not enough and you need more visibility
/// on what is going on under the hood.
///
/// Similar to the IBGLogLevelDebug level, this is not meant to be used on production environments.
///
/// Each log level will also include logs from all the levels above it. For instance,
/// IBGLogLevelInfo will include IBGLogLevelInfo logs as well as IBGLogLevelWarning
/// and IBGLogLevelError logs.
@property (class, atomic, assign) IBGLogLevel logLevel DEPRECATED_MSG_ATTRIBUTE("first deprecated in SDK 11.0.0. Use Instabug.sdkDebugLogsLevel instead");

/// Adds a handler to provide attributes to be attached with Network Traces.
///
/// This handler will be executed on a background dispatch queue.
///
/// @param urlPredicate If request's URL string matches the predicate, the handler will be executed. Pass nil to execute the handler for any request.
/// @param owner Handler will be removed if owner is deallocated. Pass nil to keep the handler indefinitely.
/// @param handler The handler which will be executed to provide Network Trace attributes, giving a Network Trace's URLRequest, URLResponse and response Data.
/// Return attributes to be attached to a Network Trace. Return nil if there isn't any attributes to be attacthed.
/// @return Handler's ID to be used for removing it later. If adding handler failed, nil will be returned.
+ (NSString* _Nullable)addNetworkTraceAttributesForURLMatchingPredicate:(NSPredicate* _Nullable)urlPredicate
                                                                  owner:(NSObject* _Nullable)owner
                                                           usingHandler:(NSDictionary<NSString *, NSString *> * _Nullable(^)(IBGNetworkTrace *networkTrace))handler;

/// Remove a previously registered attributes handler.
///
/// @param handlerID ID of the handler to be removed.
+ (void)removeNetworkTraceAttributesHandlerWithID:(NSString *)handlerID;

@end

NS_ASSUME_NONNULL_END
