// AFOAuth2Manager.h
//
// Copyright (c) 2012-2014 AFNetworking (http://afnetworking.com)
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

#import "AFHTTPRequestOperationManager.h"

@class AFOAuthCredential;

/**
 `AFOAuth2Manager` encapsulates common patterns to authenticate against a resource server conforming to the behavior outlined in the OAuth 2.0 specification.

 In your application, it is recommended that you use `AFOAuth2Manager` exclusively to get an authorization token, which is then passed to another `AFHTTPClient` subclass.

 @see RFC 6749 The OAuth 2.0 Authorization Framework: http://tools.ietf.org/html/rfc6749
 */
@interface AFOAuth2Manager : AFHTTPRequestOperationManager

///------------------------------------------
/// @name Accessing OAuth 2 Client Properties
///------------------------------------------

/**
 The service provider identifier used to store and retrieve OAuth credentials by `AFOAuthCredential`. Equivalent to the hostname of the client `baseURL`.
 */
@property (readonly, nonatomic, copy) NSString *serviceProviderIdentifier;

/**
 The client identifier issued by the authorization server, uniquely representing the registration information provided by the client.
 */
@property (readonly, nonatomic, copy) NSString *clientID;

///------------------------------------------------
/// @name Creating and Initializing OAuth 2 Clients
///------------------------------------------------

/**
 Creates and initializes an `AFOAuth2Manager` object with the specified base URL, client identifier, and secret.

 @param url The base URL for the HTTP client. This argument must not be `nil`.
 @param clientID The client identifier issued by the authorization server, uniquely representing the registration information provided by the client.
 @param secret The client secret.

 @return The newly-initialized OAuth 2 client
 */
+ (instancetype)clientWithBaseURL:(NSURL *)url
                         clientID:(NSString *)clientID
                           secret:(NSString *)secret;

/**
 Initializes an `AFOAuth2Manager` object with the specified base URL, client identifier, and secret.

 @param url The base URL for the HTTP client. This argument must not be `nil`.
 @param clientID The client identifier issued by the authorization server, uniquely representing the registration information provided by the client.
 @param secret The client secret.

 @return The newly-initialized OAuth 2 client
 */
- (id)initWithBaseURL:(NSURL *)url
             clientID:(NSString *)clientID
               secret:(NSString *)secret;

///---------------------
/// @name Authenticating
///---------------------

/**
 Creates and enqueues an `AFHTTPRequestOperation` to authenticate against the server using a specified username and password, with a designated scope.

 @param URLString The URL string used to create the request URL.
 @param username The username used for authentication
 @param password The password used for authentication
 @param scope The authorization scope
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                   username:(NSString *)username
                                   password:(NSString *)password
                                      scope:(NSString *)scope
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `AFHTTPRequestOperation` to authenticate against the server with a designated scope.

 @param URLString The URL string used to create the request URL.
 @param scope The authorization scope
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                      scope:(NSString *)scope
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `AFHTTPRequestOperation` to authenticate against the server using the specified refresh token.

 @param URLString The URL string used to create the request URL.
 @param refreshToken The OAuth refresh token
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                               refreshToken:(NSString *)refreshToken
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `AFHTTPRequestOperation` to authenticate against the server with an authorization code, redirecting to a specified URI upon successful authentication.

 @param URLString The URL string used to create the request URL.
 @param code The authorization code
 @param uri The URI to redirect to after successful authentication
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                       code:(NSString *)code
                                redirectURI:(NSString *)uri
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure;

/**
 Creates and enqueues an `AFHTTPRequestOperation` to authenticate against the server with the specified parameters.

 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded and set in the request HTTP body.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the OAuth credential returned by the server.
 @param failure A block object to be executed when the request operation finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a single argument: the error returned from the server.
 */
- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure;

@end

#pragma mark -

/**
 `AFOAuthCredential` models the credentials returned from an OAuth server, storing the token type, access & refresh tokens, and whether the token is expired.

 OAuth credentials can be stored in the user's keychain, and retrieved on subsequent launches.
 */
@interface AFOAuthCredential : NSObject <NSCoding>

///--------------------------------------
/// @name Accessing Credential Properties
///--------------------------------------

/**
 The OAuth access token.
 */
@property (readonly, nonatomic, copy) NSString *accessToken;

/**
 The OAuth token type (e.g. "bearer").
 */
@property (readonly, nonatomic, copy) NSString *tokenType;

/**
 The OAuth refresh token.
 */
@property (readonly, nonatomic, copy) NSString *refreshToken;

/**
 Whether the OAuth credentials are expired.
 */
@property (readonly, nonatomic, assign, getter = isExpired) BOOL expired;

///--------------------------------------------
/// @name Creating and Initializing Credentials
///--------------------------------------------

/**
 Create an OAuth credential from a token string, with a specified type.

 @param token The OAuth token string.
 @param type The OAuth token type.
 */
+ (instancetype)credentialWithOAuthToken:(NSString *)token
                               tokenType:(NSString *)type;

/**
 Initialize an OAuth credential from a token string, with a specified type.

 @param token The OAuth token string.
 @param type The OAuth token type.
 */
- (id)initWithOAuthToken:(NSString *)token
               tokenType:(NSString *)type;

///----------------------------
/// @name Setting Refresh Token
///----------------------------

/**
 Set the credential refresh token, with a specified expiration.

 @param refreshToken The OAuth refresh token.
 @param expiration The expiration of the access token. This must not be `nil`.
 */
- (void)setRefreshToken:(NSString *)refreshToken
             expiration:(NSDate *)expiration;

///-----------------------------------------
/// @name Storing and Retrieving Credentials
///-----------------------------------------

/**
 Stores the specified OAuth credential for a given web service identifier in the Keychain.
 with the default Keychain Accessibilty of kSecAttrAccessibleWhenUnlocked.

 @param credential The OAuth credential to be stored.
 @param identifier The service identifier associated with the specified credential.

 @return Whether or not the credential was stored in the keychain.
 */
+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier;

/**
 Stores the specified OAuth token for a given web service identifier in the Keychain.

 @param credential The OAuth credential to be stored.
 @param identifier The service identifier associated with the specified token.
 @param securityAccessibility The Keychain security accessibility to store the credential with.

 @return Whether or not the credential was stored in the keychain.
 */
+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
      withAccessibility:(id)securityAccessibility;

/**
 Retrieves the OAuth credential stored with the specified service identifier from the Keychain.

 @param identifier The service identifier associated with the specified credential.

 @return The retrieved OAuth credential.
 */
+ (AFOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier;

/**
 Deletes the OAuth credential stored with the specified service identifier from the Keychain.

 @param identifier The service identifier associated with the specified credential.

 @return Whether or not the credential was deleted from the keychain.
 */
+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;

@end

///----------------
/// @name Constants
///----------------

/**
 ## Error Domains

 The following error domain is predefined.

 - `NSString * const AFOAuth2ErrorDomain`

 ## OAuth Grant Types

 OAuth 2.0 provides several grant types, covering several different use cases. The following grant type string constants are provided:

 `kAFOAuthCodeGrantType`: "authorization_code"
 `kAFOAuthClientCredentialsGrantType`: "client_credentials"
 `kAFOAuthPasswordCredentialsGrantType`: "password"
 `kAFOAuthRefreshGrantType`: "refresh_token"
 */
extern NSString * const AFOAuth2ErrorDomain;

extern NSString * const kAFOAuthCodeGrantType;
extern NSString * const kAFOAuthClientCredentialsGrantType;
extern NSString * const kAFOAuthPasswordCredentialsGrantType;
extern NSString * const kAFOAuthRefreshGrantType;

@compatibility_alias AFOAuth2Client AFOAuth2Manager;
@compatibility_alias AFOAuth2RequestOperationManager AFOAuth2Manager;
