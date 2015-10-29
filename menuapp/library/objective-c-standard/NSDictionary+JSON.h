//
//  NSDictionary+JSON.h
//  objective-c-standard
//
//  Created by dpcc on 2014/09/29.
//  Copyright (c) 2014年 motomitsu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (JSON)

- (NSString*)toJSONString;
- (NSData*)toJSONData;

@end
