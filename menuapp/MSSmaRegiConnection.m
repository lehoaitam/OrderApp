//
//  MSSmaRegiConnection.m
//  MenuApp
//
//  Created by ipadso on 12/09/04.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MSSmaRegiConnection.h"
#import "PrinterController.h"
#import "SmaregiUtil.h"
#import "SVProgressHUD.h"
#import "SELItemDataManager.h"
#import "SELSettingDataManager.h"
#import "AFNetworking.h"
#import "SELOrderData.h"

#import "PrinterController.h"

@implementation MSSmaRegiConnection

- (void)orderConfirm:(NSArray *)orderList
{
    // AFNetwork
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // レスポンスJSON形式
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    // レスポンスのContent-Typeがtext/html
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];

    // リクエストパラメータを作成
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc]init];
    
    // 共通部分
    [requestParams setObject:@"KdlOrderService" forKey:@"service"];    // サービス名
    [requestParams setObject:@"registerOrder" forKey:@"method"];       // メソッド名
    
    // param共通
    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"smaregi_at"] forKey:@"at"];         // アクセストークン(smaregi_at)
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"smaregi_id"] forKey:@"contractId"]; // 契約ID(smaregi_id)
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"] forKey:@"tableName"]; // table名(tableNumber)
    
    // 注文詳細
    NSMutableArray* orderDetailList = [[NSMutableArray alloc]init];
    for (SELOrderData* orderData in orderList) {
        
        // 商品データ
        SELItemData* itemData = orderData.OrderItemData;
        
        // 商品データからスマレジ通信用注文詳細パラメータを作成する
        NSMutableDictionary *orderDetailParam = [self createOrderDetailParam:itemData CustomOrder:orderData.SelectedCustomOrder ParentOrderDetailNo:NULL OrderQuantity:orderData.OrderQuantity];
        
        [orderDetailList addObject:orderDetailParam];
        
        // トッピングある場合は商品として追加する
        for (SELItemData* toppingItemData in orderData.SelectedTopping) {
            
            // 親注文番号
            NSString* parentOrderDetailNo = [orderDetailParam objectForKey:@"orderDetailNo"];
            
            // 個数は親注文と同じ個数
            NSMutableDictionary *orderDetailToppingParam = [self createOrderDetailParam:toppingItemData CustomOrder:NULL ParentOrderDetailNo:parentOrderDetailNo OrderQuantity:orderData.OrderQuantity];

            [orderDetailList addObject:orderDetailToppingParam];
        }
    }
    
    [params setValue:orderDetailList forKey:@"orderDetailList"];
    
    // params dictionaryをJSONに変換する
    NSString* paramsJSON = [self DictionaryToJSONString:params];
    [requestParams setValue:paramsJSON forKey:@"params"];
    
    // リクエスト送信
    [manager POST:@"https://waiter1.smaregi.jp/services/kdl_gateway.php"
      parameters:requestParams
         success:^(NSURLSessionDataTask *task, id responseObject) {
             
             // 通信成功
             NSDictionary* responseDict = (NSDictionary*)responseObject;
             if (!responseDict) {
                 // ありえないはず
                 [self.delegate didOrderConfirm:FALSE info:@"スマレジからの返却内容がありませんでした。"];
                 return;
             }
             
             // 結果の確認
             if (![[responseDict objectForKey:@"status"] isEqualToString:@"success"]) {
                 // スマレジからエラー返却
                 NSString* errorMessage = [NSString stringWithFormat:@"スマレジ連携設定を見直してください。\n詳細:%@", [responseDict objectForKey:@"message"]];
                 [self.delegate didOrderConfirm:FALSE info:errorMessage];
                 return ;
             }
             
             // 印刷処理用パラメータ作成
             NSDictionary* responseOrderData = [responseDict objectForKey:@"data"];
             NSMutableArray* responseOrderDetailArray = [[NSMutableArray alloc]init];
             for (NSDictionary* responseOrderDetail in [responseOrderData objectForKey:@"orderDetailList"])
             {
                 // スマレジから全データ返却されるため、今回注文分のみを対象とする
                 if ([self isEqualOrder:responseOrderDetail target:orderDetailList]) {
                     [responseOrderDetailArray addObject:responseOrderDetail];
                 }
             }
             // 印刷処理
             NSDictionary* orderHeaderDict = [responseOrderData objectForKey:@"orderHeader"];
             [[PrinterController instance] printOrder:orderHeaderDict orderDetailList:responseOrderDetailArray];
             
             // 印刷エラー情報があれば、通信は成功だが、印刷エラー情報を返す
             NSString* errorInfo = [[PrinterController instance] errInfoToString];
             [self.delegate didOrderConfirm:TRUE info:errorInfo];

             return;
             
         } failure:^(NSURLSessionDataTask *task, NSError *error) {
             // 通信エラー
             NSLog(@"Error: %@", error);
             [self.delegate didOrderConfirm:FALSE info:[error localizedDescription]];
         }];
}

- (NSMutableDictionary*)createOrderDetailParam:(SELItemData*)itemData CustomOrder:(SELItemData*)customOrderItemData ParentOrderDetailNo:(NSString*)parentOrderDetailNo OrderQuantity:(NSNumber*)OrderQuantity;
{
    NSMutableDictionary *orderDetailParam = [[NSMutableDictionary alloc] init];
    
    // 注文番号
    NSString* orderDetailNo = [super createOrderDetailNo];
    [orderDetailParam setValue:orderDetailNo forKey:@"orderDetailNo"];
    
    if (parentOrderDetailNo) {
        // 親注文番号(トッピング以外はNULL)
        [orderDetailParam setValue:parentOrderDetailNo forKey:@"parentOrderDetailNo"];
        // トッピング商品
        [orderDetailParam setValue:@"3" forKey:@"itemDivision"];
    }
    else {
        // 通常商品
        [orderDetailParam setValue:@"0" forKey:@"itemDivision"];
    }
    
    // 注文日時
    [orderDetailParam setValue:[[NSDate date]dateTimeFormattedString] forKey:@"orderDateTime"];
    // 商品ID
    [orderDetailParam setValue:[itemData valueForKey:@"menuCode"] forKey:@"itemId"];
    // 商品名
    [orderDetailParam setValue:itemData.itemNameJA forKey:@"itemName"];
    
    // カスタムオーダーID カスタムオーダー名
    NSString* setMenuCode = @"";
    NSString* setMenuName = @"";
    if (customOrderItemData) {
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        SELItemData* selectedCustomOrderItem = [itemDataManager getItemData:customOrderItemData.menuCode];
        
        NSString* setMenuCodeWork = selectedCustomOrderItem.menuCode;
        setMenuName = selectedCustomOrderItem.itemNameJA;
        
        // スマレジに渡す用のコードを作成する(10000を引く)
        int nSmarejiMenuCode = [setMenuCodeWork intValue] - 10000;
        setMenuCode = [NSString stringWithFormat:@"%d",nSmarejiMenuCode];
    }
    [orderDetailParam setValue:setMenuCode forKey:@"itemDrillDownId"];
    [orderDetailParam setValue:setMenuName forKey:@"itemDrillDownName"];
    
    // 商品区分
    //[orderDetailParam setValue:@"0" forKey:@"itemDivision"];
    // カテゴリID
    [orderDetailParam setValue:[itemData valueForKey:@"category1_code"] forKey:@"categoryId"];
    // カテゴリ名
    [orderDetailParam setValue:[itemData valueForKey:@"category1_name"] forKey:@"categoryName"];
    // 数量
    [orderDetailParam setValue:OrderQuantity forKey:@"quantity"];
    // 商品価格
    [orderDetailParam setValue:[itemData valueForKey:@"price"] forKey:@"price"];
    // 販売価格
    [orderDetailParam setValue:[itemData valueForKey:@"price"] forKey:@"salesPrice"];
    // 単品値引き
    [orderDetailParam setValue:0 forKey:@"discountPrice"];
    // 単品値引き率
    [orderDetailParam setValue:0 forKey:@"discountRate"];
    // 割引区分
    [orderDetailParam setValue:0 forKey:@"discountDivision"];
    // ステータス
    [orderDetailParam setValue:0 forKey:@"status"];
    
    return orderDetailParam;
}

- (void)getOrderedList
{
    // AFNetwork
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // レスポンスJSON形式
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    // レスポンスのContent-Typeがtext/html
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    // リクエストパラメータを作成
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc]init];
    
    // 共通部分
    [requestParams setObject:@"KdlOrderService" forKey:@"service"];    // サービス名
    [requestParams setObject:@"getOrder" forKey:@"method"];       // メソッド名
    
    // param共通
    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"smaregi_at"] forKey:@"at"];         // アクセストークン(smaregi_at)
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"smaregi_id"] forKey:@"contractId"]; // 契約ID(smaregi_id)
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"] forKey:@"tableName"]; // table名(tableNumber)
    // params dictionaryをJSONに変換する
    NSString* paramsJSON = [self DictionaryToJSONString:params];
    [requestParams setValue:paramsJSON forKey:@"params"];

    // リクエスト送信
    [manager POST:@"https://waiter1.smaregi.jp/services/kdl_gateway.php"
       parameters:requestParams
          success:^(NSURLSessionDataTask *task, id responseObject) {
              
              // 通信成功
              NSDictionary* responseDict = (NSDictionary*)responseObject;
              if (!responseDict) {
                  // ありえないはず
                  [self.delegate didGetOrderedList:FALSE orderedList:NULL totalPrice:0 info:@"スマレジサーバーからの返却内容がありませんでした。"];
                  return;
              }
              
              // 結果の確認
              if (![[responseDict objectForKey:@"status"] isEqualToString:@"success"]) {
                  // スマレジからエラー返却
                  NSString* errorMessage = [NSString stringWithFormat:@"スマレジ連携設定を見直してください。\n詳細:%@", [responseDict objectForKey:@"message"]];
                  [self.delegate didGetOrderedList:FALSE orderedList:NULL totalPrice:0 info:errorMessage];
                  return ;
              }
              
              if ([responseDict objectForKey:@"data"] == [NSNull null]) {
                  // dataなし(テーブル未チェックインなど)
                  [self.delegate didGetOrderedList:FALSE orderedList:NULL totalPrice:0 info:@"チェックインされていません。"];
                  return;
              }
              
              NSDictionary* data = [responseDict objectForKey:@"data"];
              if ([data objectForKey:@"orderDetailList"] == [NSNull null]) {
                  // 注文データなし
                  [self.delegate didGetOrderedList:TRUE orderedList:NULL totalPrice:0 info:NULL];
                  return;
              }
              
              // 合計を取得
              NSDictionary* orderHeader = [data objectForKey:@"orderHeader"];
              NSInteger totalPrice = [[orderHeader objectForKey:@"total"] integerValue];
              
              NSArray* orderDetailList = [data objectForKey:@"orderDetailList"];
              
              // スマレジ形式からセルフオーダー形式に変換する
              NSMutableArray* retOrderDetailList = [self convertOrderData:orderDetailList];
              
              // 画面側に通知
              [self.delegate didGetOrderedList:TRUE orderedList:retOrderDetailList totalPrice:totalPrice info:NULL];
              
          } failure:^(NSURLSessionDataTask *task, NSError *error) {
              // 通信エラー
              NSLog(@"Error: %@", error);
              [self.delegate didGetOrderedList:FALSE orderedList:NULL totalPrice:0 info:[error localizedDescription]];
          }];
}

- (void)callStaff
{
//    // 印刷テスト(ECP/POSモード)
//    [self print_test];
//    return;
    
    // AFNetwork
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // レスポンスJSON形式
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    // レスポンスのContent-Typeがtext/html
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    // リクエストパラメータを作成
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc]init];
    
    // 共通部分
    [requestParams setObject:@"KdlOrderService" forKey:@"service"];    // サービス名
    [requestParams setObject:@"callStaff" forKey:@"method"];       // メソッド名
    
    // param共通
    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"smaregi_at"] forKey:@"at"];         // アクセストークン(smaregi_at)
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"smaregi_id"] forKey:@"contractId"]; // 契約ID(smaregi_id)
    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"] forKey:@"tableName"]; // table名(tableNumber)
    // params dictionaryをJSONに変換する
    NSString* paramsJSON = [self DictionaryToJSONString:params];
    [requestParams setValue:paramsJSON forKey:@"params"];
    
    // リクエスト送信
    [manager POST:@"https://waiter1.smaregi.jp/services/kdl_gateway.php"
       parameters:requestParams
          success:^(NSURLSessionDataTask *task, id responseObject) {
              
              // 通信成功
              NSDictionary* responseDict = (NSDictionary*)responseObject;
              if (!responseDict) {
                  // ありえないはず
                  [self.delegate didCallStaff:FALSE info:@"スマレジサーバーからの返却内容がありませんでした。"];
                  return;
              }
              
              // 結果の確認
              if (![[responseDict objectForKey:@"status"] isEqualToString:@"success"]) {
                  // スマレジからエラー返却
                  NSString* errorMessage = [NSString stringWithFormat:@"スマレジ連携設定を見直してください。\n詳細:%@", [responseDict objectForKey:@"message"]];
                  [self.delegate didCallStaff:FALSE info:errorMessage];
                  return ;
              }
              
              [self.delegate didCallStaff:TRUE info:NULL];
              return;
              
          } failure:^(NSURLSessionDataTask *task, NSError *error) {
              // 通信エラー
              NSLog(@"Error: %@", error);
              [self.delegate didCallStaff:FALSE info:[error localizedDescription]];
          }];
}

#pragma mark - util

- (NSString*)DictionaryToJSONString:(NSDictionary*)dict
{
    NSError* error;
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:dict
                                    options:kNilOptions error:&error];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

// 同一注文データがあるかどうか
- (BOOL)isEqualOrder:(NSDictionary*)src target:(NSArray*)destArray
{
    NSString* srcOrderDetailNo = [src objectForKey:@"orderDetailNo"];
    for (NSDictionary* dest in destArray) {
        NSString* destOrderDetailNo = [dest objectForKey:@"orderDetailNo"];
        if ([srcOrderDetailNo isEqualToString:destOrderDetailNo]) {
            return TRUE;
        }
    }
    return FALSE;
}

#pragma mark - test

- (void)print_test
{
//    unsigned char command[] = {0x41, 0x42, 0x43, 0x44, 0x1B, 0x7A, 0x00, 0x1B, 0x64, 0x02};
    unsigned char command[] = {0x41, 0x0A, 0x42, 0x0A, 0x43, 0x0A, 0x44, 0x0A, 0x1B, 0x7A, 0x00, 0x1B, 0x64, 0x02};
    uint bytesWritten = 0;
    
    StarPrinterStatus_2 starPrinterStatus;
    SMPort *port = nil;
    @try
    {
        port = [SMPort getPort:@"TCP:192.168.2.81" :@"" :10000];
        //Start checking the completion of printing
        [port beginCheckedBlock:&starPrinterStatus :2];
        if (starPrinterStatus.offline == SM_TRUE)
        {
            //There was an error writing to the port
        }
        while (bytesWritten < sizeof (command)) {
            bytesWritten += [port writePort: command : bytesWritten : sizeof (command) - bytesWritten];
        }
        //End checking the completion of printing
        [port endCheckedBlock:&starPrinterStatus :2];
        if (starPrinterStatus.offline == SM_TRUE)
        {
            //There was an error writing to the port
        } 
    } 
    @catch (PortException*)
    { 
        //There was an error writing to the port 
    } 
    @finally 
    { 
        [SMPort releasePort:port]; 
    } 
}

// スマレジからのオーダーリストをセルフオーダー形式に変換する
- (NSMutableArray*)convertOrderData:(NSArray*)orderDetailList
{
    NSMutableArray* orderList = [[NSMutableArray alloc]init];

    // カスタムオーダーのIDを変換する（10000足す）
    for (NSDictionary* orderDetail in orderDetailList) {
        
        NSString* sItemDrillDownId = [orderDetail objectForKey:@"itemDrillDownId"];
        
        // カスタムオーダーが無い場合はそのままセットする
        if (!sItemDrillDownId) {
            [orderList addObject:orderDetail];
            continue;
        }
        
        NSMutableDictionary* retOrderDetail = [[NSMutableDictionary alloc]initWithDictionary:orderDetail];
        
        NSInteger nItemDrillDownId = [sItemDrillDownId integerValue];
        
        // カスタムオーダーのコードは10000足す
        nItemDrillDownId = nItemDrillDownId + 10000;
        sItemDrillDownId = [NSString stringWithFormat:@"%d", nItemDrillDownId];
        
        // 変換後の値をセットする
        [retOrderDetail setValue:sItemDrillDownId forKey:@"itemDrillDownId"];
        [orderList addObject:retOrderDetail];
    }

    // 戻り値用
    NSMutableArray* retArray = [[NSMutableArray alloc]init];
    
    SELItemDataManager* itemManager = [SELItemDataManager instance];
    
    // ひも付けのため、トッピング以外のデータを先に作成、
    // その後、親データにひも付けしつつ、トッピングデータを作成します。
    
    // 先にトッピング以外のデータを作成
    for (NSDictionary* orderDetail in orderList) {
        
        if ([orderDetail objectForKey:@"parentOrderDetailNo"] != [NSNull null] &&
            [orderDetail objectForKey:@"parentOrderDetailNo"] != nil) {
            continue;
        }
        
        SELOrderData* orderData = [[SELOrderData alloc]init];
        orderData.OrderDetailNO = [orderDetail objectForKey:@"orderDetailNo"];
        orderData.SelectedTopping = [[NSMutableArray alloc]init];
        
        // 注文商品
        NSString* itemID = [orderDetail objectForKey:@"itemId"];
        orderData.OrderItemData = [itemManager getItemData:itemID];
        if (!orderData.OrderItemData) {
            continue;
        }
        
        // ステータス
        NSString* status = [orderDetail objectForKey:@"status"];
        if ([status isEqualToString:@"9"]) {
            // 9の場合はオーダーキャンセル
            orderData.OrderCancelFlag = [NSNumber numberWithBool:true];
        }
        else {
            // それ以外は通常注文
            orderData.OrderCancelFlag = [NSNumber numberWithBool:false];
        }
        
        // カスタムオーダー
        NSString* customItemID = [orderDetail objectForKey:@"itemDrillDownId"];
        orderData.SelectedCustomOrder = [itemManager getItemData:customItemID];
        
        // 注文数
        NSInteger quantity = [[orderDetail objectForKey:@"quantity"] intValue];
        orderData.OrderQuantity = [orderDetail objectForKey:@"quantity"];
        
        // 単価
        NSInteger salesPrice = [[orderDetail objectForKey:@"salesPrice"] intValue];
        
        // 合計金額
        NSInteger total = quantity * salesPrice;
        orderData.OrderTotalPrice = [NSNumber numberWithInteger: total];
        
        // 注文時間
        NSString* orderDateTime = [orderDetail objectForKey:@"orderDateTime"];
        
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:SS"];
        orderData.OrderDateTime = [inputFormatter dateFromString:orderDateTime];
        
        [retArray addObject:orderData];
        
//        // 総合計を更新(キャンセルではない場合のみ)
//        if (![orderData.OrderCancelFlag boolValue]) {
//            _totalPrice += total;
//        }
    }
    
    // トッピングデータのみ
    for (NSDictionary* orderDetail in orderList) {
        
        if ([orderDetail objectForKey:@"parentOrderDetailNo"] == [NSNull null] ||
            [orderDetail objectForKey:@"parentOrderDetailNo"] == nil) {
            continue;
        }
        
        NSString* parentOrderDetailNo = [orderDetail objectForKey:@"parentOrderDetailNo"];
        SELOrderData* parentOrderData = [self getOrderData:retArray detailNO:parentOrderDetailNo];
        if (!parentOrderData) {
            NSLog(@"ERROR:親注文データが見つかりませんでした！");
            continue;
        }
        
        // 商品データを取得
        NSString* itemID = [orderDetail objectForKey:@"itemId"];
        SELItemData* toppingItem = [itemManager getItemData:itemID];
        [parentOrderData.SelectedTopping addObject:toppingItem];
        
        // トッピング注文数
        NSInteger quantity = [[orderDetail objectForKey:@"quantity"] intValue];
        
        // トッピング金額
        NSInteger salesPrice = [[orderDetail objectForKey:@"salesPrice"] intValue];
        
        // トッピング総額
        NSInteger toppingTotal = quantity * salesPrice;
        
        // 合計金額を更新
        
        // 親注文金額
        NSInteger parentPrice = [parentOrderData.OrderTotalPrice integerValue];
        parentOrderData.OrderTotalPrice = [NSNumber numberWithInteger:parentPrice + toppingTotal];
        
//        // 合計金額を更新する(足し込むのはトッピング料金のみ)
//        if (![parentOrderData.OrderCancelFlag boolValue]) {
//            _totalPrice += toppingTotal;
//        }
    }
    
    return retArray;
}

- (SELOrderData*)getOrderData:(NSArray*)orderDataList detailNO:(NSString*)orderDetailNO
{
    for (SELOrderData* orderData in orderDataList)
    {
        if ([orderData.OrderDetailNO isEqualToString:orderDetailNO]) {
            return orderData;
        }
    }
    return NULL;
}

@end
