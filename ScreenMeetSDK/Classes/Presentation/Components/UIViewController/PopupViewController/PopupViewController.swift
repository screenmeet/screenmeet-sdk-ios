//
//  PopupViewController.swift
//  SupportHelperAppPrototype
//
//  Created by Vasyl Morarash on 09.01.2020.
//  Copyright © 2020 Projector Inc. All rights reserved.
//

import UIKit

struct PopupInputData {
    
    var title: String?
    
    var actionButtonTitle: String?
    
    var cancelButtonTitle: String?
    
    var contentView: UIView?
    
    var onActiveTap: ((PopupViewController) -> ())?
    
    var onCancelTap: ((PopupViewController) -> ())?
}

final class PopupViewController: UIViewController {
    
    @IBOutlet weak var mainWrapperView: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var contentWrapperView: UIView!
    
    @IBOutlet weak var actionButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    private var inputData: PopupInputData?
    
    //MARK: - Life cycle methods
    func setup(with input: PopupInputData?) {
        inputData = input
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = view.backgroundColor?.withAlphaComponent(0.8)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        titleLabel.text = inputData?.title
        
        
        contentWrapperView.isHidden = inputData?.contentView == nil
        
        if let contentView = inputData?.contentView {
            contentWrapperView.addSubview(contentView)
            contentWrapperView.bringSubviewToFront(contentView)
            
            contentView.translatesAutoresizingMaskIntoConstraints = false
            let horizontalConstraint = NSLayoutConstraint(item: contentView, attribute: .centerX, relatedBy: .equal, toItem: contentWrapperView, attribute: .centerX, multiplier: 1, constant: 0)
            let verticalConstraint = NSLayoutConstraint(item: contentView, attribute: .centerY, relatedBy: .equal, toItem: contentWrapperView, attribute: .centerY, multiplier: 1, constant: 0)
            let widthConstraint = NSLayoutConstraint(item: contentView, attribute: .width, relatedBy: .equal, toItem: contentWrapperView, attribute: .width, multiplier: 1, constant: 0)
            let heightConstraint = NSLayoutConstraint(item: contentView, attribute: .height, relatedBy: .equal, toItem: contentWrapperView, attribute: .height, multiplier: 1, constant: 0)
            contentWrapperView.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        }
        
        actionButton.setTitle(inputData?.actionButtonTitle, for: .normal)
        actionButton.isHidden = inputData?.actionButtonTitle == nil
        
        cancelButton.setTitle(inputData?.cancelButtonTitle, for: .normal)
        cancelButton.isHidden = inputData?.cancelButtonTitle == nil
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        inputData?.contentView?.removeFromSuperview()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //MARK: - Action methods
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        inputData?.onActiveTap?(self)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        inputData?.onCancelTap?(self)
    }
}
