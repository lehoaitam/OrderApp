//
//  SELPurchaseHistoryViewController.m
//  menuapp
//
//  Created by dpcc on 2014/05/07.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELPurchaseHistoryViewController.h"
#import "SELPurchaseHistoryViewCell.h"
#import "SELItemDataManager.h"
#import "CurrencyUtil.h"
#import "SELOrderData.h"

@interface SELPurchaseHistoryViewController ()

@end

@implementation SELPurchaseHistoryViewController

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
    SELOrderManager* orderListController = [SELOrderManager instance];
    orderListController.delegate = self;
    [orderListController getOrderedList];
    
    _totalPrice = 0;
    _numberOfPeople = 1;
    [self splitCost];
    
    // 多言語対応
    [self updateLocalizitaion];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    // 割り勘表示ON/OFF
    BOOL useWarikan = [userDefaults boolForKey:@"useWarikan"];
    if (useWarikan) {
        [_dutchLabel setHidden:NO];
        [_numberOfPeopleLabel setHidden:NO];
        [_numberOfPeoplePlusButton setHidden:NO];
        [_numberOfPeopleMinusButton setHidden:NO];
        [_splitCostLabel setHidden:NO];
    }
    else {
        [_dutchLabel setHidden:YES];
        [_numberOfPeopleLabel setHidden:YES];
        [_numberOfPeoplePlusButton setHidden:YES];
        [_numberOfPeopleMinusButton setHidden:YES];
        [_splitCostLabel setHidden:YES];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLocalizitaion
{
    // 多言語対応
    [_totalAmountLabel setText:[SELLocalization localizedStringForKey:@"IB_TOTALAMOUNT"]];
    [_totalAmountYenLabel setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_dutchLabel setText:[SELLocalization localizedStringForKey:@"IB_DUTCH"]];
    [_dutchYenLabel setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_closeButton setTitle:[SELLocalization localizedStringForKey:@"IB_CLOSE"] forState:UIControlStateNormal];
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

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.PurchaseHistory count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SELPurchaseHistoryViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"purchasehistorycell" forIndexPath:indexPath];
    [cell updateLocalizitaion];
    
    // Configure the cell...
    SELOrderData* orderData = [self.PurchaseHistory objectAtIndex:indexPath.row];
    
    // 商品名
    [cell.name setText:orderData.OrderItemData.itemName];
    
    // 注文キャンセル表示
    if ([orderData.OrderCancelFlag boolValue]) {
        [cell.canceledLabel setHidden:false];
    }
    else {
        [cell.canceledLabel setHidden:true];
    }
    
    // 商品画像
    UIImage* itemImage = [orderData.OrderItemData getItemImage];
    [cell.image setImage:itemImage];
    
    // 価格
    [cell.price setText:[NSString stringWithFormat:@"%@", [CurrencyUtil stringToCurrency:orderData.OrderItemData.price] ]];
    
    // 数量
    [cell.quantity setText:[NSString stringWithFormat:@"%@" ,orderData.OrderQuantity]];
    
    // 合計
    [cell.total setText:[NSString stringWithFormat:@"%@" , [CurrencyUtil numberToCurrency:orderData.OrderTotalPrice]]];
    
    // 注文時間
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [cell.leadtime setText:[dateFormatter stringFromDate:orderData.OrderDateTime]];
    
    // カスタムオーダー
    if (orderData.SelectedCustomOrder) {
        [cell.customOrder setText:orderData.SelectedCustomOrder.itemName];
    }
    else {
        [cell.customOrder setText:@""];
    }
    
    // トッピング
    if (orderData.SelectedTopping) {
        NSString* toppingString = @"";
        for (SELItemData* toppingItem in orderData.SelectedTopping) {
            NSString* toppingStringWk = [NSString stringWithFormat:@"%@(¥%@)", toppingItem.itemName, toppingItem.price];
            toppingString = [NSString stringWithFormat:@"%@ %@", toppingString, toppingStringWk];
        }
        [cell.topping setText:toppingString];
    }
    else {
        [cell.topping setText:@""];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void)close:(id)sender
{
    // 閉じる
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - ordermanager delegate

- (void)didGetOrderedList:(BOOL)bSuccess orderedList:(NSArray *)orderedList totalPrice:(NSInteger)totalPrice info:(id)info
{
    if (bSuccess) {
//        self.PurchaseHistory = [self tabulation:orderedList];
        
        _totalPrice = totalPrice;
        self.PurchaseHistory = orderedList;
        
        // 割り勘
        [self splitCost];
        
        [_totalPriceLabel setText:
            [CurrencyUtil stringToCurrency:[NSString stringWithFormat:@"%ld", (long)_totalPrice]]];
        [_tableView reloadData];
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

//// 注文リストを集計する
//- (NSMutableArray*)tabulation:(NSArray*)orderList
//{
//    SELItemDataManager* itemManager = [SELItemDataManager instance];
//    
//    NSMutableArray* retArray = [[NSMutableArray alloc]init];
//    
//    // ひも付けのため、トッピング以外のデータを先に作成、
//    // その後、親データにひも付けしつつ、トッピングデータを作成します。
//    
//    // 先にトッピング以外のデータを作成
//    for (NSDictionary* orderDetail in orderList) {
//        
//        if ([orderDetail objectForKey:@"parentOrderDetailNo"] != [NSNull null] &&
//            [orderDetail objectForKey:@"parentOrderDetailNo"] != nil) {
//            continue;
//        }
//        
//        SELOrderData* orderData = [[SELOrderData alloc]init];
//        orderData.OrderDetailNO = [orderDetail objectForKey:@"orderDetailNo"];
//        orderData.SelectedTopping = [[NSMutableArray alloc]init];
//        
//        // 注文商品
//        NSString* itemID = [orderDetail objectForKey:@"itemId"];
//        orderData.OrderItemData = [itemManager getItemData:itemID];
//        if (!orderData.OrderItemData) {
//            continue;
//        }
//        
//        // ステータス
//        NSString* status = [orderDetail objectForKey:@"status"];
//        if ([status isEqualToString:@"9"]) {
//            // 9の場合はオーダーキャンセル
//            orderData.OrderCancelFlag = [NSNumber numberWithBool:true];
//        }
//        else {
//            // それ以外は通常注文
//            orderData.OrderCancelFlag = [NSNumber numberWithBool:false];
//        }
//        
//        // カスタムオーダー
//        NSString* customItemID = [orderDetail objectForKey:@"itemDrillDownId"];
//        orderData.SelectedCustomOrder = [itemManager getItemData:customItemID];
//        
//        // 注文数
//        NSInteger quantity = [[orderDetail objectForKey:@"quantity"] intValue];
//        orderData.OrderQuantity = [orderDetail objectForKey:@"quantity"];
//        
//        // 単価
//        NSInteger salesPrice = [[orderDetail objectForKey:@"salesPrice"] intValue];
//        
//        // 合計金額
//        NSInteger total = quantity * salesPrice;
//        orderData.OrderTotalPrice = [NSNumber numberWithInteger: total];
//        
//        // 注文時間
//        NSString* orderDateTime = [orderDetail objectForKey:@"orderDateTime"];
//        
//        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
//        [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
//        orderData.OrderDateTime = [inputFormatter dateFromString:orderDateTime];
//
//        [retArray addObject:orderData];
//        
//        // 総合計を更新(キャンセルではない場合のみ)
//        if (![orderData.OrderCancelFlag boolValue]) {
//            _totalPrice += total;
//        }
//    }
//    
//    // トッピングデータのみ
//    for (NSDictionary* orderDetail in orderList) {
//        
//        if ([orderDetail objectForKey:@"parentOrderDetailNo"] == [NSNull null] ||
//            [orderDetail objectForKey:@"parentOrderDetailNo"] == nil) {
//            continue;
//        }
//        
//        NSString* parentOrderDetailNo = [orderDetail objectForKey:@"parentOrderDetailNo"];
//        SELOrderData* parentOrderData = [self getOrderData:retArray detailNO:parentOrderDetailNo];
//        if (!parentOrderData) {
//            NSLog(@"ERROR:親注文データが見つかりませんでした！");
//            continue;
//        }
//        
//        // 商品データを取得
//        NSString* itemID = [orderDetail objectForKey:@"itemId"];
//        SELItemData* toppingItem = [itemManager getItemData:itemID];
//        [parentOrderData.SelectedTopping addObject:toppingItem];
//        
//        // トッピング注文数
//        NSInteger quantity = [[orderDetail objectForKey:@"quantity"] intValue];
//        
//        // トッピング金額
//        NSInteger salesPrice = [[orderDetail objectForKey:@"salesPrice"] intValue];
//        
//        // トッピング総額
//        NSInteger toppingTotal = quantity * salesPrice;
//
//        // 合計金額を更新
//        
//        // 親注文金額
//        NSInteger parentPrice = [parentOrderData.OrderTotalPrice integerValue];
//        parentOrderData.OrderTotalPrice = [NSNumber numberWithInteger:parentPrice + toppingTotal];
//        
//        // 合計金額を更新する(足し込むのはトッピング料金のみ)
//        if (![parentOrderData.OrderCancelFlag boolValue]) {
//            _totalPrice += toppingTotal;
//        }
//    }
//    
//    return retArray;
//}
//
//- (SELOrderData*)getOrderData:(NSArray*)orderDataList detailNO:(NSString*)orderDetailNO
//{
//    for (SELOrderData* orderData in orderDataList)
//    {
//        if ([orderData.OrderDetailNO isEqualToString:orderDetailNO]) {
//            return orderData;
//        }
//    }
//    return NULL;
//}

- (IBAction)plus {
	if (_numberOfPeople != 100) {
		++_numberOfPeople;
		[self splitCost];
	}
	
}

- (IBAction)minus {
	if (1 < _numberOfPeople) {
		--_numberOfPeople;
		[self splitCost];
	}
}

//割り勘
- (void)splitCost {
	//合計金額を人数で割って、割り勘金額に表示する
	if (0 < _totalPrice && 0 < _numberOfPeople) {
		NSInteger nSplitCost = _totalPrice / _numberOfPeople;
        [_splitCostLabel setText:
            [CurrencyUtil stringToCurrency:[NSString stringWithFormat: @"%ld", (long)nSplitCost]]];
        [_numberOfPeopleLabel setText:[NSString stringWithFormat:@"%ld", (long)_numberOfPeople]];
	} else {
        [_splitCostLabel setText:[CurrencyUtil stringToCurrency: @"0"]];
	}
    
}

@end
