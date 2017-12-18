//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSREventTimeSelectorVC.h"
#import "CSRWeeklyDaysSelectionCell.h"

@interface CSREventTimeSelectorVC ()

@property (nonatomic, strong) NSMutableArray *weeklyDaysArray;

@property (assign) BOOL highlighted;
@property (nonatomic, retain) NSMutableArray *daysArray;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation CSREventTimeSelectorVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _hourlyDailySegmentControl.selectedSegmentIndex = 0;
    _dailyView.hidden = YES;
    
    self.dateFormatter = [NSDateFormatter new];
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [self.dateFormatter setDateFormat:@"EE"];
    
    NSString *dayString = [self.dateFormatter stringFromDate:[NSDate date]];
    _weeklyDaysArray = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", @"", @"", @"", @"", nil];
    
    NSOrderedSet *orderedSet = [NSOrderedSet orderedSetWithArray:@[@"Mon",@"Tue",@"Wed",@"Thu",@"Fri",@"Sat",@"Sun"]];
    
    [orderedSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger indexOfCurrentDay = [orderedSet indexOfObject:dayString];//3
        if (indexOfCurrentDay == idx) {
            [_weeklyDaysArray replaceObjectAtIndex:0 withObject:obj];
        } else if (indexOfCurrentDay < idx) {
            [_weeklyDaysArray replaceObjectAtIndex:(idx-indexOfCurrentDay) withObject:obj];
        } else if (indexOfCurrentDay > idx) {
            [_weeklyDaysArray replaceObjectAtIndex:(7-indexOfCurrentDay) + idx withObject:obj];
        }
    }];

    _weekDaysCollectionView.delegate = self;
    _weekDaysCollectionView.dataSource = self;
    
    _hourlyTextField.delegate = self;
    _daysArray = [[NSMutableArray alloc] initWithObjects:@0, @0, @0, @0, @0, @0, @0, nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)segmentValueChanged:(id)sender {
    
    if (_hourlyDailySegmentControl.selectedSegmentIndex == 0) {
        _hourlyView.hidden = NO;
        _dailyView.hidden = YES;
    } else if (_hourlyDailySegmentControl.selectedSegmentIndex == 1) {
        _hourlyView.hidden = YES;
        _dailyView.hidden = NO;
    }
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return [_weeklyDaysArray count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CSRWeeklyDaysSelectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"weekdaysCellIdentifier" forIndexPath:indexPath];
    cell.layer.cornerRadius = cell.bounds.size.width / 2;
    cell.layer.borderColor = [UIColor lightGrayColor].CGColor;
    cell.layer.borderWidth = 1;
    
    [_daysArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSNumber *indexNum = (NSNumber *)obj;
        if ([indexNum isEqualToNumber:@(1)]) {
            cell.backgroundColor = [UIColor lightGrayColor];
        } else {
            cell.backgroundColor = nil;
        }
    }];
    
    [collectionView setAllowsMultipleSelection:YES];
    
    cell.daysLabel.text = [_weeklyDaysArray objectAtIndex:indexPath.row];
    return cell;
}


#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CSRWeeklyDaysSelectionCell *cell = (CSRWeeklyDaysSelectionCell*)[collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor lightGrayColor];
    [_daysArray replaceObjectAtIndex:indexPath.row withObject:@1];
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CSRWeeklyDaysSelectionCell *cell = (CSRWeeklyDaysSelectionCell*)[collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = nil;
    [_daysArray replaceObjectAtIndex:indexPath.row withObject:@0];

}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
 
    [textField resignFirstResponder];
    
    return YES;
}

- (IBAction)cancelAction:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneAction:(id)sender {
    
    //save the values inputed and selected.
    
    NSMutableData *arrayData = [NSMutableData data];
    [_daysArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * stop) {
        NSNumber *indexObj = (NSNumber *)obj;
        int one = [indexObj intValue];
        [arrayData appendBytes:&one length:1];
        
    }];

    NSLog(@"arrayData :%@", arrayData);
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    NSInteger seconds = [_hourlyTextField.text integerValue];
    NSNumber *everySecond = @(seconds);
    
    [_eventsDelegate repeatEverySeconds:everySecond ofDays:arrayData];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


@end
