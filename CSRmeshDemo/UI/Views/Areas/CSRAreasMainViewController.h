//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>
#import "CSRMainViewController.h"

@interface CSRAreasMainViewController : CSRMainViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, retain) IBOutlet UITableView *areasTableView;
@property (nonatomic, retain) NSMutableArray *areasArray;

- (IBAction)addArea:(id)sender;

@end
