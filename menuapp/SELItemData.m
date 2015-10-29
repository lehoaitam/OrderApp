//
//  SELItemData.m
//  menuapp
//
//  Created by dpcc on 2014/04/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELItemData.h"
#import "SELCategoryData.h"
#import "SELItemDataManager.h"

#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"

@implementation SELItemData

- (NSString *)customOrderDataNo
{
    // customOrderDataはSCP1~12に入っているので、
    // 0以外であればそれを返す
    for (int i=1; i <= 12; i++) {
        NSString* key = [NSString stringWithFormat:@"SCP%d", i];
        NSString* value = [self valueForKey:key];
        
        if (   value != nil &&
            ![ value isEqualToString:@"0"] &&
            ![ value isEqualToString:@""]) {
            return value;
        }

    }
    return @"0";
}

- (UIImage *)getItemImage
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* imageDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/image"];
    NSString* imagePath = [imageDir stringByAppendingPathComponent:_image];
    UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
    if (!image) {
        // イメージが無い場合はカテゴリ画像をセットする
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        SELCategoryData* category = [itemDataManager getMainCategoryData:self.category1_code];
        imagePath = [imageDir stringByAppendingPathComponent:category.image];
        image = [UIImage imageWithContentsOfFile:imagePath];
        if (!image) {
            // さらにイメージが無い場合はnoimageをセットする
            image = [UIImage imageNamed:@"noimage.jpg"];
        }
    }
    return image;
}

// 多言語対応
- (NSString *)itemName
{
    if (!self.MLItemNameList) {
        return _itemName;
    }
    
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString* itemName = [self.MLItemNameList objectForKey:localization];
    if (!itemName) {
        return _itemName;
    }
    
    return itemName;
}

- (NSString *)itemNameJA
{
    return _itemName;
}

- (NSString *)desc
{
    if (!self.MLDescList) {
        return _desc;
    }
    
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString* desc = [self.MLDescList objectForKey:localization];
    if (!desc) {
        return _desc;
    }
    
    return desc;
}

- (id)valueForKey:(NSString *)key
{
    // itemNameの場合
    if ([key isEqualToString:@"itemName"]) {
        return self.itemName;
    }
    
    // descの場合
    if ([key isEqualToString:@"desc"]) {
        return self.desc;
    }
    
    return [super valueForKey:key];
}

@end
