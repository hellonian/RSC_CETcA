//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import "CSRShareViewController.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRDeviceEntity.h"
#import "CSRAreaEntity.h"
#import "CSRDatabaseManager.h"
#import <CSRmesh/MeshServiceApi.h>
#import "CSRControllerEntity.h"
#import "CSRPlaceEntity.h"
#import "CSRParseAndLoad.h"
#import "NSData+Encryption.h"
#import "CSRGatewayListViewController.h"

//Cloud
#import <CSRmeshRestClient/CSRRestMeshConfigApi.h>

@interface CSRShareViewController () {
    NSMutableData *allData;
}

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation CSRShareViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Gateway) {
        
        [_getFileFromGatwayOrCloud setTitle:@"Get file from Gateway" forState:UIControlStateNormal];
        
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Cloud) {
        
        [_getFileFromGatwayOrCloud setTitle:@"Get file from Cloud" forState:UIControlStateNormal];
        
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Bluetooth) {
        
        [_getFileFromGatwayOrCloud setTitle:@"Recover from Gateway" forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    NSLog(@"self deviceId :%@", [[MeshServiceApi sharedInstance] getControllerAddress]);
    
    CSRPlaceEntity *placeEntity = [CSRAppStateManager sharedInstance].selectedPlace;
    [[MeshServiceApi sharedInstance] setControllerAddress:placeEntity.hostControllerID];
//    [[MeshServiceApi sharedInstance] setNetworkKey:placeEntity.networkKey];
    
    
    _managedObjectContext = [CSRDatabaseManager sharedInstance].managedObjectContext;
    [[DataModelApi sharedInstance] addDelegate:self];
    allData = [[NSMutableData alloc] init];
}

- (IBAction)getFileFromGateway:(id)sender {
    
    NSString *tenantString = [CSRAppStateManager sharedInstance].selectedPlace.settings.cloudTenancyID;
    CSRGatewayEntity *currentGateway = nil;
    if ([[CSRAppStateManager sharedInstance].selectedPlace.gateways count] > 0) {
        currentGateway = (CSRGatewayEntity *)[[CSRAppStateManager sharedInstance].selectedPlace.gateways anyObject];
    }
    __block NSDictionary *jsonDictionary = [NSDictionary new];
    __block id json;
    if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Gateway) {
        
        [[CSRRestConfig sharedInstance] setServerUrl:CSRRestServerComponent_CONFIG
                                           uriScheme:kGatewayServerUriScheme
                                                host:currentGateway.host
                                                port:[NSString stringWithFormat:@"%@", currentGateway.port]
                                            basePath:[NSString stringWithFormat:@"/cgi-bin%@", kConfigServerBasePath]
                                   connectionChannel:CSRRestConnectionChannel_GATEWAY];
        
        
        
        [[CSRRestMeshConfigApi sharedInstance] getFile:[[NSBundle mainBundle] bundleIdentifier]
                                              tenantId:tenantString
                                              fileName:@"csrmesh_db"
                                       responseHandler:^(NSNumber* meshRequestId, CSRRestGetFileResponse* output, NSError* error, CSRRestErrorResponse *errorResponse){
                                           
                                           if (output) {
                                               
                                               //security
                                               NSData *ivData = [output.content subdataWithRange:NSMakeRange(0, 16)];
                                               NSData *ciper = [output.content subdataWithRange:NSMakeRange(16, (output.content.length - 16))];
                                               NSData *jsonData = [ciper AES256DecryptWithKey:[[MeshServiceApi sharedInstance] getMeshId] iv:ivData];
                                               
                                               NSString *responseString1 = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//                                               NSLog(@"string1 %@", responseString1);
                                               
                                               NSData *dataToParse = [responseString1 dataUsingEncoding:NSUTF8StringEncoding];
                                               json = [NSJSONSerialization JSONObjectWithData:dataToParse options:0 error:nil];

                                            }
                                           
                                           if (!error && json) {
                                               CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
                                               [parseLoad parseIncomingDictionary:json];
                                           } else {
                                               NSLog(@"%@", [error localizedDescription]);
                                           }
                                           
                                       }];
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Cloud) {
        
        [[CSRRestConfig sharedInstance] setServerUrl:CSRRestServerComponent_CONFIG
                                           uriScheme:kGatewayServerUriScheme
                                                host:currentGateway.host
                                                port:[NSString stringWithFormat:@"%@", currentGateway.port]
                                            basePath:[NSString stringWithFormat:@"/cgi-bin%@", kConfigServerBasePath]
                                   connectionChannel:CSRRestConnectionChannel_CLOUD];
        
        
        
        [[CSRRestMeshConfigApi sharedInstance] getFile:[[NSBundle mainBundle] bundleIdentifier]
                                              tenantId:tenantString
                                              fileName:@"csrmesh_db"
                                       responseHandler:^(NSNumber* meshRequestId, CSRRestGetFileResponse* output, NSError* error, CSRRestErrorResponse *errorResponse){
                                           
                                           if (output) {
                                               jsonDictionary = [NSJSONSerialization JSONObjectWithData:output.content options:NSJSONReadingMutableLeaves error:&error];
                                           }
                                           if (!error && jsonDictionary) {
                                               CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
                                               [parseLoad parseIncomingDictionary:jsonDictionary];
                                           } else {
                                               NSLog(@"%@", [error localizedDescription]);
                                           }
                                           
                                           NSLog(@"meshRequestId%@, output%@, error%@, errorResponse%@",meshRequestId, output, error, errorResponse);
                                           
                                       }];
        
    } else if ([CSRAppStateManager sharedInstance].bearerType == CSRSelectedBearerType_Bluetooth) {
     
        [self performSegueWithIdentifier:@"recoverySegue" sender:self];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Alert!!"
                                                                                 message:@"You should be on a Gateway or Cloud to get file"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             
                                                         }];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
        
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"recoverySegue"]) {
        UINavigationController *navController = (UINavigationController*)[segue destinationViewController];
        CSRGatewayListViewController *vc = (CSRGatewayListViewController*)[navController topViewController];
        vc.isRecovery = YES;
    }
}

#pragma mark -
#pragma mark Using Mesh Data Model

//- (IBAction)importUsingMesh:(id)sender {
//    
//    
//}

- (void)didReceiveStreamData:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber data:(NSData *)data
{
    //UI
    _importStatusIndicator.hidden = NO;
    [_importStatusIndicator startAnimating];
    
    if (data) {
        [allData appendData:data];
    }
}

- (void)didReceiveStreamDataEnd:(NSNumber *)deviceId streamNumber:(NSNumber *)streamNumber
{
    //UI
    [_importStatusIndicator stopAnimating];
    _importStatusIndicator.hidden = YES;
    
    NSError *error;
    NSData *uncompressedData = [CSRUtilities uncompressGZip:allData];
    
    NSDictionary *jsonDictionary;
    if (uncompressedData) {
        jsonDictionary = [NSJSONSerialization JSONObjectWithData:uncompressedData options:NSJSONReadingMutableLeaves error:&error];
    }
    
    if (!error && jsonDictionary) {
        CSRParseAndLoad *parseLoad = [[CSRParseAndLoad alloc] init];
        [parseLoad deleteEntitiesInSelectedPlace];
        [parseLoad parseIncomingDictionary:jsonDictionary];
    } else {
        NSLog(@"%@", [error localizedDescription]);
    }
}

@end
