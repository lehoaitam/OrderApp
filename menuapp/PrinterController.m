//
//  PrinterController.m
//  MenuApp
//
//  Created by ipadso on 12/03/05.
//  Copyright (c) 2012年 Kobe Digital Labo.,Inc. All rights reserved.
//  レジ無版対応

#import "PrinterController.h"
#import "OrderStarPrinter.h"
#import "OrderHeader.h"
#import "OrderDetail.h"
#import "OrderEpsonPrinter.h"

static id _instance = nil;

@implementation PrinterController

#pragma mark -
#pragma mark Public method
//// #############################################################################
//// スタッフ呼出伝票印刷処理
//// #############################################################################
//- (void)printCallStaff
//{    
//    unsigned char characterExpansion[] = {0x1b, 0x69, 0x01, 0x01};
//    unsigned char characterReduction[] = {0x1b, 0x69, 0x00, 0x00};
//    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x31};
//    unsigned char partialCutFeed[] = {0x1b, 0x64, 0x33};
//    NSMutableString * orderItem;
//    
//    // Alertタイトル、メッセージ
//    NSString * avTitle;
//    NSMutableString * avMessage = [NSMutableString stringWithFormat:@""];
//
//    // エラー情報初期化
//    _errInfo = [NSMutableArray array];
//    
//    // 注文日時取得
//    NSDate * dateSource = [NSDate date];
//    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateFormat:@"YYYY/MM/dd  HH:mm:ss"];
//    _orderDate = [dateFormatter stringFromDate:dateSource];
//    [dateFormatter release];
//    
//    // テーブルNo.取得
//    NSDictionary * adminDict = [[MSAdminManager instance] valueForUndefinedKey:kSettingTableNumberKey];
//    _tableNo = [adminDict valueForKey:@"value"];
//    
//	// 設定ファイルよりスタッフ呼出の商品コードを取得
//    NSString * callStaffCode = [[[MSAdminManager instance]
//                                 valueForUndefinedKey:kSettingStaffCallCodeKey] objectForKey:@"value"];
//	
//	// 商品CSVよりスタッフ呼出の商品情報を取得
//    NSDictionary * callStaffItem = [[MSMasterDataManager instance]
//                                    itemInfoFromItemID:callStaffCode];
//
//    // プリンターポートオープン（商品毎に出力先が異なる）
//    Port * printerPort = [self openPrinterPortForSmallSlip:callStaffItem];
//    
//    // プリンターポートオープン成功でスタッフ呼び出し伝票印刷
//    if (printerPort != nil)
//    {
//        // 設定コマンド送信成功で厨房伝票印刷
//        if ([self printSetting:printerPort])
//        {
//            // 注文コマンド初期化
//            [self initOrderCommand];
//            
//            // 文字サイズ拡大
//            if (_charPrintSizeExpansion)
//            {
//                [_orderCommands appendBytes:characterExpansion length:4];
//            }
//            
//            // 印字項目(テーブルNo)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"テーブルNo：%@\n", _tableNo];
//            [self createOrderCommand:orderItem];
//            
//            // 文字サイズ縮小
//            [_orderCommands appendBytes:characterReduction length:4];
//            
//            // 印字項目(呼出日時)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"呼出日時：%@\n", _orderDate];
//            [orderItem appendString:@"-----------------------------------------------\n"];
//            [self createOrderCommand:orderItem];
//            
//            // 文字サイズ拡大
//            if (_charPrintSizeExpansion)
//            {
//                [_orderCommands appendBytes:characterExpansion length:4];
//            }
//            
//            // 位置揃え（中央=[0x31]）
//            [_orderCommands appendBytes:alignmentCommand length:4];
//
//            // 印字項目(数量、商品名)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"★%@★\n", [callStaffItem objectForKey:kItemNameKey]];
//            [self createOrderCommand:orderItem];
//            
//            // 文字サイズ縮小
//            [_orderCommands appendBytes:characterReduction length:4];
//
//            // パーシャルカット
//            [_orderCommands appendBytes:partialCutFeed length:3];
//            
//            // スタッフ呼び出し伝票をプリンターへ出力
//            [self writeCommandToPrinter:printerPort printCommands:_orderCommands];
//            
//            // 注文コマンド解放
//            [self initOrderCommand];
//        }
//        else
//        {
//            // 設定コマンド送信失敗時
//            avTitle = @"店員呼出ができません";
//            [avMessage appendFormat:
//             @"お手数ですがお近くのスタッフまでお申し付け下さい。（設定コマンド送信エラー情報：%@）", [self errInfoToString]];
//            UIAlertView * av = [[UIAlertView alloc]
//                                initWithTitle:avTitle
//                                message:avMessage
//                                delegate:nil
//                                cancelButtonTitle:@"OK"
//                                otherButtonTitles: nil];
//            [av show];
//            [av release];
//        }
//    }
//    else
//    {
//        // プリンターポートオープン失敗時
//        avTitle = @"店員呼出ができません";
//        [avMessage appendFormat:
//         @"お手数ですがお近くのスタッフまでお申し付け下さい。（プリンターポートオープンエラー情報：%@）", [self errInfoToString]];
//        UIAlertView * av = [[UIAlertView alloc]
//                            initWithTitle:avTitle
//                            message:avMessage
//                            delegate:nil
//                            cancelButtonTitle:@"OK"
//                            otherButtonTitles: nil];
//        [av show];
//        [av release];
//    }
//
//    // プリンターポートクローズ
//    [self closePrinterPort:printerPort];
//}

- (BOOL) isNowOrder:(NSString*)targetOrderDetailNO localItems:(NSArray*)localItems
{
    for (NSMutableDictionary* orderDetailParam in localItems){
        NSString* orderDetailNo = [orderDetailParam objectForKey:@"orderDetailNo"];
        if ([targetOrderDetailNO isEqualToString:orderDetailNo]) {
            return TRUE;
        }
    }
    return FALSE;
}

// #############################################################################
// 注文伝票印刷処理
// #############################################################################
- (NSMutableArray *)printOrder:(NSDictionary *)orderHeaderDict orderDetailList:(NSArray*)orderDetailList;
{
    // レスポンスデータからOrderStarPrinter用オブジェクトを作成する
    NSMutableArray * decideItems = [[NSMutableArray alloc]init];
    
    // OrderHeader用
    int subtotal = 0;

    // OrderDetailを作成する
    NSMutableArray* orderDetails = [[NSMutableArray alloc]init];
    for (NSDictionary * orderDict in orderDetailList)
    {
        // トッピングデータは後で作成する
        if ([orderDict objectForKey:@"parentOrderDetailNo"] != [NSNull null]) {
            continue;
        }
        
        OrderDetail* orderDetail = [[OrderDetail alloc]init];
        
        orderDetail.orderDateTime = [orderDict objectForKey:@"orderDateTime"];
        orderDetail.staffName = @"セルフオーダー";
        orderDetail.orderDetailNo = [orderDict objectForKey:@"orderDetailNo"];
        orderDetail.itemId = [orderDict objectForKey:@"itemId"];
        orderDetail.itemName = [orderDict objectForKey:@"itemName"];
        int quantity = [[orderDict objectForKey:@"quantity"] intValue];
        orderDetail.quantity =   [[NSNumber alloc]initWithInt:quantity];
        int price = [[orderDict objectForKey:@"price"] intValue];
        orderDetail.price =      [[NSNumber alloc]initWithInt:price];
        orderDetail.salesPrice = [[NSNumber alloc]initWithInt:[[orderDict objectForKey:@"salesPrice"] intValue]];
        orderDetail.printerId = [orderDict objectForKey:@"printerId"];
        orderDetail.itemDrillDownId = [orderDict objectForKey:@"itemDrillDownId"];
        orderDetail.itemDrillDownName = [orderDict objectForKey:@"itemDrillDownName"];
        orderDetail.toppingItems = [[NSMutableArray alloc]init];
        
        [orderDetails addObject:orderDetail];
        
        // 小計を計算する
        subtotal += (quantity * price);
    }
    
    // トッピングデータのOrderDetailを作成する
    for (NSDictionary * orderDict in orderDetailList)
    {
        // トッピングデータのみ対象
        if ([orderDict objectForKey:@"parentOrderDetailNo"] == [NSNull null]) {
            continue;
        }
        
        OrderDetail* parentOrderDetail = [self getOrderData:orderDetails detailNO:[orderDict objectForKey:@"parentOrderDetailNo"]];
        
        OrderDetail* orderDetail = [[OrderDetail alloc]init];
        
        orderDetail.orderDateTime = [orderDict objectForKey:@"orderDateTime"];
        orderDetail.staffName = @"セルフオーダー";
        orderDetail.orderDetailNo = [orderDict objectForKey:@"orderDetailNo"];
        orderDetail.itemId = [orderDict objectForKey:@"itemId"];
        orderDetail.itemName = [orderDict objectForKey:@"itemName"];
        int quantity = [[orderDict objectForKey:@"quantity"] intValue];
        orderDetail.quantity =   [[NSNumber alloc]initWithInt:quantity];
        int price = [[orderDict objectForKey:@"price"] intValue];
        orderDetail.price =      [[NSNumber alloc]initWithInt:price];
        orderDetail.salesPrice = [[NSNumber alloc]initWithInt:[[orderDict objectForKey:@"salesPrice"] intValue]];
        orderDetail.printerId = [orderDict objectForKey:@"printerId"];
        orderDetail.itemDrillDownId = [orderDict objectForKey:@"itemDrillDownId"];
        orderDetail.itemDrillDownName = [orderDict objectForKey:@"itemDrillDownName"];
        
        [parentOrderDetail.toppingItems addObject:orderDetail];
        
        // 小計を計算する
        subtotal += (quantity * price);
    }
    
    // OrderHeaderを作成する
    OrderHeader* orderHeader = [[OrderHeader alloc]init];
    orderHeader.tableName = [orderHeaderDict objectForKey:@"tableName"];
    orderHeader.subtotal = [[NSNumber alloc]initWithInt:subtotal];
    orderHeader.tax = [[NSNumber alloc]initWithInt:[[orderHeaderDict objectForKey:@"tax"] intValue]];
    orderHeader.amount = [[NSNumber alloc]initWithInt:[[orderHeaderDict objectForKey:@"amount"] intValue]];
    int total = [[orderHeaderDict objectForKey:@"total"] intValue];
    orderHeader.total = [[NSNumber alloc]initWithInt:total];
    orderHeader.lastOrderDateTime = [orderHeaderDict objectForKey:@"lastOrderDateTime"];
    orderHeader.numbers = [[NSNumber alloc]initWithInt:[[orderHeaderDict objectForKey:@"numbers"] intValue]];
    
    // テーブルカテゴリー
    orderHeader.tableCategory = [orderHeaderDict objectForKey:@"tableCategory"];
    
    // 注文済み小計(total - subtotal)
    int orderedtotal = total - subtotal;
    orderHeader.orderedtotal = [[NSNumber alloc]initWithInt:orderedtotal];

    // 印刷を行う
    
    // エラー情報初期化
    _errInfo = [NSMutableArray array];

    NSString* printerType = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerType"];
    if ([printerType isEqualToString:@"0"]) {
        // スター精密FVP10
        // 印刷を行う(ここからはスマレジソース)
        OrderStarPrinter* orderStarPrinter = [[OrderStarPrinter alloc] initWithDelegate:self];
        [orderStarPrinter printOrder:orderHeader details:orderDetails];
    }
    else if([printerType isEqualToString:@"1"]) {
        // EPSON TM-T70II
        OrderEpsonPrinter* orderEpsonPrinter = [[OrderEpsonPrinter alloc] initWithDelegate:self];
        [orderEpsonPrinter printOrder:orderHeader details:orderDetails];
    }

    /*
    // Alertタイトル、メッセージ
    NSString * avTitle;
    NSMutableString * avMessage = [NSMutableString stringWithFormat:@""];

    // エラー情報初期化
    _errInfo = [NSMutableArray array];
    
    // 会計伝票用プリンターポートオープン（事前接続チェック）
    Port * printerPort = [self openPrinterPortForBigSlip];
    if (printerPort != nil)
    {
        [self closePrinterPort:printerPort];
        // add by n.sasaki スマレジ対応
        self.enabledPrint = YES;
        self.ipAddress = printerPort.portName;
    }
    else
    {
        avTitle = @"注文確定できません";
        [avMessage appendFormat:
         @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。（会計用伝票プリンター接続エラー情報：%@）", [self errInfoToString]];
        UIAlertView * av = [[UIAlertView alloc]
                            initWithTitle:avTitle
                            message:avMessage
                            delegate:nil
                            cancelButtonTitle:@"OK"
                            otherButtonTitles: nil];
        [av show];
        [av release];
        
        return nil;
    }
    
    // スマレジ対応でコメント 2012.09.29 by n.sasaki
    // 伝票No.取得
    if (![self getSlipNo])
    {
        // 伝票No取得失敗時
        avTitle = @"注文確定できません";
        [avMessage appendFormat:
         @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。（伝票No取得エラー情報：%@）", [self errInfoToString]];
        UIAlertView * av = [[UIAlertView alloc]
                           initWithTitle:avTitle
                           message:avMessage
                           delegate:nil
                           cancelButtonTitle:@"OK"
                           otherButtonTitles: nil];
        [av show];
        [av release];

        return nil;
    }
    
    // 注文日時取得
    NSDate * dateSource = [NSDate date];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY/MM/dd  HH:mm:ss"];
    _orderDate = [dateFormatter stringFromDate:dateSource];
    [dateFormatter release];
    
    // テーブルNo.取得
    _tableNo = [[MSAdminManager instance] valueForKey:kSettingTableNumberKey];

    // 厨房伝票印刷処理
    self.useOrderPrintFont2x = TRUE;
    NSMutableArray * decideItems = [self printSmallSlip:items];
    
    // 会計伝票印刷処理
    if ([decideItems count] > 0)
    {
        // 印刷が成功(注文確定)した商品退避リストに商品が1つでもあれば会計伝票を印刷(店舗用、ゲスト用の2つを印刷)
        // 2012.09.28 n.sasaki modify スマレジ印刷に変更
        [self printBigSlip:decideItems slipKind:BIG_SLIP_MASTER];
        //[self printBigSlip:decideItems slipKind:BIG_SLIP_COPY];

        if ([items count] == [decideItems count])
        {
            // 注文リストのすべての商品がプリンター出力に成功した場合
            avTitle = @"ご注文ありがとうございます";
            [avMessage appendString:@"キャンセルの際はお近くのスタッフまでお申し付け下さい。"];
        }
        else
        {
            // 注文リストの一部の商品がプリンター出力に成功した場合
            avTitle = @"未確定のご注文があります";
            [avMessage appendFormat:
             @"再度、[注文確定]ボタンを押してもエラーになる場合は、お手数ですがお近くのスタッフまでお申し付け下さい。（伝票印刷エラー情報：%@）"
             ,[self errInfoToString]];
        }

        // 伝票No.更新
        if (![self updateSlipNo])
        {
            // 伝票No更新失敗時
            [avMessage appendFormat:
             @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。（伝票No更新エラー情報：%@）"
             ,[self errInfoToString]];
        }
    }
    else
    {
        // 注文リストのすべての商品がプリンター出力に失敗した場合
        avTitle = @"ご注文ができません";
        [avMessage appendFormat:
         @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。（伝票印刷エラー情報：%@）", [self errInfoToString]];
    }
    
    UIAlertView * av = [[UIAlertView alloc]
                       initWithTitle:avTitle
                       message:avMessage
                       delegate:nil
                       cancelButtonTitle:@"OK"
                       otherButtonTitles: nil];
    [av show];
    [av release];
     */
    
    // 印刷が成功(注文確定)した商品リストを返す
    return decideItems;
}

- (OrderDetail*)getOrderData:(NSArray*)orderDataList detailNO:(NSString*)targetOrderDetailNO
{
    for (OrderDetail* orderData in orderDataList)
    {
        if ([orderData.orderDetailNo isEqualToString:targetOrderDetailNO]) {
            return orderData;
        }
    }
    return NULL;
}

// スマレジ対応
- (void)orderStarPrinterPrintDone
{
    NSLog(@"orderStarPrinterPrintDone");
}

// スマレジ対応
- (void)orderStarPrinterPrintError:(StarPrinterPrintStatus)status
{
    NSLog(@"orderStarPrinterPrintError");
    
    // 印刷エラー内容を覚えておく
    NSString* message = nil;
    switch (status) {
        case StarPrinterPrintStatusConnectError:    message = NSLocalizedString(@"POPUP_MESSAGE_ERROR_CONNECT", nil); break;
        case StarPrinterPrintStatusCoverOpen:       message = NSLocalizedString(@"POPUP_MESSAGE_COVER_OPEN", nil); break;
        case StarPrinterPrintStatusRunOutOfPaper:   message = NSLocalizedString(@"POPUP_MESSAGE_RUN_OUT_OF_PAPER", nil); break;
        case StarPrinterPrintStatusError:           message = NSLocalizedString(@"POPUP_MESSAGE_PRINTER_ERROR", nil); break;
        default:
            break;
    }
    [_errInfo addObject:message];
}

// #############################################################################
// 厨房伝票印刷処理
// #############################################################################
- (NSMutableArray *)printSmallSlip:(NSDictionary *)items
{
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x01, 0x01};
    unsigned char characterReduction[] = {0x1b, 0x69, 0x00, 0x00};
    unsigned char partialCutFeed[] = {0x1b, 0x64, 0x33};
    NSMutableString * orderItem;
    
    // 印刷が成功(注文確定)した商品退避リスト
    NSMutableArray * decideItems = [NSMutableArray array];
    
//    // 注文リストの商品を厨房伝票に印刷
//    for (NSDictionary * orderDict in items)
//    {
//        // プリンターポートオープン（商品毎に出力先が異なる）
//        Port * printerPort = [self openPrinterPortForSmallSlip:orderDict];
//        
//        // プリンターポートオープン成功で厨房伝票印刷
//        if (printerPort != nil)
//        {
//            // 設定コマンド送信成功で厨房伝票印刷
//            if ([self printSetting:printerPort])
//            {
//                // 注文コマンド初期化
//                [self initOrderCommand];
//                
//                // 文字サイズ拡大
//                if (_charPrintSizeExpansion)
//                {
//                    [_orderCommands appendBytes:characterExpansion length:4];
//                }
//                
//                // 印字項目(テーブルNo、伝票No)
//                orderItem = [NSMutableString stringWithFormat:@""];
//                [orderItem appendFormat:@"テーブルNo：%@\n伝票No：%@\n", _tableNo, _slipNo];
//                [self createOrderCommand:orderItem];
//                
//                // 文字サイズ縮小
//                [_orderCommands appendBytes:characterReduction length:4];
//                
//                // 印字項目(注文日時)
//                orderItem = [NSMutableString stringWithFormat:@""];
//                [orderItem appendFormat:@"注文日時：%@\n", _orderDate];
//                [orderItem appendString:@"-----------------------------------------------\n"];
//                [self createOrderCommand:orderItem];
//                
//                // 文字サイズ拡大
//                if (_charPrintSizeExpansion)
//                {
//                    [_orderCommands appendBytes:characterExpansion length:4];
//                }
//                
//                // 印字項目(数量、商品名)
//                orderItem = [NSMutableString stringWithFormat:@""];
//                [orderItem appendFormat:@"□(%@)%@\n",
//                 [orderDict objectForKey:kItemQuantityKey],
//                 [orderDict objectForKey:kItemNameKey]];
//                [self createOrderCommand:orderItem];
//                
//                // 印字項目(セット商品名)
//                NSMutableArray * setItems = [self getSetItemName:orderDict];
//                for (NSString * setItemName in setItems)
//                {
//                    orderItem = [NSMutableString stringWithFormat:@""];
//                    [orderItem appendFormat:@"□%@\n", setItemName];
//                    [self createOrderCommand:orderItem];
//                }
//                
//                // 文字サイズ縮小
//                [_orderCommands appendBytes:characterReduction length:4];
//                
//                // パーシャルカット
//                [_orderCommands appendBytes:partialCutFeed length:3];
//                
//                // 注文データをプリンターへ出力
//                if ([self writeCommandToPrinter:printerPort printCommands:_orderCommands])
//                {
//                    // 印刷が成功した注文データを退避
//                    [decideItems addObject:orderDict];
//                }
//                
//                // 注文コマンド解放
//                [self initOrderCommand];
//            }
//        }
//        // プリンターポートクローズ
//        [self closePrinterPort:printerPort];
//    }
    // 印刷が成功(注文確定)した商品リストを返す
    return decideItems;
}

// #############################################################################
// 会計伝票印刷処理
// #############################################################################
- (void)printBigSlip:(NSDictionary *)items slipKind:(int)slipkind
{
//    NSMutableString * orderItem = [NSMutableString stringWithFormat:@""];
//    unsigned char characterExpansion[] = {0x1b, 0x69, 0x01, 0x01};
//    unsigned char characterReduction[] = {0x1b, 0x69, 0x00, 0x00};
//    unsigned char alignmentCommandRight[] = {0x1b, 0x1d, 0x61, 0x32};
//    unsigned char alignmentCommandCenter[] = {0x1b, 0x1d, 0x61, 0x31};
//    unsigned char alignmentCommandLeft[] = {0x1b, 0x1d, 0x61, 0x30};
//    unsigned char partialCutFeed[] = {0x1b, 0x64, 0x33};
//    unsigned int pageCount = 1;
//    unsigned int totalPage = 0;
//    unsigned int itemCountPerPage = 0;
//    unsigned int itemCountPerPageSave;
//    long itemAmount = 0;
//    long totalAmount = 0;
//    BOOL printResult = false;
//    
//    // Alertタイトル、メッセージ
//    NSString * avTitle;
//    NSMutableString * avMessage = [NSMutableString stringWithFormat:@""];
//
//    // 注文コマンド初期化
//    [self initOrderCommand];
//    
//    // 総ページ数算出
//    if (_bigSlipPageBreak)
//    {
//        totalPage = [items count] / _printItemsPerPage;
//        if ([items count] % _printItemsPerPage > 0)
//        {
//            // ページがまたがる場合は総ページ数を+1する
//            totalPage ++;
//        }
//    }
//    else
//    {
//        // 商品数を退避
//        itemCountPerPageSave = [items count];
//    }
//    
//    // 会計伝票は印刷が成功するまで再試行する(厨房伝票は印刷済みのであるため会計伝票のみ印刷)
//    while (!printResult)
//    {
//        // --------------------------------------------------
//        // プリンターポートオープン
//        // --------------------------------------------------
//        Port * printerPort = [self openPrinterPortForBigSlip];
//        if (printerPort == nil)
//        {
//            // エラーの場合は再試行を促す
//            avTitle = @"会計伝票が印刷できません";
//            [avMessage appendFormat:
//             @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。エラーが解消された後で[再試行]ボタンを押して下さい。\n\n（エラー情報：%@）", [self errInfoToString]];
//            UIAlertView * av = [[UIAlertView alloc]
//                                initWithTitle:avTitle
//                                message:avMessage
//                                delegate:nil
//                                cancelButtonTitle:@"再試行"
//                                otherButtonTitles: nil];
//            [av show];
//            [av release];
//            
//            // 再試行
//            continue;
//        }
//
//        // --------------------------------------------------
//        // 設定コマンド送信
//        // --------------------------------------------------
//        if (![self printSetting:printerPort])
//        {
//            // エラーの場合は再試行を促す
//            avTitle = @"会計伝票が印刷できません";
//            [avMessage appendFormat:
//             @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。エラーが解消された後で[再試行]ボタンを押して下さい。\n\n（エラー情報：%@）", [self errInfoToString]];
//            UIAlertView * av = [[UIAlertView alloc]
//                                initWithTitle:avTitle
//                                message:avMessage
//                                delegate:nil
//                                cancelButtonTitle:@"再試行"
//                                otherButtonTitles: nil];
//            [av show];
//            [av release];
//
//            // プリンターポートクローズ
//            [self closePrinterPort:printerPort];
//            
//            // 再試行
//            continue;
//        }
//        
//        // --------------------------------------------------
//        // ヘッダー部(改ページなしの場合はここで編集)
//        // --------------------------------------------------
//        if (!_bigSlipPageBreak)
//        {
//            // 中央に位置揃え(0x31)
//            [_orderCommands appendBytes:alignmentCommandCenter length:4];
//
//            // 印字項目(伝票種別)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            if (slipkind)
//            {
//                [orderItem appendString:@"お会計伝票【店舗用】\n"];
//            }
//            else
//            {
//                [orderItem appendString:@"お会計伝票【お客様控え】\n"];
//            }
//            [self createOrderCommand:orderItem];
//
//            // 左に位置揃え(0x30)
//            [_orderCommands appendBytes:alignmentCommandLeft length:4];
//
//            // 文字サイズ拡大
//            if (_charPrintSizeExpansion)
//            {
//                [_orderCommands appendBytes:characterExpansion length:4];
//            }
//            
//            // 印字項目(テーブルNo、伝票No)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"テーブルNo：%@\n伝票No：%@\n", _tableNo, _slipNo];
//            [self createOrderCommand:orderItem];
//            
//            // 文字サイズ縮小
//            [_orderCommands appendBytes:characterReduction length:4];
//            
//            // 印字項目(注文日時)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"注文日時：%@\n", _orderDate];
//            [orderItem appendString:@"-----------------------------------------------\n"];
//            [self createOrderCommand:orderItem];
//        }
//
//        // 厨房伝票の印刷に成功(注文確定)した商品だけ会計伝票を印刷
//        for (NSDictionary * orderDict in items)
//        {
//            // --------------------------------------------------
//            // ヘッダー部(改ページありの場合はここで編集)
//            // --------------------------------------------------
//            // 1ページあたりの印字商品カウンターがゼロの場合に編集
//            if (_bigSlipPageBreak)
//            {
//                if (itemCountPerPage == 0)
//                {
//                    // 中央に位置揃え(0x31)
//                    [_orderCommands appendBytes:alignmentCommandCenter length:4];
//                    
//                    // 印字項目(伝票種別)
//                    orderItem = [NSMutableString stringWithFormat:@""];
//                    if (slipkind)
//                    {
//                        [orderItem appendString:@"お会計伝票【店舗用】\n"];
//                    }
//                    else
//                    {
//                        [orderItem appendString:@"お会計伝票【お客様控え】\n"];
//                    }
//                    [self createOrderCommand:orderItem];
//                    
//                    // 左に位置揃え(0x30)
//                    [_orderCommands appendBytes:alignmentCommandLeft length:4];
//
//                    // 印字項目(注文日時、テーブルNo、伝票No、ページ数)
//                    NSString * stringPage;
//                    stringPage = [NSString stringWithFormat : @"(%d/%d頁)", pageCount, totalPage];
//
//                    // 文字サイズ拡大
//                    if (_charPrintSizeExpansion)
//                    {
//                        [_orderCommands appendBytes:characterExpansion length:4];
//                    }
//                    
//                    // 印字項目(テーブルNo、伝票No)
//                    orderItem = [NSMutableString stringWithFormat:@""];
//                    [orderItem appendFormat:@"テーブルNo：%@\n伝票No：%@%@\n", _tableNo, _slipNo, stringPage];
//                    [self createOrderCommand:orderItem];
//                    
//                    // 文字サイズ縮小
//                    [_orderCommands appendBytes:characterReduction length:4];
//                    
//                    // 印字項目(注文日時)
//                    orderItem = [NSMutableString stringWithFormat:@""];
//                    [orderItem appendFormat:@"注文日時：%@\n", _orderDate];
//                    [orderItem appendString:@"-----------------------------------------------\n"];
//                    [self createOrderCommand:orderItem];
//                }
//            }
//
//            // --------------------------------------------------
//            // 明細部(厨房伝票の印刷に成功(注文確定)した商品)
//            // --------------------------------------------------
//            // 印字項目(数量、商品名)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"%@\n", [orderDict objectForKey:kItemNameKey]];
//            [self createOrderCommand:orderItem];
//            
//            // 印字項目(セット商品名)
//            NSMutableArray * setItems = [self getSetItemName:orderDict];
//            orderItem = [NSMutableString stringWithFormat:@"("];
//            int setItemCount = 1;
//            for (NSString * setItemName in setItems)
//            {
//                if (setItemCount < [setItems count])
//                {
//                    [orderItem appendFormat:@"%@、", setItemName];
//                }
//                else
//                {
//                    [orderItem appendFormat:@"%@", setItemName];
//                }
//                setItemCount ++;
//            }
//            if ([setItems count] > 0)
//            {
//                [orderItem appendString:@")\n"];
//                [self createOrderCommand:orderItem];
//            }
//
//            // 右に位置揃え(0x32)
//            [_orderCommands appendBytes:alignmentCommandRight length:4];
//
//            // 印字項目(単価 * 数量 = 金額)
//            orderItem = [NSMutableString stringWithFormat:@""];
//            [orderItem appendFormat:@"%@", [self convertFormatCalculationRow:orderDict]];
//            [self createOrderCommand:orderItem];
//            
//            // 左に位置揃え(0x30)
//            [_orderCommands appendBytes:alignmentCommandLeft length:4];
//            
//            // 合計金額加算
//            itemAmount = [[orderDict objectForKey:kItemQuantityKey] integerValue] *
//            [[orderDict objectForKey:kItemPriceKey] integerValue];
//            totalAmount = totalAmount + itemAmount;
//            
//            // 改ページありの場合の処理
//            if (_bigSlipPageBreak)
//            {
//                // 1ページあたりの印字商品カウンターアップ
//                itemCountPerPage ++;
//                
//                // 1ページあたりの印字商品カウンター退避
//                itemCountPerPageSave = itemCountPerPage;
//
//                // 1ページあたりの印字商品カウンターが定数に達した場合
//                if (itemCountPerPage >= _printItemsPerPage)
//                {
//                    // 最終ページでない場合は改ページ処理
//                    if (pageCount < totalPage)
//                    {
//                        // ページ終端部分の編集
//                        orderItem = [NSMutableString stringWithFormat:@""];
//                        [orderItem appendString:@"-----------------------------------------------\n"];
//                        [orderItem appendString:@"(つづきの伝票があります)\n\n\n\n\n\n"];
//                        [self createOrderCommand:orderItem];
//
//                        // パーシャルカット(改ページ)
//                        [_orderCommands appendBytes:partialCutFeed length:3];
//                    }
//
//                    // ページカウントアップ、1ページあたりの印字商品カウンター初期化
//                    pageCount ++;
//                    itemCountPerPage = 0;
//                }
//            }
//        }
//
//        // --------------------------------------------------
//        // フッター部
//        // --------------------------------------------------
//        orderItem = [NSMutableString stringWithFormat:@""];
//        [orderItem appendString:@"-----------------------------------------------\n"];
//        [self createOrderCommand:orderItem];
//
//        // 右に位置揃え(0x32)
//        [_orderCommands appendBytes:alignmentCommandRight length:4];
//
//        // 印字項目(合計金額)
//        orderItem = [NSMutableString stringWithFormat:@""];
//        [orderItem appendFormat:@"合計  %@円\n", [self convertFormatAmount:totalAmount]];
//        [self createOrderCommand:orderItem];
//
//        // 左に位置揃え(0x30)
//        [_orderCommands appendBytes:alignmentCommandLeft length:4];
//
//        orderItem = [NSMutableString stringWithFormat:@""];
//        [orderItem appendString:@"-----------------------------------------------\n"];
//        if (!slipkind)
//        {
//            [orderItem appendString:@"ご注文ありがとうございます。お会計の際は、すべての伝票をスタッフへお渡しください。\n"];
//        }
//        
//        if (itemCountPerPageSave < _printItemsPerPage)
//        {
//            // 1ページあたりの印字商品数が少ない場合は空行を挿入(伝票サイズ調整)
//            for (int i = 0; i <= _printItemsPerPage - itemCountPerPageSave; i++)
//            {
//                [orderItem appendString:@"\n\n"];
//            }
//        }
//        [self createOrderCommand:orderItem];
//
//        // パーシャルカット(終端ページ)
//        [_orderCommands appendBytes:partialCutFeed length:3];
//
//        // --------------------------------------------------
//        // プリンターへ出力
//        // --------------------------------------------------
//        if ([self writeCommandToPrinter:printerPort printCommands:_orderCommands])
//        {
//            // 印刷成功で再試行ループ脱出
//            printResult = true;
//        }
//        else
//        {
//            // エラーの場合は再試行を促す
//            avTitle = @"会計伝票が印刷できません";
//            [avMessage appendFormat:
//             @"エラーが発生しましたので、お手数ですがお近くのスタッフまでお申し付け下さい。エラーが解消された後で[再試行]ボタンを押して下さい。\n\n（エラー情報：%@）", [self errInfoToString]];
//            UIAlertView * av = [[UIAlertView alloc]
//                                initWithTitle:avTitle
//                                message:avMessage
//                                delegate:nil
//                                cancelButtonTitle:@"再試行"
//                                otherButtonTitles: nil];
//            [av show];
//            [av release];
//
//            // プリンターポートクローズ
//            [self closePrinterPort:printerPort];
//            
//            // 再試行
//            continue;
//        }
//        // プリンターポートクローズ
//        [self closePrinterPort:printerPort];
//    }
//
//    // --------------------------------------------------
//    // 注文コマンド解放
//    // --------------------------------------------------
//    [self releaseOrderCommand];
}
 
// #############################################################################
// セット商品名取得
// #############################################################################
- (NSMutableArray *)getSetItemName:(NSDictionary *)orderDict
{
    // リターン値(セット商品名の配列)
    NSMutableArray * retSetItemName = [NSMutableArray array];
    
//    // 注文データ内のセット商品データをセット
//    NSString * setItem = [orderDict objectForKey:kItemSetItemkey];
//    
//    // 注文データ内にセット商品データが含まれる場合は、その商品名を取得する(最大3階層)
//    if ([setItem isKindOfClass:[NSArray class]])
//    {
//        // セットメニュー等(1階層目)
//        NSArray * aArray = (NSArray *)setItem;
//        for (id aTemp in aArray)
//        {
//            if ([aTemp isKindOfClass:[NSArray class]])
//            {
//                // セットメニュー等(2階層目)
//                NSArray * aaArray = (NSArray *)aTemp;
//                for (id aaTemp in aaArray)
//                {
//                    if( [aaTemp isKindOfClass:[NSArray class]] )
//                    {
//                        // セットメニュー等(3階層目)
//                        NSArray * aaaArray = (NSArray *)aaTemp;
//                        for (id aaaTemp in aaaArray)
//                        {
//                            NSDictionary * item = [[MSMasterDataManager instance]
//                                                   itemInfoFromItemID:[aTemp objectForKey:kItemMenuCodeKey]];
//                            [retSetItemName insertObject:[item objectForKey:kItemNameKey] atIndex:0];
//                        }
//                    }
//                    else
//                    {
//                        NSDictionary * item = [[MSMasterDataManager instance]
//                                               itemInfoFromItemID:[aTemp objectForKey:kItemMenuCodeKey]];
//                        [retSetItemName insertObject:[item objectForKey:kItemNameKey] atIndex:0];
//                    }
//                }
//            }
//            else
//            {
//                NSDictionary * item = [[MSMasterDataManager instance]
//                                       itemInfoFromItemID:[aTemp objectForKey:kItemMenuCodeKey]];
//                [retSetItemName insertObject:[item objectForKey:kItemNameKey] atIndex:0];
//            }
//        }
//    }
    return retSetItemName;
}

// #############################################################################
// 会計伝票金額計算行印字フォーマット変換
// #############################################################################
- (NSMutableString *)convertFormatCalculationRow:(NSDictionary *)orderDict
{
    int spaceLength;
    NSString * amountString;
    NSMutableString * calculationRow = [NSMutableString stringWithFormat:@""];
    
//    // 単価
//    amountString = [self convertFormatAmount:[[orderDict objectForKey:kItemPriceKey] integerValue]];
//    spaceLength = 10 - [amountString length];
//    for (int i = 0; i < spaceLength; i++)
//    {
//        [calculationRow appendString:@" "];
//    }
//    [calculationRow appendFormat:@"%@円 * ", amountString];
//
//    // 数量
//    amountString = [orderDict objectForKey:kItemQuantityKey];
//    spaceLength = 3 - [amountString length];
//    for (int i = 0; i < spaceLength; i++)
//    {
//        [calculationRow appendString:@" "];
//    }
//    [calculationRow appendFormat:@"%@ = ", amountString];
//
//    // 金額(単価 * 数量)
//    int calculationTotal = [[orderDict objectForKey:kItemQuantityKey] integerValue] *
//    [[orderDict objectForKey:kItemPriceKey] integerValue];
//    amountString = [self convertFormatAmount:calculationTotal];
//    spaceLength = 10 - [amountString length];
//    for (int i = 0; i < spaceLength; i++)
//    {
//        [calculationRow appendString:@" "];
//    }
//    [calculationRow appendFormat:@"%@円\n", amountString];

    return calculationRow;
}

// #############################################################################
// 数値印字フォーマット変換(3桁カンマ区切り)
// #############################################################################
- (NSString *)convertFormatAmount:(int)amount
{
    NSNumber * number = [[NSNumber alloc] initWithLong:amount];
    NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    [formatter setGroupingSize:3];
    NSString * strAmount = [formatter stringFromNumber:number];            
    [number release];
    [formatter release];
    return strAmount;
}

// #############################################################################
// 伝票No取得処理
// #############################################################################
- (BOOL)getSlipNo
{
    @try
    {
        // 注文日付取得
        NSDate * dateSource = [NSDate date];
        NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"YYYYMMdd"];
        NSString * orderDate = [dateFormatter stringFromDate:dateSource];
        int orderDateNow = [orderDate intValue];
        [dateFormatter release];
        
        // 伝票No設定値初期化
        _slipNoData = @"";
        
        // ホームディレクトリ直下にあるDocumentsフォルダを取得する
        NSArray * docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        // 伝票No管理ファイルのパスを作成
        _slipNoFilePath = [[docPath objectAtIndex:0] stringByAppendingPathComponent:@"slipno_manage.txt"];
        
        // 伝票No管理ファイルマネージャー生成
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        // 伝票No管理ファイル名有無チェック
        if (![fileManager fileExistsAtPath:_slipNoFilePath])
        {
            // 伝票No管理ファイルが存在しない場合
            // 伝票No管理ファイルを作成(空ファイル作成)
            [fileManager createFileAtPath:_slipNoFilePath contents:[NSData data] attributes:nil];
            
            // 伝票Noの初期値設定
            _slipNo = @"00001";
            _slipNoData = [NSString stringWithFormat:@"%@ %@", orderDate, _slipNo];
        }
        
        // 伝票No管理ファイル・オープン
        NSFileHandle * slipNoFileHandle = [NSFileHandle fileHandleForReadingAtPath:_slipNoFilePath];
        if (slipNoFileHandle == nil)
        {
            // オープン失敗時はエラーリターン
            [_errInfo addObject:@"伝票No管理ファイルオープンエラー"];
            return false;
        }
        
        // 伝票No管理ファイルが存在する場合
        if ([_slipNoData length] <= 0)
        {
            // 伝票No管理ファイルを読み込む
            NSData * data = [slipNoFileHandle readDataToEndOfFile];
            NSString * slipNoRow = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            int orderDatePast = [[slipNoRow substringToIndex:8] intValue];
            if (orderDateNow == orderDatePast)
            {
                // 注文日付が同日の場合
                // 伝票Noをインクリメントして伝票No管理ファイルへ記録する設定値を編集
                int slipNo = [[slipNoRow substringWithRange:NSMakeRange(9,5)] intValue] + 1;
                if (slipNo > 99999)
                {
                    // 伝票Noの最大値を超えた場合は1に戻す
                    slipNo = 1;
                }
                _slipNo = [NSString stringWithFormat:@"%05d", slipNo];
                _slipNoData = [NSString stringWithFormat:@"%d %@", orderDateNow, _slipNo];
            }
            else
            {
                // 注文日付が同日でない場合(日付が変わった場合)
                // 伝票Noを初期化して伝票No管理ファイルへ記録する設定値を編集
                _slipNo = @"00001";
                _slipNoData = [NSString stringWithFormat:@"%d %@", orderDateNow, _slipNo];
            }
        }
        
        // 伝票No管理ファイル・クローズ
        [slipNoFileHandle closeFile];
        
        return true;
    }
    
    @catch (NSException * exception)
    {
        [_errInfo addObject:exception.description];
        return  false;
    }
    
}

// #############################################################################
// 伝票No更新処理
// #############################################################################
- (BOOL)updateSlipNo
{
    @try
    {
        // 伝票No管理ファイル・オープン
        NSFileHandle * slipNoFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_slipNoFilePath];
        if (slipNoFileHandle == nil)
        {
            // オープン失敗時はエラーリターン
            [_errInfo addObject:@"伝票No管理ファイルオープンエラー"];
            return false;
        }
        
        // 伝票No管理ファイルを更新
        [slipNoFileHandle seekToFileOffset:0];
        [slipNoFileHandle writeData:[_slipNoData dataUsingEncoding:NSUTF8StringEncoding]];
        
        // 伝票No管理ファイル・クローズ
        [slipNoFileHandle closeFile];
        
        return true;
    }
    
    @catch (NSException * exception)
    {
        [_errInfo addObject:exception.description];
        return  false;
    }
}

// #############################################################################
// 注文コマンド初期化
// #############################################################################
- (void)initOrderCommand
{
    _orderCommands = [[NSMutableData alloc] init];
}

// #############################################################################
// 注文コマンド解放
// #############################################################################
- (void)releaseOrderCommand
{
    [_orderCommands release];
}

// #############################################################################
// 注文コマンド作成処理
// #############################################################################
- (void)createOrderCommand:(NSMutableString *)orderItem
{
    _oderItemEncoding = [orderItem dataUsingEncoding:NSShiftJISStringEncoding];
    _orderItemBytesData = (unsigned char *)malloc([_oderItemEncoding length]);
    [_oderItemEncoding getBytes:_orderItemBytesData];
    [_orderCommands appendBytes:_orderItemBytesData length:[_oderItemEncoding length]];
    free(_orderItemBytesData);
}

// #############################################################################
// 設定コマンド送信処理
// #############################################################################
- (BOOL)printSetting:(Port *)starPort
{
    // プリンターへの送信コマンド
    NSMutableData *settingCommands = [[NSMutableData alloc] init];

    // Initial
    unsigned char initial[] = {0x1b, 0x40};
    [settingCommands appendBytes:initial length:2];
    
    // 文字コード（Shift-JIS）
    unsigned char kanjiModeCommand[] = {0x1b, 0x24, 0x01, 0x1b, 0x71};
    [settingCommands appendBytes:kanjiModeCommand length:5];
    
    // アンダーライン（なし）
    unsigned char underlineCommand[] = {0x1b, 0x2d, 0x30};
    [settingCommands appendBytes:underlineCommand length:3];
    
    // 白黒反転（なし）
    unsigned char invertColorCommand[] = {0x1b, 0x35};
    [settingCommands appendBytes:invertColorCommand length:2];
    
    // 強調印字（なし）
    unsigned char emphasizedPrinting[] = {0x1b, 0x46};
    [settingCommands appendBytes:emphasizedPrinting length:2];
    
    // アッパーライン（なし）
    unsigned char upperLineCommand[] = {0x1b, 0x5f, 0x48};
    [settingCommands appendBytes:upperLineCommand length:3];
    
    // 倒立印字（なし）
    unsigned char upsd = 0x12;
    [settingCommands appendBytes:&upsd length:1];
    
    // 文字サイズ指定（height=0 width=0：設定値幅=0〜5）
    unsigned char characterExpansion[] = {0x1b, 0x69, 0x00, 0x00};
    [settingCommands appendBytes:characterExpansion length:4];
    
    // 左マージン（Margin=1：設定値幅=0〜255）
    unsigned char leftMarginCommand[] = {0x1b, 0x6c, 0x01};
    [settingCommands appendBytes:leftMarginCommand length:3];
    
    // 位置揃え（左[48]：設定値=左[48]|中央=[49]|右=[50]）
    unsigned char alignmentCommand[] = {0x1b, 0x1d, 0x61, 0x30};
    [settingCommands appendBytes:alignmentCommand length:4];
    
    // 設定コマンドをプリンターへ出力
    BOOL ret = [self writeCommandToPrinter:starPort printCommands:settingCommands];
    
    [settingCommands release];

    return ret;

}

// #############################################################################
// 厨房伝票印刷用プリンターポートオープン
// #############################################################################
//- (Port *)openPrinterPortForSmallSlip:(NSDictionary *)orderDict
//{
//    // 商品CSVからプリンターのIPアドレスとポート番号を取得する
//    NSString * printerIP = [orderDict objectForKey:kItemPrinterIP];
//    NSString * printerPort = [orderDict objectForKey:kItemPrinterPort];
//
//    // プリンターのIPアドレス、またはポート番号が設定されていない場合は何もしない
//    if ([printerIP length] <= 0 || [printerPort length] <= 0)
//    {
//        [_errInfo addObject:@"プリンター接続設定不正・商品コード："];
//        [_errInfo addObject:[orderDict objectForKey:kItemMenuCodeKey]];
//        return nil;
//    }
//
//    // プリンターIPアドレスの先頭に"TCP:"を付加(FVP10 StarIOの仕様)
//    printerIP = [NSString stringWithFormat:@"TCP:%@", printerIP];
//
//    // プリンターポートオープン（商品毎に出力先が異なる）
//    return [self openPrinterPort:printerIP portSettings:printerPort];
//}

// #############################################################################
// 会計伝票印刷用プリンターポートオープン
// #############################################################################
//- (Port *)openPrinterPortForBigSlip
//{
//    // 管理画面で設定されたIPアドレスとポート番号を取得する
//    NSString * printerIP;
//    NSString * printerPort;
//    printerIP = [[MSAdminManager instance] valueForKey:kSettingPrinterIPAddressKey];
//    printerPort = [[MSAdminManager instance] valueForKey:kSettingPrinterPortNoKey];
//
//    // プリンターのIPアドレス、ポート番号の設定確認
//    if ([printerIP length] <= 0 || [printerPort length] <= 0)
//    {
//        [_errInfo addObject:@"プリンター接続設定不正"];
//        return false;
//    }
//
//    // プリンターIPアドレスの先頭に"TCP:"を付加(FVP10 StarIOの仕様)
//    printerIP = [NSString stringWithFormat:@"TCP:%@", printerIP];
//
//    // プリンターポートオープン(管理画面で設定されたIPアドレスとポート番号)
//    return [self openPrinterPort:printerIP portSettings:printerPort];
//}

// #############################################################################
// プリンターポートオープン
// #############################################################################
- (Port *)openPrinterPort:(NSString *)portName portSettings:(NSString *)portNo
{
    Port *starPort = nil;
    
    @try
    {
        // プリンターポートオープン
        int retryCount = 0;
        while (retryCount < _printerOpenRetryNum)
        {
            starPort = [Port getPort:portName :portNo :_printerOpenTimeOut];
            if (starPort != nil)
            {
                break;
            }
            srand(time(nil));
            int randVal = (rand() % _printerOpenRetryRand) + 1;
            usleep(randVal * _printerOpenRetryWait);
            retryCount ++;
        }
        
        if (starPort == nil)
        {
            [_errInfo addObject:@"プリンターポートオープンエラー"];
        }
    }
    
    @catch (PortException *exception)
    {
        starPort = nil;
        [_errInfo addObject:@"プリンターポートオープン例外"];
        [_errInfo addObject:exception.description];
    }
    
    @finally
    {
        return starPort;
    }
}

// #############################################################################
// プリンターポートクローズ
// #############################################################################
- (void)closePrinterPort:(Port *)starPort
{
    [Port releasePort:starPort];
}

// #############################################################################
// プリンター出力処理
// #############################################################################
- (BOOL)writeCommandToPrinter:(Port *)starPort printCommands:(NSMutableData *)commands
{
    // 印刷コマンドを出力バッファにセット
    int commandSize = [commands length];
    unsigned char *dataToSentToPrinter = (unsigned char *)malloc(commandSize);
    [commands getBytes:dataToSentToPrinter];
    
    BOOL ret = true;
    
    @try
    {
        // プリンター状態チェック（エラー・オフライン検出時はリトライ）
        BOOL printerAvailable = false;
        int retryCount = 0;
        while (retryCount < _printerCheckRetryNum)
        {
            printerAvailable = [self checkPrinterStatus:starPort];
            if (printerAvailable)
            {
                break;
            }
            srand(time(nil));
            int randVal = (rand() % _printerCheckRetryRand) + 1;
            usleep(randVal * _printerCheckRetryWait);
            retryCount ++;
        }

        if (printerAvailable)
        {
            // プリンターの状態に問題なければ印刷する
            struct timeval endTime;
            gettimeofday(&endTime, NULL);
            endTime.tv_sec += 30;
            
            // プリンター出力
            int totalAmountWritten = 0;
            while (totalAmountWritten < commandSize)
            {
                int amountWritten = [starPort writePort:dataToSentToPrinter :totalAmountWritten :commandSize];
                totalAmountWritten += amountWritten;
                
                struct timeval now;
                gettimeofday(&now, NULL);
                if (now.tv_sec > endTime.tv_sec)
                {
                    break;
                }
            }
            
            if (totalAmountWritten < commandSize)
            {
                [_errInfo addObject:@"印刷タイムアウト"];
                ret = false;
            }
        }
        else
        {
            ret = false;
        }
    }
    
    @catch (PortException *exception)
    {
        [_errInfo addObject:@"印刷例外"];
        [_errInfo addObject:exception.description];
        ret = false;
    }
    
    free(dataToSentToPrinter);
    return ret;
}

// #############################################################################
// プリンター状態チェック処理
// #############################################################################
- (BOOL)checkPrinterStatus:(Port *)starPort
{    
    BOOL ret = true;
    
    @try
    {
        // usleep(1000 * 1000);
        
        StarPrinterStatus_2 status;
        [starPort getParsedStatus:&status :2];
        
        // プリンターがオフラインの場合はエラー詳細を通知する
        if (status.offline == SM_TRUE)
        {
            NSString * errMessage = @"";
            
            if (status.coverOpen == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"coverOpen "];
            }
            
            if (status.compulsionSwitch == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"compulsionSwitch "];
            }
            
            if (status.overTemp == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"overTemp "];
            }
            
            if (status.unrecoverableError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"unrecoverableError "];
            }
            
            if (status.cutterError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"cutterError "];
            }
            
            if (status.mechError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"mechError "];
            }
            
            if (status.headThermistorError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"headThermistorError "];
            }
            
            if (status.receiveBufferOverflow == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"receiveBufferOverflow "];
            }
            
            if (status.pageModeCmdError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"pageModeCmdError "];
            }
            
            if (status.blackMarkError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"blackMarkError "];
            }
            
            if (status.presenterPaperJamError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"presenterPaperJamError "];
            }
            
            if (status.headUpError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"headUpError "];
            }
            
            if (status.voltageError == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"voltageError "];
            }
            
            if (status.receiptBlackMarkDetection == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"receiptBlackMarkDetection "];
            }
            
            if (status.receiptPaperEmpty == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"receiptPaperEmpty "];
            }
            
            if (status.receiptPaperNearEmptyInner == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"receiptPaperNearEmptyInner "];
            }
            
            if (status.receiptPaperNearEmptyOuter == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"receiptPaperNearEmptyOuter "];
            }
            
            if (status.presenterPaperPresent == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"presenterPaperPresent "];
            }
            
            if (status.peelerPaperPresent == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"peelerPaperPresent "];
            }
            
            if (status.stackerFull == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"stackerFull "];
            }
            
            if (status.slipTOF == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"slipTOF "];
            }
            
            if (status.slipCOF == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"slipCOF "];
            }
            
            if (status.slipBOF == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"slipBOF "];
            }
            
            if (status.validationPaperPresent == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"validationPaperPresent "];
            }
            
            if (status.slipPaperPresent == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"slipPaperPresent "];
            }
            
            if (status.etbAvailable == SM_TRUE)
            {
                errMessage = [errMessage stringByAppendingString:@"etbAvailable "];
            }
            
            errMessage = [errMessage stringByAppendingString:@"）"];

            [_errInfo addObject:@"プリンター状態チェックエラー検出"];
            [_errInfo addObject:errMessage];
            ret = false;
        }
    }
    
    @catch (PortException *exception)
    {
        [_errInfo addObject:@"プリンター状態チェック例外"];
        [_errInfo addObject:exception.description];
        ret = false;
    }
    return ret;
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

// #############################################################################
// 初期化処理
// #############################################################################
- (id) init
{
	self = [super init];
	if (self != nil)
    {
        // システム共通パラメータ(setting.jsonの設定項目)を取得
        _printerOpenTimeOut = 10000;
        _printerOpenRetryNum = 10;
        _printerOpenRetryWait = 100000;
        _printerOpenRetryRand = 10;
        _printerCheckRetryNum = 10;
        _printerCheckRetryWait = 1000000;
        _printerCheckRetryRand = 10;
        _printItemsPerPage = 10;
        _bigSlipPageBreak = 1;
        _charPrintSizeExpansion = 0;
        
        /*
        NSDictionary * aDict;
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterOpenTimeOutKey];
        _printerOpenTimeOut = [[aDict objectForKey:@"value"] intValue];
         
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterOpenRetryNumKey];
        _printerOpenRetryNum = [[aDict objectForKey:@"value"] intValue];

        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterOpenRetryWaitKey];
        _printerOpenRetryWait = [[aDict objectForKey:@"value"] intValue];
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterOpenRetryRandKey];
        _printerOpenRetryRand = [[aDict objectForKey:@"value"] intValue];
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterCheckRetryNumKey];
        _printerCheckRetryNum = [[aDict objectForKey:@"value"] intValue];
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterCheckRetryWaitKey];
        _printerCheckRetryWait = [[aDict objectForKey:@"value"] intValue];
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrinterCheckRetryRandKey];
        _printerCheckRetryRand = [[aDict objectForKey:@"value"] intValue];
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingPrintItemsPerPageKey];
        _printItemsPerPage = [[aDict objectForKey:@"value"] intValue];
        
        aDict = [[MSAdminManager instance] valueForKey:kSettingBigSlipPageBreakKey];
        _bigSlipPageBreak = [[aDict objectForKey:@"value"] boolValue];

        aDict = [[MSAdminManager instance] valueForKey:kSettingCharPrintSizeExpansionKey];
        _charPrintSizeExpansion = [[aDict objectForKey:@"value"] boolValue];
         */
	}
	return self;
}

#pragma mark -
#pragma mark シングルトン
// #############################################################################
// 以下はシングルトンにする為に必須のオーバーライド
// #############################################################################
+ (id)instance {
	@synchronized(self) {
		if(!_instance) {
			[[self alloc] init];
		}
	}
	return _instance;
}

+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (!_instance) {
			_instance = [super allocWithZone:zone];
			return _instance;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (NSUInteger)retainCount {
	return UINT_MAX;
}

- (oneway void)release {
}

- (id)autorelease {
	return self;
}

@end
