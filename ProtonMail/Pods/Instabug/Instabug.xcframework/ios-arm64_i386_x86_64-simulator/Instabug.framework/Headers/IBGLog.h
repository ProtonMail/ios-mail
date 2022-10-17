/*
 File:       Instabug/IBGLog.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */

#import <Foundation/Foundation.h>

@interface IBGLog : NSObject

@property (class, atomic, assign) BOOL printsToConsole;

/**
 @brief Adds custom logs that will be sent with each report. Logs are added with the debug log level.
 
 @param log Message to be logged.
 */
+ (void)log:(NSString *)log;

/**
 @brief Adds custom logs with the verbose log level. Logs will be sent with each report.
 
 @param log Message to be logged.
 */
+ (void)logVerbose:(NSString *)log;

/**
 @brief Adds custom logs with the debug log level. Logs will be sent with each report.
 
 @param log Message to be logged.
 */
+ (void)logDebug:(NSString *)log;

/**
 @brief Adds custom logs with the info log level. Logs will be sent with each report.
 
 @param log Message to be logged.
 */
+ (void)logInfo:(NSString *)log;

/**
 @brief Adds custom logs with the warn log level. Logs will be sent with each report.
 
 @param log Message to be logged.
 */
+ (void)logWarn:(NSString *)log;

/**
 @brief Adds custom logs with the error log level. Logs will be sent with each report.
 
 @param log Message to be logged.
 */
+ (void)logError:(NSString *)log;

/**
 @brief Clear all Logs.
 
 @discussion Clear all Instabug logs, console logs, network logs and user steps.
 
 */
+ (void)clearAllLogs;

/**
 @brief Adds custom logs that will be sent with each report.
 
 @discussion Can be used in a similar fashion to NSLog. Logs are added with the debug log level.
 For usage in Swift, see `Instabug.ibgLog()`.
 
 @param format Format string.
 @param ... Optional varargs arguments.
 */
OBJC_EXTERN void InstabugLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/**
 @brief Adds custom logs with the verbose log level. Logs will be sent with each report.
 
 @discussion Can be used in a similar fashion to NSLog. For usage in Swift, see `Instabug.logVerbose()`.
 
 @param format Format string.
 @param ... Optional varargs arguments.
 */
OBJC_EXTERN void IBGLogVerbose(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/**
 @brief Adds custom logs with the debug log level. Logs will be sent with each report.
 
 @discussion Can be used in a similar fashion to NSLog. For usage in Swift, see `Instabug.logDebug()`.
 
 @param format Format string.
 @param ... Optional varargs arguments.
 */
OBJC_EXTERN void IBGLogDebug(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/**
 @brief Adds custom logs with the info log level. Logs will be sent with each report.
 
 @discussion Can be used in a similar fashion to NSLog. For usage in Swift, see `Instabug.logInfo()`.
 
 @param format Format string.
 @param ... Optional varargs arguments.
 */
OBJC_EXTERN void IBGLogInfo(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/**
 @brief Adds custom logs with the warn log level. Logs will be sent with each report.
 
 @discussion Can be used in a similar fashion to NSLog. For usage in Swift, see `Instabug.logWarn()`.
 
 @param format Format string.
 @param ... Optional varargs arguments.
 */
OBJC_EXTERN void IBGLogWarn(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);

/**
 @brief Adds custom logs with the error log level. Logs will be sent with each report.
 
 @discussion Can be used in a similar fashion to NSLog. For usage in Swift, see `Instabug.logError()`.
 
 @param format Format string.
 @param ... Optional varargs arguments.
 */
OBJC_EXTERN void IBGLogError(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2) ;

/**
 @brief Used to reroute all your NSLogs to Instabug to be able to automatically include them with reports.
 
 @discussion For details on how to reroute your NSLogs to Instabug, see https://docs.instabug.com/docs/ios-logging
 
 @param format Format string.
 @param args Arguments list.
 */
OBJC_EXTERN void IBGNSLog(NSString *format, va_list args);

/**
 @brief Used to reroute all your NSLogs to Instabug with their log level to be able to automatically include them with reports.
 
 @discussion For details on how to reroute your NSLogs to Instabug, see https://docs.instabug.com/docs/ios-logging
 
 @param format Format string.
 @param args Arguments list.
 @param logLevel log level.
 */
OBJC_EXTERN void IBGNSLogWithLevel(NSString *format, va_list args, IBGLogLevel logLevel);

@end
