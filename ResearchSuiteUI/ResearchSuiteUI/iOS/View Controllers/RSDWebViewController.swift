//
//  RSDWebViewController.swift
//  ResearchSuiteUI
//
//  Copyright © 2016 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit

/// `RSDWebViewController` is a simple view controller for showing a webview. The base-class implementation
/// supports loading a web view from a URL, HTML string, or `RSDResourceTransformer`. It is assumed that
/// the property will be set for one of these values.
open class RSDWebViewController: UIViewController, UIWebViewDelegate {
    
    /// The webview attached to this view controller.
    @IBOutlet var webView: UIWebView!
    
    /// The URL to load into the webview on `viewWillAppear()`.
    open var url: URL?
    
    /// The HTML string to load into the webview on `viewWillAppear()`.
    open var html: String?
    
    /// The resource to load into the webview on `viewWillAppear()`.
    open var resourceTransformer: RSDResourceTransformer?
    
    fileprivate var _webviewLoaded = false
    
    /// Convenience method for instantiating a web view controller that is the root view controller for a
    /// navigation controller.
    open class func instantiateController() -> (RSDWebViewController, UINavigationController) {
        let webVC = RSDWebViewController()
        webVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: Localization.buttonClose(), style: .plain, target: webVC, action: #selector(close))
        return (webVC, UINavigationController(rootViewController: webVC))
    }
    
    // MARK: View management
    
    /// Override `viewDidLoad()` to instantiate a webview if there wasn't one created using a storyboard or nib.
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if (webView == nil) {
            self.view.backgroundColor = UIColor.white
            let subview = UIWebView(frame: self.view.bounds)
            self.view.addSubview(subview)
            subview.rsd_alignAllToSuperview(padding: 0)
            subview.delegate = self
            subview.dataDetectorTypes = .all
            subview.backgroundColor = UIColor.white
            self.webView = subview
        }
    }
    
    /// Override `viewWillAppear()` to load the webview on first appearance.
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (!_webviewLoaded) {
            _webviewLoaded = true
            if let url = self.url {
                let request = URLRequest(url: url)
                webView.loadRequest(request)
            }
            else if let html = self.html {
                // Include main bundle resourceURL as the baseURL so any stylesheets and images from the 
                // bundle that are referenced in the HTML will load in the UIWebView.
                webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
            }
            else if let resource = resourceTransformer {
                do {
                    let (data, _) = try resource.resourceData()
                    if let html = String(data: data, encoding: String.Encoding.utf8) {
                        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
                    } else {
                        loadFailed()
                    }
                } catch let err {
                    loadFailed(with: err)
                }
            }
        }
    }
    
    /// Failed to load the webview. Default implementation will print the error to the console but is otherwise silent.
    open func loadFailed(with error: Error? = nil) {
        if let err = error {
            debugPrint("Failed to load resource. \(err)")
        } else {
            debugPrint("Failed to load.")
        }
    }
    
    /// Dismiss the view controller that was presented modally.
    @objc open func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: UIWebViewDelegate
    
    /// If the webview request is a clicked link then open using the `UIApplication.open()` method.
    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        if let url = request.url, (navigationType == .linkClicked) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return false
        }
        else {
            return true
        }
    }
}
