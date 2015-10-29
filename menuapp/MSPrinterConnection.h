//
//  MSPrinterConnection.h
//  MenuApp
//
//  Created by dpcc on 13/03/29.
//
//

#import "SELConnectionBase.h"
#import "OrderStarPrinter.h"

@interface MSPrinterConnection : SELConnectionBase<OrderStarPrinterDelegate> {
    // エラー情報
    NSMutableArray * _errInfo;
}

// エラー情報編集
- (NSString *)errInfoToString;

@end
