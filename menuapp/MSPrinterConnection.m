//
//  MSPrinterConnection.m
//  MenuApp
//
//  Created by dpcc on 13/03/29.
//
//

#import "MSPrinterConnection.h"
#import "PrinterController.h"
#import "SmaregiUtil.h"
#import "SELOrderData.h"

#import "OrderEpsonPrinter.h"
#import "SELItemDataManager.h"

@implementation MSPrinterConnection

- (void)orderConfirm:(NSArray*)orderList{
    
    int amount = 0;
    int total = 0;
    
    // 印刷処理用データを作成する
    NSMutableArray* orderDetails = [[NSMutableArray alloc]init];
    for (SELOrderData* orderData in orderList)
    {
        SELItemData* itemData = orderData.OrderItemData;
        
        // 注文番号を作成
        NSString* orderDetailNo = [self createOrderDetailNo];
        
        // カスタムオーダがある場合は作成する
        NSString* setMenuCode = @"";
        NSString* setMenuName = @"";
        if (orderData.SelectedCustomOrder != NULL) {
            setMenuCode = orderData.SelectedCustomOrder.menuCode;
            setMenuName = orderData.SelectedCustomOrder.itemNameJA;
        }
        
        // OrderDetailを作成する
        OrderDetail* orderDetail = [[OrderDetail alloc]init];
        orderDetail.orderDateTime = [orderData.OrderDateTime dateTimeFormattedString];
        orderDetail.staffName = @"セルフオーダー";
        orderDetail.orderDetailNo = orderDetailNo;
        orderDetail.itemId = itemData.menuCode;
        orderDetail.itemName = itemData.itemNameJA;
        orderDetail.quantity = orderData.OrderQuantity;
        orderDetail.price = [NSNumber numberWithInteger:[itemData.price integerValue]];
        orderDetail.salesPrice = [NSNumber numberWithInteger:[itemData.price integerValue]];
        orderDetail.printerId = @"";
        orderDetail.itemDrillDownId = setMenuCode;
        orderDetail.itemDrillDownName = setMenuName;
        orderDetail.toppingItems = [[NSMutableArray alloc]init];
        [orderDetails addObject:orderDetail];
        
        total += [orderDetail.price intValue] * [orderDetail.quantity intValue];
        
        // トッピングある場合は商品として追加する
        for (SELItemData* toppingItemData in orderData.SelectedTopping) {
            
            // 親注文番号
            //NSString* parentOrderDetailNo = orderDetail.orderDetailNo;
            
            // OrderDetailを作成する
            OrderDetail* toppingOrderDetail = [[OrderDetail alloc]init];
            toppingOrderDetail.orderDateTime = [orderData.OrderDateTime dateTimeFormattedString];
            toppingOrderDetail.staffName = @"セルフオーダー";
            toppingOrderDetail.orderDetailNo = orderDetailNo;
            toppingOrderDetail.itemId = toppingItemData.menuCode;
            toppingOrderDetail.itemName = toppingItemData.itemNameJA;
            toppingOrderDetail.quantity = orderData.OrderQuantity;
            toppingOrderDetail.price = [NSNumber numberWithInteger:[toppingItemData.price integerValue]];
            toppingOrderDetail.salesPrice = [NSNumber numberWithInteger:[toppingItemData.price integerValue]];
            toppingOrderDetail.printerId = @"";
            toppingOrderDetail.itemDrillDownId = @"";
            toppingOrderDetail.itemDrillDownName = @"";
            
            // 親注文に追加
            [orderDetail.toppingItems addObject:toppingOrderDetail];
            
            total += [toppingOrderDetail.price intValue] * [toppingOrderDetail.quantity intValue];
        }
        
        amount += [orderData.OrderQuantity intValue];
    }
    
    // OrderHeaderを作成する
    OrderHeader* orderHeader = [[OrderHeader alloc]init];
    orderHeader.tableName = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];
    orderHeader.subtotal = [[NSNumber alloc]initWithInt:total];
    orderHeader.tax = [[NSNumber alloc]initWithInt:0];
    orderHeader.amount = [[NSNumber alloc]initWithInt:amount];
    orderHeader.total = [[NSNumber alloc]initWithInt:total];
    orderHeader.lastOrderDateTime = [[NSDate date] dateTimeFormattedString];
    orderHeader.numbers = [NSNumber numberWithInteger:1];
    orderHeader.isPrintSubTotalOnly = YES;

    NSString* printerType = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerType"];
    
    // エラー情報を初期化
    _errInfo = nil;
    
    if ([printerType isEqualToString:@"0"]) {
        // スター精密FVP10
        // 印刷を行う(ここからはスマレジソース)
        OrderStarPrinter* orderStarPrinter = [[OrderStarPrinter alloc] initWithDelegate:self];
        orderStarPrinter.delegate = self;
        [orderStarPrinter printOrder:orderHeader details:orderDetails];
    }
    else if([printerType isEqualToString:@"1"]) {
        // EPSON TM-T70II
        OrderEpsonPrinter* orderEpsonPrinter = [[OrderEpsonPrinter alloc] initWithDelegate:self];
        orderEpsonPrinter.delegate = self;
        [orderEpsonPrinter printOrder:orderHeader details:orderDetails];
    }
    
    if (!_errInfo) {
        // 印刷成功
        [self.delegate didOrderConfirm:TRUE info:@""];
    }
    else {
        NSString* errorMessage = [_errInfo componentsJoinedByString:@","];
        [self.delegate didOrderConfirm:FALSE info:errorMessage];
    }
    
}

- (void)getOrderedList{
    // プリンタ連携では注文履歴照会はできない
    [self.delegate didGetOrderedList:FALSE orderedList:NULL totalPrice:0 info:@"恐れ入りますがお近くのスタッフにお申し付けください。"];
}

- (void)callStaff{
    
    BOOL bResult = false;
    
    // スタッフ呼出伝票印刷処理
    OrderHeader* orderHeader = [[OrderHeader alloc]init];
    orderHeader.tableName = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];
    orderHeader.lastOrderDateTime = [[NSDate date] dateTimeFormattedString];

    NSString* printerType = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerType"];

    if ([printerType isEqualToString:@"0"]) {
        // スター精密FVP10
        // 印刷を行う(ここからはスマレジソース)
        OrderStarPrinter* orderStarPrinter = [[OrderStarPrinter alloc] initWithDelegate:self];
        bResult = [orderStarPrinter printCallStuff:orderHeader];
    }
    else if([printerType isEqualToString:@"1"]) {
        // EPSON TM-T70II
        OrderEpsonPrinter* orderEpsonPrinter = [[OrderEpsonPrinter alloc] initWithDelegate:self];
        bResult = [orderEpsonPrinter printCallStuff:orderHeader];
    }

    if (bResult) {
        [self.delegate didCallStaff:TRUE info:NULL];
    }
    else{
        [self.delegate didCallStaff:FALSE info:NULL];
    }

}

- (void)orderStarPrinterPrintDone
{
    NSLog(@"orderStarPrinterPrintDone");
}

- (void)orderStarPrinterPrintError:(StarPrinterPrintStatus)status
{
    NSLog(@"orderStarPrinterPrintError");
    
    if (!_errInfo) {
        _errInfo = [[NSMutableArray alloc]init];
    }
    
    // 印刷エラーを覚えておく
    NSString* message = nil;
    switch (status) {
        case StarPrinterPrintStatusConnectError:    message = NSLocalizedString(@"POPUP_MESSAGE_ERROR_CONNECT", nil); break;
        case StarPrinterPrintStatusCoverOpen:       message = NSLocalizedString(@"POPUP_MESSAGE_COVER_OPEN", nil); break;
        case StarPrinterPrintStatusRunOutOfPaper:   message = NSLocalizedString(@"POPUP_MESSAGE_RUN_OUT_OF_PAPER", nil); break;
        case StarPrinterPrintStatusError:           message = NSLocalizedString(@"POPUP_MESSAGE_PRINTER_ERROR", nil); break;
        default:
            message = NSLocalizedString(@"POPUP_MESSAGE_PRINTER_ERROR", nil); break;
    }
    [_errInfo addObject:message];
}

// #############################################################################
// エラー情報編集
// #############################################################################
- (NSString *)errInfoToString
{
    NSMutableString * retErrInfo = [NSMutableString stringWithFormat:@""];
    for (int i = 0; i < _errInfo.count; i++)
    {
        [retErrInfo appendString:[_errInfo objectAtIndex:i]];
        // エラー文言は長くなるため一つだけにする
        break;
//        if (i < _errInfo.count - 1)
//        {
//            [retErrInfo appendString:@", "];
//        }
    }
    return retErrInfo;
}

@end
