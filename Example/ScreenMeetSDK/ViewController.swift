//
//  ViewController.swift
//  ScreenMeetSDK
//
//  Created by Vasyl Morarash on 06/19/2020.
//  Copyright (c) 2020 Vasyl Morarash. All rights reserved.
//

import UIKit
import ScreenMeetSDK

class ViewController: UIViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var imageView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let giphyImageView = UIImageView.fromGif(frame: imageView.bounds, resourceName: "giphy") else { return }
        imageView.addSubview(giphyImageView)
        giphyImageView.startAnimating()
        
        
        print("ScreenMeetSDK version: \(ScreenMeet.version())")
        
        ScreenMeet.shared.registerLifecycleListener(self)
        ScreenMeet.shared.registerSessionEventListener(self)
        
        pauseButton.isHidden = true
        loadingIndicator.isHidden = true
        startButton.setTitle("Start Session", for: .normal)
        pauseButton.setTitle("Pause", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenMeet.shared.localVideoSource.frameProcessor.setConfidential(view: startButton)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ScreenMeet.shared.localVideoSource.frameProcessor.unsetConfidential(view: startButton)
    }

    @IBAction func startSessionButtonTapped(_ sender: Any) {
        if ScreenMeet.shared.session == nil {
            ScreenMeet.shared.interface.showSessionCodeDialog { [weak self] (code) in
                self?.pauseButton.isHidden = true
                self?.startButton.isHidden = true
                self?.loadingIndicator.isHidden = false
                
                ScreenMeet.shared.connect(code: code) { (result) in
                    switch result {
                    case .success(let session):
                        print("Session owner name: \(session.ownerName ?? "-")")
                        self?.startButton.setTitle("Stop Session", for: .normal)
                        self?.pauseButton.isHidden = false
                    case .failure(let error):
                        self?.startButton.setTitle("Start Session", for: .normal)
                        self?.pauseButton.isHidden = true
                        self?.showToast("\(error)")
                    }
                    self?.startButton.isHidden = false
                    self?.loadingIndicator.isHidden = true
                }
            }
        } else {
            ScreenMeet.shared.disconnect()
        }
    }
    
    @IBAction func pauseButtonPressed(_ sender: UIButton) {
        if ScreenMeet.shared.session?.lifecycleState == .pause {
            ScreenMeet.shared.session?.resume()
        } else {
            ScreenMeet.shared.session?.pause()
        }
    }
}

extension UIViewController {

    func showToast(_ message : String, font: UIFont = .systemFont(ofSize: 12.0)) {

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

extension ViewController: LifecycleListener {
    
    func onStreaming(oldState: ScreenMeet.Session.State, streamingReason: ScreenMeet.Session.State.StreamingReason) {
        switch streamingReason {
        case .sessionResumed:
            showToast("Session Resumed")
            pauseButton.setTitle("Pause", for: .normal)
        }
    }
    
    func onInactive(oldState: ScreenMeet.Session.State, inactiveReason: ScreenMeet.Session.State.InactiveReason) {
        switch inactiveReason {
        case .terminatedLocal:
            showToast("Session stopped by User.")
            pauseButton.isHidden = true
            startButton.isHidden = false
            loadingIndicator.isHidden = true
            startButton.setTitle("Start Session", for: .normal)
        case .terminatedServer:
            showToast("Session stopped by Agent.")
            pauseButton.isHidden = true
            startButton.isHidden = false
            loadingIndicator.isHidden = true
            startButton.setTitle("Start Session", for: .normal)
        }
    }
    
    func onPause(oldState: ScreenMeet.Session.State, pauseReason: ScreenMeet.Session.State.PauseReason) {
        pauseButton.setTitle("Resume", for: .normal)
        showToast("Session Paused")
    }
    
    func networkDisconnect() {
        showToast("Session disconnect.")
        pauseButton.isHidden = true
        startButton.isHidden = true
        loadingIndicator.isHidden = false
    }
    
    func networkReconnect() {
        showToast("Session reconnect")
        pauseButton.isHidden = false
        startButton.isHidden = false
        loadingIndicator.isHidden = true
    }
}

extension ViewController: SessionEventListener {
    
    func onParticipantAction(participant: ScreenMeet.Session.Participant, participantAction: ScreenMeet.Session.ParticipantAction) {
        switch participantAction {
        case .added:
            showToast("User \(participant.name) joined session")
        case .removed:
            showToast("User \(participant.name) left session")
        default: break
        }
    }
}

extension UIImageView {
    static func fromGif(frame: CGRect, resourceName: String) -> UIImageView? {
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "gif") else {
            print("Gif does not exist at that path")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
            let source = CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        let gifImageView = UIImageView(frame: frame)
        gifImageView.animationImages = images
        return gifImageView
    }
}
