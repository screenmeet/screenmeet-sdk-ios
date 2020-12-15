//
//  WebViewController.swift
//  ScreenMeetSDK_Example
//
//  Created by Vasyl Morarash on 18.11.2020.
//

import UIKit
import WebKit
import ScreenMeetSDK

class WebViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = URL(string: "https://stackoverflow.com/users/login?ssrc=head&returnurl=https%3a%2f%2fstackoverflow.com%2f") {
            webView.load(URLRequest(url: url))
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ScreenMeet.shared.localVideoSource.frameProcessor.setConfidentialWeb(view: webView)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ScreenMeet.shared.localVideoSource.frameProcessor.unsetConfidentialWeb(view: webView)
    }
    
    @IBAction func back(sender: Any) {
        if (self.webView.canGoBack) {
            self.webView.goBack()
        }
    }

    @IBAction func forward(sender: Any) {
        if (self.webView.canGoForward) {
            self.webView.goForward()
        }
    }
}
