//
//  SELTestCollectionViewCell.m
//  selforder
//
//  Created by dpcc on 2014/06/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELTestCollectionViewCell.h"

@implementation SELTestCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)updateView:(NSURL*)url
{
    [_webView loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f]];
}

@end
