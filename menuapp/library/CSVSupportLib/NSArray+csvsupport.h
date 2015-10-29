//
//  NSArray+csvsupport.h
//

@interface NSArray (csvsupport)
/*
 csvの決まり
 ・一行目にかならずキーを入れる
 ・UTF8で記述されていることを前提としている
 */
+ (id)arrayWithCSV:(NSString *)csv;

@end
