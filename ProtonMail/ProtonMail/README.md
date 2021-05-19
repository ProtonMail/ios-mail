# ProtonMail

The main app target and it contains UI related code

folder based on the UI name


## Rendering of HTML emails
Since all emails are treated as HTML documents, we're using `WKWebViews` of `WebKit.framework` to render them. 

Unlike other clients, iOS app user settings have only one toggle `Auto show images` which should switch off loading of _all remote content_ by html. Thus, inline images transferred as attachments will be shown but remote fonts will not.

Here the goal is to prevent the execution of possible code received by email, prevent XSS and prevent IP disclosure for cases when `Auto show images` if off - until the user will tap `Load remote images` button.

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

