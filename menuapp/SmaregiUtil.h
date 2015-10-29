//
//  SmaregiUtil.h
//  MenuApp
//
//  Created by dpcc on 12/10/02.
//
//

#import <Foundation/Foundation.h>

#define ORDERHEADER_STATUS_VACANCY @"0"
#define ORDERHEADER_STATUS_INPROCESS @"1"
#define ORDERHEADER_STATUS_CHECKOUT @"3"
#define ORDERHEADER_STATUS_CANCELED @"9"

#define ORDERDETAIL_STATUS_ORDERED @"0"
#define ORDERDETAIL_STATUS_CATERED @"1"
#define ORDERDETAIL_STATUS_CANCELED @"9"

#define DISCOUNT_DIVISION_NONE @"0"
#define DISCOUNT_DIVISION_PRICE @"1"
#define DISCOUNT_DIVISION_RATE @"2"
#define DISCOUNT_DIVISION_PRICE_COUPON @"3"
#define DISCOUNT_DIVISION_RATE_COUPON @"4"
#define DISCOUNT_DIVISION_FREE_COUPON @"5"

#define SYNCHRONIZED_OK @"0"
#define SYNCHRONIZED_NO @"1"

#define ITEM_DIVISION_ITEM @"0"
#define ITEM_DIVISION_PLAN @"1"
#define ITEM_DIVISION_PLAN_ITEM @"2"

@interface SmaregiUtil : NSObject

+ (NSString*)storePrinterIPAddress;

@end

@interface FormatUtil : NSObject

+ (NSString*)peopleNumbersFormat:(NSNumber*)number;
+ (NSString*)stringDateToStringTime:(NSString*)date;
+ (NSString*)quantityFormat:(NSNumber*)number;
+ (NSString*)percentFormat:(NSNumber*)number;
+ (NSString*)currencyFormat:(NSNumber*)number;
+ (NSString*)numberFormat:(NSNumber*)number;

@end

@interface NSNumber(Smaregi)

- (BOOL)isZero;
- (BOOL)isNegative;

@end

@interface NSDate(Smaregi)

- (NSString*)dateTimeFormattedString;

@end
