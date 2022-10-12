# ProtnMail

The main app target and it contains UI related code

folder based on the UI name


## Rendering of HTML emails
Since all emails are treated as HTML documents, we're using `WKWebView` of `WebKit.framework` to render them. 

As opposed to the legacy `UIWebView`, `WKWebView` runs out of process, meaning the app has no direct access to how the HTML document is rendered. That said, since our goal is to prevent the possibility of remote code execution, XSS and IP disclosure, we apply extra security measures, such as disabling JavaScript and applying a strictier Content Security Policy. We also allow the user to block loading all remote images through a single switch in Settings, and only load them on demand for messages from trusted senders.

## Other WebViews
we also use the `UIWebview` to load the human verification code(captcha-like system). 
1. In the signup flow 
2. In-app human check

### Incoming and outgoing emails
JavaScript execution is turned off for emails viewers (emails Composer utilises JS for editing the message).

We're using `DOMPurify` to sanitize html before rendering it. This is done by `WKUserScript` at the end of document loading. `WKWebView` is smart object and tries to load all remote html contents before calling this script, so first thing we're doing is disabling _all_ remote content loading until sanitization will be over, and only then start loading of document itself. Once it is over, JSContext will send us a message and we'll roll back to remote content loading mode desired by user.

The technique was chosen to disable loading of remote content (both before and after sanitization) is different for iOS 9-10 and iOS 11-12 due to the difference in `WebKit` API:
- for iOS 9-10 we're injecting `<meta>` tag defining CSP into HTML. Before sanitization, we're injecting similar `<meta>` tag for complete lockdown before loading HTML into `WKWebView` via `WKUserScript` running before the document loading.
- for iOS 11-12 we're simulating URL request to return URL response with HTTP headers with the desired CSP. This is done via a custom scheme and `WKURLSchemeHandler`. Before sanitization, we're using `WKContentRuleList` for complete lockdown before loading HTML into `WKWebView`.

### Composer
Email composer uses javascript runtime heavily, so we could not afford to switch it off on WKWebView configuration level.

Thus, we're running DOMPurify sanitization before loading document parts (signature, draft of message, other message as a reply or forward base, etc) into the composer and use CSP `<meta>` tag to restrict remote content loading.
