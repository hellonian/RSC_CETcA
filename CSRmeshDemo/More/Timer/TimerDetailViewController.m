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
    BOOL enabled;
    NSDate *time;
    NSDate *date;
    NSString *repeatStr;
    NSLayoutConstraint *top_chooseTitle;
    dispatch_semaphore_t semaphore;
    BOOL reparePop;//当信号量为0时，释放semaphore会引起程序奔溃。
    NSInteger memeberCount;
    
    NSNumber *channeling;
    NSNumber *indexing;
    SceneMemberEntity *sceneMembering;
    
    int sendandreceive;
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
@property (nonatomic,strong) UIView *translucentBgView;

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
    sendandreceive = 0;
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
        if ([sceneEntity.sceneName isEqualToString:@"Home"] || [sceneEntity.sceneName isEqualToString:@"Away"] || [sceneEntity.sceneName isEqualToString:@"Scene1"] || [sceneEntity.sceneName isEqualToString:@"Scene2"] || [sceneEntity.sceneName isEqualToString:@"Scene3"] || [sceneEntity.sceneName isEqualToString:@"Scene4"]) {
            titleLabel.text = AcTECLocalizedStringFromTable(sceneEntity.sceneName, @"Localizable");
        }else {
            titleLabel.text = sceneEntity.sceneName;
        }
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
    if ([scene.sceneName isEqualToString:@"Home"] || [scene.sceneName isEqualToString:@"Away"] || [scene.sceneName isEqualToString:@"Scene1"] || [scene.sceneName isEqualToString:@"Scene2"] || [scene.sceneName isEqualToString:@"Scene3"] || [scene.sceneName isEqualToString:@"Scene4"]) {
        selectedTitleLabel.text = AcTECLocalizedStringFromTable(scene.sceneName, @"Localizable");
    }else {
        selectedTitleLabel.text = scene.sceneName;
    }
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(multichannelAddAlarmCall:) name:@"multichannelAddAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteTimerCall:) name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeAlarmEnabledCall:) name:@"changeAlarmEnabledCall" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSendStreamData:) name:@"didSendStreamData" object:nil];
//    [[MeshServiceApi sharedInstance] setRetryCount:@2];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"addAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"multichannelAddAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"deleteAlarmCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"changeAlarmEnabledCall" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didSendStreamData" object:nil];
//    [[MeshServiceApi sharedInstance] setRetryCount:@6];
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
    if (!_selectedScene) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:AcTECLocalizedStringFromTable(@"mustSelectScene", @"Localizable") preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    _hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10*[_selectedScene.members count] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        
        if ([self.backs count]<[_selectedScene.members count]) {
            NSLog(@"-->>>>> %lu %lu",(unsigned long)[self.backs count],(unsigned long)[_selectedScene.members count]);
            NSString *addFailNames = @"";
            for (SceneMemberEntity *sceneMember in _selectedScene.members) {
                if (![self.backs containsObject:sceneMember.deviceID]) {
                    CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:sceneMember.deviceID];
                    addFailNames = [NSString stringWithFormat:@"%@  %@",addFailNames,deviceEntity.name];
                }
            }
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",addFailNames,AcTECLocalizedStringFromTable(@"notRespond", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
            [alertController.view setTintColor:DARKORAGE];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (self.handle) {
                    self.handle();
                }
                if ([self.backs count]>0) {
                    reparePop = YES;
                    dispatch_semaphore_signal(semaphore);
                    dispatch_semaphore_signal(semaphore);
                }
                NSLog(@"popViewControllerAnimated~>1");
                reparePop = YES;
                dispatch_semaphore_signal(semaphore);
                dispatch_semaphore_signal(semaphore);
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
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
    
    enabled = _enabledSwitch.on;
    
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
    
    semaphore = dispatch_semaphore_create(1);
    dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
    
    for (SceneMemberEntity *sceneMember in _selectedScene.members) {
        sceneMembering = sceneMember;
        NSNumber *timerIndex;
        if (_newadd) {
            timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:sceneMember.deviceID];
        }else {
            __block NSNumber *existTimerIndex;
            [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
                if ([timerDevice.deviceID isEqualToNumber:sceneMember.deviceID]) {
                    existTimerIndex = timerDevice.timerIndex;
                    *stop = YES;
                }
            }];
            if (existTimerIndex) {
                timerIndex = existTimerIndex;
            }else {
                timerIndex = [[CSRDatabaseManager sharedInstance] getNextFreeTimerIDOfDeivice:sceneMember.deviceID];
            }
        }
        indexing = timerIndex;
        [self.deviceIdsAndIndexs setObject:timerIndex forKey:[NSString stringWithFormat:@"%@",sceneMember.deviceID]];
        
        NSString *eveD1 = @"00";
        NSString *eveD2 = @"00";
        NSString *eveD3 = @"00";
        if ([sceneMember.eveType isEqualToNumber:@(13)] || [sceneMember.eveType isEqualToNumber:@(14)] || [sceneMember.eveType isEqualToNumber:@(20)]) {
            eveD1 = [NSString stringWithFormat:@"%@",sceneMember.colorRed];
            eveD2 = [NSString stringWithFormat:@"%@",sceneMember.colorGreen];
            eveD3 = [NSString stringWithFormat:@"%@",sceneMember.colorBlue];
        }else if ([sceneMember.eveType isEqualToNumber:@(18)] || [sceneMember.eveType isEqualToNumber:@(19)]) {
            NSString *colorTemperatureStr = [CSRUtilities stringWithHexNumber:[sceneMember.colorTemperature integerValue]];
            eveD1 = [colorTemperatureStr substringToIndex:2];
            eveD2 = [colorTemperatureStr substringFromIndex:2];
        }
        if ([CSRUtilities belongToTwoChannelDimmer:sceneMember.kindString] || [CSRUtilities belongToSocket:sceneMember.kindString] || [CSRUtilities belongToTwoChannelSwitch:sceneMember.kindString]) {
            if (sceneMember.eveType && [sceneMember.eveType integerValue]>0 && sceneMember.colorTemperature && [sceneMember.colorTemperature integerValue]>0) {
                dispatch_async(queue, ^{
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    if (!reparePop) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            channeling = @(1);
                            [[DataModelManager shareInstance] addAlarmForDevice:sceneMember.deviceID alarmIndex:[timerIndex integerValue] enabled:enabled fireDate:date fireTime:time repeat:repeatStr eveType:sceneMember.eveType level:[sceneMember.level integerValue] eveD1:eveD1 eveD2:eveD2 eveD3:eveD3 channel:@"01"];
                        });
                    }
                });
                
                dispatch_async(queue, ^{
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    if (!reparePop) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            channeling = @(2);
                            [[DataModelManager shareInstance] addAlarmForDevice:sceneMember.deviceID alarmIndex:[timerIndex integerValue] enabled:enabled fireDate:date fireTime:time repeat:repeatStr eveType:sceneMember.colorTemperature level:[sceneMember.colorGreen integerValue] eveD1:eveD1 eveD2:eveD2 eveD3:eveD3 channel:@"02"];
                        });
                    }
                });
            }else {
                if (sceneMember.eveType && [sceneMember.eveType integerValue]>0) {
                    dispatch_async(queue, ^{
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        if (!reparePop) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                channeling = @(1);
                                [[DataModelManager shareInstance] addAlarmForDevice:sceneMember.deviceID alarmIndex:[timerIndex integerValue] enabled:enabled fireDate:date fireTime:time repeat:repeatStr eveType:sceneMember.eveType level:[sceneMember.level integerValue] eveD1:eveD1 eveD2:eveD2 eveD3:eveD3 channel:@"01"];
                            });
                        }
                    });
                }
                if (sceneMember.colorTemperature && [sceneMember.colorTemperature integerValue]>0) {
                    dispatch_async(queue, ^{
                        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                        if (!reparePop) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                channeling = @(2);
                                [[DataModelManager shareInstance] addAlarmForDevice:sceneMember.deviceID alarmIndex:[timerIndex integerValue] enabled:enabled fireDate:date fireTime:time repeat:repeatStr eveType:sceneMember.colorTemperature level:[sceneMember.colorGreen integerValue] eveD1:eveD1 eveD2:eveD2 eveD3:eveD3 channel:@"02"];
                            });
                        }
                    });
                }
            }
        }else {
            dispatch_async(queue, ^{
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if (!reparePop) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[DataModelManager shareInstance] addAlarmForDevice:sceneMember.deviceID alarmIndex:[timerIndex integerValue] enabled:enabled fireDate:date fireTime:time repeat:repeatStr eveType:sceneMember.eveType level:[sceneMember.level integerValue] eveD1:eveD1 eveD2:eveD2 eveD3:eveD3];
                    });
                }
            });
        }
    }
}

- (void)didSendStreamData:(NSNotification *)result {
//    NSDictionary *resultDic = result.userInfo;
//    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    if (sendandreceive==1) {
        dispatch_semaphore_signal(semaphore);
        sendandreceive = 0;
    }else {
        sendandreceive ++;
    }
}

- (void)addTimerToDeviceCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *resultStr = [resultDic objectForKey:@"addAlarmCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    NSLog(@"---->> %@ ::: %@",deviceId,resultStr);
    if (sendandreceive==1) {
        dispatch_semaphore_signal(semaphore);
        sendandreceive = 0;
    }else {
        sendandreceive ++;
    }

    if ([resultStr boolValue]) {
        [self.backs addObject:deviceId];
        _timerEntity = [[CSRDatabaseManager sharedInstance] saveNewTimer:timerIdNumber timerName:name enabled:@(enabled) fireTime:time fireDate:date repeatStr:repeatStr sceneID:_selectedScene.sceneID];
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
        newTimerDeviceEntity.channel = @(10);
        [_timerEntity addTimerDevicesObject:newTimerDeviceEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];

    }else {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        [self showTextHud:[NSString stringWithFormat:@"%@:%@ set timer fail.",AcTECLocalizedStringFromTable(@"Error", @"Localizable"),deviceEntity.name]];
    }
    
    if ([self.backs count] == [_selectedScene.members count]) {
        if (self.handle) {
            self.handle();
        }
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        NSLog(@"popViewControllerAnimated~>2");
        reparePop = YES;
        dispatch_semaphore_signal(semaphore);
        dispatch_semaphore_signal(semaphore);
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void)multichannelAddAlarmCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSNumber *deviceId = resultDic[@"deviceId"];
    NSNumber *channel = resultDic[@"channel"];
    NSNumber *index = resultDic[@"index"];
    NSNumber *state = resultDic[@"state"];
    if (sendandreceive==1) {
        dispatch_semaphore_signal(semaphore);
        sendandreceive = 0;
    }else {
        sendandreceive ++;
    }

    NSLog(@"%@,%@,%@,%@,%@,%@,%@",deviceId,channel,index,state,sceneMembering.deviceID,channeling,indexing);
    if ([state boolValue] && [deviceId isEqualToNumber:sceneMembering.deviceID] && [channel isEqualToNumber:channeling] && [index isEqualToNumber:indexing]) {
        _timerEntity = [[CSRDatabaseManager sharedInstance] saveNewTimer:timerIdNumber timerName:name enabled:@(enabled) fireTime:time fireDate:date repeatStr:repeatStr sceneID:_selectedScene.sceneID];
        NSNumber *index = [self.deviceIdsAndIndexs objectForKey:[NSString stringWithFormat:@"%@",deviceId]];
        __block TimerDeviceEntity *newTimerDeviceEntity;
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timerDevice, BOOL * _Nonnull stop) {
            if ([timerDevice.deviceID isEqualToNumber:deviceId] && [timerDevice.timerIndex isEqualToNumber:index] && [timerDevice.channel isEqualToNumber:channel]) {
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
        newTimerDeviceEntity.channel = channel;
        [_timerEntity addTimerDevicesObject:newTimerDeviceEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];
    }
    if ([sceneMembering.colorTemperature isEqualToNumber:@(10)]||[sceneMembering.colorTemperature isEqualToNumber:@(11)]||[sceneMembering.colorTemperature isEqualToNumber:@(12)]) {
        if ([channel isEqualToNumber:@(2)]) {
            [self.backs addObject:deviceId];
        }
    }else {
        if ([channel isEqualToNumber:@(1)]) {
            [self.backs addObject:deviceId];
        }
    }
    NSLog(@"++>>>>> %lu %lu %@",(unsigned long)[self.backs count],(unsigned long)[_selectedScene.members count],sceneMembering.colorTemperature);
    if ([self.backs count] == [_selectedScene.members count]) {
        if (self.handle) {
            self.handle();
        }
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        NSString *messge = [state boolValue]? AcTECLocalizedStringFromTable(@"timeraddsuccess", @"Localizable"):AcTECLocalizedStringFromTable(@"timeraddfail", @"Localizable");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:messge preferredStyle:UIAlertControllerStyleAlert];
        [alertController.view setTintColor:DARKORAGE];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"popViewControllerAnimated~>3");
            reparePop = YES;
            dispatch_semaphore_signal(semaphore);
            dispatch_semaphore_signal(semaphore);
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [alertController addAction:yesAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
}

- (void)deleteTimerCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *state = [resultDic objectForKey:@"deleteAlarmCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    NSLog(@"---->> %@ ~~~ %@",deviceId,state);
    if (sendandreceive==1) {
        dispatch_semaphore_signal(semaphore);
        sendandreceive = 0;
    }else {
        sendandreceive ++;
    }
    if ([state boolValue]) {
        [self.backs addObject:deviceId];
        [_timerEntity.timerDevices enumerateObjectsUsingBlock:^(TimerDeviceEntity *timeDevice, BOOL * _Nonnull stop) {
            if ([timeDevice.deviceID isEqualToNumber:deviceId]) {
                [_timerEntity removeTimerDevicesObject:timeDevice];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:timeDevice];
                [[CSRDatabaseManager sharedInstance] saveContext];
                *stop = YES;
            }
        }];

    }else {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        [self showTextHud:[NSString stringWithFormat:@"%@:%@ delete timer fail.",AcTECLocalizedStringFromTable(@"Error", @"Localizable"),deviceEntity.name]];
    }
    if ([self.backs count] == memeberCount) {
        [[CSRAppStateManager sharedInstance].selectedPlace removeTimersObject:self.timerEntity];
        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.timerEntity];
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.handle) {
            self.handle();
        }
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        NSLog(@"popViewControllerAnimated~>4");
        reparePop = YES;
        dispatch_semaphore_signal(semaphore);
        dispatch_semaphore_signal(semaphore);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)changeAlarmEnabledCall:(NSNotification *)result {
    NSDictionary *resultDic = result.userInfo;
    NSString *state = [resultDic objectForKey:@"changeAlarmEnabledCall"];
    NSNumber *deviceId = [resultDic objectForKey:@"deviceId"];
    NSLog(@"---->> %@ +++ %@",deviceId,state);
    if (sendandreceive==1) {
        dispatch_semaphore_signal(semaphore);
        sendandreceive = 0;
    }else {
        sendandreceive ++;
    }
    
    if ([state boolValue]) {
        [self.backs addObject:deviceId];
    }else {
        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:deviceId];
        [self showTextHud:[NSString stringWithFormat:@"%@:%@ change enable fail.",AcTECLocalizedStringFromTable(@"Error", @"Localizable"),deviceEntity.name]];
    }
    
    if ([self.backs count] == memeberCount) {
        _timerEntity.enabled = @(![_timerEntity.enabled boolValue]);
        [[CSRDatabaseManager sharedInstance] saveContext];
        if (self.handle) {
            self.handle();
        }
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        NSLog(@"popViewControllerAnimated~>5");
        reparePop = YES;
        dispatch_semaphore_signal(semaphore);
        dispatch_semaphore_signal(semaphore);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (IBAction)deleteTimerAction:(UIButton *)sender {
    [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.mode = MBProgressHUDModeIndeterminate;
    _hud.delegate = self;
    memeberCount = [_timerEntity.timerDevices count];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*memeberCount * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (_hud) {
            [_hud hideAnimated:YES];
            _hud = nil;
        }
        if (_translucentBgView) {
            [_translucentBgView removeFromSuperview];
            _translucentBgView = nil;
        }
        
        if ([self.backs count] < memeberCount) {
            NSString *deleteFailNames = @"";
            for (TimerDeviceEntity *timeDevice in _timerEntity.timerDevices) {
                CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:timeDevice.deviceID];
                deleteFailNames = [NSString stringWithFormat:@"%@  %@",deleteFailNames,deviceEntity.name];
            }
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@ %@",deleteFailNames,AcTECLocalizedStringFromTable(@"notRespond", @"Localizable"),AcTECLocalizedStringFromTable(@"deletetimernow", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
            [alertController.view setTintColor:DARKORAGE];
            
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[CSRAppStateManager sharedInstance].selectedPlace removeTimersObject:self.timerEntity];
                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:self.timerEntity];
                [[CSRDatabaseManager sharedInstance] saveContext];
                if (self.handle) {
                    self.handle();
                }
                if ([self.backs count]>0) {
                    reparePop = YES;
                    dispatch_semaphore_signal(semaphore);
                    dispatch_semaphore_signal(semaphore);
                }
                NSLog(@"popViewControllerAnimated~>6");
                [self.navigationController popViewControllerAnimated:YES];
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Cancel", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (self.handle) {
                    self.handle();
                }
                if ([self.backs count]>0) {
                    reparePop = YES;
                    dispatch_semaphore_signal(semaphore);
                    dispatch_semaphore_signal(semaphore);
                }
                NSLog(@"popViewControllerAnimated~>7");
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [alertController addAction:yesAction];
            [alertController addAction:cancelAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
    });
    
    [self.backs removeAllObjects];
    
    NSLog(@"开始删除，成员个数：%lu",(unsigned long)[_timerEntity.timerDevices count]);
    semaphore = dispatch_semaphore_create(1);
    dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
    for (TimerDeviceEntity *timeDevice in _timerEntity.timerDevices) {
        dispatch_async(queue, ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (!reparePop) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"删除定时器：%@",timeDevice.deviceID);
                    if ([timeDevice.channel isEqualToNumber:@(10)]) {
                        [[DataModelManager shareInstance] deleteAlarmForDevice:timeDevice.deviceID index:[timeDevice.timerIndex integerValue]];
                    }else {
                        [[DataModelManager shareInstance] deleteAlarmForDevice:timeDevice.deviceID channel:[timeDevice.channel integerValue] index:[timeDevice.timerIndex integerValue]];
                    }
                });
            }
        });
    }
}

- (IBAction)changeEnabled:(UISwitch *)sender {
    if (!_newadd && _timerEntity) {
        
        [[UIApplication sharedApplication].keyWindow addSubview:self.translucentBgView];
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
        _hud.delegate = self;
        memeberCount = [_timerEntity.timerDevices count];
        [self.backs removeAllObjects];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2*memeberCount * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_hud) {
                [_hud hideAnimated:YES];
                _hud = nil;
            }
            if (_translucentBgView) {
                [_translucentBgView removeFromSuperview];
                _translucentBgView = nil;
            }
            if ([self.backs count] < memeberCount) {
                NSString *enableFailName = @"";
                for (TimerDeviceEntity *timerDevice in _timerEntity.timerDevices) {
                    if (![self.backs containsObject:timerDevice.deviceID]) {
                        CSRDeviceEntity *deviceEntity = [[CSRDatabaseManager sharedInstance] getDeviceEntityWithId:timerDevice.deviceID];
                        enableFailName = [NSString stringWithFormat:@"%@  %@",enableFailName,deviceEntity.name];
                    }
                }
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:[NSString stringWithFormat:@"%@ %@",enableFailName,AcTECLocalizedStringFromTable(@"notRespond", @"Localizable")] preferredStyle:UIAlertControllerStyleAlert];
                [alertController.view setTintColor:DARKORAGE];
                UIAlertAction *yesAction = [UIAlertAction actionWithTitle:AcTECLocalizedStringFromTable(@"Yes", @"Localizable") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    _timerEntity.enabled = @(![_timerEntity.enabled boolValue]);
                    [[CSRDatabaseManager sharedInstance] saveContext];
                    if (self.handle) {
                        self.handle();
                    }
                    if ([self.backs count]>0) {
                        reparePop = YES;
                        dispatch_semaphore_signal(semaphore);
                        dispatch_semaphore_signal(semaphore);
                    }
                    NSLog(@"popViewControllerAnimated~>8");
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                [alertController addAction:yesAction];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        });
        
        NSLog(@"开始改使能，成员个数：%lu",(unsigned long)[_timerEntity.timerDevices count]);
        semaphore = dispatch_semaphore_create(1);
        dispatch_queue_t queue = dispatch_queue_create("串行", NULL);
        for (TimerDeviceEntity *timerDevice in _timerEntity.timerDevices) {
            dispatch_async(queue, ^{
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                if (!reparePop) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"使能定时器：%@",timerDevice.deviceID);
                        if ([timerDevice.channel isEqualToNumber:@(10)]) {
                            [[DataModelManager shareInstance] enAlarmForDevice:timerDevice.deviceID stata:sender.on index:[timerDevice.timerIndex integerValue]];
                        }else {
                            [[DataModelManager shareInstance] enAlarmForDevice:timerDevice.deviceID stata:sender.on index:[timerDevice.timerIndex integerValue] channel:[timerDevice.channel integerValue]];
                        }
                    });
                }
            });
        }
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

- (UIView *)translucentBgView {
    if (!_translucentBgView) {
        _translucentBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _translucentBgView.backgroundColor = [UIColor blackColor];
        _translucentBgView.alpha = 0.4;
    }
    return _translucentBgView;
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
