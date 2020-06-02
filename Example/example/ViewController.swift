//
//  ViewController.swift
//  example
//
//  Created by v on 2020/6/2.
//  Copyright © 2020 v. All rights reserved.
//

import UIKit
import SafariServices
import GitHubMarkdownView

class WebViewCell: UITableViewCell {
    weak var tableView: UITableView?
    var linkActivedHandler: ((URL)-> Void)? {
        didSet {
            markdownWebView.linkActivedHandler = linkActivedHandler
        }
    }

    lazy var markdownWebView = GitHubMarkdownView(frame: contentView.bounds)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        markdownWebView.heightChangedHandler = { [weak self] (height) in
            NSLog("height changed: %lf", height)
            
            if #available(iOS 11.0, *) {
                self?.tableView?.performBatchUpdates({
                })
            } else {
                self?.tableView?.beginUpdates()
                self?.tableView?.endUpdates()
            }
        }
        contentView.addSubview(markdownWebView)
        markdownWebView.translatesAutoresizingMaskIntoConstraints = false

        let padding: CGFloat = 20

        contentView.addConstraints([
            NSLayoutConstraint(item: markdownWebView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: markdownWebView, attribute: .left, relatedBy: .equal, toItem: contentView, attribute: .left, multiplier: 1, constant: padding),
            NSLayoutConstraint(item: markdownWebView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: markdownWebView, attribute: .right, relatedBy: .equal, toItem: contentView, attribute: .right, multiplier: 1, constant: -padding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func load(_ handler: ((_ completion: ((_ html: String?) -> Void)?) -> Void)?, baseURL: URL?) {
        markdownWebView.load(handler, baseURL: baseURL)
    }
}

class DummyCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var isLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Github Markdown WebView", comment: "")

        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.register(WebViewCell.self, forCellReuseIdentifier: NSStringFromClass(WebViewCell.self))
        tableView.register(DummyCell.self, forCellReuseIdentifier: NSStringFromClass(DummyCell.self))
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 160
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = indexPath.row

        return row == 2 ? UITableView.automaticDimension : 44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row

        if row == 2 {
            let url = URL(string: "https://raw.githubusercontent.com/github/cmark-gfm/master/README.md")
            let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(WebViewCell.self), for: indexPath) as! WebViewCell
            cell.tableView = tableView
            cell.linkActivedHandler = { [weak self] (url) in
                NSLog("link actived: \(url)")

                let vc = SFSafariViewController(url: url)
                self?.present(vc, animated: true, completion: nil)
            }
            cell.load({ [weak self] (completion) in
                guard let isLoaded = self?.isLoaded, !isLoaded else {
                    return
                }

                self?.isLoaded = true
                self?.loadURL(url, completion: completion)
                }, baseURL: url?.deletingLastPathComponent())

            return cell
        }

        return tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(DummyCell.self), for: indexPath)
    }

    func loadURL(_ url: URL?, completion: ((String?) -> Void)?) {
        let task = URLSession.shared.dataTask(with: url!) { (data, resp, error) in
            DispatchQueue.main.async {
                if let data = data, let markdown = String(data: data, encoding: .utf8) {
                    completion?(markdown)
                }
            }
        }
        task.resume()
    }
}

