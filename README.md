# casdoor-ios-example

[![Build](https://github.com/casdoor/casdoor-ios-example/actions/workflows/build.yml/badge.svg)](https://github.com/casdoor/casdoor-ios-example/actions/workflows/build.yml)

A SwiftUI app that shows how to sign in to [Casdoor](https://casdoor.ai) with [casdoor-ios-sdk](https://github.com/casdoor/casdoor-ios-sdk):

- Sign in and sign up in a browser sheet (OAuth 2.0 authorization code flow with PKCE, no client secret in the app)
- Show the user's profile, roles, permissions and groups from `/api/userinfo`
- Show the claims of the ID token
- Refresh the access token
- Sign out, with or without ending the browser session

## Run

Requirements: Xcode 16 or later, iOS 17 or later.

```bash
git clone https://github.com/casdoor/casdoor-ios-example.git
open casdoor-ios-example/CasdoorDemo.xcodeproj
```

Choose an iPhone simulator and press Run. Xcode downloads the SDK by Swift Package Manager.

The app uses the `app-casnode` application on the Casdoor demo server https://door.casdoor.com, so you can sign in with an account on that server. To run on a device, choose your team in Signing & Capabilities.

## Use your own Casdoor application

1. In Casdoor, open your application and add `casdoor://callback` to **Redirect URLs**. Both sign-in and sign-out redirect to it.
2. Edit [CasdoorDemo/Config.swift](CasdoorDemo/Config.swift):

   | Name             | Description                                                      |
   | ---------------- | ---------------------------------------------------------------- |
   | endpoint         | Casdoor server URL, such as `https://door.casdoor.com`           |
   | clientID         | Client ID of the application                                     |
   | organizationName | Organization of the application                                  |
   | redirectUri      | `casdoor://callback`, or your own scheme, it must be in Redirect URLs |
   | appName          | Name of the application                                          |

   With your own scheme there is nothing to register in Info.plist: `ASWebAuthenticationSession` catches the redirect itself.

3. Roles, permissions and groups are returned when the token has the `profile` scope (the SDK's default). If the application has a **Token fields** list, add `Roles`, `Permissions` and `Groups` to it.

## How it works

All Casdoor calls are in [CasdoorDemo/AuthModel.swift](CasdoorDemo/AuthModel.swift), the UI is in [CasdoorDemo/ContentView.swift](CasdoorDemo/ContentView.swift).

```swift
let casdoor = Casdoor(config: casdoorConfig)

// Sign in: open the login page in a browser sheet, then exchange the code for tokens
let callbackUrl = try await webAuthenticationSession.authenticate(
    using: try casdoor.getSigninUrl(),
    callbackURLScheme: "casdoor",
    preferredBrowserSession: .shared
)
let token = try await casdoor.handleCallback(url: callbackUrl)

// User info, including roles and permissions
let user = try await casdoor.getUserInfo(accessToken: token.accessToken)

// New access token
let newToken = try await casdoor.renewToken(refreshToken: token.refreshToken!)

// Sign out and end the browser session
_ = try await webAuthenticationSession.authenticate(
    using: try casdoor.getSignoutUrl(idToken: token.idToken!),
    callbackURLScheme: "casdoor",
    preferredBrowserSession: .shared
)

// Or only expire the token, the browser session stays
try await casdoor.logout(idToken: token.idToken!)
```

Keep one `Casdoor` instance from `getSigninUrl()` to `handleCallback(url:)`: it holds the PKCE code verifier, state and nonce of the sign-in.

The login page is opened with `ASWebAuthenticationSession`, not in a `WKWebView`. Embedded web views are not allowed for OAuth ([RFC 8252](https://www.rfc-editor.org/rfc/rfc8252)): the app could read the password, and providers such as Google refuse to sign in there.

This example keeps the tokens in memory only. A real app should store them in the Keychain.

## License

[Apache-2.0](LICENSE)
