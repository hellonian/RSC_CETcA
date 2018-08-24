//
//  TimerDetailViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/3/2.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import "TimerDetailViewController.h"
#import <objc/runtime.h>
#import "PureLayout.h"
#import "DeviceListViewController.h"
#import "DeviceModelManager.h"
#import "CSRDatabaseManager.h"
#import "TimerEntity.h"
#import "CSRUtilities.h"
#import "TimerDeviceEntity.h"
#import "DataModelManager.h"
#import "CSRAppStateManager.h"
#import <MBProgressHUD.h>

@interface TimerDetailViewController ()<UITextFieldDelegate,MBProgressHUDDelegate>
{
    NSNumber *timerIdNumber;
    NSString *name;
    NSNumber *enabled;
    NSDate *time;
    NSDate *date;
    NSString *repeatStr;
    NSLayoutConstraint *top_chooseTitle;
}

@property (weak, nonatomic) IBOutlet UIDatePicker *timerPicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UIView *weekView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *repeatChooseSegment;
@property (weak, nonatomic) IBOutlet UITextField *nameTF;
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (nonatomic,strong) NSMutableArray *deviceIds;
@property (nonatomic,strong) NSMutableDictionary *deviceIdsAndIndexs;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (nonatomic,strong) NSMutableArray *deleteTimers;
@property (nonatomic,strong) NSMutableArray *backs;
@property (nonatomic,strong) MBProgressHUD *hud;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UILabel *chooseTitle;

@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) SceneEntity *selectedScene;
@property (nonatomic,strong) NSMutableArray *sceneMutableArray;
@property (nonatomic,strong) UIView *selectedView;
@property (nonatomic,strong) UIView *sceneView;
//@property (nonatomic,strong) UIView *topBgView;

@end

@implementation TimerDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:AcTECLocalizedStringFromTable(@"Done", @"Localizable") style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
    self.navigationItem.rightBarButtonItem = done;
    
    [self setDatePickerTextColor:self.timerPicker];
    [self setDatePickerTextColor:self.datePicker];
    self.nameTF.delegate = self;
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:_scrollView];
    [_scrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *top;
    if (@available(iOS 11.0,*)) {
        top = [NSLayoutConstraint constraintWithItem:_scrollView
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.view.safeAreaLayoutGuide
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1.0
                                            constant:0];
    }else {
        self.automaticallyAdjustsScrollViewInsets = NO;
        top = [NSLayoutConstraint constraintWithItem:_scrollView
                                           attribute:NSLayoutAttributeTop
                                           relatedBy:NSLayoutRelationEqual
                                              toItem:self.view
                                           attribute:NSLayoutAttributeTop
                                          multiplier:1.0
                                            constant:64];
    }
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:_scrollView
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:_scrollView
                                                             attribute:NSLayoutAttributeRight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeRight
                                                            multiplier:1.0
                                                              constant:0];
    NSLayoutConstraint *bottom;
    if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
        bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:50.0];
    }else {
        bottom = [NSLayoutConstraint constraintWithItem:_scrollView
                                              attribute:NSLayoutAttributeBottom
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:self.view
                                              attribute:NSLayoutAttributeBottom
                                             multiplier:1.0
                                               constant:0];
        
    }
    
    [NSLayoutConstraint activateConstraints:@[top,left,bottom,right]];
    
    [_scrollView addSubview:_bgView];
    [_bgView autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [_bgView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_bgView autoSetDimension:ALDimensionHeight toSize:89];
    [_bgView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    _sceneMutableArray = [[NSMutableArray alloc] init];
    NSMutableArray *areaMutableArray =  [[[CSRAppStateManager sharedInstance].selectedPlace.scenes allObjects] mutableCopy];
    if (areaMutableArray != nil || [areaMutableArray count] != 0) {
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
        [areaMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        for (SceneEntity *sceneEntity in areaMutableArray) {
            if ([sceneEntity.members count]>0) {
                [_sceneMutableArray addObject:sceneEntity];
            }
        }
    }
    
    if (!self.newadd && self.timerEntity) {
        self.navigationItem.title = self.timerEntity.name;
        self.nameTF.text = self.timerEntity.name;
        [self.enabledSwitch setOn:[self.timerEntity.enabled boolValue]];
        
        _selectedScene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:self.timerEntity.sceneID];
        _selectedView = [self addSelectedView:_selectedScene];
        [_scrollView addSubview:_selectedView];
        [_selectedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView];
        [_selectedView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_selectedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_selectedView autoSetDimension:ALDimensionHeight toSize:45];
        
        [_sceneMutableArray removeObject:_selectedScene];
        
        [_scrollView addSubview:_chooseTitle];
        top_chooseTitle = [_chooseTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView withOffset:57];
        [_chooseTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
        
        _sceneView = [self addSceneView:_sceneMutableArray];
        [_scrollView addSubview:_sceneView];
        [_sceneView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_chooseTitle withOffset:10];
        [_sceneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_sceneView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        if (_sceneMutableArray && [_sceneMutableArray count]>0) {
            [_sceneView autoSetDimension:ALDimensionHeight toSize:45*[_sceneMutableArray count]-1];
        }else {
            _sceneView.backgroundColor = [UIColor clearColor];
            [_sceneView autoSetDimension:ALDimensionHeight toSize:1];
        }
        
        [_scrollView addSubview:_timerPicker];
        [_timerPicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_timerPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_sceneView withOffset:12];
        
        [_scrollView addSubview:_repeatChooseSegment];
        [_repeatChooseSegment autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_repeatChooseSegment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_timerPicker withOffset:12];
        [_repeatChooseSegment autoSetDimension:ALDimensionHeight toSize:30];
        [_repeatChooseSegment autoSetDimension:ALDimensionWidth toSize:140];
        
        [self.timerPicker setDate:self.timerEntity.fireTime];
        
        if ([self.timerEntity.repeat isEqualToString:@"00000000"]) {
            [self.repeatChooseSegment setSelectedSegmentIndex:1];
            [_scrollView addSubview:self.datePicker];
            [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:12.0];
            [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
            [self.datePicker autoSetDimension:ALDimensionHeight toSize:160.0];
            
            [self.datePicker setDate:self.timerEntity.fireDate];
            
            [_scrollView addSubview:_deleteButton];
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_datePicker withOffset:12.0];
            [_deleteButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_deleteButton autoSetDimension:ALDimensionWidth toSize:WIDTH];
            
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
                _scrollView.contentSize = CGSizeMake(WIDTH-321, 45*[_sceneMutableArray count]-1+618);
            }else {
                _scrollView.contentSize = CGSizeMake(WIDTH, 45*[_sceneMutableArray count]-1+618);
            }
            
        }else {
            [self.repeatChooseSegment setSelectedSegmentIndex:0];
            [_scrollView addSubview:self.weekView];
            [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:44.0];
            [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
            [self.weekView autoSetDimension:ALDimensionHeight toSize:60.0];
            
            NSString *repeat = [self.timerEntity.repeat substringFromIndex:1];
            [self.weekView.subviews enumerateObjectsUsingBlock:^(UIButton * btn, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *str = [repeat substringWithRange:NSMakeRange(6-idx, 1)];
                if ([str boolValue]) {
                    btn.selected = YES;
                    [btn setBackgroundImage:[UIImage imageNamed:@"weekBtnSelected"] forState:UIControlStateNormal];
                }else {
                    btn.selected = NO;
                    [btn setBackgroundImage:[UIImage imageNamed:@"weekBtnSelect"] forState:UIControlStateNormal];
                }
            }];
            
            [_scrollView addSubview:_deleteButton];
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weekView withOffset:44.0];
            [_deleteButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
            [_deleteButton autoSetDimension:ALDimensionWidth toSize:WIDTH];
            
            if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
                _scrollView.contentSize = CGSizeMake(WIDTH-321, 45*[_sceneMutableArray count]-1+582);
            }else {
                _scrollView.contentSize = CGSizeMake(WIDTH, 45*[_sceneMutableArray count]-1+582);
            }
        }
        
    }else {
        
        [_scrollView addSubview:_chooseTitle];
        top_chooseTitle = [_chooseTitle autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView withOffset:12];
        [_chooseTitle autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
        
        _sceneView = [self addSceneView:_sceneMutableArray];
        [_scrollView addSubview:_sceneView];
        [_sceneView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_chooseTitle withOffset:10];
        [_sceneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_sceneView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_sceneView autoSetDimension:ALDimensionHeight toSize:45*[_sceneMutableArray count]-1];
        
        [_scrollView addSubview:_timerPicker];
        [_timerPicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_timerPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_sceneView withOffset:12];
        
        [_scrollView addSubview:_repeatChooseSegment];
        [_repeatChooseSegment autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_repeatChooseSegment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_timerPicker withOffset:12];
        [_repeatChooseSegment autoSetDimension:ALDimensionHeight toSize:30];
        [_repeatChooseSegment autoSetDimension:ALDimensionWidth toSize:140];
        
        [_scrollView addSubview:_weekView];
        [_weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [_weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_repeatChooseSegment withOffset:44];
        [_weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [_weekView autoSetDimension:ALDimensionHeight toSize:60.0];
        
        if ([UIDevice currentDevice].userInterfaceIdiom==UIUserInterfaceIdiomPad) {
            _scrollView.contentSize = CGSizeMake(WIDTH-321, 45*[_sceneMutableArray count]-1+493);
        }else {
            _scrollView.contentSize = CGSizeMake(WIDTH, 45*[_sceneMutableArray count]-1+493);
        }
        
    }
    
}

- (UIView *)addSceneView:(NSMutableArray *)scenes {
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor whiteColor];
    [scenes enumerateObjectsUsingBlock:^(SceneEntity *sceneEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = [sceneEntity.sceneID integerValue] + 100;
        [btn addTarget:self action:@selector(sceneSelectAction:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *titleLabel = [[UILabel alloc] init];
        titleLabel.frame = CGRectMake(20, 12, 150, 20);
        titleLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
        titleLabel.font = [UIFont systemFontOfSize:14];
        titleLabel.text = sceneEntity.sceneName;
        [btn addSubview:titleLabel];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"To_select"]];
        [btn addSubview:imageView];
        
        [imageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:11];
        [imageView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
        [imageView autoSetDimension:ALDimensionHeight toSize:22];
        [imageView autoSetDimension:ALDimensionWidth toSize:22];
        
        [bgView addSubview:btn];
        
        [btn autoSetDimension:ALDimensionHeight toSize:44.0];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeRight];
        [btn autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:idx*45];
        
        if (idx !=0) {
            UIView *line = [[UIView alloc] init];
            line.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
            [bgView addSubview:line];
            [line autoSetDimension:ALDimensionHeight toSize:1];
            [line autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
            [line autoPinEdgeToSuperviewEdge:ALEdgeRight];
            [line autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:44+(idx-1)*45];
        }
    }];
    return bgView;
}

- (void)sceneSelectAction:(UIButton *)button {
    SceneEntity *scene = [[CSRDatabaseManager sharedInstance] getSceneEntityWithId:[NSNumber numberWithInteger:button.tag - 100]];
    if (_selectedScene) {
        [_sceneMutableArray addObject:_selectedScene];
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"sceneID" ascending:YES];
        [_sceneMutableArray sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        [_selectedView removeFromSuperview];
    }
    _selectedView = [self addSelectedView:scene];
    [_scrollView addSubview:_selectedView];
    [_selectedView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_bgView];
    [_selectedView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    [_selectedView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_selectedView autoSetDimension:ALDimensionHeight toSize:45];
    
    _selectedScene = scene;
    [_sceneMutableArray removeObject:scene];
    
    top_chooseTitle.constant = 57;
    
    [_sceneView removeFromSuperview];
    _sceneView = [self addSceneView:_sceneMutableArray];
    [_scrollView addSubview:_sceneView];
    [_sceneView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_chooseTitle withOffset:10];
    [_sceneView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [_sceneView autoAlignAxisToSuperviewAxis:ALAxisVertical];
    if (_sceneMutableArray && [_sceneMutableArray count]>0) {
        [_sceneView autoSetDimension:ALDimensionHeight toSize:45*[_sceneMutableArray count]-1];
    }else {
        _sceneView.backgroundColor = [UIColor clearColor];
        [_sceneView autoSetDimension:ALDimensionHeight toSize:1];
    }
    
    [_timerPicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_sceneView withOffset:12];

    [_repeatChooseSegment autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_timerPicker withOffset:12];
    
    if (_repeatChooseSegment.selectedSegmentIndex == 0) {
        [_weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_repeatChooseSegment withOffset:44];
        if (_newadd) {
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+538);
        }else {
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weekView withOffset:44.0];
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+582);
        }
    }else {
        [_datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_repeatChooseSegment withOffset:12.0];
        if (_newadd) {
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+574);
        }else {
            _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+618);
        }
    }
    
}

- (UIView *)addSelectedView:(SceneEntity *)scene {
    UIView *selectedBgView = [[UIView alloc] init];
    selectedBgView.backgroundColor = [UIColor whiteColor];
    UIView *line = [[UIView alloc] initWithFrame:CGRectZero];
    line.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    [selectedBgView addSubview:line];
    [line autoPinEdgeToSuperviewEdge:ALEdgeTop];
    [line autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20];
    [line autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [line autoSetDimension:ALDimensionHeight toSize:1];
    UILabel *selectedTitleLabel = [[UILabel alloc] init];
    selectedTitleLabel.frame = CGRectMake(20, 12, 150, 20);
    selectedTitleLabel.textColor = [UIColor colorWithRed:77/255.0 green:77/255.0 blue:77/255.0 alpha:1];
    selectedTitleLabel.font = [UIFont systemFontOfSize:14];
    selectedTitleLabel.text = scene.sceneName;
    [selectedBgView addSubview:selectedTitleLabel];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Be_selected"]];
    [selectedBgView addSubview:imageView];
    [imageView autoSetDimension:ALDimensionWidth toSize:22];
    [imageView autoSetDimension:ALDimensionHeight toSize:22];
    [imageView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:11];
    [imageView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:16];
    return selectedBgView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addTimerToDeviceCall:) name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteTimerCall:) name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlarmEnabledCall:) name:@"changeAlarmEnabledCall" object:nil];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeAlarmEnabledCall" object:nil];
}

#pragma mark - 修改日期选择器的字体颜色

- (void)setDatePickerTextColor:(UIDatePicker *)picker {
    unsigned int outCount;
    int i;
    objc_property_t *pProperty = class_copyPropertyList([UIDatePicker class], &outCount);
    for (i = outCount -1; i >= 0; i--)
    {
        //         循环获取属性的名字   property_getName函数返回一个属性的名称
        NSString *getPropertyName = [NSString stringWithCString:property_getName(pProperty[i]) encoding:NSUTF8StringEncoding];
        if([getPropertyName isEqualToString:@"textColor"])
        {
            [picker setValue:DARKORAGE forKey:@"textColor"];
        }
    }
    //通过NSSelectorFromString获取setHighlightsToday方法
    SEL selector = NSSelectorFromString(@"setHighlightsToday:");
    //创建NSInvocation
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDatePicker instanceMethodSignatureForSelector:selector]];
    BOOL no = NO;
    [invocation setSelector:selector];
    //setArgument中第一个参数的类picker，第二个参数是SEL，
    [invocation setArgument:&no atIndex:2];
    //让invocation执行setHighlightsToday方法
    [invocation invokeWithTarget:picker];
}

- (IBAction)repeatClick:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self.datePicker removeFromSuperview];
        [_scrollView addSubview:self.weekView];
        [self.weekView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.weekView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:44.0];
        [self.weekView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
        [self.weekView autoSetDimension:ALDimensionHeight toSize:60.0];
        if (_newadd) {
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+538);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+493);
            }
        }else {
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_weekView withOffset:44.0];
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+582);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+537);
            }
        }
        
        
    }else {
        [self.weekView removeFromSuperview];
        [_scrollView addSubview:self.datePicker];
        [self.datePicker autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.datePicker autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.repeatChooseSegment withOffset:12.0];
        [self.datePicker autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:20.0];
        [self.datePicker autoSetDimension:ALDimensionHeight toSize:160.0];
        if (_newadd) {
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+574);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+529);
            }
        }else {
            [_deleteButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_datePicker withOffset:12.0];
            if (_selectedScene) {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+618);
            }else {
                _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, 45*[_sceneMutableArray count]-1+573);
            }
        }
    }
}
/*
- (IBAction)chooseDevice:(UIButton *)sender {
    DeviceListViewController *list = [[DeviceListViewController alloc] init];
    list.selectMode = DeviceListSelectMode_Multiple;
    [list getSelectedDevices:^(NSArray *devices) {
        if (devices.count > 0) {
            __block NSString *string = @"";
            [devices enumerateObjectsUsingBlock:^(NSNumber *deviceId, NSUInteger idx, BOOL * _Nonnull stop) {
                DeviceModel *device = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
                string = [NSString stringWithFormat:@"%@ %@",string,device.name];
            }];
            self.devicesListLabel.text = string;
            self.deviceIds = [NSMutableArray arrayWithArray:devices];
        }
    }];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:list];
    [self presentViewController:nav animated:YES completion:nil];
}
*/
#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.backgroundColor = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    textField.backgroundColor = [UIColor whiteColor];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - weekButton

- (IBAction)weekButtonClick:(UIButton *)sender {
    __block BOOL exist = 0;
    [_weekView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIButton class]]) {
            UIButton *btn = (UIButton *)obj;
            if (btn.tag!=sender.tag && btn.selected) {
                exist = YES;
                *stop = YES;
            }
        }
    }];
    if (exist) {
        sender.selected = !sender.selected;
        UIImage *bgImage = sender.selected? [UIImage imageNamed:@"weekBtnSelected"]:[UIImage imageNamed:@"weekBtnSelect"];
        [sender setBackgroundImage:bgImage forState:UIControlStateNormal];
    }
    
}

- (void)doneAction {
    
//    if ([self.deviceIds count]==0) {
//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"MustChoose", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
//        [alertController.view setTintColor:DARKORAGE];
//        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//            
//        }];
//        [alertController addAction:cancelAction];
//        [self presentViewController:alertController animated:YES completion:nil];
//        return;
//    }
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_hud hideAnimated:YES];
        _hud = nil;
        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"Error", @"Localizable")]];
    });
    [self.backs removeAllObjects];
    
//    NSNumber *timerIdNumber;
    if (_newadd) {
        if (!_timerEntity) {
            timerIdNumber = [[CSRDatabaseManager sharedInstance] getNextFreeIDOfType:@"TimerEntity"];
        }
    }else {
        if (_timerEntity) {
            timerIdNumber = _timerEntity.timerID;
        }
    }
    
//    NSString *name;
    if (![CSRUtilities isStringEmpty:_nameTF.text]) {
        name = _nameTF.text;
    }else {
        name = [NSString stringWithFormat:@"timer %@",timerIdNumber];
    }
    
    enabled = @(_enabledSwitch.on);
    
    NSDateFormatter *dateFormate_time = [[NSDateFormatter alloc] init];
    [dateFormate_time setDateFormat:@"HHmm"];
    NSString *timeStr = [dateFormate_time stringFromDate:_timerPicker.date];
    time = [dateFormate_time dateFromString:timeStr];
//    NSDate *date;
    
    repeatStr = @"";
    if (_repeatChooseSegment.selectedSegmentIndex == 0) {
        for (UIButton *btn in self.weekView.subviews) {
            repeatStr = [NSString stringWithFormat:@"%d%@",btn.selected,repeatStr];
        }
        repeatStr = [NSString stringWithFormat:@"0%@",repeatStr];
        date = nil;
    }else {
        repeatStr = @"00000000";
        NSDateFormatter *dateFormate_date = [[NSDateFormatter alloc] init];
        [dateFormate_date setDateFormat:@"yyyyMMdd"];
        NSString *dateStr = [dateFormate_date stringFromDate:_datePicker.date];
        date = [dateFormate_date dateFromString:dateStr];
    }
    
    for (SceneMemberEntity *sceneMember in _selectedScene.members) {
        NSNumber *timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:sceneMember.deviceID];
        [self.deviceIdsAndIndexs setObject:timerIndex forKey:[NSString stringWithFormat:@"%@",sceneMember.deviceID]];
        NSString *eveType;
        if ([sceneMember.powerState boolValue]) {
            if ([CSRUtilities belongToSwitch:sceneMember.kindString]) {
                eveType = @"10";
            }else if ([CSRUtilities belongToDimmer:sceneMember.kindString]) {
                eveType = @"12";
            }
        }else {
            eveType = @"11";
        }
        [[DataModelManager shareInstance] addAlarmForDevice:sceneMember.deviceID alarmIndex:[timerIndex integerValue] enabled:enabled fireDate:date fireTime:time repeat:repeatStr eveType:eveType level:[sceneMember.level integerValue]];
    }
    
    /*
    if (!_newadd) {
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            
            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:timerDevice];
            [[CSRDatabaseManager sharedInstance] saveContext];
        }];
    }
    
//    _timerEntity = [[CSRDatabaseManager sharedInstance] saveNewTimer:timerIdNumber timerName:name enabled:enabled fireTime:time fireDate:date repeatStr:repeatStr];

    for (NSNumber *deviceId in self.deviceIds) {
        
        NSNumber *timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:deviceId];
        NSLog(@"timerIndex--> %@",timerIndex);

        [self.deviceIdsAndIndexs setObject:timerIndex forKey:[NSString stringWithFormat:@"%@",deviceId]];

        DeviceModel *model = [[DeviceModelManager sharedInstance] getDeviceModelByDeviceId:deviceId];
        NSString *eveType;
        if ([CSRUtilities belongToSwitch:model.shortName]) {
            if ([model.powerState boolValue]) {
                eveType = @"10";
            }else {
                eveType = @"11";
            }
        }else if ([CSRUtilities belongToDimmer:model.shortName]) {
            if ([model.powerState boolValue]) {
                eveType = @"12";
            }else {
                eveType = @"11";
            }
        }
        [[DataModelManager shareInstance] addAlarmForDevice:deviceId alarmIndex:[timerIndex integerValue] enabled:[enabled boolValue] fireDate:date fireTime:time repeat:repeatStr eveType:eveType level:[model.level integerValue]];
        
    }
    
    */
    
    
}

- (void)addTimerToDeviceCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *resultStr = [resultDic objectForKey:@"addAlarmCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    NSLog(@"---->> %@ ::: %@",deviceId,resultStr);
    
    if ([resultStr boolValue]) {
        _timerEntity = [[CSRDatabaseManager sharedInstance] saveNewTimer:timerIdNumber timerName:name enabled:enabled fireTime:time fireDate:date repeatStr:repeatStr sceneID:_selectedScene.sceneID];
        NSNumber *index = [self.deviceIdsAndIndexs objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
        __block TimerDeviceEntity *newTimerDeviceEntity;
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            if ([timerDevice.deviceID isEqualToNumber:deviceId] && [timerDevice.timerIndex isEqualToNumber:index]) {
                newTimerDeviceEntity = timerDevice;
                *stop = YES;
            }
        }];
        if (!newTimerDeviceEntity) {
            newTimerDeviceEntity = [NSEntityDescription insertNewObjectForEntityForName:@"TimerDeviceEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];
        }
        newTimerDeviceEntity.timerID = _timerEntity.timerID;
        newTimerDeviceEntity.deviceID = deviceId;
        newTimerDeviceEntity.timerIndex = index;
        [_timerEntity addTimerDevicesObject:newTimerDeviceEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];

        [self.backs addObject:deviceId];
        if ([self.backs count] == [_selectedScene.members count]) {
            if (self.handle) {
                self.handle();
            }
            [_hud hideAnimated:YES];
            _hud = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else {
        if (self.handle) {
            self.handle();
        }
        [_hud hideAnimated:YES];
        _hud = nil;
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        [self showTextHud:[NSString stringWithFormat:@"%@:%@ set timer fail.",AcTECLocalizedStringFromTable(@"Error", @"Localizable"),deviceEntity.name]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
}

- (void)deleteTimerCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *state = [resultDic objectForKey:@"deleteAlarmCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    if ([state boolValue]) {
        [self.deleteTimers enumerateObjectsUsingBlock:^(TimerDeviceEntity *timeDevice, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([timeDevice.deviceID isEqualToNumber:deviceId]) {
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:timeDevice];
                [[CSRDatabaseManager sharedInstance] saveContext];
                if (self.handle) {
                    self.handle();
                }
                [_hud hideAnimated:YES];
                _hud = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
    }else {
        if (self.handle) {
            self.handle();
        }
        [_hud hideAnimated:YES];
        _hud = nil;
        [self showTextHud:[NSString stringWithFormat:@"%@:%@!",AcTECLocalizedStringFromTable(@"Error", @"Localizable"),AcTECLocalizedStringFromTable(@"NotFoundDevice", @"Localizable")]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    
}

- (void)changeAlarmEnabledCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *state = [resultDic objectForKey:@"changeAlarmEnabledCall"];
//    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    if ([state boolValue]) {
        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"Success", @"Localizable")]];
        if (self.handle) {
            self.handle();
        }
    }else {
        [self showTextHud:[NSString stringWithFormat:@"%@",AcTECLocalizedStringFromTable(@"Error", @"Localizable")]];
    }
}

- (IBAction)deleteTimerAction:(UIButton *)sender {
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    
    [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timeDevice, BOOL * _Nonnull stop) {
        if (timeDevice) {
            [[DataModelManager shareInstance] deleteAlarmForDevice:timeDevice.deviceID index:[timeDevice.timerIndex integerValue]];
            [self.deleteTimers addObject:timeDevice];
        }
    }];
    
    [[CSRAppStateManager sharedInstance].selectedPlace removeTimersObject:self.timerEntity];
    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.timerEntity];
    [[CSRDatabaseManager sharedInstance] saveContext];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if (_hud) {
//            if (self.handle) {
//                self.handle();
//            }
//            [_hud hideAnimated:YES];
//            _hud = nil;
//            [self.navigationController popViewControllerAnimated:YES];
//        }
//    });
}

- (IBAction)changeEnabled:(UISwitch *)sender {
    if (!_newadd && _timerEntity) {
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            [[DataModelManager shareInstance] enAlarmForDevice:timerDevice.deviceID stata:sender.on index:[timerDevice.timerIndex integerValue]];
        }];
        
        _timerEntity.enabled = @(sender.on);
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
}

- (NSMutableDictionary *)deviceIdsAndIndexs {
    if (!_deviceIdsAndIndexs) {
        _deviceIdsAndIndexs = [NSMutableDictionary new];
    }
    return _deviceIdsAndIndexs;
}

- (NSMutableArray *)deleteTimers {
    if (!_deleteTimers) {
        _deleteTimers = [NSMutableArray new];
    }
    return _deleteTimers;
}

- (NSMutableArray *)backs {
    if (!_backs) {
        _backs = [NSMutableArray new];
    }
    return _backs;
}

- (NSMutableArray *)deviceIds {
    if (!_deviceIds) {
        _deviceIds = [NSMutableArray new];
    }
    return _deviceIds;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

- (void)showTextHud:(NSString *)text {
    MBProgressHUD *successHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    successHud.mode = MBProgressHUDModeText;
    successHud.label.text = text;
    successHud.label.numberOfLines = 0;
    successHud.delegate = self;
    [successHud hideAnimated:YES afterDelay:2.0f];
}

@end
