//
//  SELWebView.m
//  menuapp
//
//  Created by dpcc on 2014/04/10.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELWebView.h"
#import "SELMenuDataManager.h"

@implementation SELWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self myInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self myInit];
    }
    return self;
}

- (void)myInit
{
    for (id subview in self.subviews)
        if ([[subview class] isSubclassOfClass: [UIScrollView class]])
            ((UIScrollView *)subview).bounces = NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)loadLocalFile:(NSString *)filePath
{
//    NSURL* url = [NSURL fileURLWithPath:filePath];
//    [self loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
    
    SELMenuDataManager* dataManager = [SELMenuDataManager instance];
    NSString* workPath = [dataManager getCurrentMenuWorkPath];
    NSData *htmlData = [NSData dataWithContentsOfFile:filePath];
    [self loadData:htmlData MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:[NSURL fileURLWithPath:workPath]];
    
//    NSString* htmlString = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
//    [self loadHTMLString:htmlString baseURL:[NSURL fileURLWithPath:workPath]];
}

@end
