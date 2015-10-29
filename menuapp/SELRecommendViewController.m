//
//  SELRecommendViewController.m
//  selforder
//
//  Created by dpcc on 2015/06/15.
//  Copyright (c) 2015年 kdl. All rights reserved.
//

#import "SELRecommendViewController.h"
#import "SELRecommendTableViewCell.h"
#import "SELItemDataManager.h"
#import "CurrencyUtil.h"
#import "SELItemDetailViewController.h"

#import "SELSettingDataManager.h"
#import "SELMenuDataManager.h"

@implementation RecommendItem
@end

@interface SELRecommendViewController ()

@end

@implementation SELRecommendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // おすすめ商品数を取得する
    _recommendationItems = [[NSArray alloc]init];
    
    NSDictionary* itemstatuses = [[NSUserDefaults standardUserDefaults] objectForKey:@"itemstatus"];
    if (itemstatuses) {
        NSMutableArray* workArray = [[NSMutableArray alloc]init];
        for (NSString* itemCode in [itemstatuses allKeys]) {
            NSDictionary* itemStatus = [itemstatuses objectForKey:itemCode];
            NSNumber* reccommendation = [itemStatus objectForKey:@"recommendation"];
            if (!reccommendation) {
                // お気に入りではない
                continue;
            }
            if ([reccommendation boolValue]) {
                RecommendItem* recommendItem = [[RecommendItem alloc]init];
                recommendItem.itemCode = itemCode;
                recommendItem.sortKey = [itemStatus objectForKey:@"recommendation_order"];
                // おすすめ商品コードを覚えておく
                [workArray addObject:recommendItem];
            }
        }
        // _recommendationItemCodesをsortkey順にする
        _recommendationItems = [workArray sortedArrayUsingComparator:^NSComparisonResult(RecommendItem* obj1, RecommendItem* obj2) {
            return [obj1.sortKey compare:obj2.sortKey];
        }];
        
        NSLog(@"%@", [_recommendationItems description]);
    }
    
    // おすすめメニュータイトル
    NSDictionary* itemstatus_otherdata = [[NSUserDefaults standardUserDefaults] objectForKey:@"itemstatus_otherdata"];
    if (itemstatus_otherdata) {
        NSString* recommendation_title;
        
        SELSettingDataManager* setting = [SELSettingDataManager instance];
        NSInteger menuNumber = [setting GetMenuNumber];
        SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
        NSString* localization = [menuDataManager GetMenuLocalization:menuNumber];
        
        NSDictionary* MLRecommendationTitleList = [itemstatus_otherdata objectForKey:@"recommendation_title_multilang"];
        if ([localization isEqualToString:@"ja"]) {
            // 日本語タイトルを使用する
            recommendation_title = [itemstatus_otherdata objectForKey:@"recommendation_title"];
        }
        else {
            // 多言語設定
            recommendation_title = [MLRecommendationTitleList objectForKey:localization];
            if (!recommendation_title) {
                // その言語のタイトルが未設定の場合、日本語を使う
                recommendation_title = [itemstatus_otherdata objectForKey:@"recommendation_title"];
            }
        }
        
        if (recommendation_title && ![recommendation_title isEqualToString:@""]) {
            [_titleLabel setText:recommendation_title];
        }
        else {
            // 空文字を設定するとタイトルバーそのものが消えてしまうので、空白文字を設定する
            [_titleLabel setText:@" "];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
     [_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)dismiss:(id)sender
{
    // 閉じる
    [self dismissViewControllerAnimated:YES completion:nil];
}

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_recommendationItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SELRecommendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reccommendcell" forIndexPath:indexPath];
    
    // Configure the cell...
    RecommendItem* recommendItem = [_recommendationItems objectAtIndex:indexPath.row];
    NSString* itemCode = recommendItem.itemCode;
    
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    SELItemData* itemData = [itemDataManager getItemData:itemCode];
    
    // 商品情報
    [cell.name setText:[itemData valueForKey:@"itemName"]];
    [cell.price setText:[NSString stringWithFormat:@"%@", [CurrencyUtil stringToCurrency:[itemData valueForKey:@"price"] ]]];
    
    // 商品画像
    UIImage* itemImage = [itemData getItemImage];
    [cell.image setImage:itemImage];
    
    // 商品詳細
    [cell.comment setText:[itemData valueForKey:@"desc"]];
    [cell.comment sizeToFit];
    
    return cell;
}

/*
 -(CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath {
 return 120;
 }
 */

/*
 - (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
 {
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 商品詳細へ
    RecommendItem* recommendItem = [_recommendationItems objectAtIndex:indexPath.row];
    NSString* itemCode = recommendItem.itemCode;
    
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    SELItemData* itemData = [itemDataManager getItemData:itemCode];
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

@end
