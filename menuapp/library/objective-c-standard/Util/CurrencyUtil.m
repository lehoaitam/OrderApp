//
//  CurrencyUtil.m
//  objective-c-standard
//
//  Created by dpcc on 2014/04/15.
//  Copyright (c) 2014年 motomitsu. All rights reserved.
//

#import "CurrencyUtil.h"

@implementation CurrencyUtil

+ (NSString *)numberToCurrency:(NSNumber *)price
{
    NSNumberFormatter* nf = [[NSNumberFormatter alloc]init];
    [nf setNumberStyle:NSNumberFormatterCurrencyStyle];
//    [nf setCurrencyCode:@"JPY"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"];
    [nf setLocale:locale];
    
    NSString *strPrice = [nf stringFromNumber:price];
    
    return strPrice;
}

+ (NSString *)integerToCurrency:(NSInteger)price
{
    NSNumber *priceNumber = [[NSNumber alloc] initWithInteger:price];
    return [CurrencyUtil numberToCurrency:priceNumber];
}

+ (NSString *)stringToCurrency:(NSString *)price
{
    NSInteger priceInteger = [price integerValue];
    return [CurrencyUtil integerToCurrency:priceInteger];
}

+ (NSString *)numberSeparate:(NSNumber *)price
{
    // まずはNSNumberに変換
//    NSNumber *priceNumber = [[NSNumber alloc] initWithInteger:price];
    
    // 数値を3桁ごとカンマ区切りにするように設定
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setGroupingSeparator:@","];
    [formatter setGroupingSize:3];
    
    // 数値を3桁ごとカンマ区切り形式で文字列に変換する
    NSString *result = [formatter stringFromNumber:price];
    
    return result;
}

+ (NSString *)stringSeparate:(NSString *)price
{
    NSInteger priceInteger = [price integerValue];
    return [CurrencyUtil integerSeparate:priceInteger];
}

+ (NSString *)integerSeparate:(NSInteger)price
{
    NSNumber *priceNumber = [[NSNumber alloc] initWithInteger:price];
    return [CurrencyUtil numberSeparate:priceNumber];
}


@end
