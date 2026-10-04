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

import SwiftUI
import AuthenticationServices
import Casdoor

struct ContentView: View {
    @State private var model = AuthModel()
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    var body: some View {
        NavigationStack {
            List {
                if let token = model.token {
                    signedIn(token)
                } else {
                    signedOut
                }
            }
            .navigationTitle("Casdoor Demo")
            .disabled(model.isWorking)
            .overlay {
                if model.isWorking {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: isErrorShown, presenting: model.errorMessage) { _ in
                Button("OK") {}
            } message: { message in
                Text(message)
            }
        }
    }

    @ViewBuilder
    private var signedOut: some View {
        Section {
            Button("Sign in") {
                Task { await model.signIn(authenticate) }
            }
            Button("Sign up") {
                Task { await model.signUp(authenticate) }
            }
        } footer: {
            Text("Opens the Casdoor login page in a browser sheet.")
        }

        Section("Casdoor application") {
            LabeledContent("Endpoint", value: casdoorConfig.endpoint)
            LabeledContent("Organization", value: casdoorConfig.organizationName)
            LabeledContent("Application", value: casdoorConfig.appName)
            LabeledContent("Redirect URI", value: casdoorConfig.redirectUri)
        }
    }

    @ViewBuilder
    private func signedIn(_ token: AccessTokenResponse) -> some View {
        if let user = model.user {
            Section("User") {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: user.avatar ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())

                    VStack(alignment: .leading) {
                        Text(user.displayName ?? user.name ?? user.sub)
                            .font(.headline)
                        if let email = user.email {
                            Text(email)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                LabeledContent("Username", value: user.name ?? "")
                LabeledContent("Roles", value: joined(user.roles))
                LabeledContent("Permissions", value: joined(user.permissions))
                LabeledContent("Groups", value: joined(user.groups))
            }
        }

        if !model.idTokenClaims.isEmpty {
            Section("ID token") {
                ForEach(model.idTokenClaims) { claim in
                    LabeledContent(claim.name, value: claim.value)
                }
            }
        }

        Section("Access token") {
            Text(token.accessToken)
                .font(.caption.monospaced())
                .lineLimit(3)
                .textSelection(.enabled)
            LabeledContent("Scope", value: token.scope)
            LabeledContent("Expires in", value: "\(token.expiresIn) s")
            Button("Refresh token") {
                Task { await model.refresh() }
            }
            .disabled(token.refreshToken == nil)
        }

        Section {
            Button("Sign out", role: .destructive) {
                Task { await model.signOut(authenticate) }
            }
            Button("Revoke token only") {
                Task { await model.revokeToken() }
            }
        } footer: {
            Text("Sign out opens the Casdoor logout page, so the next sign-in asks for the password again. Revoke token only expires the token with an API call and keeps the browser session.")
        }
    }

    private var isErrorShown: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { isShown in
                if !isShown {
                    model.errorMessage = nil
                }
            }
        )
    }

    private func joined(_ items: [String]) -> String {
        items.isEmpty ? "None" : items.joined(separator: ", ")
    }

    // Shares cookies with Safari (.shared), so the user stays signed in to Casdoor
    // across sign-ins until "Sign out" clears the session.
    private func authenticate(_ url: URL) async throws -> URL {
        do {
            return try await webAuthenticationSession.authenticate(
                using: url,
                callbackURLScheme: callbackScheme,
                preferredBrowserSession: .shared
            )
        } catch ASWebAuthenticationSessionError.canceledLogin {
            throw CancellationError()
        }
    }
}

#Preview {
    ContentView()
}
