//
//  CustomDialogs.swift
//  FullExample
//
//  Created by Ivan Makhnyk on 15.09.2020.
//

import Foundation
import ScreenMeetSDK

class CustomDialogs: ScreenMeetUIProtocol {
    func showSessionCodeDialog(completion: @escaping (String) -> Void) {
            if let rootVC = rootViewController() {
            let alert = UIAlertController(title: "ScreenMeet", message: "Enter your session code", preferredStyle: UIAlertController.Style.alert)
            alert.addTextField { (textField) in
                textField.placeholder = "code"
                textField.keyboardType = .numberPad
            }
            alert.addAction(UIAlertAction(title: "Start", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0]
                completion(textField?.text ?? "")
            }))

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                  completion("")
            }))
            
            rootVC.present(alert, animated: true, completion: nil)
        } else {
            //TODO can't show Alert for user
            completion("")
        }
    }
    
    func showAppMirrorPermissionDialog(completion: @escaping (Bool) -> Void) {
        if let rootVC = rootViewController() {
            let alert = UIAlertController(title: "ScreenMeet", message: "Do you agree to share screen?", preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "Agree", style: .default, handler: { (action: UIAlertAction!) in
                  completion(true)
            }))

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                  completion(false)
            }))
            
            rootVC.present(alert, animated: true, completion: nil)
        } else {
            //TODO can't show Alert for user
            completion(true)
        }
    }
    
    func showDisconnectSessionDialog(completion: @escaping (Bool) -> Void) {
        if let rootVC = rootViewController() {
            let alert = UIAlertController(title: "ScreenMeet", message: "Are you sure to stop session?", preferredStyle: UIAlertController.Style.alert)

            alert.addAction(UIAlertAction(title: "Stop", style: .default, handler: { (action: UIAlertAction!) in
                  completion(true)
            }))

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                  completion(false)
            }))
            
            rootVC.present(alert, animated: true, completion: nil)
        } else {
            //TODO can't show Alert for user
            completion(true)
        }
    }
    
    var lpRequestAlert: UIAlertController! = nil

    func showLaserPointerPermissionDialog(completion: @escaping (Bool) -> Void) {
        if lpRequestAlert != nil {
            //second request LP while first one is not answered
            return
        }
        if let rootVC = rootViewController() {
            self.lpRequestAlert = UIAlertController(title: "ScreenMeet", message: "Do you agree to start Laser pointer?", preferredStyle: UIAlertController.Style.alert)

            self.lpRequestAlert.addAction(UIAlertAction(title: "Agree", style: .default, handler: { (action: UIAlertAction!) in
                self.lpRequestAlert = nil
                completion(true)
            }))

            self.lpRequestAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                self.lpRequestAlert = nil
                completion(false)
            }))
            
            rootVC.present(self.lpRequestAlert, animated: true, completion: nil)
        } else {
            //TODO can't show Alert for user
            self.lpRequestAlert = nil
            completion(true)
        }
    }
    
    func dismissLaserPointerPermissionDialog() {
        if lpRequestAlert == nil {
            return
        }
        self.lpRequestAlert.dismiss(animated: true, completion: nil)
        self.lpRequestAlert = nil
    }

    private func rootViewController() -> UIViewController? {
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabBarController = rootViewController as? UITabBarController {
            rootViewController = tabBarController.selectedViewController
        }
        return rootViewController
    }
}

