//
//  PowerViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2019/1/4.
//  Copyright © 2019 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "PowerViewController.h"
#import "SocketPowerCell.h"
#import <CSRmesh/DataModelApi.h>
#import "CSRUtilities.h"
#import "PowerModel.h"
#import "PureLayout.h"
#import "DeviceModelManager.h"

@interface PowerViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
{
    CGFloat cellW;
    CGFloat maxPowerValue;
    NSInteger screenRowNum;
}

@property (weak, nonatomic) IBOutlet UIButton *dayBtn;
@property (weak, nonatomic) IBOutlet UIButton *weekBtn;
@property (weak, nonatomic) IBOutlet UIButton *monthBtn;
@property (nonatomic, assign) NSInteger selectedTag;
//@property (weak, nonatomic) IBOutlet UICollectionView *powerList;
@property (nonatomic, strong) UICollectionView *powerList;
@property (nonatomic, strong)NSMutableArray *dataMutableArray;
@property (weak, nonatomic) IBOutlet UILabel *middleLabel;
@property (weak, nonatomic) IBOutlet UILabel *topDateLabel;
@property (nonatomic,strong) NSMutableArray *offsets;
@property (nonatomic,strong) NSArray *fulOffsets;
@property (weak, nonatomic) IBOutlet UILabel *powerStateLabel;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIView *line;


@end

@implementation PowerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIButton *btn = [[UIButton alloc] init];
    [btn setImage:[UIImage imageNamed:@"Btn_back"] forState:UIControlStateNormal];
    [btn setTitle:AcTECLocalizedStringFromTable(@"Back", @"Localizable") forState:UIControlStateNormal];
    [btn setTitleColor:DARKORAGE forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(backSetting) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithCustomView:btn];
    self.navigationItem.leftBarButtonItem = back;
    self.navigationItem.title = @"Electricity Statistics";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(socketPowerStatisticsCall:)
                                                 name:@"socketPowerStatisticsCall"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setSocketSuccess:)
                                                 name:@"setPowerStateSuccess"
                                               object:nil];
    _dataMutableArray = [[NSMutableArray alloc] init];
    _offsets = [[NSMutableArray alloc] init];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 0;
    layout.minimumInteritemSpacing = 0;
    _powerList = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _powerList.backgroundColor = DARKORAGE;
    _powerList.bounces = NO;
    _powerList.showsHorizontalScrollIndicator = NO;
    _powerList.delegate = self;
    _powerList.dataSource = self;
    [_powerList registerNib:[UINib nibWithNibName:@"SocketPowerCell" bundle:nil] forCellWithReuseIdentifier:@"SocketPowerCell"];
    [self.bgView addSubview:_powerList];
    [_powerList autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_powerList autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [_powerList autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_topDateLabel];
    [_powerList autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:_line];
    [self changePowerStateLabel:_deviceId];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dayWeekMonthTouch:_dayBtn];
    });
    
}

- (void)backSetting{
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)setSocketSuccess: (NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSNumber *deviceId = userInfo[@"deviceId"];
    if ([deviceId isEqualToNumber:_deviceId]) {
        [self changePowerStateLabel:deviceId];
    }
}

- (void)changePowerStateLabel:(NSNumber *)deviceId {
    DeviceModel *deviceModel = [[DeviceModelManager sharedInstance]getDeviceModelByDeviceId:deviceId];
    if (deviceModel) {
        switch (_channel) {
            case 1:
                if (deviceModel.channel1PowerState) {
                    _powerStateLabel.text = @"Socket 1 ON";
                    _powerStateLabel.textColor = DARKORAGE;
                }else {
                    _powerStateLabel.text = @"Socket 1 OFF";
                    _powerStateLabel.textColor = [UIColor colorWithRed:120/255.0 green:120/255.0 blue:120/255.0 alpha:1];
                }
                break;
            case 2:
                if (deviceModel.channel2PowerState) {
                    _powerStateLabel.text = @"Socket 2 ON";
                    _powerStateLabel.textColor = DARKORAGE;
                }else {
                    _powerStateLabel.text = @"Socket 2 OFF";
                    _powerStateLabel.textColor = [UIColor colorWithRed:120/255.0 green:120/255.0 blue:120/255.0 alpha:1];
                }
                break;
            default:
                break;
        }
    }
}

- (IBAction)dayWeekMonthTouch:(UIButton *)sender {
    [_dataMutableArray removeAllObjects];
    [_offsets removeAllObjects];
    switch (sender.tag) {
        case 1:
        {
            [sender setImage:[UIImage imageNamed:@"btn_day_highlight"] forState:UIControlStateNormal];
            [sender setTitleColor:DARKORAGE forState:UIControlStateNormal];
            [_weekBtn setImage:[UIImage imageNamed:@"btn_week"] forState:UIControlStateNormal];
            [_weekBtn setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1] forState:UIControlStateNormal];
            [_monthBtn setImage:[UIImage imageNamed:@"btn_month"] forState:UIControlStateNormal];
            [_monthBtn setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1] forState:UIControlStateNormal];
            screenRowNum = 13;
            
            _fulOffsets = @[@(0),@(3),@(6),@(9),@(12),@(15),@(18),@(21),@(24),@(27)];
            
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea434%ldff001e",_channel]] success:nil failure:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![_offsets containsObject:@(30)]) {
                    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea434%ld1e",_channel]] success:nil failure:nil];
                }
            });
        }
            break;
        case 2:
        {
            [sender setImage:[UIImage imageNamed:@"btn_week_highlight"] forState:UIControlStateNormal];
            [sender setTitleColor:DARKORAGE forState:UIControlStateNormal];
            [_dayBtn setImage:[UIImage imageNamed:@"btn_day"] forState:UIControlStateNormal];
            [_dayBtn setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1] forState:UIControlStateNormal];
            [_monthBtn setImage:[UIImage imageNamed:@"btn_month"] forState:UIControlStateNormal];
            [_monthBtn setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1] forState:UIControlStateNormal];
            screenRowNum = 7;
            _fulOffsets = @[@(0),@(3),@(6),@(9)];
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea433%ldff000b",_channel]] success:nil failure:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![_offsets containsObject:@(9)]) {
                    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea433%ld09",_channel]] success:nil failure:nil];
                }
            });
        }
            break;
        case 3:
        {
            [sender setImage:[UIImage imageNamed:@"btn_month_highlight"] forState:UIControlStateNormal];
            [sender setTitleColor:DARKORAGE forState:UIControlStateNormal];
            [_dayBtn setImage:[UIImage imageNamed:@"btn_day"] forState:UIControlStateNormal];
            [_dayBtn setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1] forState:UIControlStateNormal];
            [_weekBtn setImage:[UIImage imageNamed:@"btn_week"] forState:UIControlStateNormal];
            [_weekBtn setTitleColor:[UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1] forState:UIControlStateNormal];
            screenRowNum = 5;
            _fulOffsets = @[@(0),@(3),@(6),@(9)];
            [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea432%ldff000b",_channel]] success:nil failure:nil];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (![_offsets containsObject:@(9)]) {
                    [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea432%ld09",_channel]] success:nil failure:nil];
                }
            });
        }
            break;
        default:
            break;
    }
}

- (void)socketPowerStatisticsCall:(NSNotification *)notification {
    NSDictionary *userInfoDic = notification.userInfo;
    NSNumber *deviceId = userInfoDic[@"deviceId"];
    NSString *userInfoStr = userInfoDic[@"socketPowerStatisticsCall"];
    NSUInteger channel = [CSRUtilities numberWithHexString:[userInfoStr substringWithRange:NSMakeRange(1, 1)]];
    
    if ([deviceId isEqualToNumber:_deviceId] && channel == _channel) {
        
        NSString *kindStr = [userInfoStr substringWithRange:NSMakeRange(0, 1)];
        NSInteger offset =[CSRUtilities numberWithHexString:[userInfoStr substringWithRange:NSMakeRange(2, 2)]];
        if (![_offsets containsObject:@(offset)]) {
            [_offsets addObject:@(offset)];
            switch ([kindStr integerValue]) {
                case 4:
                    if (screenRowNum==13) {
                        if (offset==30) {
                            PowerModel *powerModel = [[PowerModel alloc] init];
                            powerModel.kindInt = 4;
                            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                            [dateComponents setDay:-offset];
                            powerModel.powerDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                            powerModel.power = [CSRUtilities numberWithHexString:[userInfoStr substringWithRange:NSMakeRange(4, 4)]]/10.0;
                            powerModel.selected = NO;
                            if (![_dataMutableArray containsObject:powerModel]) {
                                [_dataMutableArray addObject:powerModel];
                            }
                            
                            NSLog(@"4~~> %@  %f  %d",powerModel.powerDate,powerModel.power,powerModel.selected);
                            
                            if ([_dataMutableArray count]<31) {
                                for (NSNumber *offset in _fulOffsets) {
                                    if (![_offsets containsObject:offset]) {
                                        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea434%ld%@",_channel,[CSRUtilities stringWithHexNumber:[offset integerValue]]]] success:nil failure:nil];
                                    }
                                }
                            }
                            
                        }else {
                            for (int i=0; i<3; i++) {
                                PowerModel *powerModel = [[PowerModel alloc] init];
                                powerModel.kindInt = 4;
                                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                                NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                                [dateComponents setDay:-offset-i];
                                powerModel.powerDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                                powerModel.power = [CSRUtilities numberWithHexString:[userInfoStr substringWithRange:NSMakeRange(4*i+4, 4)]]/10.0;
                                if (offset==0&&i==0) {
                                    powerModel.selected = YES;
                                }else {
                                    powerModel.selected = NO;
                                }
                                NSLog(@"4~~> %@  %f",powerModel.powerDate,powerModel.power);
                                if (![_dataMutableArray containsObject:powerModel]) {
                                    [_dataMutableArray addObject:powerModel];
                                }
                            }
                        }
                        
                        if ([_dataMutableArray count]==31) {
                            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"power" ascending:YES];
                            [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort1]];
                            PowerModel *p = [_dataMutableArray lastObject];
                            maxPowerValue = p.power;
                            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"powerDate" ascending:YES];
                            [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
                            
                            for (int i=0; i<6; i++) {
                                [_dataMutableArray insertObject:@(0) atIndex:0];
                                [_dataMutableArray addObject:@(0)];
                            }
                            NSLog(@"%@",_dataMutableArray);
                            
                            [_powerList reloadData];
                            
                            [_powerList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:42 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
                            PowerModel *startP = [_dataMutableArray objectAtIndex:30];
                            PowerModel *endP = [_dataMutableArray objectAtIndex:36];
                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                            [formatter setDateFormat:@"dd/MM"];
                            _topDateLabel.text = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:startP.powerDate],[formatter stringFromDate:endP.powerDate]];
                            _middleLabel.text = [NSString stringWithFormat:@"%.1f",endP.power];
                        }
                    }
                    break;
                case 3:
                    if (screenRowNum == 7) {
                        for (int i=0; i<3; i++) {
                            PowerModel *powerModel = [[PowerModel alloc] init];
                            powerModel.kindInt = 3;
                            if (offset==0&&i==0) {
                                powerModel.selected = YES;
                            }else {
                                powerModel.selected = NO;
                            }
                            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                            [dateComponents setDay:-offset*7-i*7];
                            powerModel.powerDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                            powerModel.power = [CSRUtilities numberWithHexString:[userInfoStr substringWithRange:NSMakeRange(4*i+4, 4)]]/10.0;
                            NSLog(@"3~~> %@  %f",powerModel.powerDate,powerModel.power);
                            if (![_dataMutableArray containsObject:powerModel]) {
                                [_dataMutableArray addObject:powerModel];
                            }
                        }
                        if (offset==9) {
                            if ([_dataMutableArray count]<12) {
                                for (NSNumber *offset in _fulOffsets) {
                                    if (![_offsets containsObject:offset]) {
                                        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea433%ld%@",_channel,[CSRUtilities stringWithHexNumber:[offset integerValue]]]] success:nil failure:nil];
                                    }
                                }
                            }
                        }
                        
                        if ([_dataMutableArray count]==12) {
                            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"power" ascending:YES];
                            [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort1]];
                            PowerModel *p = [_dataMutableArray lastObject];
                            maxPowerValue = p.power;
                            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"powerDate" ascending:YES];
                            [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
                            for (int i=0; i<3; i++) {
                                [_dataMutableArray insertObject:@(0) atIndex:0];
                                [_dataMutableArray addObject:@(0)];
                            }
                            
                            [_powerList reloadData];
                            
                            [_powerList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:17 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
                            PowerModel *startP = [_dataMutableArray objectAtIndex:11];
                            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                            NSDateComponents *weekdayComponents = [gregorian components:NSCalendarUnitWeekday fromDate:startP.powerDate];
                            NSInteger week = [weekdayComponents weekday];
                            NSDateComponents *sDateComponents = [[NSDateComponents alloc] init];
                            [sDateComponents setDay:-(week-1)];
                            NSDate *startDate = [gregorian dateByAddingComponents:sDateComponents toDate:startP.powerDate options:0];
                            PowerModel *endP= [_dataMutableArray objectAtIndex:14];
                            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                            [formatter setDateFormat:@"dd/MM"];
                            _topDateLabel.text = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:startDate],[formatter stringFromDate:endP.powerDate]];
                            _middleLabel.text = [NSString stringWithFormat:@"%.1f",endP.power];
                        }
                    }
                    break;
                case 2:
                    if (screenRowNum==5) {
                        for (int i=0; i<3; i++) {
                            PowerModel *powerModel = [[PowerModel alloc] init];
                            powerModel.kindInt = 2;
                            if (offset==0&&i==0) {
                                powerModel.selected = YES;
                            }else {
                                powerModel.selected = NO;
                            }
                            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
                            [dateComponents setMonth:-i-offset];
                            powerModel.powerDate = [calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
                            powerModel.power = [CSRUtilities numberWithHexString:[userInfoStr substringWithRange:NSMakeRange(4*i+4, 4)]]/10.0;
                            NSLog(@"2~~> %@  %f",powerModel.powerDate,powerModel.power);
                            [_dataMutableArray addObject:powerModel];
                        }
                        if (offset==9) {
                            if ([_dataMutableArray count]<12) {
                                for (NSNumber *offset in _fulOffsets) {
                                    if (![_offsets containsObject:offset]) {
                                        [[DataModelApi sharedInstance] sendData:_deviceId data:[CSRUtilities dataForHexString:[NSString stringWithFormat:@"ea432%ld%@",_channel,[CSRUtilities stringWithHexNumber:[offset integerValue]]]] success:nil failure:nil];
                                    }
                                }
                            }
                        }
                        if ([_dataMutableArray count]==12) {
                            NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"power" ascending:YES];
                            [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort1]];
                            PowerModel *p = [_dataMutableArray lastObject];
                            maxPowerValue = p.power;
                            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"powerDate" ascending:YES];
                            [_dataMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
                            for (int i=0; i<2; i++) {
                                [_dataMutableArray insertObject:@(0) atIndex:0];
                                [_dataMutableArray addObject:@(0)];
                            }
                            
                            [_powerList reloadData];
                            
                            [_powerList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:15 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:NO];
                            NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
                            [monthFormatter setDateFormat:@"MMM"];
                            PowerModel *startP = [_dataMutableArray objectAtIndex:11];
                            PowerModel *endP = [_dataMutableArray objectAtIndex:13];
                            _topDateLabel.text = [NSString stringWithFormat:@"%@-%@",[monthFormatter stringFromDate:startP.powerDate],[monthFormatter stringFromDate:endP.powerDate]];
                            _middleLabel.text = [NSString stringWithFormat:@"%.1f",endP.power];
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    }
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_dataMutableArray count];
}

- (SocketPowerCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SocketPowerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SocketPowerCell" forIndexPath:indexPath];
    if (cell) {
        id info = [_dataMutableArray objectAtIndex:indexPath.row];
        [cell configureCellWithiInfo:info maxPowerValue:maxPowerValue];
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    cellW = ceilf(WIDTH/screenRowNum);
    return CGSizeMake(cellW, _powerList.bounds.size.height);
}

#pragma mark 居中显示
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGPoint endDraggingVelocity = velocity;
    if (endDraggingVelocity.x == 0) {
        *targetContentOffset = [self nearByOffSet:_powerList.contentOffset withVeloctiy:velocity];
    }else{
        //初速度--放手时候的速度  fabs:取绝对值
        CGFloat startVelocity_X = fabs(endDraggingVelocity.x);
        //加速度
        CGFloat decelerationRate = 100;
        //减速的时间
        CGFloat decelerationSeconds = startVelocity_X / decelerationRate;
        //滑动距离 s = vt -(1/2)*a*(t^2)
        CGFloat distance = startVelocity_X * decelerationSeconds - 0.5 * decelerationRate * decelerationSeconds *decelerationSeconds;
        //停止位置
        CGFloat endOffSet_x = endDraggingVelocity.x > 0 ? (_powerList.contentOffset.x + distance) : (_powerList.contentOffset.x - distance);
        *targetContentOffset = [self nearByOffSet:CGPointMake(endOffSet_x, _powerList.contentOffset.y) withVeloctiy:velocity];
    }
    
    NSInteger row = targetContentOffset->x/cellW+(screenRowNum-1)/2;
    [self selectAction:row];
}

-(CGPoint)nearByOffSet:(CGPoint)contentOffSet withVeloctiy:(CGPoint)velocity
{
    //以中线位置为基准的偏移量
    CGFloat center_x = contentOffSet.x + (CGRectGetWidth(_powerList.frame))*0.5;
    //在中线之前 完整Cell+interval的个数
    NSInteger index = (center_x) / cellW;
    //剩余偏移量:cell在中线左边的宽度 正数
    CGFloat remain_x = (center_x) - (index*(cellW));
    //滑动最小量:这个参数控制cell偏移到什么程度才会跳转到下一个。也可以写死一个数。
    CGFloat minOffset = (cellW/5);
    if (remain_x > (cellW*0.5+minOffset) && velocity.x > 0) {
        index += 1;
    }else if (remain_x < (cellW*0.5-minOffset) && velocity.x < 0) {
        index -= 1;
    }else if (remain_x > (cellW-minOffset) && velocity.x == 0) {
        index += 1;
    }else if (remain_x < minOffset && velocity.x == 0) {
        index -= 1;
    }

    //应该停靠的位置
    CGFloat point_x = (index*cellW) + cellW*0.5 -((CGRectGetWidth(_powerList.frame))*0.5);
    CGPoint targetOffSet = CGPointMake( point_x, contentOffSet.y);

    return targetOffSet;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    NSInteger index;
    switch (screenRowNum) {
        case 13:
            if (indexPath.row<6) {
                index=6;
            }else if (indexPath.row>36) {
                index=36;
            }else {
                index=indexPath.row;
            }
            break;
        case 7:
            if (indexPath.row<3) {
                index=3;
            }else if (indexPath.row>14) {
                index=14;
            }else {
                index=indexPath.row;
            }
            break;
        case 5:
            if (indexPath.row<2) {
                index=2;
            }else if (indexPath.row>13) {
                index=13;
            }else {
                index=indexPath.row;
            }
            break;
        default:
            index=0;
            break;
    }
    [self selectAction:index];
}

- (void)selectAction:(NSInteger)index {
    [_dataMutableArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[PowerModel class]]) {
            PowerModel *p = (PowerModel *)obj;
            if (idx == index) {
                if (!p.selected) {
                    p.selected = YES;
                    _middleLabel.text = [NSString stringWithFormat:@"%.1f",p.power];
                    NSDate *startDate;
                    NSDate *endDate;
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"dd/MM"];
                    switch (p.kindInt) {
                        case 4:
                        {
                            PowerModel *startP;
                            PowerModel *endP;
                            if (idx<12) {
                                startP = [_dataMutableArray objectAtIndex:6];
                                endP = [_dataMutableArray objectAtIndex:idx+6];
                            }else if (idx>30) {
                                startP = [_dataMutableArray objectAtIndex:idx-6];
                                endP = [_dataMutableArray objectAtIndex:36];
                            }else {
                                startP = [_dataMutableArray objectAtIndex:idx-6];
                                endP = [_dataMutableArray objectAtIndex:idx+6];
                            }
                            startDate = startP.powerDate;
                            endDate = endP.powerDate;
                            _topDateLabel.text = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:startDate],[formatter stringFromDate:endDate]];
                        }
                            break;
                        case 3:
                        {
                            PowerModel *startP;
                            PowerModel *endP;
                            if (idx<6) {
                                startP = [_dataMutableArray objectAtIndex:3];
                                endP = [_dataMutableArray objectAtIndex:idx+3];
                            }else if (idx>11) {
                                startP = [_dataMutableArray objectAtIndex:idx-3];
                                endP = [_dataMutableArray objectAtIndex:14];
                            }else {
                                startP = [_dataMutableArray objectAtIndex:idx-3];
                                endP = [_dataMutableArray objectAtIndex:idx+3];
                            }
                            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                            NSDateComponents *weekdayComponents = [gregorian components:NSCalendarUnitWeekday fromDate:startP.powerDate];
                            NSInteger week = [weekdayComponents weekday];
                            NSDateComponents *sDateComponents = [[NSDateComponents alloc] init];
                            [sDateComponents setDay:-(week-1)];
                            startDate = [gregorian dateByAddingComponents:sDateComponents toDate:startP.powerDate options:0];
                            if ([[formatter stringFromDate:endP.powerDate] isEqualToString:[formatter stringFromDate:[NSDate date]]]) {
                                endDate = endP.powerDate;
                            }else {
                                NSDateComponents *eDateComponents = [[NSDateComponents alloc] init];
                                [eDateComponents setDay:7-week];
                                endDate = [gregorian dateByAddingComponents:eDateComponents toDate:endP.powerDate options:0];
                            }
                            _topDateLabel.text = [NSString stringWithFormat:@"%@-%@",[formatter stringFromDate:startDate],[formatter stringFromDate:endDate]];
                        }
                            break;
                        case 2:
                        {
                            NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
                            [monthFormatter setDateFormat:@"MMM"];
                            PowerModel *startP;
                            PowerModel *endP;
                            if (idx<4) {
                                startP = [_dataMutableArray objectAtIndex:2];
                                endP = [_dataMutableArray objectAtIndex:idx+2];
                            }else if (idx>8) {
                                startP = [_dataMutableArray objectAtIndex:idx-2];
                                endP = [_dataMutableArray objectAtIndex:13];
                            }else {
                                startP = [_dataMutableArray objectAtIndex:idx-2];
                                endP = [_dataMutableArray objectAtIndex:idx+2];
                            }
                            _topDateLabel.text = [NSString stringWithFormat:@"%@-%@",[monthFormatter stringFromDate:startP.powerDate],[monthFormatter stringFromDate:endP.powerDate]];
                        }
                            break;
                        default:
                            break;
                    }
                }
            }else {
                if (p.selected) {
                    p.selected = NO;
                }
            }
        }
    }];
    [_powerList reloadData];
}

@end
