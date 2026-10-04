// Copyright 2021 The casbin Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import Observation
import Casdoor

/// Opens a URL in the system browser sheet and returns the URL Casdoor redirected back to.
/// Throws `CancellationError` when the user closes the sheet.
typealias Authenticate = (URL) async throws -> URL

struct Claim: Identifiable {
    let name: String
    let value: String
    var id: String { name }
}

@MainActor
@Observable
final class AuthModel {
    private(set) var token: AccessTokenResponse?
    private(set) var user: CasdoorUserInfo?
    private(set) var idTokenClaims: [Claim] = []
    private(set) var isWorking = false
    var errorMessage: String?

    // One instance for the whole sign-in: getSigninUrl() keeps the PKCE verifier,
    // state and nonce that handleCallback(url:) checks
    private let casdoor = Casdoor(config: casdoorConfig)

    func signIn(_ authenticate: Authenticate) async {
        await run {
            let callbackUrl = try await authenticate(try casdoor.getSigninUrl())
            try await load(try await casdoor.handleCallback(url: callbackUrl))
        }
    }

    func signUp(_ authenticate: Authenticate) async {
        await run {
            let callbackUrl = try await authenticate(try casdoor.getSignupUrl())
            try await load(try await casdoor.handleCallback(url: callbackUrl))
        }
    }

    func refresh() async {
        guard let refreshToken = token?.refreshToken else {
            return
        }
        await run {
            try await load(try await casdoor.renewToken(refreshToken: refreshToken))
        }
    }

    /// Opens Casdoor's logout page in the browser sheet: the token is expired and the Casdoor
    /// session cookie is cleared, so the next sign-in asks for the password again.
    func signOut(_ authenticate: Authenticate) async {
        guard let idToken = token?.idToken else {
            clear()
            return
        }
        await run {
            _ = try await authenticate(try casdoor.getSignoutUrl(idToken: idToken))
            clear()
        }
    }

    /// Expires the token with an API call, no UI. The browser session is kept.
    func revokeToken() async {
        guard let idToken = token?.idToken else {
            clear()
            return
        }
        await run {
            try await casdoor.logout(idToken: idToken)
            clear()
        }
    }

    private func load(_ token: AccessTokenResponse) async throws {
        self.token = token
        idTokenClaims = AuthModel.claims(of: token.idToken)
        user = try await casdoor.getUserInfo(accessToken: token.accessToken)
    }

    private func clear() {
        token = nil
        user = nil
        idTokenClaims = []
    }

    private func run(_ action: () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await action()
        } catch is CancellationError {
            // the user closed the browser sheet
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // A few claims of the ID token. The SDK does not verify its signature,
    // it came from Casdoor over HTTPS.
    private static func claims(of idToken: String?) -> [Claim] {
        guard let idToken = idToken, let claims = try? Casdoor.decodeJwtPayload(idToken) else {
            return []
        }
        return ["iss", "sub", "aud", "owner", "name", "exp"].compactMap { name in
            switch claims[name] {
            case let seconds as Double where name == "exp":
                return Claim(name: name, value: Date(timeIntervalSince1970: seconds).formatted())
            case let values as [String]:
                return Claim(name: name, value: values.joined(separator: ", "))
            case let value?:
                return Claim(name: name, value: "\(value)")
            case nil:
                return nil
            }
        }
    }
}
