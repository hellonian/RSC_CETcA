//
//  PlacesViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/22.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "PlacesViewController.h"
#import "CSRDatabaseManager.h"
#import "PlaceTableViewCell.h"
#import "CSRPlaceEntity.h"
#import "CSRConstants.h"
#import "CSRmeshStyleKit.h"
#import "CSRUtilities.h"
#import "CSRAppStateManager.h"
#import "PlaceDetailsViewController.h"

@interface PlacesViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) NSMutableArray *placesArray;
@property (nonatomic,assign) BOOL isEdit;
@property (nonatomic,assign) NSInteger selectedRow;

@end

@implementation PlacesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Places";
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction)];
    self.navigationItem.rightBarButtonItem = edit;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PlaceTableViewCell" bundle:nil] forCellReuseIdentifier:PlaceTableViewCellIdentifier];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 65.0;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    
}

- (void)editAction {
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];
    self.navigationItem.leftBarButtonItem = add;
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    
    _isEdit = YES;
}

- (void)addAction {
    PlaceDetailsViewController *pdvc = [[PlaceDetailsViewController alloc] init];
    pdvc.navigationItem.title = @"Creat a new place";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pdvc];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)doneAction {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editAction)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    
    _isEdit = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshPlaces];
}

- (void)refreshPlaces {
    [self.placesArray removeAllObjects];
    self.placesArray = [[[CSRDatabaseManager sharedInstance] fetchObjectsWithEntityName:@"CSRPlaceEntity" withPredicate:nil] mutableCopy];
    if (self.placesArray != nil || [self.placesArray count] != 0 ) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        [_placesArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    }
    [self.tableView reloadData];
    
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_placesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PlaceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlaceTableViewCellIdentifier forIndexPath:indexPath];
    if (self.placesArray && [self.placesArray count]>0) {
        CSRPlaceEntity *placeEntity = [self.placesArray objectAtIndex:indexPath.row];
        if (placeEntity) {
            if (placeEntity.iconID) {
                NSArray *placeIcons = kPlaceIcons;
                [placeIcons enumerateObjectsUsingBlock:^(NSDictionary *placeDictionary, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([placeDictionary[@"id"] integerValue] > -1 && [placeDictionary[@"id"] integerValue] == [placeEntity.iconID integerValue]) {
                        SEL imageSelector = NSSelectorFromString(placeDictionary[@"iconImage"]);
                        if ([CSRmeshStyleKit respondsToSelector:imageSelector]) {
                            cell.placeIcon.image = [CSRmeshStyleKit performSelector:imageSelector];
                        }
                        *stop = YES;
                    }
                }];
            }
            
            cell.placeIcon.image = [cell.placeIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.placeIcon.tintColor = [UIColor whiteColor];
            
            cell.placeIcon.backgroundColor = [CSRUtilities colorFromRGB:[placeEntity.color integerValue]];
            cell.placeIcon.layer.cornerRadius = 5;
            cell.placeIcon.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            cell.placeIcon.layer.borderWidth = .5;
            cell.placeNameLabel.text = placeEntity.name;
            
            if ([CSRAppStateManager sharedInstance].selectedPlace && [[placeEntity objectID] isEqual:[[CSRAppStateManager sharedInstance].selectedPlace objectID]]) {
                cell.currentPlaceIndicator.hidden = NO;
                cell.currentPlaceIndicator.image = [CSRmeshStyleKit imageOfThick_circle];
                _selectedRow = indexPath.row;
            }else {
                cell.currentPlaceIndicator.hidden = YES;
            }
        }
    }
    UIImageView *image = [[UIImageView alloc] initWithImage:[CSRmeshStyleKit imageOfGear]];
    cell.accessoryView = image;
    return cell;
}

#pragma mark - table view delegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isEdit) {
        PlaceDetailsViewController *pdvc = [[PlaceDetailsViewController alloc] init];
        pdvc.navigationItem.title = @"Edit place";
        pdvc.placeEntity = [self.placesArray objectAtIndex:indexPath.row];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pdvc];
        [self presentViewController:nav animated:YES completion:nil];
    }
    else {
        if (indexPath.row == _selectedRow) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else if (_placesArray && [_placesArray count] > 0) {
            if ([[_placesArray objectAtIndex:indexPath.row] isKindOfClass:[CSRPlaceEntity class]]) {
                CSRPlaceEntity *placeEntuty = [_placesArray objectAtIndex:indexPath.row];
                [self showAlert:placeEntuty];
            }
        }
    }
}

- (void) showAlert:(CSRPlaceEntity *)placeEntuty
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                                             message:[NSString stringWithFormat:@"Are you sure you want to switch place to the %@.",placeEntuty.name]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [CSRAppStateManager sharedInstance].selectedPlace = placeEntuty;
                                                         
                                                         if (![[CSRUtilities getValueFromDefaultsForKey:@"kCSRLastSelectedPlaceID"] isEqualToString:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString]]) {
                                                             
                                                             [CSRUtilities saveObject:[[[[CSRAppStateManager sharedInstance].selectedPlace objectID] URIRepresentation] absoluteString] toDefaultsWithKey:@"kCSRLastSelectedPlaceID"];
                                                             
                                                         }
                                                         
                                                         [[CSRAppStateManager sharedInstance] setupPlace];
                                                         
                                                         [self.tableView reloadData];
                                                         [[NSNotificationCenter defaultCenter] postNotificationName:@"reGetDataForPlaceChanged" object:nil];
                                                     }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"CANCEL"
                                                     style:UIAlertActionStyleCancel 
                                                   handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark - lazy

- (NSMutableArray *)placesArray {
    if (!_placesArray) {
        _placesArray = [[NSMutableArray alloc] init];
    }
    return _placesArray;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
