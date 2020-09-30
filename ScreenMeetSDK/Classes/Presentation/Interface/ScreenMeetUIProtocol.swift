//
//  ScreenMeetUIProtocol.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 04.09.2020.
//

import Foundation

/// Implement ScreenMeetUI protocol to implement all user interactions in style of your application UI
public protocol ScreenMeetUIProtocol {
    
    /// Display a dialog requesting a session code from the user.
    func showSessionCodeDialog(completion: @escaping (String) -> Void)
    
    /// Display a dialog requesting their approval for screen sharing.
    func showAppMirrorPermissionDialog(completion: @escaping (Bool) -> Void)
    
    /// Display a dialog requesting their approval for disconnect session.
    func showDisconnectSessionDialog(completion: @escaping (Bool) -> Void)
    
    /// Display a dialog requesting their approval for laser pointer.
    func showLaserPointerPermissionDialog(completion: @escaping (Bool) -> Void)
    
    /// Display a dialog requesting approval to stop laser pointer.
    func dismissLaserPointerPermissionDialog()
}

extension ScreenMeetUIProtocol {
    
    func rootController<T: UIViewController>() -> T? {
        let presentedController = UIApplication.shared.keyWindow?.rootViewController
        if let root = presentedController as? T {
            return root
        } else if let topController = (presentedController as? UINavigationController)?.topViewController as? T {
            return topController
        } else if let tabController = (presentedController as? UITabBarController)?.selectedViewController as? T {
            return tabController
        }
        
        return nil
    }
}
