//
//  SELMenuViewController.h
//  menuapp
//
//  Created by dpcc on 2014/04/10.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELWebView.h"
#import "SELBadgeView.h"
#import "SELItemSelectPopoverViewController.h"
#import "SELOrderManager.h"

@interface SELMenuViewController : UIViewController<UIWebViewDelegate, UIScrollViewDelegate, UIPopoverControllerDelegate, SELItemSelectPopoverViewControllerDelegate, SELOrderManagerDelegate,
    UIAlertViewDelegate> {
    
        // スクロールビュー
        IBOutlet UIScrollView* _scrollView;
        // １ページ前
        SELWebView* _previousWebView;
        // 現在のページ
        SELWebView* _currentWebView;
        // １ページ後
        SELWebView* _nextWebView;
        
        // work
        NSString* _selectedItemCode;
        
        IBOutlet UIButton* _orderListButton;
        IBOutlet SELBadgeView* _badgeView;
        
//        BOOL _doScrollDidScroll;
        
        // ポップオーバー保持用
        UIPopoverController* _popover;
        
        // 点滅用
        NSTimer* _blinkTimer;
        IBOutlet UILabel* _blinkLabel;
        
        // 店員呼出ボタン
        IBOutlet UIButton* _callStaffButton;
        IBOutlet UILabel* _callStaffLabel;
        
        // 注文履歴ボタン
        IBOutlet UIButton* _purchaseHistoryButton;
        IBOutlet UILabel* _purchaseHistoryLabel;
        
        // テーブル名
        IBOutlet UILabel* _tableName;
        
        // TOPへ戻る
        IBOutlet UILabel* _toTopLabel;
        
        // おすすめボタン
        IBOutlet UIButton* _recommendButton;
        IBOutlet UILabel* _recommendLabel;
}

- (IBAction)setting:(id)sender;
- (IBAction)orderlist:(id)sender;
- (IBAction)callStaff:(id)sender;

- (IBAction)dismiss:(id)sender;
- (IBAction)list:(id)sender;
- (IBAction)recommend:(id)sender;

- (IBAction)tablesetting:(id)sender;

@property NSArray* urlList;
@property NSInteger currentPageIndex;

@end
