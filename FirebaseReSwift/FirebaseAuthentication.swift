/*
 |  _   ____   ____   _
 | | |‾|  ⚈ |-| ⚈  |‾| |
 | | |  ‾‾‾‾| |‾‾‾‾  | |
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
public enum FirebaseAuthenticationError: Error {
    case logInMissingUserId
    case signUpFailedLogIn
    case currentUserNotFound
}

/**
 An event type regarding user authentication
 
 - `PasswordChanged`:   The password for the user was successfully changed
 - `EmailChanged`:      The email for the user was successfully changed
 - `PasswordReset`:     The user was sent a reset password email
 - `EmailVerificationSent`: The user was an email confirmation email
 */
public enum FirebaseAuthenticationEvent {
    case passwordChanged
    case emailChanged
    case passwordReset
    case emailVerificationSent
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
        guard let currentApp = currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
        guard let user = auth.currentUser else { return nil }
        return user.uid
    }
    
    /**
     Attempts to retrieve user's email verified status.
     
     - returns: `True` if email has been verified, otherwise `false`.
     */
    public func getUserEmailVerified() -> Bool {
        guard let currentApp = currentApp, let auth = FIRAuth(app: currentApp) else { return false }
        guard let user = auth.currentUser else { return false }
        return user.isEmailVerified
    }
    
    /**
     Reloads the current user object. This is useful for checking whether `emailVerified` is now true.
     */
    public func reloadCurrentUser<T: StateType>() -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
            guard let user = auth.currentUser else { return nil }
            user.reload { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else {
                    store.dispatch(UserIdentified(userId: user.uid, emailVerified: user.isEmailVerified))
                }
            }
            return nil
        }
    }
    
    /**
     Sends verification email to specified user, or current user if not specified.
     */
    public func sendEmailVerification<T: StateType>(to user: FIRUser?) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            let emailUser: FIRUser
            if let user = user {
                emailUser = user
            } else {
                guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
                guard let user = auth.currentUser else { return nil }
                emailUser = user
            }
            emailUser.sendEmailVerification { error in
                if let error = error {
                    store.dispatch(EmailVerificationError(error: error))
                } else {
                    store.dispatch(UserAuthenticationAction(action: .emailVerificationSent))
                }
            }
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
     
     - returns:     An `ActionCreator` (`(state: StateType, store: StoreType) -> Action?`) whose
     type matches the state type associated with the store on which it is dispatched.
     */
    public func logInUser<T: StateType>(with email: String, and password: String) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
            auth.signIn(withEmail: email, password: password) { user, error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else if let user = user {
                    store.dispatch(UserLoggedIn(userId: user.uid, emailVerified: user.isEmailVerified, email: email))
                } else {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.logInMissingUserId))
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
    public func signUpUser<T: StateType>(with email: String, and password: String, completion: ((_ userId: String?) -> Void)?) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
            auth.createUser(withEmail: email, password: password) { user, error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                    completion?(nil)
                } else if let user = user {
                    store.dispatch(UserSignedUp(userId: user.uid, email: email))
                    if let completion = completion {
                        completion(user.uid)
                    } else {
                        store.dispatch(UserLoggedIn(userId: user.uid, email: email))
                    }
                } else {
                    store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.signUpFailedLogIn))
                    completion?(nil)
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
    public func changeUserPassword<T: StateType>(to newPassword: String) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
            guard let user = auth.currentUser else {
                store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.currentUserNotFound))
                return nil
            }
            user.updatePassword(newPassword) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.passwordChanged))
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
    public func changeUserEmail<T: StateType>(to email: String) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
            guard let user = auth.currentUser else {
                store.dispatch(UserAuthFailed(error: FirebaseAuthenticationError.currentUserNotFound))
                return nil
            }
            user.updateEmail(email) { error in
                if let error = error {
                    store.dispatch(UserAuthFailed(error: error))
                } else {
                    store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.emailChanged))
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
    public func resetPassword<T: StateType>(for email: String) -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
            auth.sendPasswordReset(withEmail: email) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        store.dispatch(UserAuthFailed(error: error))
                    } else {
                        store.dispatch(UserAuthenticationAction(action: FirebaseAuthenticationEvent.passwordReset))
                    }
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
    public func logOutUser<T: StateType>() -> (_ state: T, _ store: Store<T>) -> Action? {
        return { state, store in
            do {
                guard let currentApp = self.currentApp, let auth = FIRAuth(app: currentApp) else { return nil }
                try auth.signOut()
                store.dispatch(UserLoggedOut())
            } catch {
                store.dispatch(UserAuthFailed(error: error))
            }
            return nil
        }
    }

}


// MARK: - User actions

/**
 Action indicating that the user has just successfully logged in with email and password.
 - Parameters
    - userId: The id of the user
    - emailVerified: Status of user’s email verification
    - email: Email address of user
 */
public struct UserLoggedIn: FirebaseAuthenticationAction {
    public var userId: String
    public var emailVerified: Bool
    public var email: String
    
    public init(userId: String, emailVerified: Bool = false, email: String) {
        self.userId = userId
        self.emailVerified = emailVerified
        self.email = email
    }
}

/**
 Action indicating that the user has just successfully signed up.
 - Parameters
    - userId: The id of the user
    - email: Email address of user
 */
public struct UserSignedUp: FirebaseAuthenticationAction {
    public var userId: String
    public var email: String
    
    public init(userId: String, email: String) {
        self.userId = userId
        self.email = email
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
    public var error: Error
    public init(error: Error) { self.error = error }
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
    public var error: Error
    public init(error: Error) { self.error = error }
}
