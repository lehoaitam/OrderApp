//
//  SELTestCollectionViewController.m
//  selforder
//
//  Created by dpcc on 2014/06/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELTestCollectionViewController.h"
#import "SELTestCollectionViewCell.h"

#import "SELMenuDataManager.h"

@interface SELTestCollectionViewController ()

@end

@implementation SELTestCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    return [menuDataManager.MenuPages count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // セルオブジェクトを得る
    SELTestCollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:@"CellId" forIndexPath:indexPath];
    // 指定位置のオブジェクトを得る
    // セルオブジェクトのプロパティを設定する
//    [cell.titleLabel setText:[_items objectAtIndex:indexPath.row]];
    
    SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
    NSURL* url = [menuDataManager.MenuPages objectAtIndex:indexPath.row];
    [cell updateView:url];
    
    return cell;
}

- (void)toPage:(id)sender
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:3 inSection:0];
    [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

@end
