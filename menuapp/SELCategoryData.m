//
//  SELCategoryData.m
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELCategoryData.h"
#import "SELItemDataManager.h"

#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"

@implementation SELCategoryData

// 多言語対応
- (NSString *)name
{
    if (!self.MLNameList) {
        return _name;
    }
    
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString* name = [self.MLNameList objectForKey:localization];
    if (!name) {
        return _name;
    }
    
    return name;
}

- (NSString *)image
{
    if (!self.MLImageList) {
        return _image;
    }
    
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString* image = [self.MLImageList objectForKey:localization];
    if (!image) {
        return _image;
    }
    
    return image;
}

- (id)valueForKey:(NSString *)key
{
    // itemNameの場合
    if ([key isEqualToString:@"name"]) {
        return self.name;
    }
    
    // descの場合
    if ([key isEqualToString:@"image"]) {
        return self.image;
    }
    
    return [super valueForKey:key];
}

@end
