//
//  SELLocalSettingViewController.m
//  menuapp
//
//  Created by dpcc on 2014/04/22.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELLocalSettingViewController.h"
#import "SELMenuDataManager.h"
#import "SELSettingDataManager.h"

#import "UIAlertView+Blocks.h"
#import "RIButtonItem.h"
#import "SVProgressHUD.h"

#import "SELItemDataManager.h"

@interface SELLocalSettingViewController ()

@end

@implementation SELLocalSettingViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // データ更新 notification
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateMenuSuccess:) name:SELUpdateMenuSuccessNotification object:nil];
//    [notificationCenter addObserver:self selector:@selector(updateMenuError:) name:SELUpdateMenuErrorNotification object:nil];
//    [notificationCenter addObserver:self selector:@selector(updateMenuStatus:) name:SELUpdateMenuStatusNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"テーブル設定";
            break;
            
        case 1:
            return @"メニュー選択";
            break;
            
        case 2:
            return @"プリンターグループ選択";
            break;
            
        case 3:
            return @"データ更新";
            break;
            
        default:
            break;
    }
    return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"このiPadから注文する際のテーブル名称を設定してください。";
            break;
            
        case 1:
            return @"使用するメニューを選択してください。";
            break;
            
        case 2:
            return @"使用するプリンターグループを選択してください。";
            break;
            
        case 3:
            return @"管理画面で入力したデータをiPadに取り込みます。";
            break;
            
        default:
            break;
    }
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
        {
            // 席番号設定
            return 1;
        }
        case 1:
        {
            // メニュー選択
            SELMenuDataManager* dataManager = [SELMenuDataManager instance];
            NSArray* menus = [dataManager GetMenus];
            return menus.count;
        }
        case 2:
        {
            // プリンターグループ選択
            SELItemDataManager* dataManager = [SELItemDataManager instance];
            return dataManager.printerGroupList.count;
        }
        case 3:
        {
            // メニュー更新
            return 1;
        }
            break;
            
        default:
            break;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tablenamesetcell" forIndexPath:indexPath];
            [cell.textLabel setText:@"テーブル名"];
            
            SELSettingDataManager* dataManager = [SELSettingDataManager instance];
            [cell.detailTextLabel setText:[dataManager GetTableName]];
            
            return cell;
        }
        case 1:
        {
            NSInteger menuNumber = indexPath.row + 1;
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menuselectcell" forIndexPath:indexPath];
            
            NSString* menuName = [[SELMenuDataManager instance]GetMenuName:menuNumber];
            [cell.textLabel setText:menuName];
            
            SELSettingDataManager* settingManager = [SELSettingDataManager instance];
            if ([settingManager GetMenuNumber] == menuNumber) {
                //
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                //
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        }
        case 2:
        {
            // プリンターグループ選択
            SELItemDataManager* dataManager = [SELItemDataManager instance];
            
            NSDictionary* printerGroup = [dataManager.printerGroupList objectAtIndex:indexPath.row];
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"menuselectcell" forIndexPath:indexPath];
            
            NSString* printerGroupName = [printerGroup objectForKey:@"printerGroupName"];
            [cell.textLabel setText:printerGroupName];
            
            SELSettingDataManager* settingManager = [SELSettingDataManager instance];
//            NSString* printerGroupKey = [settingManager GetPrinterGroupKey];
            NSString* printerGroupKey = [settingManager GetPrinterGroupKey];
            if ([printerGroupKey isEqualToString:[printerGroup objectForKey:@"id"]]) {
//            if ([printerGroupKey isEqualToString:[printerGroup objectForKey:@"id"]]) {
                //
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                //
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        }
        case 3:
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dataupdatecell" forIndexPath:indexPath];
            
            //
            NSString* last = [[SELSettingDataManager instance] GetMenuDataLastModified];
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"最終更新日:%@", last]];
            return cell;
        }
        default:
            break;
    }
    return NULL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            // テーブル名
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"テーブル名" message:@"テーブル名を入力してください。" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
            return;
        }
        case 1:
        {
            // メニュー選択
            NSInteger menuNumber = indexPath.row + 1;

            SELSettingDataManager* settingManager = [SELSettingDataManager instance];
            [settingManager SetMenuNumber:menuNumber];

            // メニュー切替
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
            [notificationCenter postNotificationName:SELMenuChangeNotification object:nil];
            
            // table更新
            [self.tableView reloadData];
            
            return;
        }
        case 2:
        {
            SELItemDataManager* dataManager = [SELItemDataManager instance];
            NSDictionary* printerGroup = [dataManager.printerGroupList objectAtIndex:indexPath.row];
            NSString* key = [printerGroup objectForKey:@"id"];

            SELSettingDataManager* settingManager = [SELSettingDataManager instance];
            [settingManager SetPrinterGroupKey:key];
            
            // table更新
            [self.tableView reloadData];
            
            return;
        }
        case 3:
        {
            // メニュー更新
            [[[UIAlertView alloc] initWithTitle:@"データ更新"
                                        message:@"商品データ、メニューデータ更新を行います。よろしいですか？"
                               cancelButtonItem:[RIButtonItem itemWithLabel:@"キャンセル" action:^{
                // cancel
                
            }]
                               otherButtonItems:[RIButtonItem itemWithLabel:@"はい" action:^{
                // yes
                SELMenuDataManager* menuDataManager = [SELMenuDataManager instance];
                [menuDataManager Update];
                
            }], nil] show];
            return;
        }
        default:
            break;
    }
    return;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* tableName = [[alertView textFieldAtIndex:0] text];
    
    SELSettingDataManager* dataManager = [SELSettingDataManager instance];
    [dataManager SetTableName:tableName];
    
    [self.tableView reloadData];
    
    // 設定切り替えのため、リロード呼出
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:SELUISettingChangeNotification object:nil];
}

#pragma mark - notification

- (void)updateMenuSuccess:(NSNotification *)notification
{
//    [SVProgressHUD showSuccessWithStatus:@"正常終了しました"];
    
    [self.tableView reloadData];
}

/*
- (void)updateMenuError:(NSNotification *)notification
{
    if ([notification isKindOfClass:[NSNotification class]]) {
        NSString* error = (NSString*)[notification object];
        [SVProgressHUD showErrorWithStatus:error];
    }
    else {
        [SVProgressHUD showErrorWithStatus:@"異常終了しました"];
    }
}

- (void)updateMenuStatus:(NSNotification *)notification
{
    NSDictionary* dict = (NSDictionary*)[notification object];
    NSNumber* progress = [dict objectForKey:@"progress"];
    CGFloat progressF = [progress floatValue];
    NSString* status = [dict objectForKey:@"status"];
    
    [SVProgressHUD showProgress:progressF status:status];
}
*/

@end
