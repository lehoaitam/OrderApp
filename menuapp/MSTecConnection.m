//
//  MSTecConnection.m
//  selforder
//
//  Created by dpcc on 2015/01/23.
//  Copyright (c) 2015年 kdl. All rights reserved.
//

#import "MSTecConnection.h"
#import "SELOrderData.h"
#import "SELItemDataManager.h"

#define CUSTOMER_INFO @"customerInfoFromTableID"
#define ORDERING_ITEMS @"orderingOfItems"
#define ORDER_HISTORY @"orderHistoryFromTableID"
#define CALL_STAFF @"callStaff"

@implementation MSTecConnection

- (id) init
{
    self = [super init];
    if (self != nil)
    {
        // 通信処理クラスを作成
        kolSocket* socket = [kolSocket instance];
        socket.delegate = self;
        
        // システムパラメータを取得
        NSString* stationAddress = [[NSUserDefaults standardUserDefaults] objectForKey:@"stationAddress"];
        socket.hostAddr = stationAddress;
        
        // receivePort
        NSString* receivePort = [[NSUserDefaults standardUserDefaults] objectForKey:@"receivePort"];
        socket.portReq = receivePort;
        
        // sendPort
        NSString* sendPort = [[NSUserDefaults standardUserDefaults] objectForKey:@"sendPort"];
        socket.portAsk = sendPort;
        
        // socket_retry
        NSString* socket_retry = [[NSUserDefaults standardUserDefaults] objectForKey:@"socket_retry"];
        socket.rtry = socket_retry;
        
        // socket_waitSec
        // staffCallCode
        
        // 通信中のリスト
        _reqList = [[NSMutableArray alloc] init];
    }
    return self;
}

// 顧客情報取得
- (void)getCustomerInfo
{
    NSString* tableNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];

    //テーブル情報取得依頼を送信する
    NSNumber* reqNum = [[kolSocket instance] customerInfoFromTableID:tableNumber];
//    NSLog(@"reqNum:%@", [reqNum description]);
    
    NSDictionary* aDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            reqNum, @"number",
                            CUSTOMER_INFO, @"method",
                            nil, @"target", nil];
    [_reqList addObject:aDict];
}

// 注文する
- (void)orderConfirm:(NSArray *)orderList
{
    NSMutableArray* items = [[NSMutableArray alloc]init];
    
    // 注文データをTEC送信データに変換
    for (SELOrderData* orderData in orderList) {
        
        NSMutableDictionary* tecItemData = [[NSMutableDictionary alloc]init];
        [tecItemData setObject:orderData.OrderItemData.menuCode forKey:@"menuCode"];
        [tecItemData setObject:[orderData.OrderQuantity stringValue] forKey:@"quantity"];
        [tecItemData setObject:orderData.OrderItemData.price forKey:@"price"];
        [items addObject:tecItemData];
    }
    
    // TEC送信処理を呼びだす
    NSString* tableNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];
    NSNumber* reqNum = [[kolSocket instance] orderingOfItems:tableNumber orderItems:items];
    
    NSDictionary* aDict = [NSDictionary dictionaryWithObjectsAndKeys:
                           reqNum, @"number",
                           ORDERING_ITEMS, @"method",
                           nil, @"target",nil];
    [_reqList addObject:aDict];
}

// 注文一覧取得
- (void)getOrderedList
{
    NSString* tableNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];

    NSNumber * reqNum = [[kolSocket instance] orderHistoryFromTableID:tableNumber];
    NSDictionary * aDict = [NSDictionary dictionaryWithObjectsAndKeys:
                            reqNum, @"number",
                            ORDER_HISTORY, @"method",
                            nil, @"target",nil];
    [_reqList addObject:aDict];

    
/*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        // 返却結果を注文一覧形式に変換する
        
        sleep(0.5);
//        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
//        
//        NSMutableArray* orderDetailList = [[NSMutableArray alloc]init];
//        
//        // 10件分　商品情報からランダムに商品を作成する
//        for (int i=0; i < 10; i++ ) {
//            
//            // dummyデータセット
//            NSMutableDictionary* orderDetailView = [[NSMutableDictionary alloc]init];
//            
//            // 乱数を発生させる
//            int n = random() % [itemDataManager.itemDict count];
//            // dummyItemを取得する
//            SELItemData* itemData = [itemDataManager getItemDataFromIndex:n];
//            if (!itemData) {
//                continue;
//            }
//            
//            // 商品コード
//            [orderDetailView setValue:itemData.menuCode forKey:@"itemId"];
//            
//            // 金額
//            NSString* salesPrice = itemData.price;
//            [orderDetailView setValue:salesPrice forKey:@"salesPrice"];
//            
//            // 品数
//            NSString* quantity = [NSString stringWithFormat:@"%d",2];
//            [orderDetailView setValue:quantity forKey:@"quantity"];
//            
//            // 注文日時
//            NSString* orderDate = @"2014-01-01 00:00:00";
//            [orderDetailView setValue:orderDate forKey:@"orderDateTime"];
//            
//            // 取消フラグ
//            //        [orderDetailView setValue:@"00" forKey:kItemSt2key];
//            
//            [orderDetailList addObject:orderDetailView];
//        }
        //    [result setValue:ar forKey:kOrderHistoryItemKey];
        
        // Header
        //    NSNumber* totalPriceNum = [[NSNumber alloc]initWithInt:totalPrice];
        //    [result setValue:totalPriceNum forKey:kOrderTotalPriceKey];        // 合計金額
        //    NSNumber* numbers = [[NSNumber alloc]initWithInt:4];      // 来店人数
        //    MSCustomerInfo * customerInfo = [MSCustomerInfo instance];
        //    customerInfo.headCount = [[NSString alloc]initWithFormat:@"%@", numbers];
        //    customerInfo.totalPrice = [[NSString alloc]initWithFormat:@"%@", totalPriceNum];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate didGetOrderedList:TRUE orderedList:NULL info:NULL];
        });
        
    });
    */
}

- (void)callStaff
{
    // 店員呼出コード
    NSString* staffCallCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"staffCallCode"];

    NSMutableArray* items = [[NSMutableArray alloc]init];

    NSMutableDictionary* tecItemData = [[NSMutableDictionary alloc]init];
    [tecItemData setObject:staffCallCode forKey:@"menuCode"];
    [tecItemData setObject:@"0" forKey:@"price"];
    [items addObject:tecItemData];
    
    // TEC送信処理を呼びだす
    NSString* tableNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];
    NSNumber* reqNum = [[kolSocket instance] orderingOfItems:tableNumber orderItems:items];

    NSDictionary* aDict = [NSDictionary dictionaryWithObjectsAndKeys:
                           reqNum, @"number",
                           CALL_STAFF, @"method",
                           nil, @"target",nil];
    [_reqList addObject:aDict];
}

- (void)kolSocket:(NSNumber *)reqNo didReadData:(id)data error:(NSError *)error
{
    NSLog(@"kolSocket:didReadData");
    
    // 何の電文の応答か判断する
    NSDictionary * info = nil;
    for (NSDictionary * aDict in _reqList) {
        NSNumber * number = [aDict objectForKey:@"number"];
        if ([number isEqualToNumber:reqNo]) {
            info = aDict;
            break;
        }
    }
    
    if (info) {
        NSString * method = [info objectForKey:@"method"];
//        id aDelegate = [info objectForKey:@"target"];
//        id sendData;
        
        if ([CUSTOMER_INFO isEqualToString:method]) {
//            [_customerInfo release];
//            _customerInfo = (NSDictionary *)data;
//            [_customerInfo retain];
//            MSCustomerInfo * customerInfo = [MSCustomerInfo instance];
//            customerInfo.isService = [[_customerInfo objectForKey:@"operationFlag"] boolValue];
//            customerInfo.charge = [_customerInfo objectForKey:@"charge"];
//            customerInfo.headCount = [_customerInfo objectForKey:@"headCount"];
//            customerInfo.totalPrice = [_customerInfo objectForKey:@"totalPrice"];
//            aDelegate = customerInfo;
            
            if (!error) {
                NSLog(@"顧客情報を取得");
            }
            else {
                NSLog(@"顧客情報を取得に失敗しました:%@", [error description]);
            }
            
            // Add Start 2012-03-11 kitada
            // 通信制御不具合改修(志様・01CAFE障害対応)
//        } else if ([CUSTOMER_INFO_BEFORE_ORDER isEqualToString:method]) {
//            // 顧客情報照会応答の契機を注文リストに通知
//            [_customerInfo release];
//            _customerInfo = (NSDictionary *)data;
//            [_customerInfo retain];
//            sendData = _customerInfo;
//            // Add Start 2012-03-11 kitada
//
        } else if ([ORDER_HISTORY isEqualToString:method]) {
//            [_orderHistory release];
//            _orderHistory = (NSArray *)data;
//            [_orderHistory retain];
//            sendData = _orderHistory;
            
            if (!error) {
                // 返却値からorderHistoryデータを取り出す
                NSArray* orderDetailList = [data objectForKey:@"orderHistory"];
                // 返却値からtotalを取り出す
                NSInteger totalPrice = [[data objectForKey:@"totalPrice"] integerValue];
                // TEC形式からセルフオーダー形式に変換する
                NSMutableArray* retOrderDetailList = [self convertOrderData:orderDetailList];
                // 画面に通知
                [self.delegate didGetOrderedList:TRUE orderedList:retOrderDetailList totalPrice:totalPrice info:NULL];
            }
            else {
                [self.delegate didGetOrderedList:FALSE orderedList:NULL totalPrice:0 info:NULL];
            }
            
        } else if ([ORDERING_ITEMS isEqualToString:method]) {
//            [_sinagireArray release];
//            _sinagireArray = (NSArray *)data;
//            [_sinagireArray retain];
//            sendData = _sinagireArray;
            if (!error) {
                [self.delegate didOrderConfirm:TRUE info:@""];
            }
            else {
                [self.delegate didOrderConfirm:FALSE info:error.description];
            }
        } else if ([CALL_STAFF isEqualToString:method]) {
            if (!error) {
                [self.delegate didCallStaff:TRUE info:@""];
            }
            else {
                [self.delegate didCallStaff:FALSE info:error.description];
            }
        } else {
            NSLog(@"返却電文の種別が異常です:%@", method);
        }
        
        [_reqList removeObject:info];
    }
    else {
        NSLog(@"対象外の電文が返却されました:%@",data);
    }
}

- (NSMutableArray*)convertOrderData:(NSArray*)orderDetailList {
    
    // 店員呼出コード
    NSString* staffCallCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"staffCallCode"];

    SELItemDataManager* itemManager = [SELItemDataManager instance];

    NSMutableArray* retArray = [[NSMutableArray alloc]init];

    for (NSDictionary* orderDetail in orderDetailList) {
        
        SELOrderData* orderData = [[SELOrderData alloc]init];

        // 注文商品(4桁0埋め)
        NSInteger tempID = [[orderDetail objectForKey:@"menuCode"] integerValue];
        NSString* itemID = [NSString stringWithFormat:@"%04d",tempID];
        orderData.OrderItemData = [itemManager getItemData:itemID];
        if (!orderData.OrderItemData) {
            NSLog(@"商品マスタになし:%@", itemID);
            continue;
        }
        
        // 呼出は表示しない
        if ([staffCallCode isEqualToString:itemID]) {
            NSLog(@"店員呼出は表示しない");
            continue;
        }
        
        NSLog(@"%@",orderData.OrderItemData.itemName);
        NSLog(@"%@",[orderDetail description]);
        
        // カスタムオーダー/トッピングはそのまま表示
        
        // 注文数
        NSInteger quantity = [[orderDetail objectForKey:@"quantity"] intValue];
        orderData.OrderQuantity = [orderDetail objectForKey:@"quantity"];
        
        // 単価
        NSInteger salesPrice = [[orderDetail objectForKey:@"price"] intValue];
        
        // 注文取消
        NSString* st2 = [orderDetail objectForKey:@"ST2"];
        // st2の下１桁が8の場合は取消
        if ([[st2 substringFromIndex:1] isEqualToString:@"8"]) {
            orderData.OrderCancelFlag = [NSNumber numberWithBool:true];
            salesPrice = salesPrice * -1;   // 単価を反転
        }
        else {
            orderData.OrderCancelFlag = [NSNumber numberWithBool:false];
        }
        
        // 合計金額
        NSInteger total = quantity * salesPrice;
        orderData.OrderTotalPrice = [NSNumber numberWithInteger: total];

        // 注文時間
        NSString* orderDateTime = [orderDetail objectForKey:@"orderDate"];
        
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
        [inputFormatter setDateFormat:@"HHmm"];
        orderData.OrderDateTime = [inputFormatter dateFromString:orderDateTime];
        
        [retArray addObject:orderData];
    }

    return retArray;
}

@end
