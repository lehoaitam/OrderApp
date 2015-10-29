//
//  WriteFile.h
//  MenuApp
//
//  Created by  on 12/03/08.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString;

@end

@interface Logger : NSObject

+ (void)WriteLog:(NSData*)data sendrecv:(BOOL)isSend;

// Add Start 2012-03-11 kitada
// 通信制御不具合改修(志様・01CAFE障害対応)
// 電文ログ削除
+ (void)DeleteLog;
// Add End 2012-03-11 kitada

@end

