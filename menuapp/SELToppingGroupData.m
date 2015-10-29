//
//  SELToppingGroupData.m
//  menuapp
//
//  Created by dpcc on 2014/05/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELToppingGroupData.h"

#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"

@implementation SELToppingGroupData

- (id) init {
    if (self = [super init]) {
        self.itemlist = [[NSMutableArray alloc]init];
    }
    return self;
}

// 多言語対応
- (NSString *)itemToppingGroupName
{
    if (!self.MLGroupNameList) {
        return _itemToppingGroupName;
    }
    
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString* groupName = [self.MLGroupNameList objectForKey:localization];
    if (!groupName) {
        return _itemToppingGroupName;
    }
    
    return groupName;
}

// valueForKeyではアクセスしていないが、念のため
- (id)valueForKey:(NSString *)key
{
    // Messageの場合
    if ([key isEqualToString:@"itemToppingGroupName"]) {
        return self.itemToppingGroupName;
    }
    
    return [super valueForKey:key];
}

@end
