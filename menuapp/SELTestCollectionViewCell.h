//
//  SELTestCollectionViewCell.h
//  selforder
//
//  Created by dpcc on 2014/06/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SELTestCollectionViewCell : UICollectionViewCell {
    IBOutlet UIWebView* _webView;
}

- (void)updateView:(NSURL*)url;

@end
