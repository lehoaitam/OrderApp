//
//  PrintData.m
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/06/12.
//  Copyright (c) 2012年 genephics design,Inc. All rights reserved.
//

#import "PrintData.h"

@implementation PrintData
@synthesize printer = _printer;
@synthesize data = _data;
@synthesize status = _status;
@synthesize abort = _abort;
@synthesize isDone;

- (void) dealloc
{
    [_printer release];
    [_data release];
    [super dealloc];
}
- (BOOL) isDone
{
    if (self.abort) return true;
    return (self.status == StarPrinterPrintStatusSuccess || self.status == StarPrinterPrintStatusDisabled);
}
- (id) initWithData:(NSMutableData*)data printer:(Printer*)printer
{
    self = [super init];
    self.data  = data;
    self.printer = printer;
    self.abort = false;
    return self;
}
@end
