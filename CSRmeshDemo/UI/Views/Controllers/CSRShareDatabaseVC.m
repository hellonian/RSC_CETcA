//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRShareDatabaseVC.h"
#import "CSRParseAndLoad.h"
#import "CSRPlaceEntity.h"
#import "CSRUtilities.h"
#import "CSRAppStateManager.h"
#import "ZipArchive.h"
#import <CSRmesh/DataModelApi.h>
#import "CSRAppStateManager.h"
#import <CSRmesh/CSRMeshUserManager.h>
#import "CSRSettingsEntity.h"

@interface CSRShareDatabaseVC ()

@end

@implementation CSRShareDatabaseVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _dataTransferView.hidden = YES;
    _sharingOptionPickerView.hidden = NO;
    
    [[DataModelApi sharedInstance] addDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareUsingThirdParty:(id)sender {
    
    CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
    NSData *jsonData = [parseLoad composeDatabase];
    
    NSError *error;
    NSString *jsonString;
    if (jsonData) {
        jsonString = [CSRUtilities stringFromData:jsonData];
    } else {
        NSLog(@"Got an error while NSJSONSerialization:%@", error);
    }
    
    CSRPlaceEntity *placeEntity = [[CSRAppStateManager sharedInstance] selectedPlace];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* dPath = [paths objectAtIndex:0];
    NSString* zipfile = [dPath stringByAppendingPathComponent:@"test.zip"] ;
    
    NSString *appFile = [NSString stringWithFormat:@"%@_%@", placeEntity.name, @"Database.qti"];
    NSString *realPath = [dPath stringByAppendingPathComponent:appFile] ;
    [jsonString writeToFile:realPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    
    ZipArchive* zip = [[ZipArchive alloc] init];
    if([zip CreateZipFile2:zipfile Password:[[MeshServiceApi sharedInstance] getMeshId]])
    {
        NSLog(@"Zip File Created");
        if([zip addFileToZip:realPath newname:@"MyFile.qti"])
        {
            NSLog(@"File Added to zip");
        }
    }
    
    NSURL *jsonURL = [NSURL fileURLWithPath:zipfile];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[jsonURL] applicationActivities:nil];
    [activityVC setValue:@"JSON Attached" forKey:@"subject"];
    
    activityVC.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (completed) {
            NSLog(@"Activity completed");
        } else {
            if (activityType == NULL) {
                NSLog(@"User dismissed the view controller without making a selection");
            } else {
                NSLog(@"Activity was not performed");
            }
        }
    };
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        
        activityVC.popoverPresentationController.sourceView = self.parentVC.view;
        [self dismissViewControllerAnimated:NO completion:nil];
        [self.parentVC presentViewController:activityVC animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:NO completion:nil];
        [self.parentVC presentViewController:activityVC animated:YES completion:nil];
    }
}

- (IBAction)cancelTransferOfData:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveBlockData:(NSNumber *)deviceId data:(NSData *)data
{
    NSLog(@"receiving data for data model");
}

- (void) didReceiveStreamData:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber data:(NSData *)data
{
    NSLog(@"Receiving stream data for data model");
}

- (void)didReceiveStreamDataEnd:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Steps animation

- (void)animateStepsBetweenFirstView:(UIView *)firstView andSecondView:(UIView *)secondView
{
    [secondView setTransform:(CGAffineTransformMakeScale(0.8f, 0.8f))];
    secondView.alpha = 0.f;
    secondView.hidden = NO;
    
    [UIView animateWithDuration:0.5
                          delay:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         firstView.alpha = 0.f;
                         [firstView setTransform:(CGAffineTransformMakeScale(1.2f, 1.2f))];
                         
                         secondView.alpha = 1.f;
                         [secondView setTransform:(CGAffineTransformMakeScale(1.0f, 1.0f))];
                         
                     } completion:^(BOOL finished) {
                         firstView.hidden = YES;
                         
                     }];
}


@end
