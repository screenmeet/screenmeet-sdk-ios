//
//  ScreenMeetUI.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 26.08.2020.
//

import UIKit

final class ScreenMeetUI {
    
    lazy private var codeView: CodeView = {
        CodeView()
    }()
    
    lazy private var popupViewController: PopupViewController? = {
        let popup = UIStoryboard(name: "Popup", bundle: ScreenMeetUI.currentBundle).instantiateInitialViewController() as? PopupViewController
        popup?.modalPresentationStyle = .overFullScreen
        popup?.modalTransitionStyle = .crossDissolve
        return popup
    }()
    
    private var showSessionCodeDialogCompletion: ((String) -> Void)?
    
    private var isLaserPointerDialogActive: Bool = false
    
    static var currentBundle: Bundle {
        let frameworkBundle = Bundle(for: self)
        
        guard let resourceBundleURL = frameworkBundle.url(forResource: "ScreenMeetResource", withExtension: "bundle") else {
            fatalError("ScreenMeetResource.bundle not found")
        }
        
        guard let resourceBundle = Bundle(url: resourceBundleURL) else {
            fatalError("Cannot access ScreenMeetResource.bundle")
        }
        
        
        return resourceBundle
    }
}

extension ScreenMeetUI: CodeViewDelegate {
    
    func codeViewDidChange(codeView: CodeView) { }
    
    func codeViewFinishChange(codeView: CodeView) {
        showSessionCodeDialogCompletion?(codeView.code)
        showSessionCodeDialogCompletion = nil
        popupViewController?.dismiss(animated: true, completion: nil)
    }
}

extension ScreenMeetUI: ScreenMeetUIProtocol {
    
    func showSessionCodeDialog(completion: @escaping (String) -> Void) {
        self.showSessionCodeDialogCompletion = completion
        guard let rootVC = self.rootController(), let popupViewController = self.popupViewController else { return }
        
        self.codeView.delegate = self
        self.codeView.clear()
        let inputData = PopupInputData(title: "Enter code", cancelButtonTitle: "Cancel", contentView: self.codeView, onCancelTap: { (popup) in
            popup.dismiss(animated: true, completion: nil)
        })
        popupViewController.setup(with: inputData)
        
        rootVC.present(popupViewController, animated: true, completion: nil)
        self.codeView.firstResponder()
    }
    
    func showAppMirrorPermissionDialog(completion: @escaping (Bool) -> Void) {
        guard let rootVC = self.rootController(), let popupViewController = self.popupViewController else { return }
        
        let inputData = PopupInputData(title: "Do you agree to screenshare?", actionButtonTitle: "Yes", cancelButtonTitle: "No", onActiveTap: { (popup) in
            completion(true)
            popup.dismiss(animated: true, completion: nil)
        }, onCancelTap: { (popup) in
            completion(false)
            popup.dismiss(animated: true, completion: nil)
        })
        popupViewController.setup(with: inputData)
        
        rootVC.present(popupViewController, animated: true, completion: nil)
    }
    
    func showDisconnectSessionDialog(completion: @escaping (Bool) -> Void) {
        guard let rootVC = self.rootController(), let popupViewController = self.popupViewController else { return }
        
        let inputData = PopupInputData(title: "Do you agree to disconnect session?", actionButtonTitle: "Yes", cancelButtonTitle: "No", onActiveTap: { (popup) in
            completion(true)
            popup.dismiss(animated: true, completion: nil)
        }, onCancelTap: { (popup) in
            completion(false)
            popup.dismiss(animated: true, completion: nil)
        })
        popupViewController.setup(with: inputData)
        
        rootVC.present(popupViewController, animated: true, completion: nil)
    }
    
    func showLaserPointerPermissionDialog(completion: @escaping (Bool) -> Void) {
        guard let rootVC = self.rootController(), let popupViewController = self.popupViewController else { return }
        
        let inputData = PopupInputData(title: "Do you agree to start Laser pointer?", actionButtonTitle: "Yes", cancelButtonTitle: "No", onActiveTap: { [weak self] (popup) in
            completion(true)
            popup.dismiss(animated: true, completion: {
                self?.isLaserPointerDialogActive = false
            })
        }, onCancelTap: { [weak self] (popup) in
            completion(false)
            popup.dismiss(animated: true, completion: {
                self?.isLaserPointerDialogActive = false
            })
        })
        popupViewController.setup(with: inputData)
        
        rootVC.present(popupViewController, animated: true, completion: { [weak self] in
            self?.isLaserPointerDialogActive = true
        })
    }
    
    func dismissLaserPointerPermissionDialog() {
        guard isLaserPointerDialogActive else { return }
        self.popupViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.isLaserPointerDialogActive = true
        })
    }
}
