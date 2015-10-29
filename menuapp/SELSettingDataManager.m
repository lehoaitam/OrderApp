//
//  SELUserDataManager.m
//  menuapp
//
//  Created by dpcc on 2014/04/08.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELSettingDataManager.h"
#import "NSDate+Utilities.h"
#import "NSNull+isNull.h"

@implementation SELSettingDataManager

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

- (SELUserData *)GetUserData
{
    NSString* companyName = [[NSUserDefaults standardUserDefaults] objectForKey:@"companyName"];
    NSString* companyCode = [[NSUserDefaults standardUserDefaults] objectForKey:@"companyCode"];
    NSString* companyPass = [[NSUserDefaults standardUserDefaults] objectForKey:@"companyPass"];
    
    if (companyCode && companyCode && companyPass) {
        SELUserData* userData = [[SELUserData alloc]init];
        userData.CompanyName = companyName;
        userData.CompanyCode = companyCode;
        userData.CompanyPass = companyPass;
        return userData;
    }
    
    return NULL;
}

- (void)SetTableName:(NSString *)tableName
{
    [[NSUserDefaults standardUserDefaults] setObject:tableName forKey:@"tableNumber"];
}

- (NSString *)GetTableName
{
    NSString* tableNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"tableNumber"];
    return tableNumber;
}

- (void)SetMenuNumber:(NSInteger)menuNumber
{
    NSNumber* num = [NSNumber numberWithInteger:menuNumber];
    [[NSUserDefaults standardUserDefaults] setObject:num forKey:@"menuNumber"];
}

- (NSInteger)GetMenuNumber
{
    NSNumber* num = [[NSUserDefaults standardUserDefaults] objectForKey:@"menuNumber"];
    if (num == NULL) {
        return 1;
    }
    return [num integerValue];
}

- (void)SetPrinterGroupKey:(NSString*)printerGroupKey
{
    [[NSUserDefaults standardUserDefaults] setObject:printerGroupKey forKey:@"printergroupkey"];
}

- (NSString*)GetPrinterGroupKey
{
    NSString* printerGroupKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"printergroupkey"];
    return printerGroupKey;
}

- (void)UpdateSettingData
{
    // ダウンロードしたsetting.jsonから、NSUserDefaultを更新する
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* destinationPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode"];
    NSString* filePath = [destinationPath stringByAppendingPathComponent:@"setting.json"];
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        NSLog(@"setting.jsonファイルがありません。%@", filePath);
        return;
    }
    NSError* error = nil;
    NSDictionary *controlDictData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (!controlDictData) {
        NSLog(@"setting.jsonファイルのJSONシリアライズに失敗しました。%@", [error description]);
        return;
    }
    
	//
	NSArray * keys = [controlDictData allKeys];
	for (NSString * key in keys) {
        NSString* value = [controlDictData objectForKey:key];
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
	}
    
    // メニューデータバージョンを更新する
    //NSString* strVersion = [self getMenuFileDate];
    //[[NSUserDefaults standardUserDefaults] setObject:strVersion forKey:@"menuUpdateDate"];
    
	//保存
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)GetMenuDataLastModified
{
    NSDate* lastModifiedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastModifiedDate"];
    if(!lastModifiedDate){
        return @"";
    }
    
    // YYYY/MM/DD HH/mm/SSに直す
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy年MM月dd日 HH時mm分ss秒"];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    return [formatter stringFromDate:lastModifiedDate];
}

- (void)SetMenuDataLastModified:(NSString *)lastModified
{
    NSDate* lastModifiedDate;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    
    NSArray* dates = [NSArray arrayWithObjects:
                      @"EEE',' dd MMM yyyy HH':'mm':'ss z",    // RFC1123
                      @"EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z", // RFC850
                      @"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ",     // ISO8610
                      @"EEE MMM d HH':'mm':'ss yyyy",          // asctime
                      nil];
    
    for (NSString* dataformat in dates)
    {
        df.dateFormat = dataformat;
        lastModifiedDate = [df dateFromString:lastModified];
        if (lastModifiedDate)
        {
            break;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:lastModifiedDate forKey:@"lastModifiedDate"];
}

- (OrderStatus)GetOrderStatus
{
    NSNumber* orderStatusNum = [[NSUserDefaults standardUserDefaults] objectForKey:@"orderStatus"];
    if (orderStatusNum == NULL) {
        // 未設定の場合は開設を返す
        return OrderStatusEstablish;
    }
    return (OrderStatus)[orderStatusNum integerValue];
}

- (void)SetOrderStatus:(OrderStatus)orderStatus
{
    NSNumber* orderStatusNum = [NSNumber numberWithInteger:orderStatus];
    [[NSUserDefaults standardUserDefaults] setObject:orderStatusNum forKey:@"orderStatus"];
}

- (NSString *)GetMessage
{
    NSString* message = [[NSUserDefaults standardUserDefaults] objectForKey:@"message"];
    return message;
}

- (void)SetMessage:(NSString *)message
{
    [[NSUserDefaults standardUserDefaults] setObject:message forKey:@"message"];
}

- (NSNumber*)GetiPadSoldoutUpdateInterval
{
    NSNumber* interval = [[NSUserDefaults standardUserDefaults] objectForKey:@"ipadSoldoutUpdateInterval"];
    if (interval == nil) {
        return [NSNumber numberWithFloat:10.0f];
    }
    return interval;
}

- (void)SetiPadSoldoutUpdateInterval:(NSNumber*)interval
{
    if ([NSNull isNull:interval]) {
        interval = nil;
    }
    [[NSUserDefaults standardUserDefaults] setObject:interval forKey:@"ipadSoldoutUpdateInterval"];
}

- (NSNumber*)GetiPadStatusUpdateInterval
{
    id interval = [[NSUserDefaults standardUserDefaults] objectForKey:@"ipadStatusUpdateInterval"];
    if (interval == nil) {
        return nil;
    }
    NSInteger nInterval = [interval integerValue];
    if (nInterval == 0) {
        return nil;
    }
    return [NSNumber numberWithInteger:nInterval];
}

- (void)SetiPadStatusUpdateInterval:(NSNumber*)interval
{
    if ([NSNull isNull:interval]) {
        interval = nil;
    }
    [[NSUserDefaults standardUserDefaults] setObject:interval forKey:@"ipadStatusUpdateInterval"];
}

- (NSNumber*)GetWaiterListUpdateInterval
{
    NSNumber* interval = [[NSUserDefaults standardUserDefaults] objectForKey:@"waiterListUpdateInterval"];
    if (interval == nil) {
        return [NSNumber numberWithFloat:10.0f];
    }
    return interval;
}

- (void)SetWaiterListUpdateInterval:(NSNumber*)interval
{
    if ([NSNull isNull:interval]) {
        interval = nil;
    }
    [[NSUserDefaults standardUserDefaults] setObject:interval forKey:@"waiterListUpdateInterval"];
}


- (NSNumber*)GetWaiterSoldoutUpdateInterval;
{
    NSNumber* interval = [[NSUserDefaults standardUserDefaults] objectForKey:@"waiterSoldoutUpdateInterval"];
    if (interval == nil) {
        return [NSNumber numberWithFloat:10.0f];
    }
    return interval;
}

- (void)SetWaiterSoldoutUpdateInterval:(NSNumber*)interval
{
    if ([NSNull isNull:interval]) {
        interval = nil;
    }
    [[NSUserDefaults standardUserDefaults] setObject:interval forKey:@"waiterSoldoutUpdateInterval"];
}

@end

