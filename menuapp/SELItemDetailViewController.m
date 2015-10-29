//
//  SELItemDetailViewController.m
//  menuapp
//
//  Created by dpcc on 2014/04/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELItemDetailViewController.h"
#import "SELItemDataManager.h"
#import "SELCustomOrderViewController.h"
#import "CurrencyUtil.h"
#import "SELOrderManager.h"
#import "SELOrderData.h"
#import "SELOrderListViewController.h"
#import "NSDate+Utilities.h"

@interface SELItemDetailViewController ()

@end

@implementation SELItemDetailViewController

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
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

- (void)updateOrderList
{
    // 注文リスト数を更新する
    SELOrderManager* orderListController = [SELOrderManager instance];
    NSInteger count = [orderListController getOrderList].count;
    if (count > 0) {
        _badgeView.text = [NSString stringWithFormat:@"%ld", (long)count];
        // 点滅オン
        [self blinkON];
    }
    else{
        _badgeView.text = @"";
        // 点滅オフ
        [self blinkOFF];
    }
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)updateView:(SELItemData*)itemData
{
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    self.ItemData = itemData;
    
    // 数量の初期化
    _quantity = 1;
    [self updateQuantity];

    // 商品基本情報
    [_name setText: [self.ItemData valueForKey:@"itemName"] ];
    [_price setText: [NSString stringWithFormat:@"%@", [CurrencyUtil stringToCurrency:[self.ItemData valueForKey:@"price"] ]]];
    [_description setText: [self.ItemData valueForKey:@"desc"] ];
    
    // 商品画像
    UIImage* itemImage = [self.ItemData getItemImage];
    [_image setImage:itemImage];
    
    // カスタムオーダー
    NSLog(@"customOrderDataNo - %@", self.ItemData.customOrderDataNo);
    if (   self.ItemData.customOrderDataNo != nil &&
        ![ self.ItemData.customOrderDataNo isEqualToString:@"0"] &&
        ![ self.ItemData.customOrderDataNo isEqualToString:@""]) {
        _customOrderData = [itemDataManager getCustomOrderData:self.ItemData.customOrderDataNo];
        [_customOrderTitleLabel setText:_customOrderData.message];
        [_customOrderTitleLabel setHidden:FALSE];
        
        [_customOrderValueLabel setText:[SELLocalization localizedStringForKey:@"MES_CHOISE"]];
        [_customOrderValueLabel setHidden:FALSE];
        
        [_customOrderButton setHidden:FALSE];
    }
    else {
        [_customOrderTitleLabel setHidden:TRUE];
        [_customOrderValueLabel setHidden:TRUE];
        [_customOrderButton setHidden:TRUE];
    }
    
    // トッピング
    NSLog(@"itemToppingGroupId - %@", self.ItemData.itemToppingGroupId);
    if (   self.ItemData.itemToppingGroupId != nil &&
        ![ self.ItemData.itemToppingGroupId isEqualToString:@"0"] &&
        ![ self.ItemData.itemToppingGroupId isEqualToString:@""]) {
        _toppingGroupData = [itemDataManager getToppingGroupData:self.ItemData.itemToppingGroupId];
        [_toppingTitleLabel setText:_toppingGroupData.itemToppingGroupName];
        [_toppingTitleLabel setHidden:FALSE];
        
        [_toppingValueLabel setText:[SELLocalization localizedStringForKey:@"MES_CHOISE"]];
        [_toppingValueLabel setHidden:FALSE];
        
        [_toppingButton setHidden:FALSE];
    }
    else {
        [_toppingTitleLabel setHidden:TRUE];
        [_toppingValueLabel setHidden:TRUE];
        [_toppingButton setHidden:TRUE];
    }
    
    // おすすめメニュー
    BOOL isExistSuggest = FALSE;    // おすすめメニューラベル隠し用
    if (![[self.ItemData valueForKey:@"suggest1"] isEqualToString:@""]) {
        [_suggest1 setHidden:FALSE];
        [_suggest1label setHidden:FALSE];
        isExistSuggest = TRUE;
        
        // おすすめ１
        SELItemData* itemData = [itemDataManager getItemData: [self.ItemData valueForKey:@"suggest1"] ];
        UIImage* itemImage = [itemData getItemImage];
        [_suggest1 setBackgroundImage:itemImage forState:UIControlStateNormal];
        [_suggest1label setText:[itemData valueForKey:@"itemName"]];
    }
    else {
        [_suggest1 setHidden:TRUE];
        [_suggest1label setHidden:TRUE];
    }
    
    if (![[self.ItemData valueForKey:@"suggest2"] isEqualToString:@""]) {
        [_suggest2 setHidden:FALSE];
        [_suggest2label setHidden:FALSE];
        isExistSuggest = TRUE;
        
        // おすすめ２
        SELItemData* itemData = [itemDataManager getItemData: [self.ItemData valueForKey:@"suggest2"] ];
        UIImage* itemImage = [itemData getItemImage];
        [_suggest2 setBackgroundImage:itemImage forState:UIControlStateNormal];
        [_suggest2label setText:[itemData valueForKey:@"itemName"]];
    }
    else {
        [_suggest2 setHidden:TRUE];
        [_suggest2label setHidden:TRUE];
    }
    
    if (![[self.ItemData valueForKey:@"suggest3"] isEqualToString:@""]) {
        [_suggest3 setHidden:FALSE];
        [_suggest3label setHidden:FALSE];
        isExistSuggest = TRUE;
        
        // おすすめ３
        SELItemData* itemData = [itemDataManager getItemData: [self.ItemData valueForKey:@"suggest3"] ];
        UIImage* itemImage = [itemData getItemImage];
        [_suggest3 setBackgroundImage:itemImage forState:UIControlStateNormal];
        [_suggest3label setText:[itemData valueForKey:@"itemName"]];
    }
    else {
        [_suggest3 setHidden:TRUE];
        [_suggest3label setHidden:TRUE];
    }
    
    if (isExistSuggest) {
        [_suggestTitle setHidden:FALSE];
    }
    else{
        [_suggestTitle setHidden:TRUE];
    }
    
    // 時間帯対応
    NSString* sNowTime = [[NSDate date] stringWithFormat:@"HHmm"];
    int iNowTime = [sNowTime intValue];
    int iStartTime = 0;
    if (![self.ItemData.startTime isEqualToString:@""]) {
        iStartTime = [self.ItemData.startTime intValue];
    }
    int iEndTime = 2400;
    if (![self.ItemData.endTime isEqualToString:@""]) {
        iEndTime = [self.ItemData.endTime intValue];
    }
//    NSLog(@"Item Start %d", iStartTime);
//    NSLog(@"Item End   %d", iEndTime);
//    NSLog(@"Item Now   %d", iNowTime);
    
    if (iStartTime > iNowTime || iEndTime < iNowTime) {
        //アイテムが注文時間外の場合はボタンを非活性にして文言を変更する
        NSMutableString *msTitle = [NSMutableString stringWithCapacity:1];
        //商品データが存在しない場合は「この商品はデータがありません。スタッフをお呼び下さい。」と
        //ボタンに表示する
        if(self.ItemData != nil)
        {
            [msTitle appendString:[SELLocalization localizedStringForKey:@"ORDER_OUTTIME"]];
            [msTitle appendFormat:@"(%@:%@～%@:%@)",
             [self.ItemData.startTime substringWithRange:NSMakeRange(0, 2)],
             [self.ItemData.startTime substringWithRange:NSMakeRange(2, 2)],
             [self.ItemData.endTime substringWithRange:NSMakeRange(0, 2)],
             [self.ItemData.endTime substringWithRange:NSMakeRange(2, 2)]];
        }
        else
        {
            [msTitle appendString:[SELLocalization localizedStringForKey:@"NO_ITEMDATA"]];
            [_addOrderButton.titleLabel setFont:[UIFont systemFontOfSize:18]];
        }
        
        ((UILabel*)_addOrderButton).lineBreakMode=NSLineBreakByWordWrapping;
        [_addOrderButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        
        [_addOrderButton setTitle:msTitle forState:UIControlStateNormal];
        _addOrderButton.enabled = NO;
    }    else {
        [_addOrderButton setTitle:[SELLocalization localizedStringForKey:@"IB_ADDORDERLIST"] forState:UIControlStateNormal];
        _addOrderButton.enabled = YES;
    }
    
    // 品切れ表示
    NSDictionary* itemstatuses = [[NSUserDefaults standardUserDefaults] objectForKey:@"itemstatus"];
    if (itemstatuses) {
        NSDictionary* itemstatus = [itemstatuses objectForKey:self.ItemData.menuCode];
        if (itemstatus) {
            NSString* soldout = [itemstatus objectForKey:@"soldout"];
            if ([soldout isEqualToString:@"true"]) {
                NSMutableString *msTitle = [NSMutableString stringWithCapacity:1];
                [msTitle appendString:[SELLocalization localizedStringForKey:@"SOLD_OUT"]];
                
                ((UILabel*)_addOrderButton).lineBreakMode=NSLineBreakByWordWrapping;
                [_addOrderButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
                
                [_addOrderButton setTitle:msTitle forState:UIControlStateNormal];
                _addOrderButton.enabled = NO;
            }
        }
    }

}

- (void)updateQuantity
{
    // 注文個数
    [_quantityLabel setText:[NSString stringWithFormat:@"%ld", (long)_quantity]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _badgeView.badgeColor = [UIColor redColor];
    _badgeView.textColor = [UIColor whiteColor];
    
    // ボタン表示・非表示設定
    [self updateButtonVisible];

    // 商品情報設定
    [self updateView:self.ItemData];
    
    // 注文リストバッジ更新用Notification設定
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateOrderList) name:SELUpdateOrderListMessageNotification object:nil];
    
    // animation用Array初期化
    _animationViewQueue = [[NSMutableArray alloc]init];
    
    // ボタン画像の比率を正しくする
    _suggest1.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _suggest2.imageView.contentMode = UIViewContentModeScaleAspectFit;
    _suggest3.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    // 多言語対応
    [self updateLocalizitaion];
}

- (void)updateButtonVisible
{
    // 注文機能のON/OFF
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString* orderStationFlag = [ud stringForKey:@"orderStationFlag"];
    if ([orderStationFlag isEqualToString:@"0"]) {
        [_addOrderButton setHidden:TRUE];
        [_quantityPlusButton setHidden:TRUE];
        [_quantityMinusButton setHidden:TRUE];
        [_orderListButton setHidden:TRUE];
        [_blinkLabel setHidden:TRUE];
    }
    else {
        [_addOrderButton setHidden:FALSE];
        [_quantityPlusButton setHidden:FALSE];
        [_quantityMinusButton setHidden:FALSE];
        [_orderListButton setHidden:FALSE];
        [_blinkLabel setHidden:FALSE];
    }
}

- (void)updateLocalizitaion
{
    // 多言語対応
    [_toMenuLabel setText:[SELLocalization localizedStringForKey:@"IB_TOMENU"]];
    [_blinkLabel setText:[SELLocalization localizedStringForKey:@"IB_ORDERLIST"]];
    [_addOrderNote setText:[SELLocalization localizedStringForKey:@"IB_ADDORDERLISTNOTE"]];
    [_yen setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_pieces setText:[SELLocalization localizedStringForKey:@"IB_PIECES"]];
    // 注文ボタンは時間帯によって変わるため、setitemdataで行う
//    [_addOrderButton setTitle:[SELLocalization localizedStringForKey:@"IB_ADDORDERLIST"] forState:UIControlStateNormal];
    [_suggestTitle setText:[SELLocalization localizedStringForKey:@"IB_SUGGEST_TITLE"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateOrderList];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    NSLog(@"will rotate");
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"did rotate");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)list:(id)sender
{
    // unwindsegueで戻れなくなったので、結局segueで行うことにした
    /*
    SELOrderListViewController *viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"orderlistview"];
//    viewController.preferredContentSize = CGSizeMake(460, 1800);
    
    _popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    _popover.delegate = self;
//    _popover.popoverContentSize = CGSizeMake(460, 1800);
    
//    CGRect rect = CGRectMake(self.view.frame.size.width/2, 50, 1, 1);
    [_popover presentPopoverFromRect:_orderListButton.frame //rect
                             inView:self.view
           permittedArrowDirections:UIPopoverArrowDirectionRight
                           animated:YES];
     */
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"tocustomorder"]) {
        SELCustomOrderViewController* vc = (SELCustomOrderViewController*)segue.destinationViewController;
        vc.delegate = self;
        vc.customOrderData = _customOrderData;
        // 閉じるためにpopover保持
        _popover = [(UIStoryboardPopoverSegue *)segue popoverController];
    }
    else if([segue.identifier isEqualToString:@"totopping"]) {
        SELToppingViewController* vc = (SELToppingViewController*)segue.destinationViewController;
        vc.delegate = self;
        vc.toppingGroupData = _toppingGroupData;
        // 選択内容を渡す
        vc.selectedToppingDataList = _selectedToppingDataList;
    }
}

- (void)dismiss:(id)sender
{
    // 閉じる
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)touchSuggest1:(id)sender
{
    // おすすめ１
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    SELItemData* itemData = [itemDataManager getItemData: [self.ItemData valueForKey:@"suggest1"] ];
    
    // トッピング、カスタムオーダー、選択個数を元に戻す
    [self SelectedCustomOrder:NULL sender:NULL];
    [self SelectedTopping:NULL sender:NULL];
    _quantity = 1;
    [self updateQuantity];

    // 商品情報を更新
    [self updateView:itemData];
}

- (void)touchSuggest2:(id)sender
{
    // おすすめ２
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    SELItemData* itemData = [itemDataManager getItemData: [self.ItemData valueForKey:@"suggest2"] ];

    // トッピング、カスタムオーダー、選択個数を元に戻す
    [self SelectedCustomOrder:NULL sender:NULL];
    [self SelectedTopping:NULL sender:NULL];
    _quantity = 1;
    [self updateQuantity];

    [self updateView:itemData];
}

- (void)touchSuggest3:(id)sender
{
    // おすすめ３
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    SELItemData* itemData = [itemDataManager getItemData: [self.ItemData valueForKey:@"suggest3"] ];
    
    // トッピング、カスタムオーダー、選択個数を元に戻す
    [self SelectedCustomOrder:NULL sender:NULL];
    [self SelectedTopping:NULL sender:NULL];
    _quantity = 1;
    [self updateQuantity];

    [self updateView:itemData];
}

- (void)addOrder:(id)sender
{
    // カスタムオーダー必須チェック
    if (   self.ItemData.customOrderDataNo != nil &&
        ![ self.ItemData.customOrderDataNo isEqualToString:@"0"] &&
        ![ self.ItemData.customOrderDataNo isEqualToString:@""]) {
        if (_selectedCustomOrderData == nil) {
            //
            NSString* errorMessage = _customOrderData.message;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[SELLocalization localizedStringForKey:@"MES_CHOISE"]
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    // トッピング入力数チェック
    if (   self.ItemData.itemToppingGroupId != nil &&
        ![ self.ItemData.itemToppingGroupId isEqualToString:@"0"] &&
        ![ self.ItemData.itemToppingGroupId isEqualToString:@""]) {
        
        NSUInteger nToppingSelectedCount = [_selectedToppingDataList count];
        if (nToppingSelectedCount < [_toppingGroupData.min intValue]){
            //
            NSString* errorMessage = _toppingGroupData.itemToppingGroupName;
            NSString* errorTitle = [NSString stringWithFormat:[SELLocalization localizedStringForKey:@"MES_MORE_SELECTION"], _toppingGroupData.min];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        // 未設定の場合は最大値をセットする
        int toppingGroupDataMax = 999;
        if ([_toppingGroupData.max length] > 0) {
            toppingGroupDataMax = [_toppingGroupData.max intValue];
        }
        if (nToppingSelectedCount > toppingGroupDataMax){
            //
            NSString* errorMessage = _toppingGroupData.itemToppingGroupName;
            NSString* errorTitle = [NSString stringWithFormat:[SELLocalization localizedStringForKey:@"MES_WITHIN_SELECTED"], _toppingGroupData.max];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    // 注文データを作成する
    SELOrderData* orderData = [[SELOrderData alloc]init];
    orderData.OrderItemData = self.ItemData;
    orderData.SelectedCustomOrder = _selectedCustomOrderData;
    orderData.SelectedTopping = _selectedToppingDataList;
    orderData.OrderQuantity = [NSNumber numberWithInteger:_quantity];
    orderData.OrderDateTime = [NSDate date];
    
    // 注文データを追加する
    SELOrderManager* orderListController = [SELOrderManager instance];
    [orderListController addOrder:orderData];
    
    // 注文リスト数を更新する
    [self updateOrderList];
    
    // 注文リストを自動表示
//    [self performSegueWithIdentifier:@"orderlistpopover" sender:self];
    
    // view操作を無効
    [self.view setUserInteractionEnabled:FALSE];
    
    // アニメーションを行う
    // cart in animation
    [self startCartInAnimation:_image.image];
}

- (void)startCartInAnimation:(UIImage*)itemImage
{
    // CAKeyframeAnimationオブジェクトを生成
    CAKeyframeAnimation *animation;
    animation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = 0.5f;
    animation.delegate = self;
    
    // 放物線のパスを生成
    //    CGPoint kStartPos = self.cartStartTarget.center;
    CGPoint kStartPos = _addOrderButton.center;
    CGPoint kEndPos = _orderListButton.center;
    
    CGFloat jumpHeight = 100.0;
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath, NULL, kStartPos.x, kStartPos.y);
    CGPathAddCurveToPoint(curvedPath, NULL,
                          kStartPos.x + jumpHeight/2, kStartPos.y - jumpHeight,
                          kEndPos.x - jumpHeight/2, kStartPos.y - jumpHeight,
                          kEndPos.x, kEndPos.y);
    
    // パスをCAKeyframeAnimationオブジェクトにセット
    animation.path = curvedPath;
    
    // パスを解放
    CGPathRelease(curvedPath);
    
    // レイヤーにアニメーションを追加
    UIImageView *_animationView = [[UIImageView alloc]initWithImage:itemImage];
    _animationView.frame = CGRectMake(0, 0, 40, 30);
    [self.view addSubview:_animationView];
    [_animationView.layer addAnimation:animation forKey:nil];
    
    [_animationViewQueue addObject:_animationView];
    
    /*
     [UIView animateWithDuration:1.0f
     delay:0.0f
     options:UIViewAnimationOptionCurveEaseIn
     animations:^{
     //                         UIImageView* anImageView = (UIImageView *)[self.view viewWithTag:kMSItemDetailViewMainItemImageTag];
     //                         anImageView.frame = CGRectMake(20, 1000, 50, 50);
     
     UIImageView* imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"icon.png"]];
     
     
     
     
     } completion:^(BOOL finished) {
     }
     ];
     */
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
    if (_animationViewQueue.count > 0) {
        UIImageView* view = [_animationViewQueue objectAtIndex:0];
        [view removeFromSuperview];
        [_animationViewQueue removeObject:view];
        
        NSTimer *timer_ = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                  target:self
                                                         selector:@selector(returnmenu:)
                                                userInfo:nil
                                                 repeats:NO];
        NSLog(@"%@", timer_.description);
    }
}

-(void)returnmenu:(NSTimer*)timer{
    // view操作を有効
    [self.view setUserInteractionEnabled:TRUE];
    
    // MenuViewへ戻る
    [self performSegueWithIdentifier:@"returnmenu1" sender:self];
}

- (void)touchCustomOrder:(id)sender
{
    SELCustomOrderViewController *viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"customorderview"];
    //    viewController.preferredContentSize = CGSizeMake(460, 1800);
    viewController.preferredContentSize = CGSizeMake(500, 300);
    viewController.delegate = self;
    viewController.customOrderData = _customOrderData;
    
    _popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    _popover.delegate = self;
    //    _popover.popoverContentSize = CGSizeMake(460, 1800);
    
    //    CGRect rect = CGRectMake(self.view.frame.size.width/2, 50, 1, 1);
    [_popover presentPopoverFromRect:_customOrderTitleLabel.frame //rect
                              inView:self.view
            permittedArrowDirections:UIPopoverArrowDirectionDown
                            animated:YES];
}

- (void)touchTopping:(id)sender
{
    SELToppingViewController *viewController = [[self storyboard] instantiateViewControllerWithIdentifier:@"toppingview"];
//    NSLog(@"%@", NSStringFromCGRect(viewController.view.frame));
    viewController.preferredContentSize = CGSizeMake(500, 300);
    viewController.delegate = self;
    viewController.toppingGroupData = _toppingGroupData;
    viewController.selectedToppingDataList = _selectedToppingDataList;

    _popover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    _popover.delegate = self;
    //    _popover.popoverContentSize = CGSizeMake(460, 1800);
    
    //    CGRect rect = CGRectMake(self.view.frame.size.width/2, 50, 1, 1);
//    CGRect rect = CGRectMake(self.view.frame.size.width/2, self.view.frame.size.height/2, 1, 1);
    [_popover presentPopoverFromRect:_toppingTitleLabel.frame //rect
                              inView:self.view
            permittedArrowDirections:UIPopoverArrowDirectionDown
                            animated:YES];
}

#pragma mark - SELOrderListControllerDelegate

- (void)didDeleteOrder
{
    [self updateOrderList];
}

#pragma mark - SELCustomOrderViewControllerDelegate

- (void)SelectedCustomOrder:(SELItemData *)selectedCustomOrder sender:(SELCustomOrderViewController *)sender
{
    _selectedCustomOrderData = selectedCustomOrder;
    
    [_popover dismissPopoverAnimated:YES];
    
    // customオーダー更新
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    _customOrderData = [itemDataManager getCustomOrderData:self.ItemData.customOrderDataNo];
    
    NSString* title = [NSString stringWithFormat: @"%@", [_selectedCustomOrderData valueForKey:@"itemName"] ];
    [_customOrderValueLabel setText:title];
//    [_customOrderButton setHidden:FALSE];
    
    if (_customOrderData) {
        [_customOrderButton setImage:[UIImage imageNamed:@"option_on"] forState:UIControlStateNormal];
    }
    else {
        [_customOrderButton setImage:[UIImage imageNamed:@"option_off"] forState:UIControlStateNormal];
        [_customOrderValueLabel setText:[SELLocalization localizedStringForKey:@"MES_CHOISE"]];
    }
}

#pragma mark - SELToppingViewControllerDelegate

- (void)SelectedTopping:(NSMutableArray *)selectedToppingList sender:(SELToppingViewController *)sender
{
    _selectedToppingDataList = selectedToppingList;
    
    // ToppingGroup更新
    NSString* title = @"";
    for (SELItemData* itemData in selectedToppingList) {
        NSString* selectedToppingItem = [NSString stringWithFormat: @"%@(+%@)", itemData.itemName, itemData.price ];
        title = [NSString stringWithFormat:@"%@ %@", title, selectedToppingItem];
    }
    [_toppingValueLabel setText:title];
//    [_toppingButton setHidden:FALSE];

    if (_selectedToppingDataList && _selectedToppingDataList.count > 0) {
        [_toppingButton setImage:[UIImage imageNamed:@"option_on"] forState:UIControlStateNormal];
    }
    else {
        [_toppingButton setImage:[UIImage imageNamed:@"option_off"] forState:UIControlStateNormal];
        [_toppingValueLabel setText:[SELLocalization localizedStringForKey:@"MES_CHOISE"]];
    }
}

- (void)touchQuantityPlus:(id)sender
{
    if (_quantity >= 9) {
        return;
    }
    _quantity++;
    [self updateQuantity];
}

- (void)touchQuantityMinus:(id)sender
{
    if (_quantity <= 1) {
        return;
    }
    _quantity--;
    [self updateQuantity];
}

@end
