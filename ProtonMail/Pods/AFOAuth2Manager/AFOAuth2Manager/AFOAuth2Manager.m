// AFOAuth2Manager.m
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

#import <Security/Security.h>

#import "AFOAuth2Manager.h"

NSString * const AFOAuth2ErrorDomain = @"com.alamofire.networking.oauth2.error";

NSString * const kAFOAuthCodeGrantType = @"authorization_code";
NSString * const kAFOAuthClientCredentialsGrantType = @"client_credentials";
NSString * const kAFOAuthPasswordCredentialsGrantType = @"password";
NSString * const kAFOAuthRefreshGrantType = @"refresh_token";

NSString * const kAFOAuth2CredentialServiceName = @"AFOAuthCredentialService";

static NSDictionary * AFKeychainQueryDictionaryWithIdentifier(NSString *identifier) {
    NSCParameterAssert(identifier);

    return @{
      (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
      (__bridge id)kSecAttrService: kAFOAuth2CredentialServiceName,
      (__bridge id)kSecAttrAccount: identifier
    };
}

// See: http://tools.ietf.org/html/rfc6749#section-5.2
static NSError * AFErrorFromRFC6749Section5_2Error(id object) {
    if (![object valueForKey:@"error"] || [[object valueForKey:@"error"] isEqual:[NSNull null]]) {
        return nil;
    }

    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionary];

    NSString *description = nil;
    if ([object valueForKey:@"error_description"]) {
        description = [object valueForKey:@"error_description"];
    } else {
        if ([[object valueForKey:@"error"] isEqualToString:@"invalid_request"]) {
            description = NSLocalizedStringFromTable(@"The request is missing a required parameter, includes an unsupported parameter value (other than grant type), repeats a parameter, includes multiple credentials, utilizes more than one mechanism for authenticating the client, or is otherwise malformed.", @"AFOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"invalid_client"]) {
            description = NSLocalizedStringFromTable(@"Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method).  The authorization server MAY return an HTTP 401 (Unauthorized) status code to indicate which HTTP authentication schemes are supported.  If the client attempted to authenticate via the \"Authorization\" request header field, the authorization server MUST respond with an HTTP 401 (Unauthorized) status code and include the \"WWW-Authenticate\" response header field matching the authentication scheme used by the client.", @"AFOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"invalid_grant"]) {
            description = NSLocalizedStringFromTable(@"The provided authorization grant (e.g., authorization code, resource owner credentials) or refresh token is invalid, expired, revoked, does not match the redirection URI used in the authorization request, or was issued to another client.", @"AFOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"unauthorized_client"]) {
            description = NSLocalizedStringFromTable(@"The authenticated client is not authorized to use this authorization grant type.", @"AFOAuth2Manager", @"invalid_request");
        } else if ([[object valueForKey:@"error"] isEqualToString:@"unsupported_grant_type"]) {
            description = NSLocalizedStringFromTable(@"The authorization grant type is not supported by the authorization server.", @"AFOAuth2Manager", @"invalid_request");
        }
    }

    if (description) {
        mutableUserInfo[NSLocalizedDescriptionKey] = description;
    }

    if ([object valueForKey:@"error_uri"]) {
        mutableUserInfo[NSLocalizedRecoverySuggestionErrorKey] = [object valueForKey:@"error_uri"];
    }

    return [NSError errorWithDomain:AFOAuth2ErrorDomain code:-1 userInfo:mutableUserInfo];
}

#pragma mark -

@interface AFOAuth2Manager ()
@property (readwrite, nonatomic, copy) NSString *serviceProviderIdentifier;
@property (readwrite, nonatomic, copy) NSString *clientID;
@property (readwrite, nonatomic, copy) NSString *secret;
@end

@implementation AFOAuth2Manager

+ (instancetype)clientWithBaseURL:(NSURL *)url
                         clientID:(NSString *)clientID
                           secret:(NSString *)secret
{
    return [[self alloc] initWithBaseURL:url clientID:clientID secret:secret];
}

- (id)initWithBaseURL:(NSURL *)url
             clientID:(NSString *)clientID
               secret:(NSString *)secret
{
    NSParameterAssert(clientID);

    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }

    self.serviceProviderIdentifier = [self.baseURL host];
    self.clientID = clientID;
    self.secret = secret;

    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    return self;
}

#pragma mark -

- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                   username:(NSString *)username
                                   password:(NSString *)password
                                      scope:(NSString *)scope
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(username);
    NSParameterAssert(password);
    NSParameterAssert(scope);

    NSDictionary *parameters = @{
                                 @"grant_type": kAFOAuthPasswordCredentialsGrantType,
                                 @"username": username,
                                 @"password": password,
                                 @"scope": scope
                                };

    [self authenticateUsingOAuthWithURLString:URLString parameters:parameters success:success failure:failure];
}

- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                      scope:(NSString *)scope
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(scope);

    NSDictionary *parameters = @{
                                 @"grant_type": kAFOAuthClientCredentialsGrantType,
                                 @"scope": scope
                                };

    [self authenticateUsingOAuthWithURLString:URLString parameters:parameters success:success failure:failure];
}

- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                               refreshToken:(NSString *)refreshToken
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(refreshToken);

    NSDictionary *parameters = @{
                                 @"grant_type": kAFOAuthRefreshGrantType,
                                 @"refresh_token": refreshToken
                                };

    [self authenticateUsingOAuthWithURLString:URLString parameters:parameters success:success failure:failure];
}

- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                       code:(NSString *)code
                                redirectURI:(NSString *)uri
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(code);
    NSParameterAssert(uri);

    NSDictionary *parameters = @{
                                 @"grant_type": kAFOAuthCodeGrantType,
                                 @"code": code,
                                 @"redirect_uri": uri
                                };

    [self authenticateUsingOAuthWithURLString:URLString parameters:parameters success:success failure:failure];
}

- (void)authenticateUsingOAuthWithURLString:(NSString *)URLString
                                 parameters:(NSDictionary *)parameters
                                    success:(void (^)(AFOAuthCredential *credential))success
                                    failure:(void (^)(NSError *error))failure
{
    NSMutableDictionary *mutableParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    mutableParameters[@"client_id"] = self.clientID;
    mutableParameters[@"client_secret"] = self.secret;
    parameters = [NSDictionary dictionaryWithDictionary:mutableParameters];

    [self POST:URLString parameters:parameters success:^(__unused AFHTTPRequestOperation *operation, id responseObject) {
        if (!responseObject) {
            if (failure) {
                failure(nil);
            }

            return;
        }

        if ([responseObject valueForKey:@"error"]) {
            if (failure) {
                failure(AFErrorFromRFC6749Section5_2Error(responseObject));
            }

            return;
        }

        NSString *refreshToken = [responseObject valueForKey:@"refresh_token"];
        if (!refreshToken || [refreshToken isEqual:[NSNull null]]) {
            refreshToken = [parameters valueForKey:@"refresh_token"];
        }

        AFOAuthCredential *credential = [AFOAuthCredential credentialWithOAuthToken:[responseObject valueForKey:@"access_token"] tokenType:[responseObject valueForKey:@"token_type"]];

        NSDate *expireDate = [NSDate distantFuture];
        id expiresIn = [responseObject valueForKey:@"expires_in"];
        if (expiresIn && ![expiresIn isEqual:[NSNull null]]) {
            expireDate = [NSDate dateWithTimeIntervalSinceNow:[expiresIn doubleValue]];
        }

        if (refreshToken && expireDate) {
            [credential setRefreshToken:refreshToken expiration:expireDate];
        }

        if (success) {
            success(credential);
        }
    } failure:^(__unused AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

@end

#pragma mark -

@interface AFOAuthCredential ()
@property (readwrite, nonatomic, copy) NSString *accessToken;
@property (readwrite, nonatomic, copy) NSString *tokenType;
@property (readwrite, nonatomic, copy) NSString *refreshToken;
@property (readwrite, nonatomic, copy) NSDate *expiration;
@end

@implementation AFOAuthCredential
@dynamic expired;

#pragma mark -

+ (instancetype)credentialWithOAuthToken:(NSString *)token
                               tokenType:(NSString *)type
{
    return [[self alloc] initWithOAuthToken:token tokenType:type];
}

- (id)initWithOAuthToken:(NSString *)token
               tokenType:(NSString *)type
{
    self = [super init];
    if (!self) {
        return nil;
    }

    self.accessToken = token;
    self.tokenType = type;

    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ accessToken:\"%@\" tokenType:\"%@\" refreshToken:\"%@\" expiration:\"%@\">", [self class], self.accessToken, self.tokenType, self.refreshToken, self.expiration];
}

- (void)setRefreshToken:(NSString *)refreshToken
             expiration:(NSDate *)expiration
{
    NSParameterAssert(expiration);

    self.refreshToken = refreshToken;
    self.expiration = expiration;
}

- (BOOL)isExpired {
    return [self.expiration compare:[NSDate date]] == NSOrderedAscending;
}

#pragma mark Keychain

+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
{
    id securityAccessibility = nil;
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 43000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
    if (&kSecAttrAccessibleWhenUnlocked != NULL) {
        securityAccessibility = (__bridge id)kSecAttrAccessibleWhenUnlocked;
    }
#endif

    return [[self class] storeCredential:credential withIdentifier:identifier withAccessibility:securityAccessibility];
}

+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier
      withAccessibility:(id)securityAccessibility
{
    NSMutableDictionary *queryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];

    if (!credential) {
        return [self deleteCredentialWithIdentifier:identifier];
    }

    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
    updateDictionary[(__bridge id)kSecValueData] = [NSKeyedArchiver archivedDataWithRootObject:credential];

    if (securityAccessibility) {
        updateDictionary[(__bridge id)kSecAttrAccessible] = securityAccessibility;
    }

    OSStatus status;
    BOOL exists = ([self retrieveCredentialWithIdentifier:identifier] != nil);

    if (exists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)queryDictionary, (__bridge CFDictionaryRef)updateDictionary);
    } else {
        [queryDictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)queryDictionary, NULL);
    }

    if (status != errSecSuccess) {
        NSLog(@"Unable to %@ credential with identifier \"%@\" (Error %li)", exists ? @"update" : @"add", identifier, (long int)status);
    }

    return (status == errSecSuccess);
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];

    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDictionary);

    if (status != errSecSuccess) {
        NSLog(@"Unable to delete credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
    }

    return (status == errSecSuccess);
}

+ (AFOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = [AFKeychainQueryDictionaryWithIdentifier(identifier) mutableCopy];
    queryDictionary[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
    queryDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&result);

    if (status != errSecSuccess) {
        NSLog(@"Unable to fetch credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
        return nil;
    }

    return [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge_transfer NSData *)result];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    self.accessToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(accessToken))];
    self.tokenType = [decoder decodeObjectForKey:NSStringFromSelector(@selector(tokenType))];
    self.refreshToken = [decoder decodeObjectForKey:NSStringFromSelector(@selector(refreshToken))];
    self.expiration = [decoder decodeObjectForKey:NSStringFromSelector(@selector(expiration))];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.accessToken forKey:NSStringFromSelector(@selector(accessToken))];
    [encoder encodeObject:self.tokenType forKey:NSStringFromSelector(@selector(tokenType))];
    [encoder encodeObject:self.refreshToken forKey:NSStringFromSelector(@selector(refreshToken))];
    [encoder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
}

@end
