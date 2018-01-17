//
//  QRCodeGenerateVC.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/10/10.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "QRCodeGenerateVC.h"
#import "SGQRCode.h"
#import "CSRAppStateManager.h"
#import "KeyChainDataManager.h"
#import "MySQLDatabaseTool.h"
#import "CSRDeviceEntity.h"
#import "CSRParseAndLoad.h"
#import "CSRUtilities.h"
#import "PureLayout.h"

@interface QRCodeGenerateVC ()
{
    NSString *uuidInKeyChain;
}

@property (weak, nonatomic) IBOutlet UIImageView *QRCode;

@end

@implementation QRCodeGenerateVC

static NSString * const sceneListKey = @"com.actec.bluetooth.sceneListKey";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    uuidInKeyChain = [KeyChainDataManager readUUID];
    if (!uuidInKeyChain) {
        uuidInKeyChain = [[UIDevice currentDevice].identifierForVendor UUIDString];
        [KeyChainDataManager saveUUID:uuidInKeyChain];
    }
    
    NSData *uuidData = [uuidInKeyChain dataUsingEncoding:NSUTF8StringEncoding];
    _QRCode.image = [SGQRCodeGenerateManager generateWithDefaultQRCodeData:uuidData imageViewWidth:200];
    
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = [UIColor whiteColor];
    bgView.alpha = 0.5;
    [self.view addSubview:bgView];
    [bgView autoPinEdgesToSuperviewEdges];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [UIColor blackColor];
    [bgView addSubview:spinner];
    [spinner autoCenterInSuperview];
    [spinner startAnimating];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        
        [self upload];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [spinner stopAnimating];
            [bgView removeFromSuperview];
        });
        
    });
    
    
    
}

- (void)upload {
    MySQLDatabaseTool *tool = [[MySQLDatabaseTool alloc] init];
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    NSString *jsonString;
    if (jsonData) {
        jsonString = [CSRUtilities stringFromData:jsonData];
    }
    
    [tool insertWithUuid:uuidInKeyChain data:jsonString];
    
    
    [tool endConnect];
    
    
    
    /*
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_async(group, queue, ^{
        CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
        NSData *jsonData = [parseLoad composeDatabase];
        
        if (jsonData) {
            NSString *jsonString = [CSRUtilities stringFromData:jsonData];
            [tool insertWithUuid:uuidInKeyChain LampData:jsonString];
        }
    });
    
    dispatch_group_async(group, queue, ^{
        NSDictionary *list = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"com.actec.bluetooth.visualControlKey"];
        if (list) {
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:list options:0 error:&error];
            NSString *jsonString = [CSRUtilities stringFromData:jsonData];
            [tool insertWithUuid:uuidInKeyChain GalleryData:jsonString];
        }
    });
    
    dispatch_group_notify(group, queue, ^{
        [tool endConnect];
    });
    */
    
}

//二进制数据转十六进制字符串
- (NSString *)hexStringForData: (NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
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
