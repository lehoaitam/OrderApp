//
//  SmaregiUtil.m
//  MenuApp
//
//  Created by dpcc on 12/10/02.
//
//

#import "SmaregiUtil.h"

@implementation SmaregiUtil

+ (NSString*)storePrinterIPAddress {
    
    NSString* printerIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"printerIPAddress"];
    if (printerIP == NULL || [printerIP isEqualToString:@""]) {
        // printer未設定
        return NULL;
    }
    
    //NSString* printerPort = [[MSAdminManager instance] valueForKey:kSettingPrinterPortNoKey];
    return [NSString stringWithFormat:@"TCP:%@", printerIP];
}


@end

@implementation FormatUtil

+ (NSString*)peopleNumbersFormat:(NSNumber*)number{
    NSString* ret = [NSString stringWithFormat:@"%d人", [number intValue]];
    return ret;
}

+ (NSString*)stringDateToStringTime:(NSString*)date{
    return date;
}

+ (NSString*)quantityFormat:(NSNumber*)number{
    NSString* ret = [NSString stringWithFormat:@"%d点", [number intValue]];
    return ret;
}

+ (NSString*)percentFormat:(NSNumber*)number{
    NSString* ret = [NSString stringWithFormat:@"%d", [number intValue]];
    return ret;
}

+ (NSString*)currencyFormat:(NSNumber*)number{
    NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
    [nf setPositiveFormat:@"￥#,##0"];
    NSString *str = [nf stringFromNumber:number];
    return str;
}

+ (NSString*)numberFormat:(NSNumber*)number{
    NSNumberFormatter *nf = [[[NSNumberFormatter alloc] init] autorelease];
    [nf setPositiveFormat:@"#,##0"];
    NSString *str = [nf stringFromNumber:number];
    return str;
}

@end

@implementation NSNumber(Smaregi)

- (BOOL)isZero {
    if(self == NULL) return TRUE;
    if([self intValue] == 0) return TRUE;
    return FALSE;
}

- (BOOL)isNegative {
    if(self == NULL) return FALSE;
    if([self intValue] < 0) return TRUE;
    return FALSE;
}

@end

@implementation NSDate(Smaregi)

- (NSString *)dateTimeFormattedString {
    
    NSString* date_converted;
    // NSDateFormatter を用意します。
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    // 変換用の書式を設定します。
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    // NSDate を NSString に変換します。
    date_converted = [formatter stringFromDate:self];
    return date_converted;
}

@end
