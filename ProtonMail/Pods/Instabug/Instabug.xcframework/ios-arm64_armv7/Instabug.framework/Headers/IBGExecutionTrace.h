/*
 File:       Instabug/IBGExecutionTrace.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.
 
 Version:    11.3.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ExecutionTrace)
@interface IBGExecutionTrace : NSObject

/// Ends this instance of Execution Trace.
- (void)end;

/// Sets custom attributes for this instance of ExecutionTrace.
///
/// Setting an attribute value to nil will remove its corresponding key if it already exists.
///
/// Attribute key name cannot exceed 30 characters. Leading and trailing whitespaces are also ignored. Does not accept empty strings or nil.
///
/// Attribute value name cannot exceed 60 characters, leading and trailing whitespaces are also ignored. Does not accept empty strings.
///
/// If the execution trace is ended, attributes will not be added and existing ones will not be updated.
///
/// @param key Execution Trace attribute key.
/// @param value  Execution Trace attribute value.
- (void)setAttributeWithKey:(NSString *)key value:(NSString *_Nullable)value;

- (instancetype)init __attribute__((unavailable("Init not available, use +[IBGAPM startExecutionTraceWithName:] instead.")));

@end

NS_ASSUME_NONNULL_END
