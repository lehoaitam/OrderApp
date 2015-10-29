//
//  StarPrinterUtil.m
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/04/26.
//  Copyright (c) 2012 genephics design,Inc. All rights reserved.
//

#import "StarPrinterUtil.h"
//#import "RasterDocument.h"
//#import "StarBitmap.h"
#import "ePOS-Print.h"

@implementation StarPrinterUtil

@synthesize showErrorMessage = _showErrorMessage;
@synthesize enabledPrint = _enabledPrint;
@synthesize ipAddress = _ipAddress;

- (void) dealloc
{
    [_ipAddress release];
    [super dealloc];
}

+ (id) starPrinterUtilWithIpAddress:(NSString*)ipAddress
{
    StarPrinterUtil* printer = [[[StarPrinterUtil alloc] init] autorelease];
    printer.ipAddress = ipAddress;
    printer.enabledPrint = true;
    return printer;
}

- (void) showErrorAlert:(NSString*)message
{
    if (!self.showErrorMessage) return;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"POPUP_TITLE_PRINTER_ERROR", nil) 
                                                    message:message
                                                   delegate:nil 
                                          cancelButtonTitle:NSLocalizedString(@"BUTTON_OK", nil) 
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (StarPrinterPrintStatus) writePort:(NSMutableData *)data ipAddress:(NSString*)portName
{
	if (![self enabledPrint]) return StarPrinterPrintStatusDisabled;
    
	Port * ioPort = [Port getPort:portName :portName :PRINTER_PORT];
    
	// ポートが取得できなかった場合0.5秒後にリトライ
	if (!ioPort)
	{
        [NSThread sleepForTimeInterval:0.5];
		[Port releasePort:ioPort];
		ioPort = [Port getPort:portName :portName :PRINTER_PORT];
	}
	
	// プリンターに接続できない場合
	if (!ioPort)
	{
        [self showErrorAlert:NSLocalizedString(@"POPUP_MESSAGE_ERROR_CONNECT", nil)];
		return StarPrinterPrintStatusConnectError;
	}
	
	StarPrinterPrintStatus printStatus;
	@try 
    {
		StarPrinterStatus_2 status;
		[ioPort beginCheckedBlock: &status: 2];
		
		if (status.offline == SM_TRUE)
		{
			NSString * message = @"";
			if (status.coverOpen == SM_TRUE)
			{
				message = [message stringByAppendingString:NSLocalizedString(@"POPUP_MESSAGE_COVER_OPEN", nil)];
                printStatus = StarPrinterPrintStatusCoverOpen;
			}
			else if (status.receiptPaperEmpty == SM_TRUE)
			{
				message = [message stringByAppendingString:NSLocalizedString(@"POPUP_MESSAGE_RUN_OUT_OF_PAPER", nil)];
                printStatus = StarPrinterPrintStatusRunOutOfPaper;
			}
            else 
            {
                printStatus = StarPrinterPrintStatusError;
            }

            [self showErrorAlert:message];
		}
		else
        {
            int totalAmountWritten = 0;
            
            while (totalAmountWritten < [data length])
            {
                totalAmountWritten += [ioPort writePort:[data mutableBytes] :totalAmountWritten :[data length] - totalAmountWritten];
            }
            printStatus = StarPrinterPrintStatusSuccess;
        }
	}
	@catch (PortException* e) 
    {
        [self showErrorAlert:NSLocalizedString(@"POPUP_MESSAGE_ERROR_CONNECT", nil)];
        printStatus = StarPrinterPrintStatusError;
	}
	@finally 
    {
		[Port releasePort:ioPort];
	}
    
	
	return printStatus;
}

- (StarPrinterPrintStatus) print:(NSMutableData*)data withCut:(BOOL)cut
{
	if (!self.enabledPrint) return true;
    
	if (!data || [data length] == 0) return false;
    
    NSMutableData *printData = [NSMutableData data];
    [printData appendBytes:CMD_SPACE_FOR_KANJI(0, 0) length:sizeof(CMD_SPACE_FOR_KANJI(0, 0))];
    [printData appendData:data];
    [printData appendBytes:CMD_LF length:sizeof(CMD_LF)];
    if (cut) [printData appendBytes:CMD_CUTTER_RUNOVER_FULL length:sizeof(CMD_CUTTER_RUNOVER_FULL)];
    
	return [self writePort:printData ipAddress:self.ipAddress];
}

- (NSData*) dataWithLF:(NSString*)string printAlign:(PrintAlign)align
{
	NSMutableData *data = [NSMutableData data];
    if (!string || [string length] <= 0) return data;
    
    [data appendBytes:CMD_ALIGN(align) length:sizeof(CMD_ALIGN(align))];
    [data appendData:[string dataUsingEncoding:NSShiftJISStringEncoding]];
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
    return data;
}

- (NSData*) dataWithLF:(NSString*)string
{
    return [self dataWithLF:string printAlign:PrintAlignLeft];
}

- (NSData*) dataWithLFAlignRight:(NSString*)string
{
    return [self dataWithLF:string printAlign:PrintAlignRight];
}

- (NSData*) dataWithLFAlignCenter:(NSString*)string
{
    return [self dataWithLF:string printAlign:PrintAlignCenter];
}

- (NSData*) dataWithCaptionAndContent:(NSString*)caption content:(NSString*)content captionLength:(NSInteger)length
{
	NSMutableData *data = [NSMutableData data];
    if (length > 0)
    {
        caption = [StarPrinterUtil stringByPaddingLeftSpace:caption newLength:length];
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(CHARS_PER_LINE - length)];
    }
    else
    {
        length = [caption lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(CHARS_PER_LINE - length)];
    }
    
    [data appendBytes:CMD_ALIGN_LEFT length:sizeof(CMD_ALIGN_LEFT)];
    [data appendData:[caption dataUsingEncoding:NSShiftJISStringEncoding]];
    [data appendData:[content dataUsingEncoding:NSShiftJISStringEncoding]];
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
    return data;
}

- (NSData*) dataWithCaptionAndContent:(NSString*)caption content:(NSString*)content
{
    return [self dataWithCaptionAndContent:caption content:content captionLength:0];
}

- (NSData*) dataWithCaptionAndContent2x:(NSString*)caption content:(NSString*)content
{
    NSInteger charsPerLine = CHARS_PER_LINE/2;
	NSMutableData *data = [NSMutableData data];
    NSInteger lenCaption = [caption lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
    NSInteger lenContent = [content lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
    
    if (lenCaption + lenContent <= charsPerLine)
    {
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(charsPerLine - lenCaption)];
    }
    else 
    {
        NSInteger lenNewContent = charsPerLine - (lenCaption % charsPerLine);
        if (lenNewContent < lenContent) lenNewContent += charsPerLine;
        content = [StarPrinterUtil stringByPaddingLeftSpace:content newLength:(lenNewContent)];
    }
    
	[data appendBytes:CMD_CHARACTER_SIZE_2x length:sizeof(CMD_CHARACTER_SIZE_2x)];
    [data appendBytes:CMD_ALIGN_LEFT length:sizeof(CMD_ALIGN_LEFT)];
    [data appendData:[caption dataUsingEncoding:NSShiftJISStringEncoding]];
    [data appendData:[content dataUsingEncoding:NSShiftJISStringEncoding]];
    [data appendBytes:CMD_LF length:sizeof(CMD_LF)];
	[data appendBytes:CMD_CHARACTER_SIZE_1x length:sizeof(CMD_CHARACTER_SIZE_1x)];
    return data;
}

- (NSData*) dataLine:(NSInteger)shape
{
    NSMutableData* data = [NSMutableData data];
    int size = 0xC0;
    unsigned char line[size];
    memset(line, shape, sizeof(line));
    
    [data appendBytes:CMD_LINE(size) length:sizeof(CMD_LINE(size))];
    [data appendBytes:line length:sizeof(line)];
    return data;
}

- (NSData*) dataOpenDrawer
{
	NSMutableData *openCommand = [NSMutableData data];	
	[openCommand appendBytes:CMD_OPEN_DRAWER length:sizeof(CMD_OPEN_DRAWER)];
	return openCommand;
}

- (NSData*) dataBarcode:(NSString*)barcode barcodeType:(BarcodeType)type barcodeOption:(BarcodeOption)option barcodeMode:(BarcodeMode)mode height:(int)height
{
    NSMutableData* data = [NSMutableData data];
    u_int8_t* cmd = CMD_BARCODE_START(type , option, mode, height);
    [data appendBytes:cmd length:sizeof(cmd)];
    [data appendData:[barcode dataUsingEncoding:NSWindowsCP1252StringEncoding]];
    [data appendBytes:CMD_BARCODE_END length:sizeof(CMD_BARCODE_END)];
    return data;
}

- (NSData*) dataBarcodeCode128:(NSString*)barcode barcodeOption:(BarcodeOption)option barcodeMode:(BarcodeMode)mode height:(int)height
{
    return [self dataBarcode:barcode barcodeType:BarcodeTypeCode128 barcodeOption:option barcodeMode:mode height:height];
}

- (NSData*) dataBarcodeCode128:(NSString*)barcode
{
    return [self dataBarcode:barcode barcodeType:BarcodeTypeCode128 barcodeOption:BarcodeOptionCharsAndLF barcodeMode:BarcodeMode3Dot height:80];
}

//----------------------------------------------------------------------
+ (NSString*) trimString:(NSString*)string lengthOfLimit:(int)length
{
	NSMutableString *trimedString = [NSMutableString string];
	unichar c;
	int lengh = 0;
	for (int i = 0; i < [string length]; i++)
	{
		c = [string characterAtIndex:i];
		lengh += [[NSString stringWithCharacters:&c length:1] lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
		if (lengh > length) return trimedString;
		
		[trimedString appendFormat:@"%C", c];
	}
	
	return trimedString;
}

+ (NSString*) stringByPaddingLeftSpace:(NSString*)string newLength:(NSUInteger)newLength
{
	NSInteger len = [string lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
    if (len <= newLength)
    {
        return [[@"" stringByPaddingToLength:(newLength - len) withString:@" " startingAtIndex:0] stringByAppendingString:string];
    }
    else
    {
        return [[string copy] autorelease];
    }
}

+ (NSString*) concatWithSpace:(NSString*)value1 :(NSString*)value2 :(NSInteger)length
{
	NSInteger len1 = [value1 lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
	NSInteger len2 = [value2 lengthOfBytesUsingEncoding:NSShiftJISStringEncoding];
    if (len1 + len2 >= length)
    {
        return [self trimString:[value1 stringByAppendingString:value2] lengthOfLimit:length];
    }
    else 
    {
        return [value1 stringByAppendingString:[self stringByPaddingLeftSpace:value2 newLength:(length - len1)]];
    }
}

+ (NSData*) createImageCommand:(UIImage*)image maxWidth:(int)maxWidth
{
    /*
    RasterDocument *rasterDoc = [[RasterDocument alloc] initWithDefaults:RasSpeed_Medium endOfPageBehaviour:RasPageEndMode_None endOfDocumentBahaviour:RasPageEndMode_None topMargin:RasTopMargin_Standard pageLength:0 leftMargin:0 rightMargin:0];
    StarBitmap *starbitmap = [[StarBitmap alloc] initWithUIImage:image :maxWidth :false];
    
    NSMutableData *commands = [NSMutableData data];
    NSData *shortcommand = [rasterDoc BeginDocumentCommandData];
    [commands appendData:shortcommand];
    
    shortcommand = [starbitmap getImageDataForPrinting];
    [commands appendData:shortcommand];
    
    shortcommand = [rasterDoc EndDocumentCommandData];
    [commands appendData:shortcommand];
    
    [starbitmap release];
    [rasterDoc release];
    
    return commands;
     */

    NSException *exception = [NSException exceptionWithName: @"Not Impliment Exception"
                                                 reason: @"Not Impliment"
                                               userInfo: nil];
    @throw exception;

}

+ (NSData*) createImageTextCommand:(NSString*)text fontSize:(CGFloat)size
{
    static unsigned int RECEIPT_WIDTH = 576;
    
    UIFont *font = [UIFont systemFontOfSize:size];
    CGSize imageSize = CGSizeMake(RECEIPT_WIDTH, 10000);
    CGSize messuredSize = [text sizeWithFont:font constrainedToSize:imageSize lineBreakMode:UILineBreakModeWordWrap];
    imageSize.height = messuredSize.height;
    
    if (UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef ctr = UIGraphicsGetCurrentContext();
    
    // fill
    UIColor *color = [UIColor whiteColor];
    [color set];
    CGRect rect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    CGContextFillRect(ctr, rect);
    
    // text draw
    color = [UIColor blackColor];
    [color set];    
    rect = CGRectMake((imageSize.width - messuredSize.width) / 2, 0, messuredSize.width, messuredSize.height);
    [text drawInRect:rect withFont:font lineBreakMode:UILineBreakModeWordWrap];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return [self createImageCommand:image maxWidth:RECEIPT_WIDTH];
}

@end
