//
//  NSNull+isNull.m
//  objective-c-standard
//
//  Created by dpcc on 2014/11/17.
//  Copyright (c) 2014年 motomitsu. All rights reserved.
//

#import "NSNull+isNull.h"

@implementation NSNull (isNull)
+(BOOL)isNull:(id)obj {
    return obj == nil || [[NSNull null] isEqual:obj];
}
@end
