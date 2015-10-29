//
//  SELTestCollectionViewController.h
//  selforder
//
//  Created by dpcc on 2014/06/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SELTestCollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate> {
    IBOutlet UICollectionView* _collectionView;
}

- (IBAction)toPage:(id)sender;

@end
