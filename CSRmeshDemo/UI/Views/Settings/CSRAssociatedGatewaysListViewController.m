//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRAssociatedGatewaysListViewController.h"
#import "CSRGatewayTableViewCell.h"
#import "CSRGatewayDetailsViewController.h"
#import "CSRAppStateManager.h"
#import "CSRDatabaseManager.h"
#import "CSRGatewayEntity.h"
#import "CSRmeshStyleKit.h"
#import "CSRConstants.h"
#import "CSRUtilities.h"

@interface CSRAssociatedGatewaysListViewController () <UITableViewDelegate, UITableViewDataSource>
{
   
    NSUInteger selectedIndex;

}

@property (nonatomic) NSMutableArray *gatewaysArray;

@end

@implementation CSRAssociatedGatewaysListViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    _gatewaysArray = [NSMutableArray new];
    
    //Adjust navigation controller appearance
    self.showNavMenuButton = NO;
    self.showNavSearchButton = NO;
    
    [super adjustNavigationControllerAppearance];
    
    //Set navigation buttons
    _backButton = [[UIBarButtonItem alloc] init];
    _backButton.image = [CSRmeshStyleKit imageOfBack_arrow];
    _backButton.action = @selector(back:);
    _backButton.target = self;
    
    [super addCustomBackButtonItem:_backButton];
    
    //Add table delegates
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    [self refreshDevices:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    self.view = nil;
}

- (void)refreshDevices:(id)sender
{
    
    [_gatewaysArray removeAllObjects];
    
    _gatewaysArray = [[[CSRAppStateManager sharedInstance].selectedPlace.gateways allObjects] mutableCopy];

    //Sort devices alphabetically
    if (_gatewaysArray != nil || [_gatewaysArray count] != 0) {
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_gatewaysArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65.f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return  [_gatewaysArray count];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CSRGatewayTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CSRGatewayTableViewCellIdentifier];
    
    if (!cell) {
        cell = [[CSRGatewayTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CSRGatewayTableViewCellIdentifier];
    }
    
    CSRGatewayEntity *gateway = (CSRGatewayEntity *)[_gatewaysArray objectAtIndex:indexPath.row];
    
    if (gateway) {
        
        cell.iconImageView.image = [CSRmeshStyleKit imageOfGateway_on];
        cell.iconImageView.image = [cell.iconImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconImageView.tintColor = [UIColor darkGrayColor];
        cell.gatewayNameLabel.text = gateway.name;
        cell.gatewayIPLabel.text = [NSString stringWithFormat:@"%@:%@", gateway.host, gateway.port];
        
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_mode == CSRGatewayListMode_GatewayDetails) {
        
        selectedIndex  = indexPath.row;
        [self performSegueWithIdentifier:@"gatewayDetailsSegue" sender:self];
        
    } else {
        
        CSRGatewayTableViewCell *selectedCell = (CSRGatewayTableViewCell*)[tableView cellForRowAtIndexPath:indexPath];
        [selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self dismissViewControllerAnimated:YES completion:^{
            [[CSRAppStateManager sharedInstance] setCurrentGateway:[_gatewaysArray objectAtIndex:indexPath.row]];
//            [((CSRBearerPickerViewController *)_parentVC).delegate selectedBearerOption:CSRSelectedBearerType_Gateway];
            [_parentVC dismissViewControllerAnimated:YES completion:^{
                
                [_parentVC.parentViewController viewWillAppear:YES];
                
            }];
            
            [CSRAppStateManager sharedInstance].bearerType = CSRSelectedBearerType_Gateway;
            
        }];
       
    }
    
}

#pragma mark UITableViewCell helper

- (void)setCellColor:(UIColor *)color forCell:(UITableViewCell *)cell
{
    CSRGatewayTableViewCell *selectedCell = (CSRGatewayTableViewCell*)cell;
    selectedCell.gatewayNameLabel.textColor = color;
    selectedCell.gatewayIPLabel.textColor = color;
    selectedCell.iconImageView.tintColor = color;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"gatewayDetailsSegue"]) {
        
        NSLog(@"Gateway selected: %@", [_gatewaysArray objectAtIndex:selectedIndex]);
        
        UINavigationController *navigationController = segue.destinationViewController;
        CSRGatewayDetailsViewController *vc = (CSRGatewayDetailsViewController *)navigationController.topViewController;
        vc.gatewayEntity = [_gatewaysArray objectAtIndex:selectedIndex];
         
    }
}

#pragma mark - Actions

- (IBAction)back:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addGateway:(id)sender
{
    [self performSegueWithIdentifier:@"addGatewaySegue" sender:self];
}


@end
