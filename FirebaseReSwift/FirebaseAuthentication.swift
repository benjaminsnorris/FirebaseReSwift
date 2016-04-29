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
 
 - `LogInError`:            The user could not log in
 - `SignUpError`:           The user could not sign up
 - `ChangePasswordError`:   The password for the user could not be changed
 - `ChangeEmailError`:      The email for the user could not be chagned
 - `ResetPasswordError`:    The password for the user could not be reset
 - `LogInMissingUserId`:    The auth payload contained no user id
 */
public enum FirebaseAuthenticationError: ErrorType {
    case LogInError(error: ErrorType)
    case SignUpError(error: ErrorType)
    case ChangePasswordError(error: ErrorType)
    case ChangeEmailError(error: ErrorType)
    case ResetPasswordError(error: ErrorType)
    case LogInMissingUserId
}

/**
 An action type regarding user authentication
 
 - `UserSignedUp`:      The user successfully signed up
 - `PasswordChanged`:   The password for the user was successfully changed
 - `EmailChanged`:      The email for the user was successfully changed
 - `PasswordReset`:     The user was sent a reset password email
 */
public enum FirebaseAuthenticationAction {
    case UserSignedUp(email: String, password: String)
    case PasswordChanged
    case EmailChanged
    case PasswordReset
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
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.LogInError(error: error)))
                } else if let userId = auth.uid {
                    store.dispatch(UserLoggedIn(userId: userId))
                } else {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.LogInMissingUserId))
                }
            }
            return nil
        }
    }
    
    /**
     Creates a user with the email address and password. On success, an action is dispatched
     to log the user in.
     
     - Parameters:
        - email:    The user’s email address
        - password: The user’s password
        - state:    An object of type `StateType` which resolves the generic state type
        for the return value.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    func signUpUser<T>(email: String, password: String, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.ref.createUser(email, password: password, withValueCompletionBlock: { error, object in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.SignUpError(error: error)))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationAction.UserSignedUp(email: email, password: password)))
                    store.dispatch(self.logInUser(email, password: password, state: state))
                }
            })
            return nil
        }
    }
    
    /**
     Change a user’s password.
     
     - Parameters:
        - email:        The user’s email address
        - oldPassword:  The previous password
        - newPassword:  The new password for the user
        - state:        An object of type `StateType` which resolves the generic state type
        for the return value.
     
     - returns:         An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) 
     whose type matches the `state` parameter.
     */
    func changeUserPassword<T>(email: String, oldPassword: String, newPassword: String, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.ref.changePasswordForUser(email, fromOld: oldPassword, toNew: newPassword) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.ChangePasswordError(error: error)))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationAction.PasswordChanged))
                }
            }
            return ActionCreatorDispatched(dispatchedIn: "changeUserPassword")
        }
    }
    
    /**
     Change a user’s email address.
     
     - Parameters:
        - email:        The user’s previous email address
        - password:     The user’s password
        - newEmail:     The new email address for the user
        - state:        An object of type `StateType` which resolves the generic state type
        for the return value.
     
     - returns:         An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) 
     whose type matches the `state` parameter.
     */
    func changeUserEmail<T>(email: String, password: String, newEmail: String, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.ref.changeEmailForUser(email, password: password, toNewEmail: newEmail) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.ChangeEmailError(error: error)))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationAction.EmailChanged))
                }
            }
            return ActionCreatorDispatched(dispatchedIn: "changeUserEmail")
        }
    }
    
    /**
     Send the user a reset password email.
     
     - Parameters:
        - email:    The user’s email address
        - state:    An object of type `StateType` which resolves the generic state type
        for the return value.
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the `state` parameter.
     */
    func resetPassword<T>(email: String, state: T) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            self.ref.resetPasswordForUser(email) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.ResetPasswordError(error: error)))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationAction.PasswordReset))
                }
            }
            return ActionCreatorDispatched(dispatchedIn: "resetPassword")
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
            return ActionCreatorDispatched(dispatchedIn: "logOutUser")
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
 General action regarding user authentication
 - Parameter action: The authentication action that occurred
 */
public struct UserAuthenticationAction: Action {
    public var action: FirebaseAuthenticationAction
    public init(action: FirebaseAuthenticationAction) { self.action = action }
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
