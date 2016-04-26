/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase
import Marshal
import ReSwift

public protocol FirebaseAccess {
    static var sharedAccess: FirebaseAccess { get }
    var ref: Firebase { get }
}

public extension FirebaseAccess {
    
    // MARK: - Query helpers
    
    public func newObjectId() -> String? {
        guard let id = ref.childByAutoId().key else { return nil }
        return id
    }
    
    
    // MARK: - Public API
    
    public func updateObject<T>(ref: Firebase, parameters: MarshaledObject, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            ref.updateChildValues(parameters)
            return nil
        }
    }
    
    public func createObject<T>(ref: Firebase, parameters: MarshaledObject, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            ref.setValue(parameters)
            return nil
        }
    }
    
}
