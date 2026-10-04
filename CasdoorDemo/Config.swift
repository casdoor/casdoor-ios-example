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
import Casdoor

// The "app-casnode" application on the Casdoor demo server https://door.casdoor.com.
// Replace these values with your own Casdoor application, see README.md.
let casdoorConfig = CasdoorConfig(
    endpoint: "https://door.casdoor.com",
    clientID: "014ae4bd048734ca2dea",
    organizationName: "casbin",
    redirectUri: "casdoor://callback",
    appName: "app-casnode"
)

// The browser sheet closes when Casdoor redirects to a URL with this scheme
let callbackScheme = URL(string: casdoorConfig.redirectUri)?.scheme ?? "casdoor"
