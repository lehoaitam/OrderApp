//
//  SELCustomOrderData.m
//  menuapp
//
//  Created by dpcc on 2014/04/14.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELCustomOrderData.h"

#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"

@implementation SELCustomOrderData

// 多言語対応
- (NSString *)message
{
    if (!self.MLMessageList) {
        return _message;
    }
    
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString* message = [self.MLMessageList objectForKey:localization];
    if (!message) {
        return _message;
    }
    
    return message;
}

// valueForKeyではアクセスしていないが、念のため
- (id)valueForKey:(NSString *)key
{
    // Messageの場合
    if ([key isEqualToString:@"message"]) {
        return self.message;
    }
    
    return [super valueForKey:key];
}

@end
