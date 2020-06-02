//
//  GitHubMarkdownView.swift
//  GitHubMarkdownView
//
//  Created by v on 2020/6/2.
//  Copyright © 2020 v. All rights reserved.
//

import UIKit
import WebKit

@objc
public class GitHubMarkdownView: UIView, WKNavigationDelegate, WKScriptMessageHandler {
    @objc public var heightChangedHandler: ((_ height: CGFloat) -> Void)?
    @objc public var linkActivedHandler: ((_ url: URL) -> Void)?
    private var webView: WKWebView!
    private var contentHeight: CGFloat = 0
    private var contentSize: CGSize = .zero
    private var innerHTML: String = ""
    private var isReady: Bool = false
    private var baseURL: URL?
    private var loadMarkdownHandler: ((_ completion: ((_ html: String?) -> Void)?) -> Void)?

    public override var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
        }
    }

    deinit {
        webView.configuration.userContentController.removeAllUserScripts()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "message")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        let userContentController = WKUserContentController()
        userContentController.add(self, name: "message")

        var userScript = WKUserScript(source: "if (typeof exports == 'undefined') { var exports = {} }", injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)

        userScript = WKUserScript(source: "if (typeof github == 'undefined') { var github = new exports.GitHub(null) }", injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController

        webView = WKWebView(frame: bounds, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = self
        addSubview(webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        webView.frame = bounds

        let size = bounds.size
        if !contentSize.equalTo(size) {
            contentSize = size
            loadInnerHTML()
        }
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            decisionHandler(.cancel)
            linkActivedHandler?(url)

            return
        }

        decisionHandler(.allow)
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "message",
            let body = message.body as? Dictionary<String, Any>,
            let messageName = body["messageName"] as? String else {
            return
        }

        switch messageName {
        case "ready":
            if let isReady = body["isReady"] as? Bool {
                self.isReady = isReady
            }

            if isReady {
                load()
            }
            
            break

        case "height":
            if let height = body["height"] as? CGFloat, height != contentHeight {
                contentHeight = height
                invalidateIntrinsicContentSize()
                heightChangedHandler?(height)
            }

            break

        default:
            return
        }
    }

    @objc public func load(_ handler: ((_ completion: ((_ html: String?) -> Void)?) -> Void)?, baseURL: URL?) {
        guard baseURL != self.baseURL, !isReady else {
            return
        }

        self.baseURL = baseURL
        loadMarkdownHandler = handler
        let templateHTML = GitHubMarkdownBundle.shared.template
        webView.loadHTMLString(templateHTML, baseURL: baseURL)
    }

    private func load() {
        loadMarkdownHandler? { [weak self] (markdown) in
            let markdown = markdown ?? ""
            self?.loadMarkdown(markdown)
        }
    }

    private func loadMarkdown(_ markdown: String) {
        guard var html = CMark.renderHTML(fromMarkdown: markdown) else {
            return
        }
        
        html = html.trimmingCharacters(in: .whitespacesAndNewlines)
        html = html.replacingOccurrences(of: "\n", with: "\\n")
        html = html.replacingOccurrences(of: "\"", with: "\\\"")
        html = html.replacingOccurrences(of: "'", with: "\\'")

        innerHTML = html
        loadInnerHTML()
    }

    private func loadInnerHTML() {
        let js = String(format: "github.load('%@')", innerHTML)
        webView.evaluateJavaScript(js) { [weak self] (height, error) in
            if let height = height as? CGFloat, let contentHeight = self?.contentHeight, height != contentHeight {
                self?.contentHeight = height
                self?.invalidateIntrinsicContentSize()
                self?.heightChangedHandler?(height)
            }
        }
    }
}
