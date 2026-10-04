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
import WebKit
import Casdoor

class WebViewController: UIViewController {
    var targetURL: URL?
    let webView:WKWebView = .init()
    var tokenHandle: ((Result<AccessTokenResponse, Error>) -> ())?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.frame = self.view.bounds
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.navigationDelegate = self
        self.view.addSubview(self.webView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[view]-0-|", options: [], metrics: nil, views: ["view":self.webView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view":self.webView]))
        self.targetURL = try? casdoor.getSigninUrl()
        loadAddressURL()
    }
    func loadAddressURL() {
        guard let url = targetURL else {
            return
        }
        let req = URLRequest(url: url)
        DispatchQueue.main.async {
            self.webView.load(req)
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url , url.scheme == scheme {
            decisionHandler(.cancel)
            let tokenHandle = self.tokenHandle
            Task {
                do {
                    let token = try await casdoor.handleCallback(url: url)
                    tokenHandle?(.success(token))
                } catch {
                    tokenHandle?(.failure(error))
                }
            }
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        decisionHandler(.allow)
    }
}
