/*
 File:       Instabug/IBGNetworkLogger.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */

#import <Foundation/Foundation.h>
#import "IBGTypes.h"

NS_SWIFT_NAME(NetworkLogger)
@interface IBGNetworkLogger : NSObject

@property (class, atomic, assign) BOOL enabled;

/**
 @brief Enable logging for network requests and responses on a custom NSURLSessionConfiguration.
 
 @discussion Logging for network requests and responses may not work if you're using a custom `NSURLSession` object.
 If this is the case, call this method passing in your custom NSURLSessions's configuration to enable logging for it.
 
 @param URLSessionConfiguration The NSURLSessionConfiguration of your custom NSURLSession.
 */
+ (void)enableLoggingForURLSessionConfiguration:(NSURLSessionConfiguration *_Nonnull)URLSessionConfiguration;


/**
 @brief Use to obfuscate a request that's going to be included in network logs.
 
 @discussion Use this method if you want to make any modifications to requests before it is added to the network log.
 This won't be applied to already filtered requests
 
 Note that thsese changes doesn't affect the actual request.
 
 The provided block will be called for every request. You should do whatever processing you need to do on the request inside
 that block, then return a request to be included in network logs.
 
 This method usage overrides modifications made by `setNetworkLoggingURLObfuscationHandler:`.
 
 @param obfuscationHandler A block that takes a request and returns a new modified one to be logged..
 */
+ (void)setRequestObfuscationHandler:(nonnull NSURLRequest * _Nonnull (^)(NSURLRequest * _Nonnull request))obfuscationHandler;

/**
 @brief Use to obfuscate a request's response that's going to be included in network logs.
 
 @discussion Use this method if you want to make any modifications to a request's respone and its data before it's
 added to network logs.
 
 The provided block will be called for every response. You should do whatever processing you need to do on the response
 and data inside that block, then return response and data to be included in network logs. Changes you make to the
 response and its data only affect network logs, not the actual response.
 
 @param obfuscationHandler A block that takes the original response, its data and a return block as parameters. The
 return block should be called with the modified data and response.
 */
+ (void)setResponseObfuscationHandler:(void (^_Nonnull)(NSData * _Nullable responseData, NSURLResponse * _Nonnull response, NetworkObfuscationCompletionBlock _Nonnull returnBlock))obfuscationHandler;

/**
 @brief Use to get callbacks about progress of sending body content of a particular request when networking logging is
 enabled.
 
 @discussion The provided block will get periodical callbacks about the progress of sending the body content of a request.
 
 @param URL URL which will be attached with requestProgressHandler.
 @param requestProgressHandler A block that will be called for the requestURL when SDK intercept that request.
 
 */
+ (void)setProgressHandlerForRequestURL:(nonnull NSURL *)URL
                        progressHandler:(nonnull void (^)(NSURLSessionTask * _Nonnull task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))requestProgressHandler;

/**
 @brief Used to ask whether your app is prepared to handle a particular authentication challenge. Can be called on any thread.
 
 @discussion Set this block if your app implements SSL pinning and you have network logging enabled.
 
 @param protectionSpaceHandler A block that takes the protection space for the authentication challenge and should return
 true or false.
 */
+ (void)setCanAuthenticateAgainstProtectionSpaceHandler:(BOOL(^_Nonnull)(NSURLProtectionSpace * _Nonnull protectionSpace))protectionSpaceHandler DEPRECATED_MSG_ATTRIBUTE("'setCanAuthenticateAgainstProtectionSpaceHandler:' is deprecated: first deprecated in SDK 10.5.0 - Remove setCanAuthenticateAgainstProtectionSpaceHandler: to use your implementation of -[NSURLSessionTaskDelegate URLSession:task:didReceiveChallenge:completionHandler:].");


/**
 @brief Used to process an authentication challenge and return an NSURLCredential object.
 
 @discussion Set this block if your app implements SSL pinning and you have network logging enabled.
 
 @param reciveChallengeHandler A block that takes the authentication challenge and returns NSURLCredential.
 */
+ (void)setDidReceiveAuthenticationChallengeHandler:(NSURLCredential* _Nullable (^_Nonnull)(NSURLAuthenticationChallenge * _Nonnull challenge))reciveChallengeHandler DEPRECATED_MSG_ATTRIBUTE("'setDidReceiveAuthenticationChallengeHandler:' is deprecated: first deprecated in SDK 10.5.0 - Remove setDidReceiveAuthenticationChallengeHandler: to use your implementation of -[NSURLSessionTaskDelegate URLSession:task:didReceiveChallenge:completionHandler:].");


/**
 @brief Specify NSPredicates to be used to omit certain network requests from being logged based on their request or
 response objects.
 
 @discussion `requestFilterPredicate` will be matched against an `NSURLRequest`. It can be used to filter out requests
 to a specific domain for example.
 
 `responseFilterPredicate` will be matched against an `NSHTTPURLResponse`. It can be used to filter out responses that
 match specific status codes.
 
 If both predicates are specified, `requestFilterPredicate` is evaluated first, if it matches, the request is omitted
 from logging without evaluating `responseFilterPredicate`.
 
 @param requestFilterPredicate An NSPredicate to match against an NSURLRequest. Matching requests will be omitted.
 @param responseFilterPredicate An NSPredicate to match against an NSHTTPURLResponse. Matching responses will be omitted.
 */
+ (void)setNetworkLoggingRequestFilterPredicate:(nullable NSPredicate *)requestFilterPredicate responseFilterPredicate:(nullable NSPredicate *)responseFilterPredicate;

/**
 @brief A block that is used when an HTTP request is attempting to perform a redirection to a different URL
 
 @discussion Set this block if your app has special logic for http redirection and you have network logging enabled.
 
 @param redirectionHandler A block that takes the session, task, redirection response and redirection request and should return the new request to be made for the redirection if any.
 */
+ (void)setTaskWillPerformHTTPRedirectionBlock:(nullable NSURLRequest * _Nullable (^)(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLResponse * _Nonnull response, NSURLRequest * _Nonnull request))redirectionHandler;

/**

@brief Use to add gRPC network log.

@param url URL should be constructed from `host_ip`, `host_port`, `service_name` example grpc://{host_ip}:{host_port}/{service_name}
@param requestBody request body as string.
@param requestBodySize request body size.
@param response response body as string.
@param responseCode status code in case of success or server side error only.
@param requestHeaders request metadata.
@param responseHeaders response metadata.
@param contentType from response content-type.
@param startTime when the request started.
@param errorDomain domain of the client side error.
@param errorCode code of the error in case of client side error.
@param duration duration of the request.
@param gRPCMethod gRPC method.
@param serverErrorMessage server error message in case of server side error
 */
+ (void)addGrpcNetworkLogWithUrl:(NSString *_Nullable)url
                     requestBody:(NSString *_Nullable)requestBody
                 requestBodySize:(int64_t)requestBodySize
                    responseBody:(NSString *_Nullable)response
                responseBodySize:(int64_t)responseBodySize
                    responseCode:(int32_t)responseCode
                  requestHeaders:(NSDictionary *_Nullable)requestHeaders
                 responseHeaders:(NSDictionary *_Nullable)responseHeaders
                     contentType:(NSString *_Nullable)contentType
                       startTime:(int64_t)startTime
                     errorDomain:(NSString *_Nullable)errorDomain
                       errorCode:(int32_t)errorCode
                        duration:(int64_t)duration
                      gRPCMethod:(NSString * _Nullable)gRPCMethod
                     serverErrorMessage:(NSString *_Nullable)serverErrorMessage;
@end
