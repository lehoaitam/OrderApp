//
//  CurrencyUtil.h
//  objective-c-standard
//
//  Created by dpcc on 2014/04/15.
//  Copyright (c) 2014年 motomitsu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CurrencyUtil : NSObject

+ (NSString*)stringToCurrency:(NSString*)price;
+ (NSString*)numberToCurrency:(NSNumber*)price;
+ (NSString*)integerToCurrency:(NSInteger)price;

+ (NSString*)numberSeparate:(NSNumber*)price;
+ (NSString*)stringSeparate:(NSNumber*)price;
+ (NSString*)integerSeparate:(NSInteger)price;

@end
