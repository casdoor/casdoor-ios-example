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
import SafariServices

let config = CasdoorConfig.init(endpoint: "https://door.casdoor.com",
                                clientID: "014ae4bd048734ca2dea",
                                organizationName: "casbin",
                                redirectUri: "casdoor://callback",
                                appName: "app-casnode")

let scheme = config.redirectUri.components(separatedBy: "://")[0]

class ViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
    
    var token: String = "" {
        didSet {
            presentAlert(title: "Jwt", message: token)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    func presentAlert(title: String,message: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction.init(title: "ok", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    @IBAction func useWebView(_ sender: Any) {
        let webvc = WebViewController()
        webvc.tokenHandle = { token in
            self.token = token
        }
        self.navigationController?.pushViewController(webvc, animated: true)
        
    }
    
    @IBAction func useAsAuthSession(_ sender: Any) {
        let casdoor = Casdoor.init(config: config)
        guard let url = try? casdoor.getSigninUrl() else {
            self.presentAlert(title: "url", message: CasdoorError.invalidURL.description)
            return
        }
        let webAuthSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: scheme) { uri, error in
                if let error = error {
                    let msg = error.localizedDescription.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                    let errorDomain = (error as NSError).domain
                    let errorCode = (error as NSError).code
                    self.presentAlert(title: "error", message: "msg:\(msg ?? ""),domain:\(errorDomain),code:\(errorCode)")
                } else if let successURL = uri {
                    let params = successURL.query?.parametersFromQueryString
                    if let code = params?["code"] {
                        Task {
                           let result = try await casdoor.requestOauthAccessToken(code:code)
                            self.token = result.accessToken
                        }
                    }
                }
            }
        webAuthSession.presentationContextProvider = self
        webAuthSession.prefersEphemeralWebBrowserSession = false

        _ = webAuthSession.start()
    }
}

