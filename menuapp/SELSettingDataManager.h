//
//  SELUserDataManager.h
//  menuapp
//
//  Created by dpcc on 2014/04/08.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SELUserData.h"

typedef enum : NSInteger{
    OrderStatusClosing = 0,
    OrderStatusEstablish = 1,
} OrderStatus;


@interface SELSettingDataManager : NSObject {
    
}

+ (id)instance;

- (SELUserData*)GetUserData;

- (NSString*)GetTableName;
- (void)SetTableName:(NSString*)tableName;

- (NSInteger)GetMenuNumber;
- (NSString*)GetMenuNumberString;
- (void)SetMenuNumber:(NSInteger)menuNumber;

- (NSString*)GetMenuDataLastModified;
- (void)SetMenuDataLastModified:(NSString*)lastModified;

- (void)UpdateSettingData;

- (NSString*)GetPrinterGroupKey;
- (void)SetPrinterGroupKey:(NSString*)printerGroupKey;

- (OrderStatus)GetOrderStatus;
- (void)SetOrderStatus:(OrderStatus)orderStatus;

- (NSString*)GetMessage;
- (void)SetMessage:(NSString*)message;

// iPad売切情報取得間隔（秒）
- (NSNumber*)GetiPadSoldoutUpdateInterval;
- (void)SetiPadSoldoutUpdateInterval:(NSNumber*)interval;

// iPadステータス情報更新間隔（秒）
- (NSNumber*)GetiPadStatusUpdateInterval;
- (void)SetiPadStatusUpdateInterval:(NSNumber*)interval;

// 店員端末端末情報更新間隔（秒）
- (NSNumber*)GetWaiterListUpdateInterval;
- (void)SetWaiterListUpdateInterval:(NSNumber*)interval;

// 店員端末売切情報更新間隔（秒）
- (NSNumber*)GetWaiterSoldoutUpdateInterval;
- (void)SetWaiterSoldoutUpdateInterval:(NSNumber*)interval;

@end
