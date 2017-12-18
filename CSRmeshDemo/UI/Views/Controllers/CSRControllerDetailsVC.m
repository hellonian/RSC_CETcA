//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRControllerDetailsVC.h"
#import "CSRDatabaseManager.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRmeshStyleKit.h"
#import "CSRShareDatabaseVC.h"
#import "CSRGatewayEntity.h"
#import "CSRConstants.h"
#import <CSRmesh/CSRMeshUserManager.h>

@interface CSRControllerDetailsVC () {

    CSRGatewayEntity *currentGateway;

}
@end

@implementation CSRControllerDetailsVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _controllerImageView.image = [CSRmeshStyleKit imageOfControllerDevice];
    [self.navigationController.navigationBar setBarTintColor:[CSRUtilities colorFromHex:@"#8E95D2"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _controllerDetailsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    _controllerNameTF.text = _controllerEntity.controllerName;
    
    if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0) {
        currentGateway = (CSRGatewayEntity *)[[CSRAppStateManager sharedInstance].selectedPlace.gateways anyObject];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (currentGateway) {
        return 3;
    } else {
        return 2;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (currentGateway) {
        if (section == 0 || section == 1 || section == 2) {
            return 1;
        }
    } else {
        if (section == 0 || section == 1) {
            return 1;
        }
        
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        return @"General Information";
    } else if (section == 2) {
        return @"Gateway Status";
    } else if (section == 1) {
        return @"Updates";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"controllerDetailTableCell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"controllerDetailTableCell"];
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = @"UUID/ADDRESS";
        cell.detailTextLabel.text = [[CBUUID UUIDWithData:_controllerEntity.uuid ] UUIDString];
        
        
    } else if (indexPath.section == 1) {
        
        cell.textLabel.text = @"Updated";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"This configuration has been updated on %@", _controllerEntity.updateDate];
        
        //Create import for cell
        UIButton *importButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 50, 50)];
        [importButton setBackgroundImage:[CSRmeshStyleKit imageOfIconExport] forState:UIControlStateNormal];
        [importButton addTarget:self action:(@selector(importButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
        importButton.tag = indexPath.row;
        cell.accessoryView = importButton;
        
    } else if (indexPath.section == 2) {
        
        UIButton *gatewayButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 100, 30)];
        [gatewayButton setBackgroundColor:[UIColor grayColor]];
        [gatewayButton addTarget:self action:(@selector(gatewayToggle:)) forControlEvents:UIControlEventTouchUpInside];
        gatewayButton.tag = indexPath.row;
        cell.accessoryView = gatewayButton;
        
        if (currentGateway.state) {
            cell.textLabel.text = @"Enabled";
            cell.detailTextLabel.text = @"";
            [gatewayButton setTitle:@"Disable" forState:UIControlStateNormal];
        } else {
            cell.textLabel.text = @"Disabled";
            cell.detailTextLabel.text = @"";
            [gatewayButton setTitle:@"Enable" forState:UIControlStateNormal];
        }
    }
    return cell;
}

#pragma mark - Navigation

- (void)importButtonTapped:(UIButton*)sender
{
//    UIButton *accessoryButton = (UIButton *)sender;
//    selectedIndex = accessoryButton.tag;
    [self performSegueWithIdentifier:@"databaseSharingSegue" sender:sender];
}

- (void)gatewayToggle:(UIButton*)sender
{
    if ([[sender currentTitle] isEqualToString:@"Disable"]) {
        [sender setTitle:@"Enable" forState:UIControlStateNormal];
        
        
        [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway
                                                           withMode:CSRMeshRestMode_Config];

        __block NSString *cloudTenantID;
        [[CSRMeshUserManager sharedInstance] createTenant:kAppCode
                                                 username:@"tenant_123"
                                                  success:^(CSRMeshTenant *tenant) {
                                                      cloudTenantID = tenant.tenantId;
                                                      
                                                  }
                                                  failure:^(NSError *error) {
                                                      NSLog(@"Error while creating tenant at gateway: %@", error);
                                                  }];
        
        [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud
                                                           withMode:CSRMeshRestMode_Config];
        
        [[CSRMeshUserManager sharedInstance] setTenant:kAppCode
                                              tenantId:[CSRAppStateManager sharedInstance].selectedPlace.settings.cloudTenancyID
                                               success:^(CSRMeshTenant *tenant) {
                                                   if (tenant) {
                                                       [tenant setSite:kAppCode
                                                                siteId:[CSRAppStateManager sharedInstance].selectedPlace.settings.cloudMeshID
                                                                meshId:[CSRAppStateManager sharedInstance].selectedPlace.cloudSiteID
                                                          gatewayUUIDs:nil
                                                               success:^(NSString *siteId) {
                                                                   
                                                               } failure:^(NSError *error) {
                                                                   
                                                                   NSLog(@"Error while creating site at gateway: %@", error);
                                                               }];
                                                   }
                                               } failure:^(NSError *error) {
                                                   NSLog(@"Error while creating tenant at cloud: %@", error);
                                               }];
    } else {
        [sender setTitle:@"Disable" forState:UIControlStateNormal];
    }
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"databaseSharingSegue"]) {
        CSRShareDatabaseVC *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.presentedViewController.view.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        vc.popoverPresentationController.presentedViewController.view.layer.borderWidth = 0.5;
        vc.preferredContentSize = CGSizeMake(self.view.frame.size.width - 20, 190);
        
//        vc.controllerDelegate = self;
        vc.parentVC = self;
        vc.deviceID = _controllerEntity.deviceId;
        
//        NSIndexPath *selectedIndexPath = [_addControllersTableView indexPathForSelectedRow];
//        vc.meshDevice = (CSRmeshDevice*)[_onlyControllersArray objectAtIndex:selectedIndexPath.row];
    }

}

#pragma mark - <UIPopoverPresentationControllerDelegate>

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return NO;
}

- (IBAction)deleteController:(id)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Controller"
                                                                             message:[NSString stringWithFormat:@"Are you sure, you want to delete %@", _controllerEntity.controllerName]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         
                                                         [[CSRAppStateManager sharedInstance].selectedPlace removeControllersObject:_controllerEntity];
                                                         [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_controllerEntity];
                                                         [[CSRDatabaseManager sharedInstance] saveContext];
//                                                         [self dismissViewControllerAnimated:YES completion:nil];
                                                         [self.navigationController popViewControllerAnimated:YES];
                                                         
                                                     }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                     }];

    
    [alertController addAction:okAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)backAction:(id)sender {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)saveControllerAction:(id)sender {

    if(_controllerEntity) {
        _controllerEntity.controllerName = _controllerNameTF.text;
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.backgroundColor = [UIColor whiteColor];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    textField.backgroundColor = [UIColor clearColor];
    [textField resignFirstResponder];
    return NO;
}




@end
