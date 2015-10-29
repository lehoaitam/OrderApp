//
//  NSDictionary+JSON.m
//  objective-c-standard
//
//  Created by dpcc on 2014/09/29.
//  Copyright (c) 2014年 motomitsu. All rights reserved.
//

#import "NSDictionary+JSON.h"

@implementation NSDictionary (JSON)

- (NSString*)toJSONString
{
    NSError* error;
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:self
                                    options:kNilOptions error:&error];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSData*)toJSONData
{
    NSError* error;
    NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:self
                                    options:kNilOptions error:&error];
    
    return jsonData;
}

@end
