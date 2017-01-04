// AFNetworkActivityLogger.h
//
// Copyright (c) 2015 AFNetworking (http://afnetworking.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "AFNetworkActivityLoggerProtocol.h"

/**
 `AFNetworkActivityLogger` logs requests and responses made by AFNetworking, with an adjustable level of detail.
 
 Applications should enable the shared instance of `AFNetworkActivityLogger` in `AppDelegate -application:didFinishLaunchingWithOptions:`:

        [[AFNetworkActivityLogger sharedLogger] startLogging];
 
 `AFNetworkActivityLogger` listens for `AFNetworkingOperationDidStartNotification` and `AFNetworkingOperationDidFinishNotification` notifications, which are posted by AFNetworking as request operations are started and finish. For further customization of logging output, users are encouraged to implement desired functionality by listening for these notifications.
 */
@interface AFNetworkActivityLogger : NSObject

/**
 The set of loggers current managed by the shared activity logger. By default, this includes one `AFNetworkActivityConsoleLogger`
 */
@property (nonatomic, strong, readonly) NSSet <AFNetworkActivityLoggerProtocol> *loggers;

/**
 Returns the shared logger instance.
 */
+ (instancetype)sharedLogger;

/**
 Start logging requests and responses to all managed loggers.
 */
- (void)startLogging;

/**
 Stop logging requests and responses to all managed loggers.
 */
- (void)stopLogging;


/**
 Adds the given logger to be managed to the `loggers` set.
 */
- (void)addLogger:(id <AFNetworkActivityLoggerProtocol>)logger;

/**
 Removes the given logger from the `loggers` set.
 */
- (void)removeLogger:(id <AFNetworkActivityLoggerProtocol>)logger;

@end
