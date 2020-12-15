//
//  ModalViewController.swift
//  ScreenMeetSDK_Example
//
//  Created by Vasyl Morarash on 12.11.2020.
//

import UIKit

protocol ModalViewControllerDelegate: class {
    
    func didAppear()
    
    func willDisappear()
}

class ModalViewController: UIViewController {
    
    weak var delegate: ModalViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.didAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.willDisappear()
    }
}
