//
//  NSArray+csvsupport.m
//  SpreadsheetFunction
//

#import "NSArray+csvsupport.h"


@implementation NSArray (csvsupport)

//csvの決まり
//一行目にかならずキーを入れる
//\nで改行されている
//UTF8で記述されていることを前提としている
+ (id)arrayWithCSV:(NSString *)csv {
	NSArray *array = [csv componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	//キー
	NSMutableArray* keys = [NSMutableArray array];
	NSMutableArray* retArray = [NSMutableArray array];
	NSInteger count = 0;
	for (NSString* line in array) {
		//一行目
		if (0 == count) {
			NSArray *tempArray = [line componentsSeparatedByString:@","];
			for (NSString* key in tempArray) {
				[keys addObject:key];
			}
		} else { //二行目以降
			NSArray *tempArray = [line componentsSeparatedByString:@","];
			NSMutableDictionary *dict = [NSMutableDictionary dictionary];
			NSInteger count = 0;
			for (NSString* value in tempArray) {
                if(keys.count > count)
                {
                    //辞書を作る
                    [dict setObject:value forKey:[keys objectAtIndex:count]];
                }
				++count;
			}
			[retArray addObject:dict];
		}
		
		++count;
	}
	return retArray;
}

@end
