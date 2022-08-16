# casdoor-ios-example

## Init example

You need to init requires 5 parameters, which are all string type:

| Name         | Description                                                                                             | File                  |
| ------------ | ------------------------------------------------------------------------------------------------------- | --------------------- |
| endpoint     | Your Casdoor server host/domain                                                                         | `ViewController.swift` |
| clientID     | The Client ID of your Casdoor application                                                               | `ViewController.swift` |
| organizationName| The organization name of your Casdoor application                                                    | `ViewController.swift` |
| redirectUri  | The path of the callback URL for your Casdoor application, will be `casdoor://callback` if not provided | `ViewController.swift` |
| appName | The name of your Casdoor application                                                                         | `ViewController.swift` |

If you don't set these parameters, this project will use the [Casdoor online demo](https://door.casdoor.com) as the defult Casdoor server and use the [Casnode](https://door.casdoor.com/applications/app-casnode) as the default Casdoor application.

## How to run it

### Xcode
- download the code

```bash
 git clone https://github.com/casdoor/casdoor-ios-example.git
```

- open the CasdoorDemo.xcodeproj
if you change redirectUri,you should change the url schemes in the target CasdoorDemo
<img width="1227" alt="QQ20220816-230049@2x" src="https://user-images.githubusercontent.com/31656300/184912660-e7c41c54-5afe-4eb6-82b7-d29ce08bb6ad.png">
