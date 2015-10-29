//
//  OrderStarPrinter.m
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/04/26.
//  Copyright (c) 2012 genephics design,Inc. All rights reserved.
//

#import "OrderStarPrinter.h"
//#import "MobileOrderAppDelegate.h"
#import "SmaregiUtil.h"

#import "SELItemDataManager.h"
#import "SELItemData.h"

@interface OrderStarPrinter(Private)

- (NSMutableData*) orderReceipt_detailData:(OrderDetail*)orderDetail;
- (NSMutableData*) orderReceipt_billDivide:(OrderHeader*)orderHeader;
- (NSMutableData*) orderReceipt_summaryData:(OrderHeader*)orderHeader;

@end


@implementation OrderStarPrinter

@synthesize tag = _tag;
@synthesize delegate = _delegate;
@synthesize orderHeader = _orderHeader;
@synthesize orderDetailList = _orderDetailList;
@synthesize printDataList = _printDataList;
@synthesize errorPrintData = _errorPrintData;

- (void) dealloc
{
    [_orderHeader release];
    [_orderDetailList release];
    [_printDataList release];
    [_errorPrintData release];
    [super dealloc];
}


- (BOOL) enabledPrint
{
//    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
//    return [userDefaults boolForKey:UD_KEY_PRINT_ENABLED];
    return TRUE;
}
- (BOOL) enabledOrderPrint
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"doOrderPrintFlag"];
}
- (BOOL) enabledOrderSound
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"doPrintSoundFlag"];
}

- (BOOL) useOrderPrintFont2x
{
//    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
//    return [userDefaults boolForKey:UD_KEY_PRINTER_KITCHEN_PRINT2X];
    return TRUE;
}
- (BOOL) enabledOrderReceipt
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:@"doPrintFlag"];
}
- (BOOL) enabledCheckoutReceipt
{
//    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
//    return [userDefaults boolForKey:UD_KEY_PRINTER_HALL_CHECKOUT_RECEIPT];
    return TRUE;
}
- (BOOL) enabledCheckoutReceiptDetails
{
//    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
//    return [userDefaults boolForKey:UD_KEY_PRINTER_HALL_CHECKOUT_RECEIPT_DETAILS];
    return TRUE;
}

- (NSInteger)doPrintCount
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger doPrintCount = [userDefaults integerForKey:@"doPrintCount"];
    if (doPrintCount == 0) {
        doPrintCount = 1;  // 最低１枚は印刷。印刷しないときは会計伝票印刷をオフにする。
    }
    return doPrintCount;
}

- (NSInteger) charsPerLine
{
    return CHARS_PER_LINE;
}

- (id) initWithDelegate:(id)delegate
{
    self = [super init];
    self.delegate = delegate;
    super.showErrorMessage = false;
    self.printDataList = [NSMutableArray array];
    return self;
}




- (void) showRetryAlert:(PrintData*)printData
{
    NSString* message = nil;
    switch (printData.status) {
        case StarPrinterPrintStatusConnectError:    message = NSLocalizedString(@"POPUP_MESSAGE_ERROR_CONNECT", nil); break;
        case StarPrinterPrintStatusCoverOpen:       message = NSLocalizedString(@"POPUP_MESSAGE_COVER_OPEN", nil); break;
        case StarPrinterPrintStatusRunOutOfPaper:   message = NSLocalizedString(@"POPUP_MESSAGE_RUN_OUT_OF_PAPER", nil); break;
        case StarPrinterPrintStatusError:           message = NSLocalizedString(@"POPUP_MESSAGE_PRINTER_ERROR", nil); break;
        default:
            break;
    }
    self.errorPrintData = printData;
    message = [message stringByAppendingFormat:@"\n%@", NSLocalizedString(@"POPUP_MESSAGE_PRINT_RETRY", nil)];
    NSString* printerName = printData.printer.printerName ? printData.printer.printerName : @"";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", printerName, NSLocalizedString(@"POPUP_TITLE_PRINTER_ERROR", nil)] 
                                                    message:message
                                                   delegate:self 
                                          cancelButtonTitle:NSLocalizedString(@"BUTTON_NO", nil) 
                                          otherButtonTitles:NSLocalizedString(@"BUTTON_YES", nil) ,nil];
    [alert show];
    [alert release];
}


- (BOOL) isFirstOrder:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList
{
    NSNumber* amount = nil;
    for (OrderDetail* od in orderDetailList) 
    {
        amount = [NSNumber numberWithInt:([amount intValue] + [od.quantity intValue])];
    }
    
    return [orderHeader.amount intValue] == [amount intValue];
}


- (NSMutableData*) dataCheckoutReceipt:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList
{
	NSMutableData *data = [NSMutableData data];
	// タイトル
    [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendData:[self dataWithLFAlignCenter:NSLocalizedString(@"LABEL_RECEIPT_TITLE_CHECKOUT", nil)]];
    [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    
	// テーブル番号
	[data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
	[data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    
    
	// 担当者 + 日時
    [data appendData:[self dataWithCaptionAndContent:orderHeader.staffNameLabelForPrinter content:orderHeader.checkoutDateTime]];

    if (self.enabledCheckoutReceiptDetails)
    {
        // 区切り
        [data appendData:[self dataLine:1]];
        
        // 明細
        for (OrderDetail* od in orderDetailList) 
        {
            if (od.isCanceled) continue;
            [data appendData:[self orderReceipt_detailData:od]];
        }
    }
    
    // 区切り
    [data appendData:[self dataLine:1]];
    
    // 合計
    [data appendData:[self orderReceipt_summaryData:orderHeader]];

    // 複数人のお客の場合、割り勘金額表示
    if ([orderHeader.numbers intValue] > 1)
    {
        // 区切り
        [data appendData:[self dataLine:1]];
        
        // 割り勘
        [data appendData:[self orderReceipt_billDivide:orderHeader]];
    }
    
    return data;
}



- (NSMutableData*) dataOrderReceipt:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList isFirstOrder:(BOOL)isFirstOrder
{
	NSMutableData *data = [NSMutableData data];
    OrderDetail* orderDetail = (orderDetailList && [orderDetailList count] > 0) ? [orderDetailList objectAtIndex:0] : nil;
    
	// タイトル(追加注文の時のみ)
    if (!isFirstOrder)
    {
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        [data appendBytes:CMD_INVERSE_START length:sizeof(CMD_INVERSE_START)];
        [data appendData:[self dataWithLFAlignCenter:NSLocalizedString(@"LABEL_RECEIPT_TITLE_ADD", nil)]];
        [data appendBytes:CMD_INVERSE_END length:sizeof(CMD_INVERSE_END)];
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    }

	// テーブル番号
	[data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
	[data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    
    
	// 担当者 + 日時
    if (orderDetail)
    {
        [data appendData:[self dataWithCaptionAndContent:orderDetail.staffNameLabelForPrinter content:orderDetail.orderDateTime]];
    }
    else 
    {
        [data appendData:[self dataWithCaptionAndContent:orderHeader.staffNameLabelForPrinter content:orderHeader.lastOrderDateTime]];
    }
    
    // 区切り
    [data appendData:[self dataLine:1]];
    
    // 明細
    for (OrderDetail* od in orderDetailList) 
    {
        [data appendData:[self orderReceipt_detailData:od]];
    }
    
    // 区切り
    [data appendData:[self dataLine:1]];

    // 合計
    [data appendData:[self orderReceipt_summaryData:orderHeader]];
    
    // 複数人のお客の場合、割り勘金額表示
    if ([orderHeader.numbers intValue] > 1)
    {
        // 区切り
        [data appendData:[self dataLine:1]];
        
        // 割り勘
        [data appendData:[self orderReceipt_billDivide:orderHeader]];
    }
    
    return data;
}


- (NSMutableData*) dataOrderCancelReceipt:(OrderHeader *)orderHeader orderDetail:(OrderDetail*)orderDetail
{
	NSMutableData *data = [NSMutableData data];
    
	// タイトル
    [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendBytes:CMD_INVERSE_START length:sizeof(CMD_INVERSE_START)];
    [data appendData:[self dataWithLFAlignCenter:NSLocalizedString(@"PRINT_LABEL_ORDER_CANCEL", nil)]];
    [data appendBytes:CMD_INVERSE_END length:sizeof(CMD_INVERSE_END)];
    [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    
	// テーブル番号
	[data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
	[data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    
    
	// 担当者 + 日時
    if (orderDetail)
    {
        [data appendData:[self dataWithCaptionAndContent:orderDetail.staffNameLabelForPrinter content:orderDetail.orderDateTime]];
    }
    else 
    {
        [data appendData:[self dataWithCaptionAndContent:orderHeader.staffNameLabelForPrinter content:orderHeader.lastOrderDateTime]];
    }
    
    // 区切り
    [data appendData:[self dataLine:1]];
    
    // 明細
    [data appendData:[self orderReceipt_detailData:orderDetail]];
    
    // 区切り
    [data appendData:[self dataLine:1]];
    
    // 合計
    [data appendData:[self orderReceipt_summaryData:orderHeader]];
    
    return data;
}


- (NSMutableData*) orderReceipt_detailData:(OrderDetail*)orderDetail
{
    NSMutableData* data = [NSMutableData data];
    
    // 商品名
    [data appendData:[self dataWithLF:orderDetail.itemNameLabelForPrinter]];
    
    
    // 商品詳細要望
    if (orderDetail.hasItemDrillDownName)
    {
        [data appendData:[self dataWithLF:orderDetail.itemDrillDownNameLabelForPrinter]];
    }
    
    // メモ
    if (orderDetail.hasMemo)
    {
        [data appendData:[self dataWithLF:orderDetail.memoLabelForPrinter]];
    }
    
    // 個数と金額
    NSString* prefix = orderDetail.isCanceled ? @"-" : @"";
    NSString* quantity = [NSString stringWithFormat:@"@%@ x %@%@", [FormatUtil numberFormat:orderDetail.salesPrice], prefix, orderDetail.quantity];
    NSString* summary = [NSString stringWithFormat:@"%@%@", prefix, [FormatUtil currencyFormat:[NSNumber numberWithDouble:[orderDetail.salesPrice doubleValue] * [orderDetail.quantity intValue]]]];
    [data appendData:[self dataWithLFAlignRight:[StarPrinterUtil concatWithSpace:quantity :summary :23]]];
    
    // トッピング名と個数と金額
    if (orderDetail.hasToppingItem) {
        
        for (OrderDetail* toppingItem in orderDetail.toppingItems) {

            // 左側
            NSString* header = toppingItem.itemToppingNameLabelForPrinter;
            
            // 右側
            NSString* prefix = toppingItem.isCanceled ? @"-" : @"";
            NSString* quantity = [NSString stringWithFormat:@"@%@ x %@%@", [FormatUtil numberFormat:toppingItem.salesPrice], prefix, toppingItem.quantity];
            NSString* summary = [NSString stringWithFormat:@"%@%@", prefix, [FormatUtil currencyFormat:[NSNumber numberWithDouble:[toppingItem.salesPrice doubleValue] * [toppingItem.quantity intValue]]]];
            NSString* content = [StarPrinterUtil concatWithSpace:quantity :summary :23];
            
            [data appendData:[self dataWithCaptionAndContent:header content:content]];
        }
        
    }
    
    // キャンセルの時は印刷しない
    if (!orderDetail.isCanceled)
    {
        // 値引／割引／クーポン
        if (orderDetail.isDiscounted)
        {
            quantity = [NSString stringWithFormat:@"@%@ x %@", [FormatUtil numberFormat:orderDetail.discountPrice], orderDetail.quantity];
            summary = [FormatUtil currencyFormat:[NSNumber numberWithDouble:[orderDetail.discountPrice doubleValue] * [orderDetail.quantity intValue]]];
            [data appendData:[self dataWithCaptionAndContent:orderDetail.discountDivisionLabelForPrinter content:[StarPrinterUtil concatWithSpace:quantity :[NSString stringWithFormat:@"-%@", summary] :23]]];
        }
    }

    return data;
}

- (NSMutableData*) orderReceipt_billDivide:(OrderHeader*)orderHeader
{    
	NSMutableData *data = [NSMutableData data];
    
	// 割り勘金額
	[data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_BILLDIVIDE", nil) content:orderHeader.billDivideLabel]];
	return data;
}

- (NSMutableData*) orderReceipt_summaryData:(OrderHeader*)orderHeader
{    
	NSMutableData *data = [NSMutableData data];
    NSInteger captionLength = [self charsPerLine] - 24;
    
	// 小計
	[data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_SUBTOTAL", nil) content:orderHeader.subtotalLabel captionLength:captionLength]];
    
    // add by n.sasaki 2013.04.15 プリンタ印刷対応. 小計のみ印字するフラグ
    if (orderHeader.isPrintSubTotalOnly) {
        return data;
    }
    
    // テーブルチャージ
    if (orderHeader.tableChargePerPerson && [orderHeader.tableChargePerPerson intValue] > 0)
    {
        [data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_TABLE_CHARGE", nil) content:orderHeader.tableChargeLabel captionLength:captionLength]];
    }
    
    // サービスチャージ
    if (orderHeader.serviceChargeRate && [orderHeader.serviceChargeRate intValue] > 0)
    {
        [data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_SERVICE_CHARGE", nil) content:orderHeader.serviceChargeLabel captionLength:captionLength]];
    }

    // 値引／割引／クーポン
	if (orderHeader.isDiscounted)
	{
        [data appendData:[self dataWithCaptionAndContent:orderHeader.discountDivisionLabelForPrinter content:orderHeader.discountPriceRateLabel captionLength:captionLength]];
	}
    
    // 消費税
    [data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_TAX", nil) content:orderHeader.taxLabel captionLength:captionLength]];

    // 合計点数
    [data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_AMOUNT", nil) content:orderHeader.amountLabel captionLength:captionLength]];

    // 合計金額
    [data appendBytes:CMD_EMPHASIZE_START length:sizeof(CMD_EMPHASIZE_START)];
    [data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_TOTAL", nil) content:orderHeader.totalLabel captionLength:captionLength]];
    [data appendBytes:CMD_EMPHASIZE_END length:sizeof(CMD_EMPHASIZE_END)];
	return data;
}

- (NSMutableData*) dataOrderDetail:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail isFirstOrder:(BOOL)isFirstOrder cutForPrevData:(BOOL)cut
{
	NSMutableData *data = [NSMutableData data];

    if (isFirstOrder)
    {
        // カット用の調整
        if (cut) [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
        // 新規注文
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        [data appendBytes:CMD_INVERSE_START length:sizeof(CMD_INVERSE_START)];
        [data appendData:[self dataWithLFAlignCenter:NSLocalizedString(@"PRINT_LABEL_FIRST_ORDER", nil)]];
        [data appendBytes:CMD_INVERSE_END length:sizeof(CMD_INVERSE_END)];
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
        // カット（CurrentCutなので、このタイミングでカットして丁度テーブル番号の上あたりで切れる）
        if (cut) [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
        // テーブル番号
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    }
    else 
    {
        // カット用の調整
        if (cut) [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
        // テーブル番号
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
        // カット（CurrentCutなので、このタイミングでカットして丁度テーブル番号の上あたりで切れる）
        if (cut) [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
    }
    
	// 担当者 + 日時
    [data appendData:[self dataWithCaptionAndContent:orderDetail.staffNameLabelForPrinter content:orderDetail.orderDateTime]];
    
    // 注文NO
    [data appendData:[self dataWithLF:orderDetail.orderDetailNoLabelForPrinter]];
    
    // Font size x2 or Normal size
    if (self.useOrderPrintFont2x)
    {
        // 商品名 x 個数
        [data appendData:[self dataWithCaptionAndContent2x:orderDetail.itemNameLabelForPrinter content:orderDetail.quantityLabel]];
        
        // 商品詳細要望(カスタムオーダー)
        if (orderDetail.hasItemDrillDownName)
        {
            [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
            [data appendData:[self dataWithLF:orderDetail.itemDrillDownNameLabelForPrinter]];
            [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
        }
        
        // 商品詳細要望(トッピング)
        if (orderDetail.hasToppingItem)
        {
            for (OrderDetail* toppingItem in orderDetail.toppingItems) {
                [data appendData:[self dataWithCaptionAndContent2x:toppingItem.itemToppingNameLabelForPrinter content:toppingItem.quantityLabel]];
            }
        }
        
        // メモ
        if (orderDetail.hasMemo)
        {
            [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
            [data appendData:[self dataWithLF:orderDetail.memoLabelForPrinter]];
            [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
        }
    }
    else 
    {
        // 商品名 x 個数
        [data appendData:[self dataWithCaptionAndContent:orderDetail.itemNameLabelForPrinter content:orderDetail.quantityLabel]];
        
        // 商品詳細要望
        if (orderDetail.hasItemDrillDownName)
        {
            [data appendData:[self dataWithLF:orderDetail.itemDrillDownNameLabelForPrinter]];
        }
        
        // 商品詳細要望(トッピング)
        if (orderDetail.hasToppingItem)
        {
            for (OrderDetail* toppingItem in orderDetail.toppingItems) {
                [data appendData:[self dataWithCaptionAndContent:toppingItem.itemToppingNameLabelForPrinter content:toppingItem.quantityLabel]];
            }
        }

        // メモ
        if (orderDetail.hasMemo)
        {
            [data appendData:[self dataWithLF:orderDetail.memoLabelForPrinter]];
        }
    }
    
    return data;
}

- (NSMutableData*) dataCancelOrderDetail:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail
{
	NSMutableData *data = [NSMutableData data];
    
	// タイトル
	[data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
	[data appendBytes:CMD_INVERSE_START length:sizeof(CMD_INVERSE_START)];
    [data appendData:[self dataWithLFAlignCenter:NSLocalizedString(@"PRINT_LABEL_ORDER_CANCEL", nil)]];
	[data appendBytes:CMD_INVERSE_END length:sizeof(CMD_INVERSE_END)];
	[data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];

    // 詳細データ
    [data appendData:[self dataOrderDetail:orderHeader detail:orderDetail isFirstOrder:NO cutForPrevData:NO]];
    
    return data;
}

- (NSMutableData*) dataOrderDetailList:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList isFirstOrder:(BOOL)isFirstOrder
{
	NSMutableData *data = [NSMutableData data];
    
    // オーダー音
    if (self.enabledOrderSound)
    {
        [data appendBytes:CMD_PLAY_SOUND_ORDER length:sizeof(CMD_PLAY_SOUND_ORDER)];
        // TSP650II用音声
//        [data appendBytes:CMD_PLAY_SOUND_TEST length:sizeof(CMD_PLAY_SOUND_TEST)];
    }
    
    // オーダープリント
    BOOL isFirstPrint = true;
    for (OrderDetail* orderDetail in orderDetailList)
    {
        [data appendData:[self dataOrderDetail:orderHeader detail:orderDetail isFirstOrder:isFirstOrder cutForPrevData:!isFirstPrint]];
        isFirstPrint = false;
    }
    return data;
}

- (NSString*) getPrinterIPAddress:(OrderDetail*)orderDetail
{
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    SELItemData* itemData = [itemDataManager getItemData:orderDetail.itemId];
    
    // プリンターグループが設定されている場合は、そのPrinterIPを返す
    NSString* ip = [itemDataManager getPrinterGroupIPAddress:itemData.category1_code];
    if (ip != nil && ![ip isEqualToString:@""]) {
        return ip;
    }
    
    // プリンターグループが未設定の場合は、商品データに設定されているPrinterIPを返す
    if (itemData && itemData.printerIP && ![itemData.printerIP isEqualToString:@""]) {
        return itemData.printerIP;
    }
    return NULL;
}

- (BOOL) doPrints
{
    if (!self.printDataList)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(orderStarPrinterPrintDone)])
        {
            [self.delegate orderStarPrinterPrintDone];
        }
        return true;
    }
    
    for (PrintData* printData in self.printDataList) 
    {
        if (printData.isDone) continue; 

        self.ipAddress = printData.printer.ipAddress;
        
//        // 5回リトライ
//        int nRetryCount = 0;
//        while (TRUE) {
//            printData.status = [self print:printData.data withCut:YES];
//            if (!printData.isDone)
//            {
//                // 印刷失敗時
//                if (nRetryCount < 5) {
//                    // sleep 0.5秒
//                    [NSThread sleepForTimeInterval:0.5];
//                    nRetryCount++;
//                }else{
//                    // alert表示
////                    [self showRetryAlert:printData];
//                    if (self.delegate && [self.delegate respondsToSelector:@selector(orderStarPrinterPrintError:)])
//                    {
//                        [self.delegate orderStarPrinterPrintError:printData.status];
//                    }
//                    return false;
//                }
//            }
//            else{
//                // 印刷成功時
//                break;
//            }
//        }
        
        printData.status = [self print:printData.data withCut:YES];
        if (!printData.isDone)
        {
            // 印刷失敗時
            if (self.delegate && [self.delegate respondsToSelector:@selector(orderStarPrinterPrintError:)])
            {
                [self.delegate orderStarPrinterPrintError:printData.status];
            }
            return false;
        }
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(orderStarPrinterPrintDone)])
    {
        [self.delegate orderStarPrinterPrintDone];
    }
    return true;
}

- (void) printOrder:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail
{
    // Printer 取得
    //Printer* printer = [[MobileOrderAppDelegate database].printer findByPrimaryKey:orderDetail.printerId];
    Printer* printer = [[Printer alloc] init];
    
    // 新規注文判定
    BOOL isFirstOrder = [self isFirstOrder:orderHeader details:[NSArray arrayWithObject:orderDetail]];
    
    // 印刷
	NSMutableData *data = [self dataOrderDetail:orderHeader detail:orderDetail isFirstOrder:isFirstOrder cutForPrevData:NO];
    PrintData* printData = [[[PrintData alloc] initWithData:data printer:printer] autorelease];
    [self.printDataList addObject:printData];
    if (![self doPrints]) {
        // print error
        NSLog(@"print error");
    }
}

- (void) printOrder:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList
{
    NSMutableDictionary* printers = [NSMutableDictionary dictionary];

    // 新規注文かどうか
    BOOL isFirstOrder = [self isFirstOrder:orderHeader details:orderDetailList];
    
    // 注文レシート（ホール）
    if (self.enabledOrderReceipt)
    {
        //Printer* storePrinter = [[MobileOrderAppDelegate database].printer findByPrimaryKey:[MobileOrderAppDelegate instance].store.printerId];
        Printer* storePrinter = [[Printer alloc] init];
        storePrinter.ipAddress = [SmaregiUtil storePrinterIPAddress];

        // printerが未設定の場合は印刷しない
        if (storePrinter && storePrinter.ipAddress != NULL)
        {
            // add by n.sasaki 枚数対応 doPrintCount
            for (int i=0; i < self.doPrintCount; i++) {

                PrintData* printData = [[[PrintData alloc] initWithData:[self dataOrderReceipt:orderHeader details:orderDetailList isFirstOrder:isFirstOrder] printer:storePrinter] autorelease];
                [self.printDataList addObject:printData];
            
                // add by n.sasaki キッチンプリンターとホールの帳票は別々に印刷する
                if (![self doPrints]) {
                    // print error
                    NSLog(@"print error header");
                    return;
                }
                
            }
        }
    }
    
    // 注文プリント（キッチンプリンター）
    if (self.enabledOrderPrint)
    {
        // 出力するプリンター別に振り分ける
        for (OrderDetail* orderDetail in orderDetailList)
        {
//            NSString* kitchinPrinterIP = [self getPrinterIPAddress:orderDetail localItems:localItems];
            NSString* kitchinPrinterIP = [self getPrinterIPAddress:orderDetail];
            if (!kitchinPrinterIP) continue;
            if (![printers objectForKey:kitchinPrinterIP])
            {
                [printers setObject:[NSMutableArray array] forKey:kitchinPrinterIP];
            }
            [[printers objectForKey:kitchinPrinterIP] addObject:orderDetail];
            
            //if (!orderDetail.printerId) continue;
            //if (![printers objectForKey:orderDetail.printerId])
            //{
            //    [printers setObject:[NSMutableArray array] forKey:orderDetail.printerId];
            //}
            
            //[[printers objectForKey:orderDetail.printerId] addObject:orderDetail];
        }
        
        for (NSString* printerId in printers)
        {
            NSArray* orderDetails = [printers objectForKey:printerId];
            //Printer* printer = [[MobileOrderAppDelegate database].printer findByPrimaryKey:printerId];
            Printer* printer = [[Printer alloc] init];
            printer.ipAddress = [NSString stringWithFormat:@"TCP:%@", printerId];

            if (!printer || !printer.ipAddress) continue;
            NSMutableData* data = [self dataOrderDetailList:orderHeader details:orderDetails isFirstOrder:isFirstOrder];
            PrintData* printData = [[[PrintData alloc] initWithData:data printer:printer] autorelease];
            [self.printDataList addObject:printData];
        }
        
        if (![self doPrints]) {
            // print error
            NSLog(@"print error detail");
            return;
        }
    }
}

// add by n.sasaki 2013.04.15 店員呼出 START
- (BOOL) printCallStuff:(OrderHeader*)orderHeader
{
    if (self.enabledOrderPrint)
    {
        // プリンターグループに会計伝票が設定されている場合は、そのPrinterIPを返す
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        NSString* printerIP = [itemDataManager getKaikeiPrinterIPAddress];
        if (printerIP == nil || [printerIP isEqualToString:@""]) {
            printerIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerIPAddress"];
        }
        
        // printerが未設定の場合は印刷しない
        if (printerIP == nil || [printerIP isEqualToString:@""])
        {
            return FALSE;
        }

        // Printer作成(ホールプリンタ)
        Printer* printer = [[Printer alloc] init];
        printer.ipAddress = [NSString stringWithFormat:@"TCP:%@", printerIP];
        
        NSMutableData* data = [self dataCallStuff:orderHeader];
        PrintData* printData = [[[PrintData alloc] initWithData:data printer:printer] autorelease];
        [self.printDataList addObject:printData];
        
        if (![self doPrints]) {
            // print error
            NSLog(@"print error detail");
            return FALSE;
        }
    }
    return TRUE;
}

- (NSMutableData*) dataCallStuff:(OrderHeader*)orderHeader
{
    NSMutableData *data = [NSMutableData data];
    
    // オーダー音
    if (self.enabledOrderSound)
    {
        [data appendBytes:CMD_PLAY_SOUND_ORDER length:sizeof(CMD_PLAY_SOUND_ORDER)];
        // TSP650II用音声
//        [data appendBytes:CMD_PLAY_SOUND_TEST length:sizeof(CMD_PLAY_SOUND_TEST)];
    }
    
    // カット用の調整
    [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
    
    [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendBytes:CMD_INVERSE_START length:sizeof(CMD_INVERSE_START)];
    [data appendData:[self dataWithLFAlignCenter:@"　店員呼出　"]];
    [data appendBytes:CMD_INVERSE_END length:sizeof(CMD_INVERSE_END)];
    [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];

    // テーブル番号
    [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
    [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];

	// 担当者 + 日時
    [data appendData:[self dataWithCaptionAndContent:@"セルフオーダー" content:orderHeader.lastOrderDateTime]];
    
    [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
    [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
    
    return data;
}

- (void) printCancelOrder:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail
{
    // 注文レシート（ホール）
    if (self.enabledOrderReceipt)
    {
        //Printer* storePrinter = [[MobileOrderAppDelegate database].printer findByPrimaryKey:[MobileOrderAppDelegate instance].store.printerId];
        Printer* storePrinter = [[Printer alloc] init];

        if (storePrinter)
        {
            PrintData* printData = [[[PrintData alloc] initWithData:[self dataOrderCancelReceipt:orderHeader orderDetail:orderDetail] printer:storePrinter] autorelease];
            [self.printDataList addObject:printData];
        }
    }
    
    // 注文プリント（キッチンプリンター）
    if (self.enabledOrderPrint)
    {
        //Printer* printer = [[MobileOrderAppDelegate database].printer findByPrimaryKey:orderDetail.printerId];
        Printer* printer = [[Printer alloc] init];
        

        NSMutableData *data = [self dataCancelOrderDetail:orderHeader detail:orderDetail];
        PrintData* printData = [[[PrintData alloc] initWithData:data printer:printer] autorelease];
        [self.printDataList addObject:printData];
    }
    
    [self doPrints];
}

- (void) printCheckout:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList
{
    if (self.enabledCheckoutReceipt)
    {
        //Printer* storePrinter = [[MobileOrderAppDelegate database].printer findByPrimaryKey:[MobileOrderAppDelegate instance].store.printerId];
        Printer* storePrinter = [[Printer alloc] init];

        if (storePrinter)
        {
            PrintData* printData = [[[PrintData alloc] initWithData:[self dataCheckoutReceipt:orderHeader details:orderDetailList] printer:storePrinter] autorelease];
            [self.printDataList addObject:printData];
        }
    }

    [self doPrints];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex == buttonIndex)
    {
        self.errorPrintData.abort = true;
    }
    
    [self doPrints];
}

@end
