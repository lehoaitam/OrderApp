//
//  SELStatusManager.m
//  selforder
//
//  Created by dpcc on 2014/09/29.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELStatusManager.h"
#import "AFNetworking.h"
#import "NSDictionary+JSON.h"
#import "NSDate+Utilities.h"
#import "SELSettingDataManager.h"
#import "SELOrderManager.h"
#import "SELMenuDataManager.h"

@implementation SELStatusManager

+ (id)instance
{
    static id _instance = nil;
    @synchronized(self) {
        if (!_instance) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (id)init
{
    self = [super init];
    
    if (self != nil) {
    }
    return self;
}

- (void)sendCurrentStatus
{
    // AFNetwork
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]init];
    // レスポンスJSON形式
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    // レスポンスのContent-Typeがtext/html
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    manager.securityPolicy.allowInvalidCertificates = YES;

    // 基本認証
//    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"kdladmin" password:@"kdl12345"];
    
    // リクエストパラメータを作成
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc]init];
    
    // 共通部分
    [requestParams setObject:@"OrderService" forKey:@"service"];    // サービス名
    [requestParams setObject:@"syncTableDeviceSetting" forKey:@"method"];       // メソッド名
    
    // param共通
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    SELOrderManager* orderDataManager = [SELOrderManager instance];
    
    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    [params setObject:[settingDataManager GetTableName] forKey:@"tableName"]; // table名(tableNumber)
    [params setObject:[NSString stringWithFormat:@"%ld",(long)[settingDataManager GetMenuNumber]] forKey:@"menuId"];
    [params setObject:[NSString stringWithFormat:@"%ld",(long)[orderDataManager cartCount]] forKey:@"pendingOrderCount"];
    
    NSDate* lastPendingOrderTime = [orderDataManager lastAddCartTime];
    if (lastPendingOrderTime) {
        NSString* orderTimeString = [lastPendingOrderTime stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
        [params setObject:orderTimeString forKey:@"lastPendingOrderTime"];
    }
    else {
        [params setObject:[NSNull null] forKey:@"lastPendingOrderTime"];
//        [params setObject:@"2012-04-10 22:33:10" forKey:@"lastPendingOrderTime"];
    }
//    [params setObject:@"2012-04-10 22:33:10" forKey:@"lastPendingOrderTime"];
    
    // params dictionaryをJSONに変換する
    NSString* paramsJSON = [params toJSONString];
    [requestParams setValue:paramsJSON forKey:@"params"];
    
    NSLog(@"requestParams=%@", [requestParams description]);
    
    // リクエスト送信
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [userDefaults objectForKey:@"kdlorderserviceurl"];
    [manager POST:url
       parameters:requestParams
          success:^(NSURLSessionDataTask *task, id responseObject) {
              // 通信成功
              NSLog(@"Success: %@", [responseObject description]);
              
              // 通信成功
              NSDictionary* responseDict = (NSDictionary*)responseObject;
              if (!responseDict) {
                  // ありえないはず
                  return;
              }
              
              // 結果の確認
              if ([[responseDict objectForKey:@"status"] isEqualToString:@"fail"]) {
                  // 失敗の場合
                  NSString* message = [responseDict objectForKey:@"message"];
                  NSLog(@"message:%@", message);
                  return ;
              }
              
              // method名チェック
              NSString* methodName = [responseDict objectForKey:@"method"];
              if (![methodName isEqualToString:@"syncTableDeviceSetting"]) {
                  NSLog(@"想定外のmethodが実行されました");
                  return;
              }
              
              // 成功の場合
              NSDictionary* receive_data = (NSDictionary*)[responseDict objectForKey:@"data"];
//              NSString* className = NSStringFromClass([data class]);
//              NSLog(@"%@", className);
              
              SELSettingDataManager* settingManager = [SELSettingDataManager instance];
              
              // 開設・閉設の変更
              NSString* orderStatusNum = [receive_data objectForKey:@"ipadStatus"];
              OrderStatus orderStatus = [orderStatusNum integerValue];
              [settingDataManager SetOrderStatus:orderStatus];
              
              NSString* menuNumber;
              if (orderStatus == OrderStatusEstablish) {
                  // 開設中の場合は、設定メニューに切り替える
                  if ([receive_data objectForKey:@"menuId"] == [NSNull null] ) {
                      // 未設定の場合(null)１番目とする
                      menuNumber = @"1";
                  }
                  else {
                      menuNumber = [receive_data objectForKey:@"menuId"];
                  }
              }
              else {
                  // 閉設中の場合は、メニューを1番目にする
                  menuNumber = @"1";
              }

              // 現在のメニューと切り替わっていたら、menu更新を行う
              BOOL bNeedUpdate = FALSE;
              NSInteger currentMenuNumber = [settingDataManager GetMenuNumber];
              if (currentMenuNumber != [menuNumber integerValue]) {
                  [settingManager SetMenuNumber:[menuNumber integerValue]];
                  bNeedUpdate = TRUE;
                  
                  if ([menuNumber isEqualToString:@"1"]) {
                      // 閉設メニュー(1番目メニュー)に変更された場合、カートを空にする
                      SELOrderManager* orderManager = [SELOrderManager instance];
                      [orderManager clearOrderList];
                      // 空になったことを通知
                      NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                      [notificationCenter postNotificationName:SELUpdateOrderListMessageNotification object:self];
                  }
              }

              // メッセージの保持
              NSString* originalMessage = [settingManager GetMessage];
              NSString* message = [receive_data objectForKey:@"message"];
              if (![originalMessage isEqualToString:message]) {
                  [settingDataManager SetMessage:message];
                  bNeedUpdate = TRUE;
              }
              
              // 各タイマー設定値を更新
              [settingDataManager SetiPadSoldoutUpdateInterval:[receive_data objectForKey:@"ipadSoldoutUpdateInterval"]];
              [settingDataManager SetiPadStatusUpdateInterval:[receive_data objectForKey:@"ipadStatusUpdateInterval"]];
              [settingDataManager SetWaiterListUpdateInterval:[receive_data objectForKey:@"waiterListUpdateInterval"]];
              [settingDataManager SetWaiterSoldoutUpdateInterval:[receive_data objectForKey:@"waiterSoldoutUpdateInterval"]];
              
              // タイマーを作成し直す
              
              
              // 画面更新
              if (bNeedUpdate) {
                  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                  [notificationCenter postNotificationName:SELMenuChangeNotification object:nil];
              }

          } failure:^(NSURLSessionDataTask *task, NSError *error) {
              // 通信エラー
              NSLog(@"Error: %@", error);
          }];
}

- (void)updateItemStatus
{
    // UserDataを取得
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    SELUserData* userData = [settingDataManager GetUserData];
    if (!userData) {
        // userdataが設定されていない
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
        return;
    }

    // AFNetwork
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]init];
    // レスポンスJSON形式
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    // レスポンスのContent-Typeがtext/html
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    // 基本認証
//    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"kdladmin" password:@"kdl12345"];
    
    // リクエストパラメータを作成
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc]init];
    
    // テスト環境Xx
//    NSString *url = @"https://dev01-so.kdlapps.net/getitemstatus";
    // 本番環境
    NSString *url = @"https://www2.ipadso.net/getitemstatus";
    
    url = [[NSString alloc] initWithFormat:@"%@?name=%@&code=%@&pass=%@",url, userData.CompanyName, userData.CompanyCode, userData.CompanyPass];
    
    // リクエスト送信
    [manager POST:url
       parameters:requestParams
          success:^(NSURLSessionDataTask *task, id responseObject) {
              
              // 返却例
              // {"status":"success","revision":"20141104134243","data":{"4041":{"soldout":"true"},"4042":{"soldout":"true"},"4043":{"soldout":"true"}}}
              
              // 通信成功
              NSLog(@"Success: %@", [responseObject description]);
              
              // 通信成功
              NSDictionary* responseDict = (NSDictionary*)responseObject;
              
//              // test用JSONファイル読み込み
//              NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"json"];
//              NSData *content = [[NSData alloc] initWithContentsOfFile:filePath];
//              NSError* error;
//              responseDict = [NSJSONSerialization JSONObjectWithData:content options:kNilOptions error:&error];
              
              if (!responseDict) {
                  // ありえないはず
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
                  return;
              }
              if (![responseObject isKindOfClass:[NSDictionary class]]) {
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
                  return;
              }
              
              // 結果の確認
              if ([[responseDict objectForKey:@"status"] isEqualToString:@"fail"]) {
                  // 失敗の場合
                  NSString* message = [responseDict objectForKey:@"message"];
                  NSLog(@"message:%@", message);
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
                  return ;
              }
              
              // 成功の場合
              id receive_data = [responseDict objectForKey:@"data"];
              
              // 結果がNSDictionaryの場合のみ保存する
              if ([receive_data isKindOfClass:[NSDictionary class]]) {
                  // receive_dataを覚えておく
                  [[NSUserDefaults standardUserDefaults] setObject:receive_data forKey:@"itemstatus"];
              }
              else {
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
              }
              
              id otherdata = [responseDict objectForKey:@"otherdata"];
              
              if ([otherdata isKindOfClass:[NSDictionary class]]) {
                  [[NSUserDefaults standardUserDefaults] setObject:otherdata forKey:@"itemstatus_otherdata"];
              }
              else {
                  [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
              }
              
          } failure:^(NSURLSessionDataTask *task, NSError *error) {
              // 通信エラー
              NSLog(@"Error: %@", error);
              [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus"];
              [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"itemstatus_otherdata"];
          }];
}

- (void)getIpadList
{
    // AFNetwork
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc]init];
    // レスポンスJSON形式
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    // レスポンスのContent-Typeがtext/html
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    manager.securityPolicy.allowInvalidCertificates = YES;

    // 基本認証
//    [manager.requestSerializer setAuthorizationHeaderFieldWithUsername:@"kdladmin" password:@"kdl12345"];
    
    // リクエストパラメータを作成
    NSMutableDictionary* requestParams = [[NSMutableDictionary alloc]init];
    
    // 共通部分
    [requestParams setObject:@"OrderService" forKey:@"service"];    // サービス名
    [requestParams setObject:@"getIpadList" forKey:@"method"];       // メソッド名
    
    // param共通
    NSMutableDictionary* params = [[NSMutableDictionary alloc]init];
    //    [params setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"] forKey:@"tableName"]; // table名(tableNumber)
    // params dictionaryをJSONに変換する
    NSString* paramsJSON = [params toJSONString];
    [requestParams setValue:paramsJSON forKey:@"params"];
    
    // リクエスト送信
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [userDefaults objectForKey:@"kdlorderserviceurl"];
    [manager POST:url
       parameters:requestParams
          success:^(NSURLSessionDataTask *task, id responseObject) {
              
              // 通信成功
              NSDictionary* responseDict = (NSDictionary*)responseObject;
              if (!responseDict) {
                  // ありえないはず
                  [self.delegate didGetiPadList:FALSE info:NULL];
                  return;
              }
              
              // 結果の確認
              if (![[responseDict objectForKey:@"status"] isEqualToString:@"success"]) {
                  // サーバーからエラー返却
                  NSString* errorMessage = [NSString stringWithFormat:@"%@", [responseDict objectForKey:@"message"]];
                  [self.delegate didGetiPadList:FALSE info:errorMessage];
                  return ;
              }
              
              // method名チェック
              NSString* methodName = [responseDict objectForKey:@"method"];
              if (![methodName isEqualToString:@"getIpadList"]) {
                  [self.delegate didGetiPadList:FALSE info:Nil];
                  return;
              }
              
              if ([responseDict objectForKey:@"data"] == [NSNull null]) {
                  // dataなし
                  [self.delegate didGetiPadList:FALSE info:NULL];
                  return;
              }
              
              NSDictionary* data = [responseDict objectForKey:@"data"];
              
              // データをNSDefaultに保存する
              NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
              NSArray* ipadlist = [data objectForKey:@"ipadList"];
              [defaults setObject:ipadlist forKey:@"ipadlist"];
              
              NSString* nonDisplayCategoryCode = [data objectForKey:@"nonDisplayCategoryCode"];
              [defaults setObject:nonDisplayCategoryCode forKey:@"nondisplaycategorycode"];
              
              NSString* paymentCode = [data objectForKey:@"paymentCode"];
              [defaults setObject:paymentCode forKey:@"paymentcode"];
              
              // 設定値が反映されないバグ修正
              SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
              [settingDataManager SetWaiterListUpdateInterval:[data objectForKey:@"waiterListUpdateInterval"]];
              [settingDataManager SetWaiterSoldoutUpdateInterval:[data objectForKey:@"waiterSoldoutUpdateInterval"]];
              
              // タイマーを作成し直す
              
              
              
              [self.delegate didGetiPadList:TRUE info:data];
              return;
              
          } failure:^(NSURLSessionDataTask *task, NSError *error) {
              // 通信エラー
              NSLog(@"Error: %@", error);
              [self.delegate didGetiPadList:FALSE info:[error localizedDescription]];
          }];
}

@end
