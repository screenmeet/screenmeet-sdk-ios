//
//  ScrollViewController.swift
//  ScreenMeetSDK_Example
//
//  Created by Vasyl Morarash on 09.10.2020.
//

import UIKit
import ScreenMeetSDK

class ScrollViewController: UIViewController {

    @IBOutlet weak var privacyTextField: UITextField!
    
    @IBOutlet weak var privacyImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        ScreenMeet.shared.localVideoSource.frameProcessor.setConfidential(view: privacyTextField)
        ScreenMeet.shared.localVideoSource.frameProcessor.setConfidential(view: privacyImageView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        ScreenMeet.shared.localVideoSource.frameProcessor.unsetConfidential(view: privacyTextField)
        ScreenMeet.shared.localVideoSource.frameProcessor.unsetConfidential(view: privacyImageView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "modal":
            let modal = segue.destination as? ModalViewController
            modal?.delegate = self
        default:
            break
        }
    }
    
    @IBAction func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func presentAlertTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Alert", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true)
    }
    
    @IBAction func presentModalTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "modal", sender: nil)
    }
}

extension ScrollViewController: ModalViewControllerDelegate {
    
    func didAppear() {
        ScreenMeet.shared.localVideoSource.frameProcessor.unsetConfidential(view: privacyTextField)
        ScreenMeet.shared.localVideoSource.frameProcessor.unsetConfidential(view: privacyImageView)
    }
    
    func willDisappear() {
        ScreenMeet.shared.localVideoSource.frameProcessor.setConfidential(view: privacyTextField)
        ScreenMeet.shared.localVideoSource.frameProcessor.setConfidential(view: privacyImageView)
    }
}
