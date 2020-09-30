//
//  LaserPointer.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 03.09.2020.
//

import Foundation

final class LaserPointer {
    
    private var laserPointerCoorX = UIScreen.main.bounds.width / 2
    
    private var laserPointerCoorY = UIScreen.main.bounds.height / 2
    
    private static let laserPointerSize: CGFloat = 20
    
    private static let laserPointerTapSize: CGFloat = 25
    
    private var laserPointerImage = LaserPointerImageView(frame: CGRect(x: 0, y: 0, width: LaserPointer.laserPointerSize, height: LaserPointer.laserPointerSize))
    
    private var laserPointerTimer: Timer? = nil
    
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
    
    func startLaserPointerSession() {
        if laserPointerTimer == nil {
            self.laserPointerImage.setRounded()
            laserPointerTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
                if let v = self.rootViewController()?.view {
                    self.laserPointerImage.center = CGPoint(x: self.laserPointerCoorX, y: self.laserPointerCoorY)
                    if v != self.laserPointerImage.superview {
                        v.addSubview(self.laserPointerImage)
                    }
                }
            }
        } else {
            Logger.log.warning("Laser pointer session already started")
        }
    }
    
    func updateLaserPointerCoors(_ x: CGFloat, _ y: CGFloat) {
        if x < 0 {
            self.laserPointerCoorX = 0
        } else if x > UIScreen.main.bounds.width {
            self.laserPointerCoorX = UIScreen.main.bounds.width
        } else {
            self.laserPointerCoorX = x
        }
        
        let y = UIScreen.main.bounds.height - y
        if y < 0 {
            self.laserPointerCoorY = 0
        } else if y > UIScreen.main.bounds.height {
            self.laserPointerCoorY = UIScreen.main.bounds.height
        } else {
            self.laserPointerCoorY = y
        }
    }

    func updateLaserPointerCoorsWithTap(_ x: CGFloat, _ y: CGFloat) {
        updateLaserPointerCoors(x, y)
        UIView.animate(withDuration: 0.2, animations: {
            self.laserPointerImage.frame.size.width = LaserPointer.laserPointerTapSize
            self.laserPointerImage.frame.size.height = LaserPointer.laserPointerTapSize
            self.laserPointerImage.frame.origin.x = self.laserPointerCoorX - LaserPointer.laserPointerTapSize / 2
            self.laserPointerImage.frame.origin.y = self.laserPointerCoorY - LaserPointer.laserPointerTapSize / 2
            self.laserPointerImage.layer.backgroundColor = UIColor.red.withAlphaComponent(1).cgColor
            self.laserPointerImage.layoutIfNeeded()
        }) {_ in
            UIView.animate(withDuration: 0.2, animations: {
                self.laserPointerImage.frame.size.width = LaserPointer.laserPointerSize
                self.laserPointerImage.frame.size.height = LaserPointer.laserPointerSize
                self.laserPointerImage.frame.origin.x = self.laserPointerCoorX - LaserPointer.laserPointerSize / 2
                self.laserPointerImage.frame.origin.y = self.laserPointerCoorY - LaserPointer.laserPointerSize / 2
                self.laserPointerImage.layer.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor
                self.laserPointerImage.layoutIfNeeded()
            })
        }
    }

    func stopLaserPointerSession() {
        if laserPointerTimer == nil {
            Logger.log.warning("Laser pointer session already stoped")
        } else {
            self.laserPointerImage.removeFromSuperview()
            laserPointerTimer?.invalidate()
            laserPointerTimer = nil
        }
    }
}

fileprivate final class LaserPointerImageView: UIImageView {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
    
    func setRounded() {
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.red.withAlphaComponent(0.5).cgColor
        self.layer.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor
        self.clipsToBounds = true
        self.layer.cornerRadius = (self.frame.width / 2)
        self.layer.masksToBounds = true
    }
}
