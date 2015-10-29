//
//  SELWebViewController.h
//  menuapp
//
//  Created by dpcc on 2014/05/13.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELWebView.h"

@interface SELWebViewController : UIViewController<UIWebViewDelegate> {
    IBOutlet SELWebView* _webView;
}

- (IBAction)dismiss:(id)sender;

@property NSString* URL;

@end
