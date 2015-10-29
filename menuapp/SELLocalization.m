//
//  SELLocalization.m
//  selforder
//
//  Created by dpcc on 2014/09/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELLocalization.h"
#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"

@implementation SELLocalization

+ (NSString *)localizedStringForKey:(NSString *)aKey
{
    SELSettingDataManager* setting = [SELSettingDataManager instance];
    NSInteger menuNumber = [setting GetMenuNumber];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:localization ofType:@"lproj"];
    NSBundle *currentLangBundlePath = [[NSBundle alloc] initWithPath:[bundlePath stringByStandardizingPath]];
    return NSLocalizedStringFromTableInBundle(aKey, nil, currentLangBundlePath, nil);
}

@end
