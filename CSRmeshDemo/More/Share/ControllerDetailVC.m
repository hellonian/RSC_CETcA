//
//  ControllerDetailVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/16.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "ControllerDetailVC.h"
#import "CSRmeshStyleKit.h"

#import "CSRParseAndLoad.h"
#import "CSRUtilities.h"
#import "CSRPlaceEntity.h"
#import "ZipArchive.h"
#import <CSRmesh/MeshServiceApi.h>
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"

@interface ControllerDetailVC ()<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@end

@implementation ControllerDetailVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _controllerDetailsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _controllerDetailsTableView.delegate = self;
    _controllerDetailsTableView.dataSource = self;
    _controllerDetailsTableView.rowHeight = 80.0f;
    _controllerNameTF.text = _controllerEntity.controllerName;
    _controllerNameTF.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _controllerImageView.image = [CSRmeshStyleKit imageOfControllerDevice];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        return @"General Information";
    }  else if (section == 1) {
        return @"Updates";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"controllerDetailTableCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"controllerDetailTableCell"];
        cell.detailTextLabel.numberOfLines = 0;
    }
    if (indexPath.section == 0) {
        cell.textLabel.text = @"UUID/ADDRESS";
        cell.detailTextLabel.text = [[CBUUID UUIDWithData:_controllerEntity.uuid ] UUIDString];
    }else if (indexPath.section == 1) {
        
        cell.textLabel.text = @"Updated";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"This configuration has been updated on %@", _controllerEntity.updateDate];
        
        //Create import for cell
        UIButton *importButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 50, 50)];
        [importButton setBackgroundImage:[CSRmeshStyleKit imageOfIconExport] forState:UIControlStateNormal];
        [importButton addTarget:self action:(@selector(importButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
        importButton.tag = indexPath.row;
        cell.accessoryView = importButton;
        
    }
    
    return cell;
}

- (void)importButtonTapped:(UIButton*)sender {
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    NSError *error;
    NSString *jsonString;
    if (jsonData) {
        jsonString = [CSRUtilities stringFromData:jsonData];
    } else {
        NSLog(@"Got an error while NSJSONSerialization:%@", error);
    }
    
    CSRPlaceEntity *placeEntity = [[CSRAppStateManager sharedInstance] selectedPlace];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* dPath = [paths objectAtIndex:0];
    NSString* zipfile = [dPath stringByAppendingPathComponent:@"AcTEC.zip"] ;
    
    NSString *appFile = [NSString stringWithFormat:@"%@_%@", placeEntity.name, @"Database.qti"];
    NSString *realPath = [dPath stringByAppendingPathComponent:appFile] ;
    [jsonString writeToFile:realPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    if([zip CreateZipFile2:zipfile Password:[[MeshServiceApi sharedInstance] getMeshId]])
    {
        NSLog(@"Zip File Created");
        if([zip addFileToZip:realPath newname:@"MyFile.qti"])
        {
            NSLog(@"File Added to zip");
        }
    }
    
    NSURL *jsonURL = [NSURL fileURLWithPath:zipfile];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[jsonURL] applicationActivities:nil];
    [activityVC setValue:@"JSON Attached" forKey:@"subject"];
    
    activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (completed) {
            NSLog(@"Activity completed");
        } else {
            if (activityType == NULL) {
                NSLog(@"User dismissed the view controller without making a selection");
            } else {
                NSLog(@"Activity was not performed");
            }
        }
    };
    [self presentViewController:activityVC animated:YES completion:nil];
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        UIPopoverPresentationController *activity = [activityVC popoverPresentationController];
        activity.sourceRect = CGRectMake(10, 10, 200, 100);
        activity.sourceView = (UIButton *)sender;
    }
    
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.backgroundColor = [UIColor lightGrayColor];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    textField.backgroundColor = [UIColor clearColor];
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)deleteController:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Controller" message:[NSString stringWithFormat:@"Are you sure, you want to delete %@", _controllerEntity.controllerName] preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:@"Delete Controller"];
    [attributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:60/255.0 green:60/255.0 blue:60/255.0 alpha:1] range:NSMakeRange(0, [[attributedTitle string] length])];
    [alertController setValue:attributedTitle forKey:@"attributedTitle"];
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Are you sure, you want to delete %@", _controllerEntity.controllerName]];
    [attributedMessage addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:80/255.0 green:80/255.0 blue:80/255.0 alpha:1] range:NSMakeRange(0, [[attributedMessage string] length])];
    [alertController setValue:attributedMessage forKey:@"attributedMessage"];
    [alertController.view setTintColor:DARKORAGE];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [[CSRAppStateManager sharedInstance].selectedPlace removeControllersObject:_controllerEntity];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_controllerEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];
        [self.navigationController popViewControllerAnimated:YES];
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
