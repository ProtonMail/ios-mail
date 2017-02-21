// AFNetworkActivityLoggerProtocol.h
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


///----------------
/// @name Constants
///----------------

/**
 ## Logging Levels

 The following constants specify the available logging levels for `AFNetworkActivityLogger`:

 enum {
 AFLoggerLevelOff,
 AFLoggerLevelDebug,
 AFLoggerLevelInfo,
 AFLoggerLevelWarn,
 AFLoggerLevelError,
 AFLoggerLevelFatal = AFLoggerLevelOff,
 }

 `AFLoggerLevelOff`
 Do not log requests or responses.

 `AFLoggerLevelDebug`
 Logs HTTP method, URL, header fields, & request body for requests, and status code, URL, header fields, response string, & elapsed time for responses.

 `AFLoggerLevelInfo`
 Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses.

 `AFLoggerLevelError`
 Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses, but only for failed requests.
 */

typedef NS_ENUM(NSUInteger, AFHTTPRequestLoggerLevel) {
    AFLoggerLevelOff,
    AFLoggerLevelDebug,
    AFLoggerLevelInfo,
    AFLoggerLevelError
};


/**
 `AFNetworkActivityLoggerProtocol` declares the interface to log requests and responses made by AFNetworking, with an adjustable level of detail.

 Objects that conform to `AFNetworkActivityLoggerProtocol` should be added to the shared instance of `AFNetworkActivityLogger`. Applications should then enable the shared instance of `AFNetworkActivityLogger` in `AppDelegate -application:didFinishLaunchingWithOptions:`:

 [[AFNetworkActivityLogger sharedLogger] startLogging];
 
 For further customization of logging output, users can create additional classes that conform to this protocol, and add them to the shared logger.
 */
@protocol AFNetworkActivityLoggerProtocol <NSObject>

/**
 Omit requests which match the specified predicate, if provided. `nil` by default.

 @discussion Each notification has an associated `NSURLRequest`. To filter out request and response logging, such as all network activity made to a particular domain, this predicate can be set to match against the appropriate URL string pattern.
 */
@property (nonatomic, strong) NSPredicate *filterPredicate;

/**
 The level of logging detail. See "Logging Levels" for possible values. `AFLoggerLevelInfo` by default.
 */
@property (nonatomic, assign) AFHTTPRequestLoggerLevel level;

- (void)URLSessionTaskDidStart:(NSURLSessionTask *)task;
- (void)URLSessionTaskDidFinish:(NSURLSessionTask *)task withResponseObject:(id)responseObject inElapsedTime:(NSTimeInterval)elapsedTime withError:(NSError *)error;

@end

