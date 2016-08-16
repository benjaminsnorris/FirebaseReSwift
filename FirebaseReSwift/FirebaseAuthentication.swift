/*
 |  _   ____   ____   _
 | ⎛ |‾|  ⚈ |-| ⚈  |‾| ⎞
 | ⎝ |  ‾‾‾‾| |‾‾‾‾  | ⎠
 |  ‾        ‾        ‾
 */

import Foundation
import Firebase
import ReSwift
import Marshal

/// Empty protocol to help categorize actions
public protocol FirebaseAuthenticationAction: Action { }

/**
 An error that occurred authenticating with Firebase.
 
 - `LogInMissingUserId`:    The auth payload contained no user id
 - `SignUpFailedLogIn`:     The user was signed up, but could not be logged in
 - `CurrentUserNotFound`:   The data for the current user could not be found
 */
public enum FirebaseAuthenticationError: ErrorType {
    case LogInMissingUserId
    case SignUpFailedLogIn
    case CurrentUserNotFound
}

/**
 An event type regarding user authentication
 
 - `UserSignedUp`:      The user successfully signed up
 - `PasswordChanged`:   The password for the user was successfully changed
 - `EmailChanged`:      The email for the user was successfully changed
 - `PasswordReset`:     The user was sent a reset password email
 - `EmailVerificationSent`: The user was an email confirmation email
 */
public enum FirebaseAuthenticationEvent {
    case UserSignedUp
    case PasswordChanged
    case EmailChanged
    case PasswordReset
    case EmailVerificationSent
}

public extension FirebaseAccess {
    
    /**
     Defaults `currentApp` to default Firebase app.
     */
    public var currentApp: FIRApp? {
        return FIRApp.defaultApp()
    }

    /**
     Attempts to retrieve the user's authentication id. If successful, it is returned.
     
     - returns: The user's authentication id, or nil if not authenticated
     */
    public func getUserId() -> String? {
        guard let currentApp = currentApp, auth = FIRAuth(app: currentApp) else { return nil }
        guard let user = auth.currentUser else { return nil }
        return user.uid
    }
    
    /**
     Attempts to retrieve user's email verified status.
     
     - returns: `True` if email has been verified, otherwise `false`.
     */
    public func getUserEmailVerified() -> Bool {
        guard let currentApp = currentApp, auth = FIRAuth(app: currentApp) else { return false }
        guard let user = auth.currentUser else { return false }
        return user.emailVerified
    }
    
    /**
 
     */
    public func sendEmailVerification<T: StateType>(state: T, store: Store<T>) -> Action? {
        guard let currentApp = currentApp, auth = FIRAuth(app: currentApp) else { return nil }
        guard let user = auth.currentUser else { return nil }
        user.sendEmailVerificationWithCompletion { error in
            if let error = error {
                store.dispatch(EmailVerificationError(error: error))
            } else {
                store.dispatch(UserAuthenticationAction(action: .EmailVerificationSent))
            }
        }
        return nil
    }
    
    /**
     Authenticates the user with email address and password. If successful, dispatches an action
     with the user’s id (`UserLoggedIn`), otherwise dispatches a failed action with an error
     (`UserAuthFailed`).
     
     - Parameters:
        - email:    The user’s email address
        - password: The user’s password
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func logInUser<T: StateType>(email: String, password: String) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, auth = FIRAuth(app: currentApp) else { return nil }
            auth.signInWithEmail(email, password: password) { user, error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else if let user = user {
                    store.dispatch(UserLoggedIn(userId: user.uid, emailVerified: user.emailVerified))
                } else {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.LogInMissingUserId))
                }
            }
            return nil
        }
    }
    
    /**
     Creates a user with the email address and password.
     
     - Parameters:
        - email:    The user’s email address
        - password: The user’s password
        - completion: Optional closure that takes in the new user's `uid` if possible
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func signUpUser<T: StateType>(email: String, password: String, completion: ((userId: String?) -> Void)?) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, auth = FIRAuth(app: currentApp) else { return nil }
            auth.createUserWithEmail(email, password: password) { user, error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                    completion?(userId: nil)
                } else if let user = user {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.UserSignedUp))
                    if let completion = completion {
                        completion(userId: user.uid)
                    } else {
                        store.dispatch(UserLoggedIn(userId: user.uid))
                    }
                } else {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.SignUpFailedLogIn))
                    completion?(userId: nil)
                }
            }
            return nil
        }
    }
    
    /**
     Change a user’s password.
     
     - Parameters:
        - newPassword:  The new password for the user
     
     - returns:         An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func changeUserPassword<T: StateType>(newPassword: String) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, auth = FIRAuth(app: currentApp) else { return nil }
            guard let user = auth.currentUser else {
                store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.CurrentUserNotFound))
                return nil
            }
            user.updatePassword(newPassword) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.PasswordChanged))
                }
            }
            return nil
        }
    }
    
    /**
     Change a user’s email address.
     
     - Parameters:
        - email:        The new email address for the user
     
     - returns:         An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func changeUserEmail<T: StateType>(email: String) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, auth = FIRAuth(app: currentApp) else { return nil }
            guard let user = auth.currentUser else {
                store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.CurrentUserNotFound))
                return nil
            }
            user.updateEmail(email) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.EmailChanged))
                }
            }
            return nil
        }
    }
    
    /**
     Send the user a reset password email.
     
     - Parameters:
        - email:    The user’s email address
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func resetPassword<T: StateType>(email: String) -> (state: T, store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, auth = FIRAuth(app: currentApp) else { return nil }
            auth.sendPasswordResetWithEmail(email) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.PasswordReset))
                }
            }
            return nil
        }
    }
    
    /**
     Unauthenticates the current user and dispatches a `UserLoggedOut` action.
     
     - returns: An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func logOutUser<T: StateType>(state: T, store: Store<T>) -> Action? {
        do {
            guard let currentApp = self.currentApp, auth = FIRAuth(app: currentApp) else { return nil }
            try auth.signOut()
            store.dispatch(UserLoggedOut())
        } catch {
            store.dispatch(UserAuthFailed(error: error))
        }
        return nil
    }

}


// MARK: - User actions

/**
 Action indicating that the user has just successfully logged in with email and password.
 - Parameter userId: The id of the user
 */
public struct UserLoggedIn: FirebaseAuthenticationAction {
    public var userId: String
    public var emailVerified: Bool
    public init(userId: String, emailVerified: Bool = false) {
        self.userId = userId
        self.emailVerified = emailVerified
    }
}

/**
 General action regarding user authentication
 - Parameter action: The authentication action that occurred
 */
public struct UserAuthenticationAction: FirebaseAuthenticationAction {
    public var action: FirebaseAuthenticationEvent
    public init(action: FirebaseAuthenticationEvent) { self.action = action }
}

/**
 Action indicating that a failure occurred during authentication.
 - Parameter error: The error that produced the failure
 */
public struct UserAuthFailed: FirebaseSeriousErrorAction {
    public var error: ErrorType
    public init(error: ErrorType) { self.error = error }
}

/**
 Action indicating that the user is properly authenticated.
 - Parameter userId: The id of the authenticated user
 */
public struct UserIdentified: FirebaseAuthenticationAction {
    public var userId: String
    public var emailVerified: Bool
    public init(userId: String, emailVerified: Bool = false) {
        self.userId = userId
        self.emailVerified = emailVerified
    }
}

/**
 Action indicating that the user has been unauthenticated.
 */
public struct UserLoggedOut: FirebaseAuthenticationAction {
    public init() { }
}

/**
 Action indication an error when sending email verification.
 - Parameter error: The error that occurred
 */
public struct EmailVerificationError: FirebaseMinorErrorAction {
    public var error: ErrorType
    public init(error: ErrorType) { self.error = error }
}
