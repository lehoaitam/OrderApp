//
//  SELConnectionBase.m
//  menuapp
//
//  Created by dpcc on 2014/05/01.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELConnectionBase.h"
#import "MSSmaRegiConnection.h"
#import "MSDemoConnection.h"
#import "MSPrinterConnection.h"
#import "MSTecConnection.h"

@implementation SELConnectionBase

static SELConnectionBase* _instance = nil;

+ (id)instance
{
    @synchronized(self) {
        if (!_instance) {
            // 設定によって作成するinstanceを変える
            NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
            id linkSystem = [userDefaults objectForKey:@"linkSystem"];
            
            switch ([linkSystem intValue]) {
                case 0:
                    // プリンタ連携
                    _instance = [[MSPrinterConnection alloc] init];
                    break;
                case 1:
                    // TECレジ連携
                    _instance = [[MSTecConnection alloc] init];
                    break;
                case 2:
                    // スマレジ連携
                    _instance = [[MSSmaRegiConnection alloc] init];
                    break;
                case 9:
                    // デモ版
                    _instance = [[MSDemoConnection alloc] init];
                    break;
                default:
                    _instance = [[self alloc] init];
                    break;
            }
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

- (void)terminate{
    _instance = nil;
}

- (void)orderConfirm:(NSArray *)orderList
{
}

- (void)getOrderedList
{
}

- (void)callStaff
{
}

- (void)getCustomerInfo
{
}

- (NSString*)createOrderDetailNo{
    // 注文番号を作成する
    CFUUIDRef uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString* UUID = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    
    // 前1-4桁 - 前5-8桁目
    NSString* orderDetailNo = [NSString stringWithFormat:@"%@-%@",
                               [UUID substringWithRange:NSMakeRange(0, 4)],
                               [UUID substringWithRange:NSMakeRange(4, 4)] ];
    
    return orderDetailNo;
}

@end
