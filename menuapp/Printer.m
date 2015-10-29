//
//  Printer.m
//  MobilePOS
//
//  Created by Ryutaro Minato on 11/07/21.
//  Copyright 2011 genephics design,Inc. All rights reserved.
//

#import "Printer.h"


@implementation Printer

@synthesize printerId = _printerId;
@synthesize printerName = _printerName;
@synthesize ipAddress = _ipAddress;
@synthesize storeId = _storeId;
@synthesize sort = _sort;
@synthesize header = _header;
@synthesize footer = _footer;
@synthesize airPrintLogo = _airPrintLogo;
@synthesize airPrintCss = _airPrintCss;

@synthesize printerNameIpAddressLabel;

- (void) dealloc
{
    [_printerId release];
    [_printerName release];
    [_ipAddress release];
    [_storeId release];
    [_sort release];
    [_header release];
    [_footer release];
    [_airPrintLogo release];
    [_airPrintCss release];
    [super dealloc];
}

- (NSString*) printerNameIpAddressLabel
{
    return [NSString stringWithFormat:@"%@ (%@)", self.printerName, self.ipAddress];
}

@end
