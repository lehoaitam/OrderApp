//
//  SELWebViewController.m
//  menuapp
//
//  Created by dpcc on 2014/05/13.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELWebViewController.h"

@interface SELWebViewController ()

@end

@implementation SELWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL* toppage = [NSURL URLWithString:self.URL];
    NSURLRequest * req = [NSURLRequest requestWithURL:toppage];
	[_webView loadRequest:req];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dismiss:(id)sender
{
    if ([_webView canGoBack]) {
        [_webView goBack];
    }
    else {
        // 閉じる
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - webView delegate

-(void)webViewDidStartLoad:(UIWebView*)webView
{
    // ページ読込開始時にインジケータをくるくるさせる
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)webViewDidFinishLoad:(UIWebView*)webView
{
    // ページ読込完了時にインジケータを非表示にする
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


@end
