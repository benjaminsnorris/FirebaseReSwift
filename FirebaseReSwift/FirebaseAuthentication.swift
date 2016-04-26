/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase
import ReSwift

/**
 An error that occurred authenticating with Firebase.
 
 - `NoUserId`:    The auth payload contained no user id
 */
enum FirebaseAuthenticationError: ErrorType {
    case NoUserId
}

public extension FirebaseAccess {
    
    /**
     Attempts to retrieve the user's authentication id. If successful, dispatches an action
     with the id (`UserIdentified`).
     
     - Parameter state: An object of type `StateType` which resolves the generic state type
     for the return value.

     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func getUserId<T>(state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            guard let authData = self.ref.authData, userId = authData.uid else { return nil }
            store.dispatch(UserIdentified(userId: userId))
            return nil
        }
    }
    
    /**
     Authenticates the user with email address and password. If successful, dispatches an action
     with the user’s id (`UserLoggedIn`), otherwise dispatches a failed action with an error
     (`UserAuthFailed`).
     
     - Parameters:
        - email:    The user’s email address
        - password: The user’s password
        - state:    An object of type `StateType` which resolves the generic state type
        for the return value.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    func logInUser<T>(email: String, password: String, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.ref.authUser(email, password: password) { error, auth in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else if let userId = auth.uid {
                    store.dispatch(UserLoggedIn(userId: userId))
                } else {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.NoUserId))
                }
            }
            return nil
        }
    }
    
    /**
     Unauthenticates the current user and dispatches a `UserLoggedOut` action.
     
     - Parameter state: An object of type `StateType` which resolves the generic state type
     for the return value.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    public func logOutUser<T>(state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.ref.unauth()
            store.dispatch(UserLoggedOut())
            return nil
        }
    }

}


// MARK: - User actions

/**
 Action indicating that the user has just successfully logged in with email and password.
 - Parameter userId: The id of the user
 */
public struct UserLoggedIn: Action {
    public var userId: String
    public init(userId: String) { self.userId = userId }
}

/**
 Action indicating that a failure occurred during authentication.
 - Parameter error: The error that produced the failure
 */
public struct UserAuthFailed: Action {
    public var error: ErrorType
    public init(error: ErrorType) { self.error = error }
}

/**
 Action indicating that the user is properly authenticated.
 - Parameter userId: The id of the authenticated user
 */
public struct UserIdentified: Action {
    public var userId: String
    public init(userId: String) { self.userId = userId }
}

/**
 Action indicating that the user has been unauthenticated.
 */
public struct UserLoggedOut: Action {
    public init() { }
}
