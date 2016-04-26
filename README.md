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
Import the module into any file where you need to reference `FirebaseAccess`, the `Subscribing` protocol, or one of the generic actions.
```swift
Import FirebaseReSwift
```

### `FirebaseAccess`
This protocol along with its extension defines some core functionality with Firebase.

You will typically adopt this in a struct that might look like this:

```swift
struct FirebaseNetworkAccess: FirebaseAccess {
   static let sharedAccess: FirebaseAccess = FirebaseNetworkAccess()
   let ref: Firebase
   init() {
       Firebase.defaultConfig().persistenceEnabled = true // Only for offline access
       self.ref = Firebase(url: "https://your-app.firebaseio.com")
   }
}
```

#### New object ID
> `newObjectId() -> String?`

Generates an automatic id for a new child object

#### Create object
> `createObject<T>(ref: Firebase, createNewChildId: Bool = false, parameters: MarshaledObject, state: T) -> (state: T, store: Store<T>) -> Action?`

Writes a Firebase object with the parameters, overwriting any values at the specific location.

- Parameters:
    - `ref`: The Firebase reference to the object to be written. Usually constructed from the base `ref` using `childByAppendingPath(_)`
    - `createNewChildId`: A flag indicating whether a new child ID needs to be created before saving the new object.
    - `parameters`: A `MarshaledObject` (`[String: AnyObject]`) representing the object with all of its properties.
    - `state`: An object of type `StateType` which resolves the generic state type for the return value.

- returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose type matches the `state` parameter.

#### Update object
> `updateObject<T: StateType>(ref: Firebase, parameters: MarshaledObject, state: T) -> (state: T, store: Store<T>) -> Action?`

Updates the Firebase object with the parameters, leaving all other values intact.

- Parameters:
    - `ref`: The Firebase reference to the object to be updated. Usually constructed from the base `ref` using `childByAppendingPath(_)`
    - `parameters`: A `MarshaledObject` (`[String: AnyObject]`) representing the fields to be updated with their values.
    - `state`: An object of type `StateType` which resolves the generic state type for the return value.

- returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose type matches the `state` parameter.

#### Remove object
> `removeObject<T>(ref: Firebase, state: T) -> (state: T, store: Store<T>) -> Action?`

Removes a Firebase object at the given ref.

- Parameters:
    - `ref`:     The Firebase reference to the object to be removed.
    - `state`:   An object of type `StateType` which resolves the generic state type for the return value.

- returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose  type matches the `state` parameter.


### Subscribing
This protocol is adopted by a data object in order to receive updates of that from Firebase.

- **Note:** The object must also adopt `Unmarshaling` in order to parse JSON into an object of that type.

#### Subscribe to objects
> `subscribeToObjects<T: StateType>(query: FQuery, subscribingState: SubscribingState, state: T) -> (state: T, store: Store<T>) -> Action?`

Calling this function results in the dispatching actions to the store for the following events that occur in Firebase matching the given query. The actions are generic actions scoped to the data object on which the function is called.

- Note: The `ObjectErrored` action can be called on any of those events if the resulting data does not exist, or cannot be parsed from JSON into the data object. It is likewise a generic action scoped to the data object.

- `ChildAdded` event:      `ObjectAdded` action
- `ChildChanged` event:    `ObjectChanged` action
- `ChildRemoved` event:    `ObjectRemoved` action

- Parameters:
    - `query`: The Firebase query to which to subscribe. This is usually constructed from the base `ref` using `childByAppendingPath(_)` or other  `FQuery` functions.
    - `subscribingState`:  A state object that provides information on whether the object has already been subscribed to or not.
    - `state`: An object of type `StateType` which resolves the generic state type for the return value.

- returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose type matches the `state` parameter.

#### Errors
```swift
enum FirebaseSubscriptionError: ErrorType {
    case NoData(path: String)
    case MalformedData(path: String)
}
```

An error that occurred parsing data from a Firebase event.

- `NoData`:    The snapshot for the event contained no data
- `MalformedData`:  The data in the snapshot could not be parsed as JSON

#### Subscribing state
A protocol to be adopted by sub states that hold a flag indicating whether an object has been subscribed to in Firebase or not.



### Generic Actions
These are actions that can be dispatched to your store that are generic and scoped to a data object that you associate. This allows them to be easily parsed in your reducers.

#### Object added
> `ObjectAdded<T: Unmarshaling>: Action`

Generic action indicating that an object was added from Firebase and should be stored in the app state. The action is scoped to the object type that was added.
- Parameters:
    - T:      The type of object that was added. Must conform to `Unmarshaling` to be parsed from JSON.
    - object: The actual object that was added.

#### Object changed
> `ObjectChanged<T: Unmarshaling>: Action`

Generic action indicating that an object was changed in Firebase and should be modified in the app state. The action is scoped to the object type that was added.
- Parameters:
    - T:       The type of object that was changed. Must conform to `Unmarshaling` to be parsed from JSON.
    - object:  The actual object that was changed.

#### Object removed
> `ObjectRemoved<T: Unmarshaling>: Action`

Generic action indicating that an object was removed from Firebase and should be removed in the app state. The action is scoped to the object type that was added.
- Parameters:
    - T:       The type of object that was removed. Must conform to `Unmarshaling` to be parsed from JSON.
    - object:  The actual object that was removed.

#### Object errored
> `ObjectErrored<T>: Action`

Generic action indicating that an object has an error when parsing from a Firebase event. The action is scoped to the object type that was added.
- Parameters:
    - T:       The type of object that produced the error
    - error:   An optional error indicating the problem that occurred

#### Object subscribed
> `ObjectSubscribed<T>: Action`

Generic action indicating that an object was subscribed to in Firebase. The action is scoped to the object type that was added.
- Parameters:
    - T:           The type of object that can be subscribed or not
    - subscribed:  Flag indicating subscription status


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
