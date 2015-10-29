//
//  SELOrderListViewController.m
//  menuapp
//
//  Created by dpcc on 2014/04/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELOrderListViewController.h"
#import "SELOrderManager.h"
#import "SELOrderListViewCell.h"
#import "CurrencyUtil.h"
#import "SELItemDataManager.h"
#import "SELOrderData.h"
#import "library/SVProgressHUD/SVProgressHUD.h"

@interface SELOrderListViewController ()

@end

@implementation SELOrderListViewController

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
    
    // 合計金額
    [self updateTotal];
    
    // 注文リスト更新用
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateOrderList) name:SELUpdateOrderListMessageNotification object:nil];
    
    [self updateLocalizitaion];
}

- (void)updateLocalizitaion
{
    // 多言語対応
    [_orderListLabel setText:[SELLocalization localizedStringForKey:@"IB_ORDERLIST"]];
    [_totalOrderLabel setText:[SELLocalization localizedStringForKey:@"IB_TOTALORDER"]];
    [_confirmOrderNoteLabel setText:[SELLocalization localizedStringForKey:@"IB_CONFIRMORDERNOTE"]];
    [_yen setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_confirmOrderButton setTitle:[SELLocalization localizedStringForKey:@"IB_CONFIRMORDER"] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidAppear:(BOOL)animated{
//    self.preferredContentSize = CGSizeMake(460, 1800);
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    SELOrderManager* orderListController = [SELOrderManager instance];
    return [orderListController getOrderList].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SELOrderListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"orderlistcell" forIndexPath:indexPath];
    
    // Configure the cell...
    SELOrderManager* orderListController = [SELOrderManager instance];
    SELOrderData* orderData = [[orderListController getOrderList] objectAtIndex:indexPath.row];
    
    // 削除用にitemDataをcellに保持させる
    cell.orderData = orderData;
    SELItemData* itemData = orderData.OrderItemData;
    
    // 商品情報
    [cell.name setText:[itemData valueForKey:@"itemName"]];
    [cell.price setText:[NSString stringWithFormat:@"%@", [CurrencyUtil stringToCurrency:[itemData valueForKey:@"price"] ]]];
    
    // 商品画像
    UIImage* itemImage = [itemData getItemImage];
    [cell.image setImage:itemImage];
    
    // 個数
    [cell.quantity setText:[NSString stringWithFormat:@"%@", orderData.OrderQuantity]];
    
    // カスタムオーダー
    NSString* option = @"";
    if (orderData.SelectedCustomOrder) {
        option = orderData.SelectedCustomOrder.itemName;
    }
    
    // トッピング
    if (orderData.SelectedTopping) {
        for (SELItemData* customOrderItem in orderData.SelectedTopping) {
            option = [NSString stringWithFormat:@"%@ %@(+%@)", option, customOrderItem.itemName, customOrderItem.price];
        }
    }
    [cell.option setText:option];
    
    return cell;
}

/*
-(CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
    return 120;
}
*/

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}
*/

- (void)confirm:(id)sender
{
    SELOrderManager* orderListController = [SELOrderManager instance];
    orderListController.delegate = self;
    
    if ([[orderListController getOrderList] count] == 0) {
        return;
    }
    
    // view操作を無効
    [self.view setUserInteractionEnabled:FALSE];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD showWithStatus:[SELLocalization localizedStringForKey:@"MES_WAITORDERLING"]];
    
    [orderListController orderConfirm];
}

- (void)didOrderConfirm:(BOOL)bSuccess info:(id)info
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    // view操作を有効
    [self.view setUserInteractionEnabled:TRUE];
    
    if (bSuccess) {
        
        NSString* errorInfo = (NSString*)info;
        if ([errorInfo isEqualToString:@""]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:[SELLocalization localizedStringForKey:@"MES_ORDERFINISH"]
                                  message:[SELLocalization localizedStringForKey:@"MES_ORDERFINISHNOTE"]
                                  delegate: nil
                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                  otherButtonTitles:nil];
            [alert show];
        }
        else {
            // infoにエラー情報が設定されていれば表示する。
            NSString* infoString = @"";
            if ([info length] > 0){
                infoString = info;
            }
            NSString* errorMessage = [NSString stringWithFormat:@"恐れ入りますがお近くのスタッフにお申し付け下さい。%@",infoString];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"一部のご注文ができませんでした。"
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                  otherButtonTitles:nil];
            [alert show];
        }
        
        [self updateOrderList];
        
        // MenuViewへ戻る
        [self performSegueWithIdentifier:@"returnmenu" sender:self];
    }
    else {
        NSString* errorMessage = [NSString stringWithFormat:@"恐れ入りますがお近くのスタッフにお申し付け下さい。"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ご注文できませんでした"
										message:errorMessage
									   delegate:nil
							  cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil)
							  otherButtonTitles:nil];
        [alert show];

    }
}

- (void)updateOrderList
{
    // 合計値更新
    [self updateTotal];

    // 注文リスト更新
    [_orderListTable reloadData];
}

- (void)updateTotal
{
    _sum = 0;
    SELOrderManager* orderListController = [SELOrderManager instance];
    orderListController.delegate = self;
    for (SELOrderData* orderData in [orderListController getOrderList]) {
        SELItemData* itemData = orderData.OrderItemData;
        NSInteger price = [[itemData valueForKey:@"price"] integerValue];
        NSInteger quantity = [orderData.OrderQuantity intValue];
        _sum += price * quantity;
        
        for (SELItemData* toppingData in orderData.SelectedTopping) {
            NSInteger price = [[toppingData valueForKey:@"price"] integerValue];
            _sum += price * quantity;
        }
        
    }
    [_totalLabel setText:[CurrencyUtil integerToCurrency: _sum]];
}

@end
