//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRBridgeDiscoveryViewController.h"
#import "CSRAlertView.h"
#import "CSRConstants.h"
#import "CSRUtilities.h"

@interface CSRBridgeDiscoveryViewController ()

@end

@implementation CSRBridgeDiscoveryViewController

#pragma mark ------
#pragma mark View Lifecycle

-(void) viewDidAppear:(BOOL)animated {
    
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    
    // With exception of connected peripheral, delete all discovered peripherals
    // Some of the previously discovered peripherals may no longer be advertising
    
    [[CSRBluetoothLE sharedInstance] removeDiscoveredPeripheralsExceptConnected];
    
    // Start scan, if it has not already started
    
    [[CSRBluetoothLE sharedInstance] setScanner:YES source:self];
    
    [_tableOfBridges reloadData];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Select Bridge";
    
    [[CSRBluetoothLE sharedInstance] setBleDelegate:self];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}

#pragma mark -----------
#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[CSRBluetoothLE sharedInstance] discoveredBridges] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSNumber *RSSI = @0;
    NSString *name = @"";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    NSArray *bridges = [[CSRBluetoothLE sharedInstance] discoveredBridges];
    CBPeripheral *peripheral = (CBPeripheral *)[bridges objectAtIndex:indexPath.row];
    
    if (peripheral) {
        RSSI = peripheral.rssi;
        name = peripheral.localName;
        if (name == nil)
            name = peripheral.name;
        
    }
    if (name && name.length) {
        cell.textLabel.text = name;
    } else {
        cell.textLabel.text = @"No-Name";
    }
    if (peripheral.state == CBPeripheralStateDisconnected) {
        if (RSSI != nil) {
            cell.detailTextLabel.text = [RSSI stringValue];
        } else {
            cell.detailTextLabel.text = @"";
        }
    } else if (peripheral.state == CBPeripheralStateConnected) {
        cell.detailTextLabel.text = @"Connected";
    } else if (peripheral.state == CBPeripheralStateConnecting) {
        cell.detailTextLabel.text = @"Connecting";
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *devices = [[CSRBluetoothLE sharedInstance] discoveredBridges];
    CBPeripheral *peripheral = (CBPeripheral*)[devices objectAtIndex:indexPath.row];
    
    if ([peripheral state] == CBPeripheralStateDisconnected) {
        [[CSRBluetoothLE sharedInstance] connectPeripheral:peripheral];
        [_tableOfBridges reloadData];
    } else {
        [[CSRBluetoothLE sharedInstance] disconnectPeripheral:peripheral];
        [_tableOfBridges reloadData];
        
    }
}

#pragma mark ------
#pragma mark CBPeripheral Power State

- (void) CBPowerIsOff
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Bluetooth Power"
                                                                             message:@"You must turn on Bluetooth in Settings in order to use LE"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController.view setTintColor:[CSRUtilities colorFromHex:kColorBlueCSR]];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                         }];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                     }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void) CBPoweredOn
{
    
}

- (void) discoveredBridge
{
    [_tableOfBridges reloadData];
}

- (void)didConnectBridge:(CBPeripheral *)bridge
{
    [_tableOfBridges reloadData];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
}

#pragma mark ------
#pragma mark Kill View Lifecycle

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    
    [[[CSRBluetoothLE sharedInstance] discoveredBridges] removeAllObjects];
    [[CSRBluetoothLE sharedInstance] setScanner:NO source:self];
    [[CSRBluetoothLE sharedInstance] setBleDelegate:nil];
    
    if (self.view.window == nil) {
        self.view = nil;
    }
}

@end
