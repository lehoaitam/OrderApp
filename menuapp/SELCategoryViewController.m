//
//  SELCategoryViewController.m
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELCategoryViewController.h"
#import "SELItemDataManager.h"
#import "SELCategoryCollectionViewCell.h"
#import "SELItemCollectionViewCell.h"
#import "SELItemDetailViewController.h"

@interface SELCategoryViewController ()

@end

@implementation SELCategoryViewController

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    // Return YES for supported orientations
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger nScreenOrientation = [userDefaults integerForKey:@"screenOrientation"];
    
    if (nScreenOrientation == 0) {
        // 縦
        return UIInterfaceOrientationMaskPortrait;
    }
    else {
        // 横
        return UIInterfaceOrientationMaskLandscape;
    }
}

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
    
    if (self.isItemList) {
        
        
    }else
    {
        SELItemDataManager* dm = [SELItemDataManager instance];
        self.CategoryDict = dm.mainCategoryDict;
    }
    
    [self setTitle:[SELLocalization localizedStringForKey:@"CATEGORY_LIST_TITLE"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismiss:(id)sender
{
    // 閉じる
    [self dismissViewControllerAnimated:YES completion:NULL];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toitemdetaillandscape"] ||
        [segue.identifier isEqualToString:@"toitemdetailportrait"]) {
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        SELItemData* itemData = [itemDataManager getItemData:_selectedItemCode];
        
        SELItemDetailViewController* vc = [segue destinationViewController];
        vc.ItemData = itemData;
    }
}

#pragma mark- collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isItemList) {
        return self.itemArray.count;
    }
    else{
        return [self.categoryDict allKeys].count;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isItemList) {
        return CGSizeMake(298, 300);
    }
    else{
        return CGSizeMake(354, 130);
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isItemList) {
        SELItemCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"itemCollectionViewCell" forIndexPath:indexPath];
        SELItemData* data = [self.itemArray objectAtIndex:indexPath.row];
        [cell setItemData:data];
        return cell;
    }
    else {
        SELCategoryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"categoryCollectionViewCell" forIndexPath:indexPath];
        SELCategoryData* data = [self.categoryDict objectForKey:[[self.categoryDict allKeys] objectAtIndex:indexPath.row]];
        [cell setCategoryData:data];
        return cell;
    }
    return NULL;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isItemList) {
        // 商品詳細へ
        SELItemData* itemData = [self.itemArray objectAtIndex:indexPath.row];

        _selectedItemCode = itemData.menuCode;

        // 画面の向きによって遷移先を変える
        switch (self.interfaceOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                [self performSegueWithIdentifier:@"toitemdetaillandscape" sender:self];
                break;
                
            case UIInterfaceOrientationPortrait:
            case UIInterfaceOrientationPortraitUpsideDown:
                [self performSegueWithIdentifier:@"toitemdetailportrait" sender:self];
                break;
                
            default:
                break;
        }
    }
    else{
        // さらにカテゴリ一覧へ
        SELItemDataManager* dm = [SELItemDataManager instance];
        
        SELCategoryData* categoryData = [self.categoryDict objectForKey:[[self.categoryDict allKeys] objectAtIndex:indexPath.row]];
        
        // 属するカテゴリを取得
        
        // 無い場合、属するアイテムを取得
        NSArray* itemArray = [dm getMainCategoryItems:categoryData.code];
        
        // categoryViewにPUSH
        SELCategoryViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"categoryview"];
        [vc setTitle:categoryData.name];
        vc.itemArray = itemArray;
        vc.isItemList = TRUE;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
