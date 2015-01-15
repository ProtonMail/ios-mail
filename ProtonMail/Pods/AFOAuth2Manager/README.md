# AFOAuth2Manager

AFOAuth2Manager is an extension for [AFNetworking](http://github.com/AFNetworking/AFNetworking/) that simplifies the process of authenticating against an [OAuth 2](https://tools.ietf.org/html/rfc6749) provider.

## Example Usage

### Authentication

```objective-c
NSURL *baseURL = [NSURL URLWithString:@"http://example.com/"];
AFOAuth2Manager *OAuth2Manager =
            [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                            clientID:kClientID
                                              secret:kClientSecret];

[OAuth2Manager authenticateUsingOAuthWithURLString:@"/oauth/token"
                                          username:@"username"
                                          password:@"password"
                                             scope:@"email"
                                           success:^(AFOAuthCredential *credential) {
                                               NSLog(@"Token: %@", credential.accessToken);
                                           }
                                           failure:^(NSError *error) {
                                               NSLog(@"Error: %@", error);
                                           }];
```

### Authorizing Requests

```objective-c
AFHTTPRequestOperationManager *manager =
    [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];

[manager.requestSerializer setAuthorizationHeaderFieldWithCredential:credential.accessToken];

[manager GET:@"/path/to/protected/resource"
  parameters:nil
     success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSLog(@"Success: %@", responseObject);
     }
     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         NSLog(@"Failure: %@", error);
     }];
```

### Storing Credentials

```objective-c
[AFOAuthCredential storeCredential:credential
                    withIdentifier:serviceProviderIdentifier];
```

### Retrieving Credentials

```objective-c
AFOAuthCredential *credential =
        [AFOAuthCredential retrieveCredentialWithIdentifier:serviceProviderIdentifier];
```

## Documentation

Documentation for all releases of AFOAuth2Manager are [available on CocoaDocs](http://cocoadocs.org/docsets/AFOAuth2Manager/).

## Contact

Mattt Thompson

- http://github.com/mattt
- http://twitter.com/mattt
- m@mattt.me

## License

AFOAuth2Manager is available under the MIT license. See the LICENSE file for more info.
