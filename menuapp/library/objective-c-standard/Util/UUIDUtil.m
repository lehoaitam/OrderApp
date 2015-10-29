//
//  UUIDUtil.m
//  objective-c-standard
//
//  Created by dpcc on 2014/04/23.
//  Copyright (c) 2014年 motomitsu. All rights reserved.
//

#import "UUIDUtil.h"

@implementation UUIDUtil

// アプリ内で一意の値を取得する
+ (NSString*) stringWithUUID {
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString* UUID = [ud stringForKey:@"UUID"];
    if (UUID == NULL) {
        CFUUIDRef uuidObj = CFUUIDCreate(nil);//create a new UUID
        //get the string representation of the UUID
        UUID = (__bridge NSString*)CFUUIDCreateString(nil, uuidObj);
        CFRelease(uuidObj);
        
        [ud setObject:UUID forKey:@"UUID"];
    }
    
	return UUID;
}



@end
