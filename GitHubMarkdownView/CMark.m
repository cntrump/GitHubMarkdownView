//
//  CMark.m
//  GithubMarkdown
//
//  Created by v on 2020/5/31.
//  Copyright © 2020 v. All rights reserved.
//

#import "CMark.h"
#import "cmark-gfm.h"
#import "cmark-gfm-core-extensions.h"

extern cmark_syntax_extension *create_tagfilter_extension(void);
extern cmark_syntax_extension *create_autolink_extension(void);
extern cmark_syntax_extension *create_strikethrough_extension(void);
extern cmark_syntax_extension *create_tasklist_extension(void);
extern cmark_syntax_extension *create_table_extension(void);

static void cmarkEnableAllExtensions(cmark_parser *parser) {
    cmark_gfm_core_extensions_ensure_registered();
    cmark_parser_attach_syntax_extension(parser, create_tagfilter_extension());
    cmark_parser_attach_syntax_extension(parser, create_autolink_extension());
    cmark_parser_attach_syntax_extension(parser, create_strikethrough_extension());
    cmark_parser_attach_syntax_extension(parser, create_tasklist_extension());
    cmark_parser_attach_syntax_extension(parser, create_table_extension());
}

@implementation CMark

+ ( NSString * _Nullable)renderHTMLFromMarkdown:(NSString * _Nullable)markdown {
    if (markdown.length == 0) {
        return nil;
    }

    cmark_parser *parser = cmark_parser_new(CMARK_OPT_DEFAULT);
    if (!parser) {
        return nil;
    }

    cmarkEnableAllExtensions(parser);
    cmark_parser_feed(parser, markdown.UTF8String, strlen(markdown.UTF8String));
    cmark_node *doc = cmark_parser_finish(parser);
    cmark_parser_free(parser);

    if (!doc) {
        return nil;
    }

    char *output = cmark_render_html(doc, CMARK_OPT_DEFAULT, NULL);
    cmark_node_free(doc);

    if (!output) {
        return nil;
    }

    NSString *html = [NSString stringWithUTF8String:output];
    free(output);

    return html;
}

@end
