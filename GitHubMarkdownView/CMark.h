//
//  CMark.h
//  GithubMarkdown
//
//  Created by v on 2020/5/31.
//  Copyright © 2020 v. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMark : NSObject

+ (NSString * _Nullable)renderHTMLFromMarkdown:(NSString * _Nullable)markdown;

@end
