# AFNetworkActivityLogger

`AFNetworkActivityLogger` is an extension for [AFNetworking](http://github.com/AFNetworking/AFNetworking/) 3.0 that logs network requests as they are sent and received.

> `AFNetworkActivityLogger` listens `AFNetworkingTaskDidStartNotification` and `AFNetworkingTaskDidFinishNotification` notifications, which are posted by AFNetworking as session tasks are started and finish. For further customization of logging output, users are encouraged to implement desired functionality by creating new objects that conform to `AFNetworkActivityLoggerProtocol`.

## 2.x -> 3.x Migration
3.0.0 featured the following breaking API changes:

* The log `level` property is now found on the individual unique loggers, rather than the shared logger. This allows for more advanced customization options for logging level.
* The `filterPredicate` property is now found on the individual unique loggers, rather than the shared logger. This allows for more advanced customization options for logging specific requests.

## Usage

Add the following code to `AppDelegate.m -application:didFinishLaunchingWithOptions:`:

``` objective-c
[[AFNetworkActivityLogger sharedLogger] startLogging];
```

Now all `NSURLSessionTask` objects created by an `AFURLSessionManager` will have their request and response logged to the console, a la:

```
GET http://example.com/foo/bar.json
200 http://example.com/foo/bar.json [0.1860 s]
```

If the default logging level is too verbose—say, if you only want to know when requests fail—then changing it is as simple as:

``` objective-c
[[AFNetworkActivityLogger sharedLogger] setLevel:AFLoggerLevelError];
```

## Logging Levels
By default, the shared logger is configured with an `AFNetworkActivityConsoleLogger` with a debug level set to `AFLoggerLevelInfo`. To change the level, simply access the logger through the `loggers` property, and adjust the level. The following levels are provided:

 * `AFLoggerLevelOff`: Do not log requests or responses.
 * `AFLoggerLevelDebug` :Logs HTTP method, URL, header fields, & request body for requests, and status code, URL, header fields, response string, & elapsed time for responses.
 * `AFLoggerLevelInfo`: Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses.
 * `AFLoggerLevelError`: Logs HTTP method & URL for requests, and status code, URL, & elapsed time for responses, but only for failed requests.

## Filtering Requests
To limit the requests that are logged by a unique logger, each object that conforms to `AFNetworkActivityLoggerProtocol` has a `filterPredicate` property. If the predicate returns true, the request will not be forwarded to the logger. For example, a custom file logger could be created that only logs requests for `http://httpbin.org`, while a console logger could be used to log all errors in the application.

```Objective-C
AFNetworkActivityConsoleLogger *testLogger = [AFNetworkActivityConsoleLogger new];
NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSURLRequest *  _Nonnull request, NSDictionary<NSString *,id> * _Nullable bindings) {
    return !([[request URL] baseURL] isEqualToString:@"httpbin.org"])
}];
[testLogger setFilterPredicate:predicate];
```    

## Custom Loggers
By default, the shared logger is configured with an `AFNetworkActivityConsoleLogger`.

To create a custom logger, create a new object that conforms to `AFNetworkActivityLoggerProtocol`, and add it to the shared logger. Be sure and configure the proper default logging level.

## License

AFNetworkActivityLogger is available under the MIT license. See the LICENSE file for more info.
