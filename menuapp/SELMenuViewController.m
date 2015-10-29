//
//  SELMenuViewController.m
//  menuapp
//
//  Created by dpcc on 2014/04/10.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELMenuViewController.h"
#import "SELMenuDataManager.h"
#import "SELWebView.h"
#import "SELItemDataManager.h"
#import "SELItemData.h"
#import "SELItemDetailViewController.h"
#import "SELOrderListViewController.h"
#import "SELItemSelectPopoverViewController.h"
#import "SELPurchaseHistoryViewController.h"
#import "SELSettingDataManager.h"

#import "UIAlertView+Blocks.h"
#import "AFNetworking.h"
#import "RIButtonItem.h"
#import "SVProgressHUD.h"

//#import "KKMeasureTimeLogger.h"

#import "SELStatusManager.h"

@interface SELMenuViewController ()

@end

@implementation SELMenuViewController

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    // 向きは設定値固定とする
    
    // Return YES for supported orientations
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger nScreenOrientation = [userDefaults integerForKey:@"screenOrientation"];
    
    if (nScreenOrientation == 0) {
        // 縦
        return UIInterfaceOrientationMaskPortrait;
    }
    else {
        // 横
        return UIInterfaceOrientationMaskLandscape;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // 向きが変わったらViewを初期化する
    
    // １ページ目にする
    self.currentPageIndex = 0;
    
    // スクロールViewを初期化
    [self initScrollView];
    
    // WebViewを更新
    [self updatePage];
    
    // WEBView Reload処理(念のため)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"WEBView Reload処理");
        [_previousWebView reload];
        [_currentWebView reload];
        [_nextWebView reload];
    });
}

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
    
    // 初期設定
//    _doScrollDidScroll = YES;   // scrolleventを行うか
    self.currentPageIndex = 0;
    _badgeView.badgeColor = [UIColor redColor];
    _badgeView.textColor = [UIColor whiteColor];
    
    // 多言語対応
    [self updateLocalizitaion];
    
    // ボタン表示・非表示設定
    [self updateButtonVisible];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // メニュー切替時 Notification
    [notificationCenter addObserver:self selector:@selector(menuChange:) name:SELMenuChangeNotification object:nil];
    
    // ボタン切り替え時 Nofitication
    [notificationCenter addObserver:self selector:@selector(updateButtonVisible) name:SELUISettingChangeNotification object:nil];

    // 注文リスト更新時 Notification
    [notificationCenter addObserver:self selector:@selector(updateOrderList) name:SELUpdateOrderListMessageNotification object:nil];
    
//    NSLog(@"viewDidLoad: height:%f, width:%f", _scrollView.frame.size.height, _scrollView.frame.size.width);
    
    // データ更新 notification
    [notificationCenter addObserver:self selector:@selector(updateMenuSuccess:) name:SELUpdateMenuSuccessNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(updateMenuError:) name:SELUpdateMenuErrorNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(updateMenuStatus:) name:SELUpdateMenuStatusNotification object:nil];
    
    // 品切れ取得タイマーセット
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    NSNumber* ipadStatusUpdateInterval = [settingDataManager GetiPadStatusUpdateInterval];
    
    if (ipadStatusUpdateInterval != nil) {
        // 設定があればタイマー開始
        //    NSNumber* ipadStatusUpdateInterval = @1;
        [NSTimer scheduledTimerWithTimeInterval:[ipadStatusUpdateInterval floatValue] target:self selector:@selector(updateItemStatus:) userInfo:nil repeats:YES];
        
        // １回目はすぐに起動させておく
        [self updateItemStatus:nil];
    }
    else {
        // 設定がない場合は空にする
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
    }
}

- (void)updateItemStatus:(NSTimer*)timer {
    
    // ステータス更新（他システム連携のみ）
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    id linkSystem = [userDefaults objectForKey:@"linkSystem"];
    
    switch ([linkSystem intValue]) {
        case 0: // プリンタ連携時
        case 2: // スマレジ連携時
        case 3: // 他システム連携
        {
            // 商品情報更新
            SELStatusManager* statusManager = [SELStatusManager instance];
            [statusManager updateItemStatus];
            break;
        }
        default:
            break;
    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
//    [KKMeasureTimeLogger startWithLogMode:KKMeasureTimeLogModeAfter];
    
//    NSLog(@"viewWillAppear: height:%f, width:%f", _scrollView.frame.size.height, _scrollView.frame.size.width);
    
    // 画面表示時には注文リストを更新する
    [self updateOrderList];
    
//    [KKMeasureTimeLogger stop];
    
    // 顧客情報取得依頼を送信する
    SELOrderManager* orderListController = [SELOrderManager instance];
    [orderListController getCustomerInfo];
}

- (void)viewDidAppear:(BOOL)animated
{
//    NSLog(@"viewDidAppear: height:%f, width:%f", _scrollView.frame.size.height, _scrollView.frame.size.width);
//    [KKMeasureTimeLogger startWithLogMode:KKMeasureTimeLogModeAfter];
    
    if (!_previousWebView) {
        // 初回のみ
        [self initScrollView];
        // ページ読み込み,回転,座標更新処理
        [self updatePage];
    }    
    
//    [KKMeasureTimeLogger stop];

    /*
    CGRect webViewFrame = CGRectZero;
    webViewFrame.size = _scrollView.frame.size;
    
    // サイズ修正
    // ここで行わないとサイズが正しくない
    if (_previousWebView) {
        _previousWebView.frame = CGRectMake(_previousWebView.frame.origin.x, _previousWebView.frame.origin.y, webViewFrame.size.width, webViewFrame.size.height);
    }
    if (_currentWebView) {
        _currentWebView.frame = CGRectMake(_previousWebView.frame.origin.x, _previousWebView.frame.origin.y, webViewFrame.size.width, webViewFrame.size.height);
    }
    if (_nextWebView) {
        _nextWebView.frame = CGRectMake(_previousWebView.frame.origin.x, _previousWebView.frame.origin.y, webViewFrame.size.width, webViewFrame.size.height);
    }
    */
}

- (void)updateButtonVisible {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    id linkSystem = [userDefaults objectForKey:@"linkSystem"];
    
    switch ([linkSystem intValue]) {
        case 0:
            // プリンタ連携
            [_purchaseHistoryButton setHidden:true];
            [_purchaseHistoryLabel setHidden:true];
            break;
        case 1:
            // TECレジ連携
            [_purchaseHistoryButton setHidden:false];
            [_purchaseHistoryLabel setHidden:false];
            break;
        case 2:
            // スマレジ連携
            [_purchaseHistoryButton setHidden:false];
            [_purchaseHistoryLabel setHidden:false];
            break;
        case 9:
            // デモ版
            [_purchaseHistoryButton setHidden:false];
            [_purchaseHistoryLabel setHidden:false];
            break;
        default:
            break;
    }
    
    // 店員呼出ボタンの表示
    BOOL useCallStaff = [userDefaults boolForKey:@"useCallStaff"];
    if (useCallStaff) {
        [_callStaffButton setHidden:FALSE];
        [_callStaffLabel setHidden:FALSE];
    }
    else {
        [_callStaffButton setHidden:TRUE];
        [_callStaffLabel setHidden:TRUE];
    }
    
    // テーブル名の表示
    BOOL dispTableName = [userDefaults boolForKey:@"dispTableName"];
    if (dispTableName) {
        NSLog(@"dispTableName:TRUE");
        [_tableName setHidden:FALSE];
    }
    else {
        NSLog(@"dispTableName:FALSE");
        [_tableName setHidden:TRUE];
    }
    
    // テーブル名の設定
    [_tableName setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"]];
    
    // 注文機能のON/OFF
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString* orderStationFlag = [ud stringForKey:@"orderStationFlag"];
    if ([orderStationFlag isEqualToString:@"0"]) {
        [_orderListButton setHidden:TRUE];
        [_blinkLabel setHidden:TRUE];
    }
    else {
        [_orderListButton setHidden:FALSE];
        [_blinkLabel setHidden:FALSE];
    }
    
    // おすすめボタンのON/OFF
    NSString* recommendationVisible = [ud stringForKey:@"recommendationVisible"];
    if (recommendationVisible == nil || [recommendationVisible isEqualToString:@"0"]) {
        [_recommendButton setHidden:TRUE];
        [_recommendLabel setHidden:TRUE];
    }
    else {
        [_recommendButton setHidden:FALSE];
        [_recommendLabel setHidden:FALSE];
    }
}

- (void)updateLocalizitaion
{
    // 多言語対応
    [_toTopLabel setText:[SELLocalization localizedStringForKey:@"IB_TOTOP"]];
    [_blinkLabel setText:[SELLocalization localizedStringForKey:@"IB_ORDERLIST"]];
    [_callStaffLabel setText:[SELLocalization localizedStringForKey:@"IB_CALL_STAFF"]];
    [_purchaseHistoryLabel setText:[SELLocalization localizedStringForKey:@"IB_PURCHASE_HISTORY"]];
    [_recommendLabel setText:[SELLocalization localizedStringForKey:@"IB_RECOMMEND_MENU"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
//    NSLog(@"willAnimateRotationToInterfaceOrientation: height:%f, width:%f", _scrollView.frame.size.height, _scrollView.frame.size.width);
    
    // ページ読み込み,回転,座標更新処理
//    [self updatePage];
}

// 前後現WebViewをスクロール位置に合わせて更新する
- (void)updatePage
{
//    [KKMeasureTimeLogger lap:@"updatePage start"];

    CGRect webViewFrame = _scrollView.frame;
    
    // スクロール範囲設定(UIScrollViewの範囲を設定する)
//    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width * self.urlList.count, _scrollView.frame.size.height)];
    
    // 前後のページのサイズ(frame.size)と位置(frame.origin)を調整し、HTMLをロードする
    
    // 前ページ
    // ページがあればロードする
    long pageNum = self.currentPageIndex - 1;
    webViewFrame.origin.x = pageNum * webViewFrame.size.width;
    _previousWebView.frame = webViewFrame;
    
    if (self.urlList.count > pageNum) {
//        [_previousWebView loadRequest:[NSURLRequest requestWithURL:[self.urlList objectAtIndex:pageNum] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
        [_previousWebView loadLocalFile:[self.urlList objectAtIndex:pageNum]];
    }
    else{
        // 無い場合は空ページ
        [_previousWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
    
    // 現ページ
    // ページがあればロードする
    pageNum = self.currentPageIndex;
    webViewFrame.origin.x = pageNum * webViewFrame.size.width;
    _currentWebView.frame = webViewFrame;
    
    if (self.urlList.count > pageNum) {
//        [_currentWebView loadRequest:[NSURLRequest requestWithURL:[self.urlList objectAtIndex:self.currentPageIndex] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
        [_currentWebView loadLocalFile:[self.urlList objectAtIndex:self.currentPageIndex]];
    }
    else{
        // 無い場合は空ページ
        [_currentWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
    
    // 次ページ
    // ページがあればロードする
    pageNum = self.currentPageIndex + 1;
    webViewFrame.origin.x = pageNum * webViewFrame.size.width;
    _nextWebView.frame = webViewFrame;

    if (self.urlList.count > pageNum) {
//        [_nextWebView loadRequest:[NSURLRequest requestWithURL:[self.urlList objectAtIndex:pageNum] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
        [_nextWebView loadLocalFile:[self.urlList objectAtIndex:pageNum]];
    }
    else{
        // 無い場合は空ページ
        [_nextWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
    
    // scrollviewの位置をセット
//    [_scrollView setContentOffset:CGPointMake(self.currentPageIndex * webViewFrame.size.width, 0) animated:NO];
    
//    [KKMeasureTimeLogger lap:@"updatePage end"];
}



// スクロールView初期化
// - URLリストを読み込み
// - スクロールView上にWebViewを作成する
- (void)initScrollView
{
//    [KKMeasureTimeLogger lap:@"initScrollView start"];
    
    // 上にのっているViewをクリア
    if (_previousWebView) {
        [_previousWebView removeFromSuperview];
        [_previousWebView setDelegate:nil];
        _previousWebView = nil;
    }
    if (_currentWebView) {
        [_currentWebView removeFromSuperview];
        [_currentWebView setDelegate:nil];
        _currentWebView = nil;
    }
    if (_nextWebView) {
        [_nextWebView removeFromSuperview];
        [_nextWebView setDelegate:nil];
        _nextWebView = nil;
    }
    // URLリストの初期化
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    [menuDataManager UpdateMenuPages];
    self.urlList = menuDataManager.MenuPages;
    
    // 生成するWebViewのframeサイズを指定
    NSLog(@"height:%f, width:%f", _scrollView.frame.size.height, _scrollView.frame.size.width);
    CGRect webViewFrame = CGRectZero;
    webViewFrame.size = _scrollView.frame.size;
    
    // スクロール範囲設定
    //    NSLog(@"webViewFrame: %f,%f", webViewFrame.size.height, webViewFrame.size.width);
	[_scrollView setContentSize:CGSizeMake(webViewFrame.size.width * self.urlList.count, webViewFrame.size.height)];
    
    // webviewをセット
    // ３つのwebview(前、現在、後)を使い回す
    for (int i=-1; i <= 1; i++) {
        
        // 現在のページのインデックスを取得
//        NSInteger targetIndex = self.currentPageIndex + i;
        
        // 追加する座標設定
//        webViewFrame.origin.x = targetIndex * webViewFrame.size.width;
        
        // WebViewを作成する
        SELWebView* customWebView = [[SELWebView alloc]initWithFrame:webViewFrame];
        // ピンチイン／アウトを可能にする
        customWebView.scalesPageToFit = YES;
        // デリゲートを設定
        customWebView.delegate = self;
        
        // scrollviewに追加
        [_scrollView addSubview:customWebView];
        
        // それぞれに設定
        switch (i) {
            case -1:
            {
                _previousWebView = customWebView;
            }
                break;
            case 0:
            {
                _currentWebView = customWebView;
            }
                break;
            case 1:
            {
                _nextWebView = customWebView;
            }
                break;
            default:
                break;
        }
        
    }
    
    // スクロール位置をCurrentIndex位置にする
    [_scrollView setContentOffset:CGPointMake(_scrollView.frame.size.width * self.currentPageIndex, 0) animated:NO];
    
    _scrollView.pagingEnabled = YES;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.scrollsToTop = NO;
    
//    [KKMeasureTimeLogger lap:@"initScrollView end"];
}

//- (SELWebView*)loadMenuPage:(NSInteger)pageNum :(CGRect)pageFrame {
//    
//    SELWebView* customWebView = [[SELWebView alloc]initWithFrame:pageFrame];
//    
//    // ピンチイン／アウトを可能にする
//    customWebView.scalesPageToFit = YES;
//    // デリゲートを設定
//    customWebView.delegate = self;
//    
//    // 空htmlをロードする
//    [customWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
//    
//    /*
//    if (pageNum >= 0 && pageNum < self.urlList.count) {
//        [customWebView loadRequest:[NSURLRequest requestWithURL:[self.urlList objectAtIndex:pageNum] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f]];
////        [customWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.co.jp"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f]];
//    }
//    else{
//        // ページ範囲外であれば空ページとする
//        [customWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
//    }
//    */
//    
//    return customWebView;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"toitemdetaillandscape"] ||
        [identifier isEqualToString:@"toitemdetailportrait"]) {
        // 商品コードを検索し、該当商品がある場合のみ商品詳細画面へ遷移する
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        SELItemData* itemData = [itemDataManager getItemData:_selectedItemCode];
        if (!itemData) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                            message:@"商品がありません。"
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            
            return FALSE;
        }
    }
    return TRUE;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toitemdetaillandscape"] ||
        [segue.identifier isEqualToString:@"toitemdetailportrait"]) {
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        SELItemData* itemData = [itemDataManager getItemData:_selectedItemCode];
        
        SELItemDetailViewController* vc = [segue destinationViewController];
        vc.ItemData = itemData;
    }
    else if ([[segue identifier] isEqualToString:@"popoversetting"])
    {
        UIStoryboardPopoverSegue *pop = (UIStoryboardPopoverSegue*)segue;
        pop.popoverController.delegate = self;
    }
    else if ([[segue identifier] isEqualToString:@"orderlistpopover"])
    {
        // 注文リスト表示
        UIStoryboardPopoverSegue *pop = (UIStoryboardPopoverSegue*)segue;
        pop.popoverController.delegate = self;
    }
}

- (IBAction)menuReturnActionForSegue:(UIStoryboardSegue *)segue
{
    NSLog(@"return to menu unwind segue.");
    [self updateOrderList];
}

#pragma mark - IBOutlet

- (void)dismiss:(id)sender
{
    // 閉じる
//    [self dismissViewControllerAnimated:YES completion:NULL];
    
    // 1ページ目に戻る
    [self pageMove:0];
}

- (void)displayItemSelectPopoverView:(NSString*)itemCodes
{
    NSMutableArray* itemList = [[NSMutableArray alloc]init];
    
    // 表示するアイテムを抽出
    SELItemDataManager* itemManager = [SELItemDataManager instance];
    NSArray *itemCodeArray = [itemCodes componentsSeparatedByString:@","];
    for (NSString* itemCode in itemCodeArray) {
        SELItemData* itemData = [itemManager getItemData:itemCode];
        if (itemData) {
            [itemList addObject:itemData];
        }
    }
    
    if (itemList.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                        message:@"商品がありません。"
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    SELItemSelectPopoverViewController *viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"itemselectpopoverview"];
    viewController.ItemList = itemList;
    viewController.delegate = self;
    //    viewController.preferredContentSize = CGSizeMake(460, 1800);
    //    viewController.delegate = self;
    //    viewController.customOrderData = _customOrderData;
    
    _popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    _popover.delegate = self;
    //    _popover.popoverContentSize = CGSizeMake(460, 1800);
    
    //    CGRect rect = CGRectMake(self.view.frame.size.width/2, 50, 1, 1);
    [_popover presentPopoverFromRect:CGRectMake(self.view.center.x, self.view.center.y, 1, 1)
                              inView:self.view
            permittedArrowDirections:0
                            animated:YES];
}

- (void)list:(id)sender
{
//    // 注文リスト表示
//    SELOrderListViewController *viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderlistview"];
//    //    viewController.preferredContentSize = CGSizeMake(460, 1800);
//    
//    _popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
//    _popover.delegate = self;
//    //    _popover.popoverContentSize = CGSizeMake(460, 1800);
//    
//    //    CGRect rect = CGRectMake(self.view.frame.size.width/2, 50, 1, 1);
//    [_popover presentPopoverFromRect:_orderListButton.frame //rect
//                              inView:self.view
//            permittedArrowDirections:UIPopoverArrowDirectionRight
//                            animated:YES];
}

- (void)setting:(id)sender
{
    UILongPressGestureRecognizer* recognizer = (UILongPressGestureRecognizer*)sender;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"設定メニュー"
                                                         message:@"パスワードを入力してください。"
                                                        delegate:self
                                               cancelButtonTitle:@"キャンセル"
                                               otherButtonTitles:@"OK", nil];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        alert.tag = 10;
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 10) {
        
        if (buttonIndex == 0) {
            return;
        }
        
        NSString* inputPassword = [[alertView textFieldAtIndex:0] text];
        NSString* settingPassword =  [[NSUserDefaults standardUserDefaults] objectForKey:@"pass"];
        
        if ([inputPassword isEqualToString:settingPassword]) {
            [self performSegueWithIdentifier:@"popoversetting" sender:self];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@""
                                  message:@"パスワードが違います"
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil ];
            [alert show];
        }
    }
    
    else if(alertView.tag == 20) {
        
        if (buttonIndex == 0) {
            // cancel
            return;
        }

        // テーブル変更
        NSString* tableName = [[alertView textFieldAtIndex:0] text];
        SELSettingDataManager* dataManager = [SELSettingDataManager instance];
        [dataManager SetTableName:tableName];
        [self updateButtonVisible];
    }
}

- (void)orderlist:(id)sender
{
    // 注文確認画面へ
    [self performSegueWithIdentifier:@"toPurchaseHistoryView" sender:self];
    
    /*
     SELOrderManager* orderListController = [SELOrderManager instance];
     orderListController.delegate = self;
     [orderListController getOrderedList];
     */
}

- (void)callStaff:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:[SELLocalization localizedStringForKey:@"MES_CALLSTAFF"]
                                message:[SELLocalization localizedStringForKey:@"MES_CALLSTAFFCONFIRM"]
                       cancelButtonItem:[RIButtonItem itemWithLabel:[SELLocalization localizedStringForKey:@"IB_CANCEL"] action:^{
        // cancel
        
    }]
                       otherButtonItems:[RIButtonItem itemWithLabel:[SELLocalization localizedStringForKey:@"MES_YES"] action:^{
        // yes
        SELOrderManager* orderListController = [SELOrderManager instance];
        orderListController.delegate = self;
        [orderListController callStaff];
        
    }], nil] show];
}

- (void)recommend:(id)sender
{
    // おすすめメニュー画面へ
    [self performSegueWithIdentifier:@"torecommendview" sender:self];
}

#pragma mark - notification

- (void)updateOrderList
{
    //    [KKMeasureTimeLogger lap:@"updateOrderList start"];
    
    // 注文リスト数を更新する
    SELOrderManager* orderListController = [SELOrderManager instance];
    NSInteger count = [orderListController getOrderList].count;
    if (count > 0) {
        _badgeView.text = [NSString stringWithFormat:@"%ld", (long)count];
        [self blinkON];
    }
    else{
        _badgeView.text = @"";
        [self blinkOFF];
    }
    
    //    [KKMeasureTimeLogger lap:@"updateOrderList end"];
}

- (void)execBlink
{
//    [_orderListButton setHidden:(!_orderListButton.hidden)];
    [_badgeView setHidden:(!_badgeView.hidden)];
    [_blinkLabel setHidden:(!_blinkLabel.hidden)];
}

- (void)blinkON
{
    // 点滅オン
    if (!_blinkTimer) {
        _blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f
                                                       target:self
                                                     selector:@selector(execBlink)
                                                     userInfo:NULL
                                                      repeats:YES];
//        [_orderListButton setTitle:@"注文未完了" forState:UIControlStateNormal];
//        [_orderListButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_blinkLabel setText:[SELLocalization localizedStringForKey:@"IB_CONFIRMORDER"]];
        [_blinkLabel setTextColor:[UIColor redColor]];
        [_blinkLabel setHidden:false];

        // オン時は注文ボタン、バッジを表示に合わせる
//        [_orderListButton setHidden:(false)];
        [_badgeView setHidden:(false)];
    }
}

- (void)blinkOFF
{
    // 点滅オフ
    if (_blinkTimer) {
//        [_orderListButton setTitle:@"注文リスト" forState:UIControlStateNormal];
//        [_orderListButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_blinkLabel setText:[SELLocalization localizedStringForKey:@"IB_ORDERLIST"]];
        [_blinkLabel setTextColor:[UIColor blackColor]];
        [_blinkLabel setHidden:false];

        // オフ時は注文ボタンは表示、バッジは非表示
//        [_orderListButton setHidden:(false)];
        [_badgeView setHidden:(true)];
        
        [_blinkTimer invalidate];
        if (_blinkTimer) _blinkTimer = nil;
    }
}

#pragma mark - notification

- (void)updateMenuSuccess:(NSNotification *)notification
{
    // menudownload完了時
    [SVProgressHUD showSuccessWithStatus:@"正常終了しました"];

    // 多言語対応
    [self updateLocalizitaion];

    // ボタン表示・非表示設定
    [self updateButtonVisible];

    // cacheクリア
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    
    // １ページ目にする
    self.currentPageIndex = 0;
    
    // スクロールViewを初期化
    [self initScrollView];
    
    // WebViewを更新
    [self updatePage];
    
    // WEBView Reload処理(念のため)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"WEBView Reload処理");
        [_previousWebView reload];
        [_currentWebView reload];
        [_nextWebView reload];
    });

}

- (void)updateMenuError:(NSNotification *)notification
{
    if ([notification isKindOfClass:[NSNotification class]]) {
        NSString* error = (NSString*)[notification object];
        [SVProgressHUD showErrorWithStatus:error];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"異常終了しました"];
    }
}

- (void)updateMenuStatus:(NSNotification *)notification
{
    NSDictionary* dict = (NSDictionary*)[notification object];
    NSNumber* progress = [dict objectForKey:@"progress"];
    CGFloat progressF = [progress floatValue];
    NSString* status = [dict objectForKey:@"status"];
    
    [SVProgressHUD showProgress:progressF status:status];
}

- (void)menuChange:(NSNotification *)notification
{
    NSLog(@"menuChange");
    
    // cacheクリア
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    
    // １ページ目にする
    self.currentPageIndex = 0;
   
    // 多言語対応
    [self updateLocalizitaion];

    // ボタン表示・非表示設定
    [self updateButtonVisible];

    // スクロールViewを初期化
    [self initScrollView];
    
    // WebViewを更新
    [self updatePage];
}

#pragma mark - ordermanager delegate

- (void)didGetOrderedList:(BOOL)bSuccess orderedList:(NSArray *)orderedList info:(id)info
{
    NSLog(@"didGetOrderedList - %d", bSuccess);
    if (bSuccess) {
        [self performSegueWithIdentifier:@"toPurchaseHistoryView" sender:orderedList];
    }
    else {
        NSString* errorMessage = [NSString stringWithFormat:@"恐れ入りますがお近くのスタッフにお申し付け下さい。(%@)", info];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"注文履歴の取得が出来ませんでした。"
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)didCallStaff:(BOOL)bSuccess info:(id)info
{
    NSLog(@"didCallStaff - %d", bSuccess);
    
    if (bSuccess) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"POPUP_TITLE_CALLED_STAFF", nil)
                                                        message:NSLocalizedString(@"POPUP_MESSAGE_CALLED_STAFF", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        NSString* errorMessage = [NSString stringWithFormat:@"恐れ入りますがお近くのスタッフにお申し付け下さい。(%@)", info];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"スタッフを呼べませんでした"
                                                        message:errorMessage
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
        
    }
}

#pragma mark - scrollView Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    _isBeginScrolling = TRUE;
}

// フリックでスクロールした時に受信する
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // viewを使い回す処理
    CGFloat position = scrollView.contentOffset.x / scrollView.bounds.size.width;
    CGFloat delta = position - (CGFloat)self.currentPageIndex;
    
    if (fabs(delta) >= 1.0f) {
        if (delta > 0) {
            // 右にスクロール
            self.currentPageIndex = self.currentPageIndex + 1;
            NSLog(@"setupNextPage:%ld", (long)self.currentPageIndex);
            [self setupNextPage];
            
        } else {
            // 左にスクロール
            self.currentPageIndex = self.currentPageIndex - 1;
            NSLog(@"setupPreviusPage:%ld", (long)self.currentPageIndex);
            [self setupPreviousPage];
        }
        // 背景が更新されていない場合があるので、念のためリロードする
        [_currentWebView reload];
    }
}

- (void)setupNextPage {
    
    // ３つのWebViewを使い回す
    SELWebView* tmpView = _currentWebView;
    _currentWebView = _nextWebView;
    _nextWebView = _previousWebView;
    _previousWebView = tmpView;
    
    // ページを移動
    CGRect frame = _currentWebView.frame;
    frame.origin.x += frame.size.width;
    _nextWebView.frame = frame;
    
    // 次ページViewをロードする
    if (self.urlList.count > self.currentPageIndex + 1) {
//        [_nextWebView loadRequest:[NSURLRequest requestWithURL:[self.urlList objectAtIndex:self.currentPageIndex+1] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f]];
//        [_nextWebView reload];
        [_nextWebView loadLocalFile:[self.urlList objectAtIndex:self.currentPageIndex+1]];
    }
    else{
        // 無い場合は空ページ
        [_nextWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
}

- (void)setupPreviousPage {
    
    // ３つのWebViewを使い回す
    SELWebView* tmpView = _currentWebView;
    _currentWebView = _previousWebView;
    _previousWebView = _nextWebView;
    _nextWebView = tmpView;
    
    // ページを移動
    CGRect frame = _currentWebView.frame;
    frame.origin.x -= frame.size.width;
    _previousWebView.frame = frame;
    
    // 前ページViewをロードする
    if (0 <= self.currentPageIndex - 1) {
//        [_previousWebView loadRequest:[NSURLRequest requestWithURL:[self.urlList objectAtIndex:self.currentPageIndex-1] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f]];
//        [_previousWebView reload];
        [_previousWebView loadLocalFile:[self.urlList objectAtIndex:self.currentPageIndex-1]];
    }
    else{
        // 無い場合は空ページ
        [_previousWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    }
}

#pragma mark - webView delegate

// ページ読込開始時にインジケータをくるくるさせる
-(void)webViewDidStartLoad:(UIWebView*)webView{
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    webView.hidden = TRUE;
}

// ページ読込完了時にインジケータを非表示にする
-(void)webViewDidFinishLoad:(UIWebView*)webView{
//    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
//    // 縦のずれをなくす
//    CGRect frame = webView.frame;
//    frame.size.height = 1;
//    webView.frame = frame;
//    CGSize fittingSize = [webView sizeThatFits:CGSizeZero];
//    frame.size = fittingSize;
//    webView.frame = frame;
    
//    NSLog(@"size: %f, %f", fittingSize.width, fittingSize.height);
//    webView.hidden = FALSE;
}

// 特定のページをクリックで別ページを表示する
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL* newURL = [request URL];
    
    // リンククリック時
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        NSString * lastComponent = [[newURL relativeString] lastPathComponent];
        lastComponent = [lastComponent lowercaseString];
//        NSLog(@"選択内容:%@", lastComponent);
        
        if ([lastComponent isEqualToString:@"gocategory"]) {
            // category画面の表示
            [self performSegueWithIdentifier:@"tocategoryview" sender:self];
            return NO;
        }
        
        if ([lastComponent isEqualToString:@"gorecommend"]) {
            // おすすめ画面の表示
            [self performSegueWithIdentifier:@"torecommendview" sender:self];
            return NO;
        }

        if ([lastComponent hasPrefix:@"gomenubook:"]) {
            // menubuook(page指定)の表示
            NSString* pageIndexStr = [lastComponent substringFromIndex: 11];
            NSInteger pageIndex = [pageIndexStr integerValue] - 1;  // 配列なので-1を行う
            
            // page移動
            [self pageMove:pageIndex];
            
            return NO;
        }
        
        if ([lastComponent hasPrefix:@"gomenuset:"]) {
            
            // メニュー選択
            NSInteger menuNumber = [[lastComponent substringFromIndex: 10] integerValue];
            NSLog(@"gomenuset:%ld", (long)menuNumber);

            SELSettingDataManager* settingManager = [SELSettingDataManager instance];
            [settingManager SetMenuNumber:menuNumber];
            
            // メニュー切替
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:SELMenuChangeNotification object:nil];

            /*
            // アニメーション処理
            [UIView beginAnimations:nil context:NULL];
            [self.view setAlpha:0.0];
            self.view.backgroundColor = [[UIColor alloc] initWithRed: 0.0
                                                               green: 0.0
                                                                blue: 0.0
                                                               alpha: 0.0];
            // 0.75秒で
            [UIView setAnimationDuration:0.75];
            
            // ページきりかえ
            [self loadTopPage];
            
            [self.view setAlpha:1];
            
            self.view.backgroundColor = [[UIColor alloc] initWithRed: 0.0
                                                               green: 0.0
                                                                blue: 0.0
                                                               alpha: 0.8];
            
            [UIView commitAnimations];
            */
            
            return NO;
        }
        
        if ([lastComponent hasPrefix:@"goorderlist"]) {
            // 注文リスト表示
            [self performSegueWithIdentifier:@"orderlistpopover" sender:self];
            return NO;
        }
        
        if ([lastComponent hasPrefix:@"goorderhistory"]) {
            // 注文履歴表示
            [self orderlist:self];
            return NO;
        }
        
        if ([lastComponent hasPrefix:@"gocallstaff"]) {
            // 店員呼出表示
            [self callStaff:self];
            return NO;
        }
        
        // ,があれば複数商品と見なす
        NSRange range = [lastComponent rangeOfString:@","];
        if (range.location != NSNotFound) {
            // 商品選択TABLEViewを表示する
            [self displayItemSelectPopoverView:lastComponent];
            return YES;
        }
        
        // その他の場合、商品コードを検索し、商品があった場合は商品詳細画面へ遷移する
        _selectedItemCode = lastComponent;
        
        // 画面の向き設定によって遷移先を変える
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger nScreenOrientation = [userDefaults integerForKey:@"screenOrientation"];
        
        if (nScreenOrientation == 0) {
            // 縦
            [self performSegueWithIdentifier:@"toitemdetailportrait" sender:self];
        }
        else {
            // 横
            [self performSegueWithIdentifier:@"toitemdetaillandscape" sender:self];
        }

        /*
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                [self performSegueWithIdentifier:@"toitemdetaillandscape" sender:self];
                break;
                
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
                [self performSegueWithIdentifier:@"toitemdetailportrait" sender:self];
                break;
                
            default:
                break;
        }
        */
    }
    
    return YES;
}

- (void)pageMove:(NSInteger)pageIndex
{
//    NSLog(@"pageMove currentPage:%ld, targetPage:%ld", (long)self.currentPageIndex, (long)pageIndex);
    
    self.currentPageIndex = pageIndex;
    [self updatePage];
    
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         // アニメーションをする処理
                         // ScrollView位置設定
                         CGPoint leftOffset = CGPointMake(_scrollView.frame.size.width * pageIndex, 0);
                         CGRect scrollBounds = _scrollView.bounds;
                         scrollBounds.origin = leftOffset;
                         _scrollView.bounds = scrollBounds;

                     } completion:^(BOOL finished) {
                         // アニメーションが終わった後実行する処理
                     }];
}


#pragma mark - SELItemSelectPopoverViewControllerDelegate

- (void)SelectedItem:(SELItemData *)selectedItem sender:(SELItemSelectPopoverViewController *)sender
{
    // popup viewを閉じる
    [_popover dismissPopoverAnimated:YES];
    
    _selectedItemCode = selectedItem.menuCode;
    
    // 画面の向き設定によって遷移先を変える
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger nScreenOrientation = [userDefaults integerForKey:@"screenOrientation"];
    
    if (nScreenOrientation == 0) {
        // 縦
        [self performSegueWithIdentifier:@"toitemdetailportrait" sender:self];
    }
    else {
        // 横
        [self performSegueWithIdentifier:@"toitemdetaillandscape" sender:self];
    }

    /*
    switch (self.interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            [self performSegueWithIdentifier:@"toitemdetaillandscape" sender:self];
            break;
            
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            [self performSegueWithIdentifier:@"toitemdetailportrait" sender:self];
            break;
            
        default:
            break;
    }
     */
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
//    NSLog(@"%@", popoverController.contentViewController.restorationIdentifier);
    if ([popoverController.contentViewController.restorationIdentifier isEqualToString:@"settingview"]) {
        // ダウンロード中の場合があるので、終了処理を行う
//        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//        NSLog(@"queue count:%d", manager.operationQueue.operationCount);
//        [manager.operationQueue cancelAllOperations];
        
//        [SVProgressHUD showErrorWithStatus:@"中断しました"];
        
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dic = [userDefaults persistentDomainForName:appDomain];
        NSLog(@"defaults:%@", dic);
        
        // singleton instanceなので一度クリアする
        SELConnectionBase* connectionBase = [SELConnectionBase instance];
        [connectionBase terminate];
        
        // ボタンの表示・非表示を変更
        [self updateButtonVisible];
    }
}

/*
- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    
}
*/

- (void)tablesetting:(id)sender
{
    UILongPressGestureRecognizer* recognizer = (UILongPressGestureRecognizer*)sender;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // テーブル名
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"テーブル名" message:@"テーブル名を入力してください。" delegate:self cancelButtonTitle:@"キャンセル" otherButtonTitles:@"OK",nil];
        alert.tag = 20;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }
}

@end
