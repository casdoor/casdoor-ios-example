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

import UIKit
import Casdoor
import AuthenticationServices

let config = CasdoorConfig.init(endpoint: "https://door.casdoor.com",
                                clientID: "014ae4bd048734ca2dea",
                                organizationName: "casbin",
                                redirectUri: "casdoor://callback",
                                appName: "app-casnode")

let scheme = config.redirectUri.components(separatedBy: "://")[0]

// One instance for the whole sign-in: getSigninUrl() keeps the PKCE verifier that handleCallback(url:) needs
let casdoor = Casdoor(config: config)

class ViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    var token: AccessTokenResponse?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign out", style: .plain, target: self, action: #selector(signOut))
    }

    func presentAlert(title: String, message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "ok", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }

    func signedIn(_ token: AccessTokenResponse) async {
        self.token = token
        do {
            let user = try await casdoor.getUserInfo(accessToken: token.accessToken)
            presentAlert(title: "Signed in", message: """
                user: \(user.name ?? user.sub)
                email: \(user.email ?? "")
                roles: \(user.roles.joined(separator: ", "))
                permissions: \(user.permissions.joined(separator: ", "))

                access token: \(token.accessToken)
                """)
        } catch {
            presentAlert(title: "error", message: "\(error)")
        }
    }

    @IBAction func useWebView(_ sender: Any) {
        let webvc = WebViewController()
        webvc.tokenHandle = { result in
            Task { @MainActor in
                switch result {
                case .success(let token):
                    await self.signedIn(token)
                case .failure(let error):
                    self.presentAlert(title: "error", message: "\(error)")
                }
            }
        }
        self.navigationController?.pushViewController(webvc, animated: true)
    }

    @IBAction func useAsAuthSession(_ sender: Any) {
        let url: URL
        do {
            url = try casdoor.getSigninUrl()
        } catch {
            presentAlert(title: "url", message: "\(error)")
            return
        }
        startWebAuthSession(url: url) { callbackUrl in
            do {
                let token = try await casdoor.handleCallback(url: callbackUrl)
                await self.signedIn(token)
            } catch {
                self.presentAlert(title: "error", message: "\(error)")
            }
        }
    }

    // Opens Casdoor's logout URL in the same browser used for sign-in, so the Casdoor
    // session cookie is cleared too and the next sign-in asks for the password again.
    @objc func signOut() {
        guard let idToken = token?.idToken else {
            presentAlert(title: "Sign out", message: "Not signed in")
            return
        }
        let url: URL
        do {
            url = try casdoor.getSignoutUrl(idToken: idToken)
        } catch {
            presentAlert(title: "url", message: "\(error)")
            return
        }
        startWebAuthSession(url: url) { _ in
            self.token = nil
            self.presentAlert(title: "Sign out", message: "Signed out")
        }
    }

    func startWebAuthSession(url: URL, onCallback: @escaping @MainActor (URL) async -> Void) {
        let webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: scheme) { uri, error in
                Task { @MainActor in
                    if let error = error {
                        let errorDomain = (error as NSError).domain
                        let errorCode = (error as NSError).code
                        self.presentAlert(title: "error", message: "msg:\(error.localizedDescription),domain:\(errorDomain),code:\(errorCode)")
                    } else if let uri = uri {
                        await onCallback(uri)
                    }
                }
            }
        webAuthSession.presentationContextProvider = self
        webAuthSession.prefersEphemeralWebBrowserSession = false

        _ = webAuthSession.start()
    }
}
