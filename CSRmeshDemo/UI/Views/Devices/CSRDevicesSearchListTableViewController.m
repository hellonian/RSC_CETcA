//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDevicesSearchListTableViewController.h"
#import "CSRDeviceTableViewCell.h"
#import "CSRDeviceDetailsViewController.h"
#import "CSRDevicesManager.h"
#import "CSRUtilities.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"

@interface CSRDevicesSearchListTableViewController ()
{
    NSUInteger selectedIndex;
}
@end

@implementation CSRDevicesSearchListTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Add table delegates
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //Initialize table cell
////    [self.tableView registerNib:[UINib nibWithNibName:@"CSRDeviceTableViewCell" bundle:nil]
//         forCellReuseIdentifier:CSRDeviceTableViewCellIdentifier];
    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _filteredDevicesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CSRDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRDeviceTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRDeviceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRDeviceTableViewCellIdentifier];
    }
    
    CSRDeviceEntity *deviceEntity =  [_filteredDevicesArray objectAtIndex:indexPath.row];
    CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceEntity.deviceId];
    
    if (deviceEntity.name != nil) {
        cell.deviceNameLabel.text = [NSString stringWithFormat:@"%@",deviceEntity.name];
    }
    
    if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameLight)]) {
        
        cell.iconImageView.image = [CSRmeshStyleKit imageOfLight_on];
        
        UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
        colorView.layer.cornerRadius = colorView.bounds.size.width/2;
        colorView.layer.borderColor = [UIColor blackColor].CGColor;
        colorView.layer.borderWidth = 0.5f;
        colorView.backgroundColor = device.stateValue;
        
        UILabel *statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 462, 15)];
        statusLabel.font = [UIFont systemFontOfSize:14];
        [statusLabel setTextColor:[UIColor darkGrayColor]];
        statusLabel.text = [CSRUtilities colorNameForRGB:[CSRUtilities rgbFromColor:(UIColor*)device.stateValue]];
        for (UIView *view in cell.statusView.subviews) {
            [view removeFromSuperview];
        }
        
        [cell.statusView addSubview:colorView];
        [cell.statusView addSubview:statusLabel];
        
    } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameSensor)]) {
        
        cell.iconImageView.image = [CSRmeshStyleKit imageOfSensor];
        
    } else if ([deviceEntity.appearance isEqualToNumber:@(CSRApperanceNameHeater)]) {
        
        cell.iconImageView.image = [CSRmeshStyleKit imageOfTemperature_on];
        
    } else {
        
        cell.iconImageView.image = [CSRmeshStyleKit imageOfMesh_device];
        
    }
    
    //Create accessory view for each cell
    UIButton *accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(0., 0., 65., 65.)];
    [accessoryButton setBackgroundImage:[CSRmeshStyleKit imageOfAccessoryGear ] forState:UIControlStateNormal];
    [accessoryButton addTarget:self action:(@selector(accessoryButtonTapped:)) forControlEvents:UIControlEventTouchUpInside];
    accessoryButton.tag = indexPath.row;
    
    cell.accessoryView = accessoryButton;
    
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedIndex = indexPath.row;
    
    [_delegate selectedItemIndex:indexPath.row];
    
    [self displayLightControl];
    
    return indexPath;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"filteredLightControlSegue"]) {
    }
}

#pragma mark - Accessory type action

- (void)accessoryButtonTapped:(id)sender
{
    UIButton *accessoryButton = (UIButton *)sender;
    NSLog(@"Acessory button tapped at index: %li", (long)accessoryButton.tag);
    selectedIndex = accessoryButton.tag;
    [self performSegueWithIdentifier:@"searchedDeviceConfigurationSegue" sender:self];
}

#pragma mark - <CSRDevicesListDelegate>

- (void)displayLightControl
{
    CSRDeviceEntity *deviceEntity = [_filteredDevicesArray objectAtIndex:selectedIndex];
    CSRmeshDevice *device = [[CSRDevicesManager sharedInstance] getDeviceFromDeviceId:deviceEntity.deviceId];
    if (device) {
        [[CSRDevicesManager sharedInstance] setSelectedDevice:device];
        [[CSRDevicesManager sharedInstance] setSelectedArea:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CSRDevicesSearchListControlDisplay" object:nil];
    
}



#pragma mark - <CSRDevicesSearchListDelegate>

- (NSUInteger)selectedItemIndex:(NSUInteger)item
{
    return item;
}


@end
