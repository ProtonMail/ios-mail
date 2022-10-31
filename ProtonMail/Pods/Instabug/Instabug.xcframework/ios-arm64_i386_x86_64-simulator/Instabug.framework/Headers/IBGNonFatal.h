/*
 File:       Instabug/IBGNonFatal.h

 Contains:   API for using Instabug's SDK.

 Copyright:  (c) 2013-2022 by Instabug, Inc., all rights reserved.

 Version:    0.0.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, IBGNonFatalLevel) {
    IBGNonFatalLevelInfo,
    IBGNonFatalLevelWarning,
    IBGNonFatalLevelError,
    IBGNonFatalLevelCritical
} NS_SWIFT_NAME(NonFatalLevel);

NS_SWIFT_NAME(NonFatalBuilder)
@protocol IBGNonFatalBuilder <NSObject>

/// Report the non-fatal incident.
- (void)report;

@end

NS_SWIFT_NAME(NonFatalError)
@interface IBGNonFatalError : NSObject<IBGNonFatalBuilder>

/// The error to be reported.
@property (atomic, strong, nonnull) NSError* error;

/// The Grouping String that to be sent with the non-fatal error.
@property (atomic, strong, nonnull) NSString *groupingString;

/// The user attributes that will be attached to the report.
@property (atomic, strong, nonnull) NSDictionary<NSString *, NSString*> *userAttributes;

/// The error level.
@property (atomic, assign) IBGNonFatalLevel level;

- (instancetype)init __attribute__((unavailable("Init is not available, use +[IBGCrashReporting error:] instead.")));

@end

NS_SWIFT_NAME(NonFatalException)
@interface IBGNonFatalException : NSObject<IBGNonFatalBuilder>

/// The exception to be reported.
@property (atomic, strong, nonnull) NSException* exception;

/// The Grouping String that to be sent with the non-fatal exception.
@property (atomic, strong, nonnull) NSString *groupingString;

/// The user attributes that will be attached to the report.
@property (atomic, strong, nonnull) NSDictionary<NSString *, NSString*> *userAttributes;

/// The exception level.
@property (atomic, assign) IBGNonFatalLevel level;

- (instancetype)init __attribute__((unavailable("Init is not available, use +[IBGCrashReporting exception:] instead.")));

@end


NS_ASSUME_NONNULL_END
