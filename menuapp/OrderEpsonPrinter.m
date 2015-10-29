//
//  OrderEpsonPrinter.m
//  selforder
//
//  Created by dpcc on 2014/09/18.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "OrderEpsonPrinter.h"
#import "SmaregiUtil.h"
#import "ePOS-Print.h"
#import "SELItemDataManager.h"

@implementation OrderEpsonPrinter

- (void)printOrder:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList
{
    // 新規注文かどうか
    BOOL isFirstOrder = [self isFirstOrder:orderHeader details:orderDetailList];
    
    // 注文レシート（ホール）
    if (self.enabledOrderReceipt)
    {
        // PrinterIP設定値を取得する
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        
        // プリンターグループに会計伝票が設定されている場合は、そのPrinterIPを返す
        NSString* printerIP = [itemDataManager getKaikeiPrinterIPAddress];
        if (printerIP == nil || [printerIP isEqualToString:@""]) {
            printerIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerIPAddress"];
        }
        
        // printerが未設定の場合は印刷しない
        if (printerIP != NULL)
        {
            // プリンタ初期化
            //            NSString* printerIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerIPAddress"];
            NSMutableData* data = [[NSMutableData alloc]init];
            //    [data appendBytes:(u_int8_t[]){0x1B, 0x40} length:2];
            [data appendBytes:(u_int8_t[]){0x1C, 0x43, 0x01} length:3];
            [self doPrints:printerIP printData:data];
            
            // add by n.sasaki 枚数対応 doPrintCount
            for (int i=0; i < self.doPrintCount; i++) {
                // 注文レシートのbuilderを作成する
                NSMutableData* data = [self dataOrderReceipt:orderHeader details:orderDetailList isFirstOrder:isFirstOrder];
                
                [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
                
                // 印刷処理
                if (![self doPrints:printerIP printData:data]) {
                    [self.delegate orderStarPrinterPrintError:StarPrinterPrintStatusError];
                }
            }
        }
    }
    
    // 注文プリント（キッチンプリンター）
    if (self.enabledOrderPrint)
    {
        NSMutableDictionary* printers = [[NSMutableDictionary alloc]init];
        
        // 出力するプリンター別にOrderDetailを振り分ける
        for (OrderDetail* orderDetail in orderDetailList)
        {
            NSString* kitchinPrinterIP = [self getPrinterIPAddress:orderDetail];
            if (!kitchinPrinterIP) continue;
            if (![printers objectForKey:kitchinPrinterIP])
            {
                [printers setObject:[NSMutableArray array] forKey:kitchinPrinterIP];
            }
            [[printers objectForKey:kitchinPrinterIP] addObject:orderDetail];
        }
        
        // プリンターごとに印刷する
        for (NSString* printerAddress in printers)
        {
            if (!printerAddress) continue;
            
            // プリンタ初期化
            //            NSString* printerIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerIPAddress"];
            NSMutableData* initdata = [[NSMutableData alloc]init];
            //    [data appendBytes:(u_int8_t[]){0x1B, 0x40} length:2];
            [initdata appendBytes:(u_int8_t[]){0x1C, 0x43, 0x01} length:3];
            [self doPrints:printerAddress printData:initdata];
            
            NSArray* orderDetails = [printers objectForKey:printerAddress];
            
            NSMutableData* data = [self dataOrderDetailList:orderHeader details:orderDetails isFirstOrder:isFirstOrder];
            
            [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
            
            if (![self doPrints:printerAddress printData:data]) {
                [self.delegate orderStarPrinterPrintError:StarPrinterPrintStatusError];
            }
        }
    }
}

- (BOOL)doPrints:(NSString*)printerAddress printData:(NSData*)printData
{
    //EpsonIo クラスの初期化
    EpsonIo* port = [[EpsonIo alloc] init];
    if ( port != nil ) {
        int errorStatus = EPSONIO_OC_SUCCESS;
        // デバイスポートのオープン
        errorStatus = [port open:EPSONIO_OC_DEVTYPE_TCP DeviceName:
                       printerAddress DeviceSettings:nil];
        NSLog(@"epson port open result:%d", errorStatus);
        
        if (EPSONIO_OC_SUCCESS == errorStatus ) {
            // 送信設定
            size_t sizeWritten;
            int errStatus;
            //            NSString *str = @"Hello, World!\r\n";
            //            NSData *data = [str dataUsingEncoding:NSASCIIStringEncoding];
            // データの送信
            errStatus = [port write:printData Offset:0 Size:[printData length] Timeout:100 SizeWritten:&sizeWritten];
            NSLog(@"epson port write result:%d", errStatus);
        }
        else {
            // エラー
            return FALSE;
        }
        [port close];
    }
    return TRUE;
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

#pragma mark - 会計伝票

- (id)dataOrderReceipt:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList isFirstOrder:(BOOL)isFirstOrder
{
    //
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
    if ([orderHeader.tableCategory isEqualToString:@""] || orderHeader.tableCategory == Nil) {
        [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
    }
    else {
        [data appendData:[self dataWithLF:orderHeader.tableCategoryNameLabel]];
    }
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
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];    // dummy..(なぜかラインの後おかしくなるため)
    
    // 明細
    for (OrderDetail* od in orderDetailList)
    {
        [data appendData:[self orderReceipt_detailData:od]];
    }
    
    // 区切り
    [data appendData:[self dataLine:1]];
    
    // 合計
    [data appendData:[self orderReceipt_summaryData:orderHeader]];
    
//    // 複数人のお客の場合、割り勘金額表示
//    if ([orderHeader.numbers intValue] > 1)
//    {
//        // 区切り
//        [data appendData:[self dataLine:1]];
//        
//        // 割り勘
//        [data appendData:[self orderReceipt_billDivide:orderHeader]];
//    }
    
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
    [data appendData:[self dataWithLFAlignRight:[StarPrinterUtil concatWithSpace:quantity :summary :26]]];
    
    // トッピング名と個数と金額
    if (orderDetail.hasToppingItem) {
        
        for (OrderDetail* toppingItem in orderDetail.toppingItems) {
            
            // 左側
            NSString* header = toppingItem.itemToppingNameLabelForPrinter;
            
            // 右側
            NSString* prefix = toppingItem.isCanceled ? @"-" : @"";
            NSString* quantity = [NSString stringWithFormat:@"@%@ x %@%@", [FormatUtil numberFormat:toppingItem.salesPrice], prefix, toppingItem.quantity];
            NSString* summary = [NSString stringWithFormat:@"%@%@", prefix, [FormatUtil currencyFormat:[NSNumber numberWithDouble:[toppingItem.salesPrice doubleValue] * [toppingItem.quantity intValue]]]];
            NSString* content = [StarPrinterUtil concatWithSpace:quantity :summary :26];
            
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

- (NSMutableData*) orderReceipt_summaryData:(OrderHeader*)orderHeader
{
	NSMutableData *data = [NSMutableData data];
    NSInteger captionLength = [self charsPerLine] - 24;
    
	// 今回注文小計
	[data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_SUBTOTAL", nil) content:orderHeader.subtotalLabel captionLength:captionLength]];
    
    // add by n.sasaki 2013.04.15 プリンタ印刷対応. 小計のみ印字するフラグ
    if (orderHeader.isPrintSubTotalOnly) {
        return data;
    }
    
    // 一行あける
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
    
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

- (NSMutableData*) orderReceipt_billDivide:(OrderHeader*)orderHeader
{
	NSMutableData *data = [NSMutableData data];
    
	// 割り勘金額
	[data appendData:[self dataWithCaptionAndContent:NSLocalizedString(@"LABEL_RECEIPT_BILLDIVIDE", nil) content:orderHeader.billDivideLabel]];
	return data;
}

- (NSInteger) charsPerLine
{
    return CHARS_PER_LINE;
}

#pragma mark - 商品伝票

- (NSMutableData*) dataOrderDetailList:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList isFirstOrder:(BOOL)isFirstOrder
{
	NSMutableData *data = [NSMutableData data];
    
    // オーダー音
    if (self.enabledOrderSound)
    {
        [data appendBytes:CMD_PLAY_SOUND_ORDER length:sizeof(CMD_PLAY_SOUND_ORDER)];
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

- (NSMutableData*) dataOrderDetail:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail isFirstOrder:(BOOL)isFirstOrder cutForPrevData:(BOOL)cut
{
	NSMutableData *data = [NSMutableData data];
    
    if (isFirstOrder)
    {
        // カット用の調整
        if (cut) [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
        // カット（CurrentCutなので、このタイミングでカットして丁度テーブル番号の上あたりで切れる）
        if (cut) [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
        
        // 新規注文
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        [data appendBytes:CMD_INVERSE_START length:sizeof(CMD_INVERSE_START)];
        [data appendData:[self dataWithLFAlignCenter:NSLocalizedString(@"PRINT_LABEL_FIRST_ORDER", nil)]];
        [data appendBytes:CMD_INVERSE_END length:sizeof(CMD_INVERSE_END)];
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
        
        // テーブル番号
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        if ([orderHeader.tableCategory isEqualToString:@""] || orderHeader.tableCategory == Nil) {
            [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
        }
        else {
            [data appendData:[self dataWithLF:orderHeader.tableCategoryNameLabel]];
        }
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    }
    else
    {
        // カット用の調整
        if (cut) [data appendBytes:CMD_RUNOVER(1) length:sizeof(CMD_RUNOVER(1))];
        // カット（CurrentCutなので、このタイミングでカットして丁度テーブル番号の上あたりで切れる）
        if (cut) [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
        
        // テーブル番号
        [data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
        if ([orderHeader.tableCategory isEqualToString:@""] || orderHeader.tableCategory == Nil) {
            [data appendData:[self dataWithLF:orderHeader.tableNameLabel]];
        }
        else {
            [data appendData:[self dataWithLF:orderHeader.tableCategoryNameLabel]];
        }
        [data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
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

#pragma mark - 店員呼出

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

        // プリンタ初期化
        NSMutableData* initdata = [[NSMutableData alloc]init];
        [initdata appendBytes:(u_int8_t[]){0x1C, 0x43, 0x01} length:3];
        [self doPrints:printerIP printData:initdata];
        
        // 印刷データ作成
        NSMutableData* data = [self dataCallStuff:orderHeader];
        [data appendBytes:CMD_CUTTER_CURRENT_FULL length:sizeof(CMD_CUTTER_CURRENT_FULL)];
        
        // 印刷処理
        if (![self doPrints:printerIP printData:data]) {
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

#pragma mark - override

// define値をepsonを見るためにこちらにコピーしてくる
- (NSData*) dataWithLF:(NSString*)string printAlign:(PrintAlign)align
{
	NSMutableData *data = [NSMutableData data];
    if (!string || [string length] <= 0) return data;
    
    [data appendBytes:CMD_ALIGN(align) length:sizeof(CMD_ALIGN(align))];
    [data appendData:[string dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES]];
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
    return data;
}

- (NSData*) dataWithCaptionAndContent:(NSString*)caption content:(NSString*)content captionLength:(NSInteger)length
{
	NSMutableData *data = [NSMutableData data];
    if (length > 0)
    {
        caption = [StarPrinterUtil stringByPaddingLeftSpace:caption newLength:length];
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(CHARS_PER_LINE - length)];
    }
    else
    {
        length = [caption lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(CHARS_PER_LINE - length)];
    }
    
    [data appendBytes:CMD_ALIGN_LEFT length:sizeof(CMD_ALIGN_LEFT)];
    [data appendData:[caption dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES]];
    [data appendData:[content dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES]];
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
    return data;
}

- (NSData*) dataLine:(NSInteger)shape
{
    NSMutableData* data = [NSMutableData data];
    
    unsigned char line[(256+32)];
    memset(line, 0x01, sizeof(line));
    
    [data appendBytes:CMD_LINE length:sizeof(CMD_LINE)];
    [data appendBytes:(u_int8_t[]){0x20,1} length:2];
    [data appendBytes:line length:sizeof(line)];
    
    return data;
}

- (NSData*) dataWithCaptionAndContent2x:(NSString*)caption content:(NSString*)content
{
    NSInteger charsPerLine = CHARS_PER_LINE/2;
	NSMutableData *data = [NSMutableData data];
    NSInteger lenCaption = [caption lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
    NSInteger lenContent = [content lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
    
    if (lenCaption + lenContent <= charsPerLine)
    {
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(charsPerLine - lenCaption)];
    }
    else
    {
        NSInteger lenNewContent = charsPerLine - (lenCaption % charsPerLine);
        if (lenNewContent < lenContent) lenNewContent += charsPerLine;
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(lenNewContent)];
    }
    
	[data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendBytes:CMD_ALIGN_LEFT length:sizeof(CMD_ALIGN_LEFT)];
    [data appendData:[caption dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES]];
    [data appendData:[content dataUsingEncoding:NSShiftJISStringEncoding allowLossyConversion:YES]];
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
	[data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    return data;
}

#pragma mark - util

- (UIImage *)imageWithText:(NSString *)text fontSize:(CGFloat)fontSize rectSize:(CGSize)rectSize {
    
    // 描画する文字列のフォントを設定。
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    // オフスクリーン描画のためのグラフィックスコンテキストを作る。
    if (UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(rectSize, NO, 0.0f);
    else
        UIGraphicsBeginImageContext(rectSize);
    
    /* Shadowを付ける場合は追加でこの部分の処理を行う。
     CGContextRef ctx = UIGraphicsGetCurrentContext();
     CGContextSetShadowWithColor(ctx, CGSizeMake(1.0f, 1.0f), 5.0f, [[UIColor grayColor] CGColor]);
     */
    
    // 文字列の描画領域のサイズをあらかじめ算出しておく。
    CGSize textAreaSize = [text sizeWithFont:font constrainedToSize:rectSize];
    
    // 描画対象領域の中央に文字列を描画する。
    [text drawInRect:CGRectMake((rectSize.width - textAreaSize.width) * 0.5f,
                                (rectSize.height - textAreaSize.height) * 0.5f,
                                textAreaSize.width,
                                textAreaSize.height)
            withFont:font
       lineBreakMode:NSLineBreakByWordWrapping
           alignment:NSTextAlignmentCenter];
    
    // コンテキストから画像オブジェクトを作成する。
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
