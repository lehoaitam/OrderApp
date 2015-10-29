//
//  SELToppingViewController.m
//  menuapp
//
//  Created by dpcc on 2014/05/26.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELToppingViewController.h"
#import "CurrencyUtil.h"

@interface SELToppingViewController ()

@end

@implementation SELToppingViewController

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
    
    if (!self.selectedToppingDataList) {
        self.selectedToppingDataList = [[NSMutableArray alloc]init];
    }
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.toppingGroupData.itemlist count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"toppingcell" forIndexPath:indexPath];
    
    // Configure the cell...
    SELItemData* itemData = [self.toppingGroupData.itemlist objectAtIndex:indexPath.row];
    [cell.textLabel setText:[itemData valueForKey:@"itemName"]];
    
    NSString* price = [NSString stringWithFormat:@"+%@円", [CurrencyUtil stringSeparate:[itemData valueForKey:@"price"]]];
    [cell.detailTextLabel setText:price];
    
    if ([self isSelectedItem:itemData]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // 選択されたItemを選択リストに追加する
    SELItemData* itemData = [self.toppingGroupData.itemlist objectAtIndex:indexPath.row];
    if ([self isSelectedItem:itemData]) {
        [self.selectedToppingDataList removeObject:itemData];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        [self.selectedToppingDataList addObject:itemData];
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [self.delegate SelectedTopping:self.selectedToppingDataList sender:self];
    
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
}

- (BOOL)isSelectedItem: (SELItemData*)targetItemdata
{
    for (SELItemData* itemData in self.selectedToppingDataList) {
        if ([itemData.menuCode isEqualToString:targetItemdata.menuCode]) {
            return TRUE;
        }
    }
    return FALSE;
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

@end
