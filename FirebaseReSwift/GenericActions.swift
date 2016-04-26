/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import ReSwift
import Marshal

public struct ObjectAdded<T: Unmarshaling>: Action {
    public var object: T
    public init(object: T) { self.object = object }
}

public struct ObjectChanged<T: Unmarshaling>: Action {
    public var object: T
    public init(object: T) { self.object = object }
}

public struct ObjectRemoved<T: Unmarshaling>: Action {
    public var object: T
    public init(object: T) { self.object = object }
}

public struct ObjectErrored<T>: Action {
    public var error: ErrorType?
    public init(error: ErrorType?) { self.error = error }
}

public struct ObjectSubscribed<T>: Action {
    public var subscribed: Bool
    public init(subscribed: Bool) { self.subscribed = subscribed }
}

public protocol SubscribingState: StateType {
    var subscribed: Bool { get }
}

public struct HydrateObject<T: Hydrating>: Action {
    public var object: T
    public init(object: T) { self.object = object }
}

public protocol Hydrating {
    var hydrated: Bool { get }
}
