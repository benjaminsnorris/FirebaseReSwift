# FirebaseReSwift
[![Latest release](http://img.shields.io/github/release/benjaminsnorris/FirebaseReSwift.svg)](https://github.com/benjaminsnorris/FirebaseReSwift/releases)
[![GitHub license](https://img.shields.io/github/license/benjaminsnorris/FirebaseReSwift.svg)](/LICENSE)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)](https://github.com/Carthage/Carthage)

A small library to make working with Firebase and ReSwift easier in iOS apps

1. [Requirements](#requirements)
2. [Usage](#usage)
3. [Integration](#integration)
  - [Carthage](#carthage)
  - [Swift Package Manager](#swift-package-manager)
  - [Git Submodules](#git-submodules)

## Requirements
- iOS 9.0+
- Xcode 7.3+
- Swift 2.2+
- [ReSwift](https://github.com/ReSwift/ReSwift)
- [Firebase](https://www.firebase.com)

## Usage
More info coming soon...

## Integration
### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate FirebaseReSwift into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "benjaminsnorris/FirebaseReSwift" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `FirebaseReSwift.framework` into your Xcode project.


### Git Submodules

- If you don't already have a `.xcworkspace` for your project, create one. ([Here's how](https://developer.apple.com/library/ios/recipes/xcode_help-structure_navigator/articles/Adding_an_Existing_Project_to_a_Workspace.html))

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

```bash
$ git init
```

- Add FirebaseReSwift as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

```bash
$ git submodule add https://github.com/benjaminsnorris/FirebaseReSwift.git Vendor/FirebaseReSwift
```

- Open the new `FirebaseReSwift` folder, and drag the `FirebaseReSwift.xcodeproj` into the Project Navigator of your application's Xcode workspace.

    > It should not be nested underneath your application's blue project icon. Whether it is above or below your application's project does not matter.

- Select `FirebaseReSwift.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Linked Frameworks and Libraries" section.
- Select `FirebaseReSwift.framework` inside the `Workspace` folder.
- Click on the `+` button under the "Embedded Binaries" section.
- Select `FirebaseReSwift.framework` nested inside your project.
- An extra copy of `FirebaseReSwift.framework` will show up in "Linked Frameworks and Libraries". Delete one of them (it doesn't matter which one).
- And that's it!
