//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRMainViewController.h"

@interface CSRManagePlacesViewController : CSRMainViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPlaceButton;
@property (nonatomic) NSMutableArray *placesArray;
@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic, retain) NSURL *importedURL;

@end
