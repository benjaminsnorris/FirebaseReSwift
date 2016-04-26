/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import ReSwift
import Marshal

public protocol EndpointNaming {
    static var endpointName: String { get }
}

public protocol Identifiable {
    var id: String { get }
}

public typealias EndpointNamingIdentifiable = protocol<EndpointNaming, Identifiable>


public struct ObjectAdded<T: Unmarshaling>: Action {
    var object: T
}

public struct ObjectChanged<T: Unmarshaling>: Action {
    var object: T
}

public struct ObjectRemoved<T: Unmarshaling>: Action {
    var object: T
}

public struct ObjectErrored<T>: Action {
    var error: ErrorType?
}

public struct ObjectSubscribed<T>: Action {
    var subscribed: Bool
}

public protocol SubscribingState: StateType {
    var subscribed: Bool { get }
}

public struct HydrateObject<T: Hydrating>: Action {
    var object: T
}

public protocol Hydrating {
    var hydrated: Bool { get }
}


public struct FirebaseState: StateType {
    static var idKey: String { return "id" }
}

public typealias FirebaseActionCreator = Store<FirebaseState>.ActionCreator
