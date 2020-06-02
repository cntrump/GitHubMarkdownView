//
//  GitHubMarkdownBundle.swift
//  GitHubMarkdownView
//
//  Created by v on 2020/6/2.
//  Copyright © 2020 v. All rights reserved.
//

import Foundation

final class GitHubMarkdownBundle {
    static let shared = GitHubMarkdownBundle()
    let template: String
    private let url: URL

    init() {
        url = Bundle(for: GitHubMarkdownBundle.self).url(forResource: "GitHubMarkdownResources", withExtension: "bundle")!
        let css = try! String(contentsOf: url.appendingPathComponent("markdown.css"))
        let js = try! String(contentsOf: url.appendingPathComponent("markdown.js"))

        template = String(format: try! String(contentsOf: url.appendingPathComponent("template.html")), css, js)
    }
}
