//
//  DiscoverViewController.m
//  OTAU
//
/******************************************************************************
 *  Copyright (C) Cambridge Silicon Radio Limited 2014
 *
 *  This software is provided to the customer for evaluation
 *  purposes only and, as such early feedback on performance and operation
 *  is anticipated. The software source code is subject to change and
 *  not intended for production. Use of developmental release software is
 *  at the user's own risk. This software is provided "as is," and CSR
 *  cautions users to determine for themselves the suitability of using the
 *  beta release version of this software. CSR makes no warranty or
 *  representation whatsoever of merchantability or fitness of the product
 *  for any particular purpose or use. In no event shall CSR be liable for
 *  any consequential, incidental or special damages whatsoever arising out
 *  of the use of or inability to use this software, even if the user has
 *  advised CSR of the possibility of such damages.
 *
 ******************************************************************************/
//

#import "DiscoverViewController.h"
#import "CSRBluetoothLE.h"
#import "OTAU.h"

@interface DiscoverViewController ()<UITableViewDelegate,UITableViewDataSource,CSRBluetoothLEDelegate>

@property (strong, nonatomic) NSIndexPath *selectedCell;
@property (nonatomic,strong) NSMutableArray *devices;

@end

@implementation DiscoverViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backClick)];
    self.navigationItem.leftBarButtonItem = back;
    _devices = [[NSMutableArray alloc] init];
    
    _peripheralsList.delegate = self;
    _peripheralsList.dataSource = self;
    
    
//    [[Discovery sharedInstance] setDiscoveryDelegate:self];
//    [[Discovery sharedInstance] startScanForPeripheralsWithServices];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    [[CSRBluetoothLE sharedInstance] setIsUpdateScaning:YES];
    [[CSRBluetoothLE sharedInstance] startScan];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
//    [[Discovery sharedInstance] setDiscoveryDelegate:nil];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    [[CSRBluetoothLE sharedInstance] setIsUpdateScaning:NO];
    [_devices removeAllObjects];
}

/****************************************************************************/
/*							TableView Delegates								*/
/****************************************************************************/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_devices count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    CBPeripheral *peripheral = (CBPeripheral*)[_devices objectAtIndex:indexPath.row];
    if ([[peripheral name] length]){
        [[cell textLabel] setText:[peripheral name]];
    }else{
        [[cell textLabel] setText:@"No-Name"];
    }
    
	return cell;
}



- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"00000000000000000000");
//    devices = [[Discovery sharedInstance] foundPeripherals];
    CBPeripheral *peripheral = (CBPeripheral*)[_devices objectAtIndex:indexPath.row];

    NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
    
    if ([peripheral state] != CBPeripheralStateConnected) {
        NSLog(@"非直连");
        for (CBPeripheral *connectedPeripheral in connectedPeripherals) {
            if ([connectedPeripheral state] == CBPeripheralStateConnected) {
                [[CSRBluetoothLE sharedInstance] disconnectPeripheral:connectedPeripheral];
                break;
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"开始重连");
            [[CSRBluetoothLE sharedInstance] connectPeripheralNoCheck:peripheral];
            [[CSRBluetoothLE sharedInstance] startOTAUTest:peripheral];
            [self statusMessage:[NSString stringWithFormat:@"Connecting %@\n",peripheral.name]];
        });
    }
    else if ([self isOTAUPeripheral:peripheral]){
        NSLog(@"符合条件");
        if (self.discoveryViewDelegate && [self.discoveryViewDelegate respondsToSelector:@selector(setTarget:)]) {
            [self.discoveryViewDelegate setTarget:peripheral];
        }
    }
    
//    if ([peripheral state]!=CBPeripheralStateConnected) {
////        [[Discovery sharedInstance] connectPeripheral:peripheral];
//        [[CSRBluetoothLE sharedInstance] connectPeripheral:peripheral];
//        // is this an OTAU peripheral?
//        // Display "checking" in the cell view
//        _selectedCell = indexPath;
//        [tableView reloadData];
    
        // check for OTAU service
//        [[Discovery sharedInstance] startOTAUTest:peripheral];
        
        //[discoveryViewDelegate setTarget:peripheral];
//        [self statusMessage:[NSString stringWithFormat:@"Connecting %@\n",peripheral.name]];
    
//    }
//    else if([[Discovery sharedInstance]isOTAUPeripheral:peripheral]){
//        [_discoveryViewDelegate setTarget:peripheral];
//
//    }
    
}


-(BOOL) isOTAUPeripheral:(CBPeripheral *) peripheral {
    NSLog(@"Is this OTAU peripheral: %@",peripheral.name);
    CBUUID *uuid = [CBUUID UUIDWithString:serviceApplicationOtauUuid];
    for (CBService *service in peripheral.services) {
        NSLog(@" -Service = %@",service.UUID);
        if ([service.UUID isEqual:uuid]){
            return (YES);
        }
    }
    return (NO);
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.


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

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

/****************************************************************************/
/*                       BleDiscoveryDelegate Methods                       */
/****************************************************************************/
- (void) discoveryDidRefresh
{
    NSArray *foundPeripherals = [[CSRBluetoothLE sharedInstance] foundPeripherals];
    for (CBPeripheral *peripheral in foundPeripherals) {
        if (![_devices containsObject:peripheral]) {
            [_devices addObject:peripheral];
        }
    }
    NSArray *connectedPeripherals = [[CSRBluetoothLE sharedInstance] connectedPeripherals];
    for (CBPeripheral *peripheral in connectedPeripherals) {
        if (![_devices containsObject:peripheral]) {
            [_devices addObject:peripheral];
        }
    }
    [_peripheralsList reloadData];
}


//============================================================================
- (void) discoveryStatePoweredOff
{
    NSString *title     = @"Bluetooth Power";
    NSString *message   = @"You must turn on Bluetooth in Settings in order to use LE";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

//============================================================================
// callback: is this an otau capable peripheral
-(void) otauPeripheralTest:(CBPeripheral *) peripheral :(BOOL) isOtau {
    if (isOtau) {
        NSLog(@"333333333");
        [self statusMessage:[NSString stringWithFormat:@"Success: OTAU Test\n"]];
        [_discoveryViewDelegate setTarget:peripheral];
//        [[Discovery sharedInstance] stopScanning];
        [[CSRBluetoothLE sharedInstance] stopScan];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self statusMessage:[NSString stringWithFormat:@"Failed: OTAU Test\nDisconnecting...\n"]];
//        [[Discovery sharedInstance] disconnectPeripheral:peripheral];
        [[CSRBluetoothLE sharedInstance] disconnectPeripheral:peripheral];
    }
}


//============================================================================
// The central is successfuly powered on
-(void) centralPoweredOn
{
    [[CSRBluetoothLE sharedInstance] retrieveCachedPeripherals];
}


//============================================================================
-(void) statusMessage:(NSString *)message
{
    NSLog(@"文档内容 %@",message);
    [_statusLog setScrollEnabled:NO];
    [_statusLog setText:[_statusLog.text stringByAppendingString:message]];
    [_statusLog setScrollEnabled:YES];
    NSRange range = NSMakeRange(_statusLog.text.length - 1, 1);
    [_statusLog scrollRangeToVisible:range];
}


/****************************************************************************/
/*				            IB controls                                     */
/****************************************************************************/

- (void)backClick {
    [_discoveryViewDelegate setTarget:nil];
//    [[Discovery sharedInstance] stopScanning];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
