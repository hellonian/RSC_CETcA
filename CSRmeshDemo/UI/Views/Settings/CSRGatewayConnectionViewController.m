//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRGatewayConnectionViewController.h"
#import <CSRmesh/CSRIPAddress.h>
#import <CSRmesh/CSRMeshUserManager.h>
#import <CSRmesh/CSRMeshTenant.h>
#import "CSRAppStateManager.h"
#import "CSRDevicesManager.h"
#import "CSRDatabaseManager.h"
#import "CSRPlaceEntity.h"
#import "CSRSettingsEntity.h"
#import "CSRUtilities.h"
#import "CSRMeshUtilities.h"
#import "CSRConstants.h"
#import "CSRBluetoothLE.h"
#import "AFHTTPRequestOperationManager.h"


#import <CSRmeshRestClient/CSRRestMeshConfigApi.h>
#import <CSRmeshRestClient/CSRRestMeshConfigGatewayApi.h>
#import <CSRmeshRestClient/CSRRestCreateTenantRequest.h>
#import <CSRmeshRestClient/CSRRestCreateTenantResponse.h>
#import <CSRmeshRestClient/CSRRestCreateSiteRequest.h>
#import <CSRmeshRestClient/CSRRestCreateSiteResponse.h>

#define  kGatewayDefaultTenantName @"tenant_123"
#define  kGatewayDefaultSiteName @"site_123"

@interface CSRGatewayConnectionViewController () 
{
    CSRSettingsEntity *settings;
    CSRPlaceEntity *place;
    CSRMeshTenant *meshTenant;
    
    NSString *tenantID;
    NSString *siteID;
    NSString *siteName;
    BOOL isUpdateRequired;
    
    NSMutableArray *gatewayUUIDArray;
}

@end

@implementation CSRGatewayConnectionViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //setup references
    settings = [CSRAppStateManager sharedInstance].selectedPlace.settings;
    place = [CSRAppStateManager sharedInstance].selectedPlace;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(associationStatus:)
                                                 name:kCSRmeshManagerIsAssociatingDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAssociateGateway:)
                                                 name:kCSRmeshManagerDidAssociateDeviceNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(associationFailed:)
                                                 name:kCSRmeshManagerDeviceAssociationFailedNotification
                                               object:nil];
    
    isUpdateRequired = NO;
    
    [[CSRAppStateManager sharedInstance].selectedPlace.gateways enumerateObjectsUsingBlock:^(id obj, BOOL * stop) {
        
        if ([((CSRGatewayEntity*)obj).state intValue] == 0 && [((CSRGatewayEntity*)obj).uuid isEqualToString:[_gateway.gatewayUUID lowercaseString]]) {
            
            isUpdateRequired = YES;
            *stop = YES;
        }
    }];
    
    gatewayUUIDArray = [NSMutableArray new];
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    
    self.view.superview.layer.cornerRadius = 0;
    
    [_activityIndicator startAnimating];
    
    [[MeshServiceApi sharedInstance] addDelegate:self];
    
    [self startProcessWithMode:_mode];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[MeshServiceApi sharedInstance] removeDelegate:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerIsAssociatingDeviceNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDidAssociateDeviceNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kCSRmeshManagerDeviceAssociationFailedNotification
                                                  object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Mode

- (void)startProcessWithMode:(CSRGatewayConnectionMode)mode
{
    
    switch (mode) {
            
        case CSRGatewayConnectionMode_All:
            [self connectWithAssociation];
            break;
            
        case CSRGatewayConnectionMode_Local:
//            [self connectLocal];
            [self authenticateGateway];
            break;
            
        case CSRGatewayConnectionMode_Cloud:
            [self connectCloud];
            break;
            
        case CSRGatewayConnectionMode_DeleteGateway:
        {
            if (_gatewayEntity) {
                [self removeGateway];
            }
        }
            break;
            
        case CSRGatewayConnectionMode_DeleteCloud:
        {
//            [self getTenantsAtEndpoint:CSRMeshRestEndpoint_Gateway];
            [self deleteTenantAtEndpoint:CSRMeshRestEndpoint_Gateway];
        }
            break;
            
        default:
            break;
    }
    
}


#pragma mark - Connection methods

- (void)connectWithAssociation
{
    if ([_gateway.addresses count] > 0) {
        
        CSRIPAddress *address = [_gateway.addresses firstObject];
        
        if (address) {
            
            CSRMeshSite *site = [CSRMeshUserManager sharedInstance].site;
            
            [site.meshes addObject:_gateway.gatewayUUID];
        }
        
    }
    [self associateGateway];
}

- (void) authenticateGateway
{
    _stepsLabel.text = @"Authenticating Gateway...";
    
    NSLog(@"current gateway :%@", [CSRAppStateManager sharedInstance].currentGateway);
    
    [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway withMode:CSRMeshRestMode_AUTH];
    [[MeshServiceApi sharedInstance] authenticateRest:[[[UIDevice currentDevice] identifierForVendor] UUIDString] dhmkey:[CSRUtilities reverseData:_gatewayEntity.dhmKey]];
}

-(void) didNotifyAuthenticationState:(CSRRestAuthenticationState) status
{
    switch (status) {
        case CSRRestAuthenticated:
            NSLog(@"Auth completed..[%s]", __PRETTY_FUNCTION__);
            [self connectLocal];
            break;
            
        case CSRRestAuthenticationInProgress:
            NSLog(@"Auth in progress..[%s]", __PRETTY_FUNCTION__);
            break;
            
        case CSRRestAuthenticationExpired:
            NSLog(@"Authentication expired...[%s]", __PRETTY_FUNCTION__);
            [self authenticateGateway];
            break;
            
        default:
            break;
    }
 
}

- (void)connectLocal
{
    [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway withMode:CSRMeshRestMode_Config];
    
    NSSet *gatewaysSet = [CSRAppStateManager sharedInstance].selectedPlace.gateways;
    if (gatewaysSet.count <= 1) {
        
        [self createTenantAtEndpoint:CSRMeshRestEndpoint_Gateway];
        
    } else {
        
        [self setTenantAtEndpoint:CSRMeshRestEndpoint_Gateway];
    }
}

- (void)upgradeToCloud
{
    
}

- (void)connectCloud
{
    
//    [self createTenantAtEndpoint:CSRMeshRestEndpoint_Cloud];
    
    [self connectivityCheck];

}

- (void)removeGateway
{
    
    if (_gatewayEntity && ([_gatewayEntity.state intValue] == 0 || [_gatewayEntity.state intValue] == 1)) {
        
        [self removeNetworkAtEndpoint:CSRMeshRestEndpoint_Gateway];
        
    } else {
        
        // Set bearer to bluetooth
        [[CSRAppStateManager sharedInstance] switchConnectionForSelectedBearerType:CSRSelectedBearerType_Bluetooth];
        
        [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway withMode:CSRMeshRestMode_Config];
        
        [self getTenantsAtEndpoint:CSRMeshRestEndpoint_Gateway];
        
    }
}



- (void)removeNetworkAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    switch (endpoint) {

        case CSRMeshRestEndpoint_Gateway:
        {
            
            _stepsLabel.text = @"Removing network [gateway]";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigGatewayApi sharedInstance] removeNetwork:kAppCode
                                                                 meshId:[CSRMeshUserManager sharedInstance].meshId
                                                        responseHandler:^(NSNumber *meshRequestId, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                            
                                                            if (!error) {
                                                                
                                                                [[CSRAppStateManager sharedInstance].selectedPlace removeGatewaysObject:_gatewayEntity];
                                                                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_gatewayEntity];
                                                                [[CSRDatabaseManager sharedInstance] saveContext];
                                                                
                                                                [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                                                                                    object:nil
                                                                                                                  userInfo:nil];
                                                                
                                                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                    
                                                                    [self dismissViewControllerAnimated:YES completion:nil];
                                                                    
                                                                    [self.presentingViewController dismissViewControllerAnimated:NO completion: ^{
                                                                        
                                                                        [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                                                                        
                                                                    }];
                                                                    
                                                                });
                                                                
                                                            } else {
                                                                
                                                                NSLog(@"Error: %@", error);
                                                                
//
                                                                if (_gatewayEntity && ([_gatewayEntity.state intValue] == 0 || [_gatewayEntity.state intValue] == 1 || [_gatewayEntity.state intValue] == 2)) {
                                                                
//                                                                    [[ConfigModelApi sharedInstance] resetDevice:_gatewayEntity.deviceId];
                                                                    
                                                                    [[CSRAppStateManager sharedInstance].selectedPlace removeGatewaysObject:_gatewayEntity];
                                                                    [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_gatewayEntity];
                                                                    [[CSRDatabaseManager sharedInstance] saveContext];
                                                                    
                                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                                                                                        object:nil
                                                                                                                      userInfo:nil];
                                                                    
                                                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                        
                                                                        [self dismissViewControllerAnimated:YES completion:nil];
                                                                        
                                                                        [self.presentingViewController dismissViewControllerAnimated:NO completion: ^{
                                                                            
                                                                            [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                                                                            
                                                                        }];
                                                                        
                                                                    });
                                                                
                                                                } else {
                                                                    
                                                                    _stepsLabel.text = @"ERROR: Cannot remove network [gateway]";
                                                                    
                                                                }
                                                                
                                                            }
                                                            
                                                        }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            
            _stepsLabel.text = @"Removing network [cloud]";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigGatewayApi sharedInstance] removeNetwork:kAppCode
                                                                 meshId:[CSRMeshUserManager sharedInstance].meshId
                                                        responseHandler:^(NSNumber *meshRequestId, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                            
                                                            if (!error) {
                                                                
                                                                [self deleteTenantAtEndpoint:endpoint];
                                                                
                                                            } else {
                                                                
                                                                NSLog(@"Error: %@", error);
                                                                
                                                                _stepsLabel.text = @"ERROR: Cannot remove network [cloud]";
                                                                
                                                            }
                                                            
                                                        }];
            
        }
            break;
            
        default:
            break;
    }
        
}



#pragma mark - Association

- (void)associateGateway
{
    _stepsLabel.text = @"Associating gateway";
    
    [[MeshServiceApi sharedInstance] setResendInterval:@1000];
    [[MeshServiceApi sharedInstance] setRetryCount:@5];
    
    if (![CSRUtilities isStringEmpty:_gateway.gatewayUUID]) {
        
        NSData *hashData = [[MeshServiceApi sharedInstance] getDeviceHashFromUuid:[CSRMeshUtilities CBUUIDWithFlatUUIDString:_gateway.gatewayUUID]];
        //TODO: make sure about auth code
        [CSRDevicesManager sharedInstance].isDeviceTypeGateway = YES;
        [[CSRDevicesManager sharedInstance] associateDeviceFromCSRDeviceManager:hashData authorisationCode:nil];
        
    }
    
}

#pragma mark - Connectivity

- (void)connectivityCheck
{
    AFHTTPRequestOperationManager *_manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", kCloudServerUriScheme, [CSRAppStateManager sharedInstance].globalCloudHost, kCloudServerPort]]];
    __weak AFHTTPRequestOperationManager *manager = _manager;
    
    NSOperationQueue *operationQueue = manager.operationQueue;
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
     
    {
        switch (status)
        {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                NSSet *gatewaysSet = [CSRAppStateManager sharedInstance].selectedPlace.gateways;
                if (gatewaysSet.count <= 1) {
                    [self setTenantAtEndpoint:CSRMeshRestEndpoint_Cloud];
                    NSLog(@"Site ID DB:%@", place.cloudSiteID);
                } else {
                    [self updateSiteAtEndpoint:CSRMeshRestEndpoint_Cloud];
                    
                }
                [operationQueue setSuspended:YES];
                [_manager.reachabilityManager stopMonitoring];
            }
                break;
                
            case AFNetworkReachabilityStatusNotReachable:
            default:
            {
                
                _stepsLabel.text = @"Gateway connected";
                
                _gatewayEntity.state = @(CSRGateWayState_Local);
                [self setCurrentGatewayAtEndpoint:CSRMeshRestEndpoint_Gateway];
                [[CSRDatabaseManager sharedInstance] saveContext];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                                    object:nil
                                                                  userInfo:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                    
                });
                
                [operationQueue setSuspended:YES];
                [_manager.reachabilityManager stopMonitoring];
                break;
            }
        }
    }];
    
    [_manager.reachabilityManager startMonitoring];
    
}

#pragma mark - Create methods

- (void)createTenantAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            
            _stepsLabel.text = @"Setting up gateway";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint withMode:CSRMeshRestMode_Config];
            
            
            [[CSRMeshUserManager sharedInstance] createTenant:kAppCode
                                                     username:@"SJ21"
                                                      success:^(CSRMeshTenant *tenant) {
                                                          
                                                          meshTenant = tenant;
                                                          settings.cloudTenancyID = meshTenant.tenantId;
                                                          [[CSRDatabaseManager sharedInstance] saveContext];
                                                          [self createSiteWithTenant:meshTenant AtEndpoint:CSRMeshRestEndpoint_Gateway];
                                                          
                                                      }
                                                      failure:^(NSError *error) {
                                                          
                                                          NSLog(@"Error while creating tenant at gateway: %@", error);
                                                          
                                                          _stepsLabel.text = @"ERROR: Cannot create tenant\n in gateway";
                                                          
                                                      }];
            
            
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRMeshUserManager sharedInstance] createTenant:kAppCode
                                                     username:@"SJ21"
                                                      success:^(CSRMeshTenant *tenant) {
                                                          
                                                          meshTenant = tenant;
                                                          
                                                          //save userCloudId to db
                                                          settings.cloudTenancyID = meshTenant.tenantId;
                                                          
                                                      }
                                                      failure:^(NSError *error) {
                                                          
                                                          NSLog(@"Error while creating tenant at cloud: %@", error);
                                                          
                                                          _stepsLabel.text = @"ERROR: Cannot create tenant\n in cloud";
                                                          
                                                      }];
            
        }
            break;
            
        default:
            break;
    }
    
}

- (void)createSiteWithTenant:(CSRMeshTenant *)tenant AtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    NSString *gatewayUUID;
    
    if (_gateway) {
        
        gatewayUUID = _gateway.gatewayUUID;
        
    } else {
        
        gatewayUUID = _gatewayEntity.uuid;
        
    }
    
    switch (endpoint) {

        case CSRMeshRestEndpoint_Gateway:
        {
            [tenant createSite:kAppCode
                      siteName:@"iOS"
                        meshId:[CSRMeshUserManager sharedInstance].meshId
                  gatewayUUIDs:@[gatewayUUID]
                       success:^(NSString *siteId) {
                           
                           _gatewayEntity.state = @2;
                           [[CSRDatabaseManager sharedInstance] saveContext];
                           
                           if (![CSRUtilities isStringEmpty:siteId]) {
                               NSLog(@"Site ID : %@", siteId);
                               
                               place.cloudSiteID = siteId;
                               [[CSRDatabaseManager sharedInstance] saveContext];
                               
                               if (_mode == CSRGatewayConnectionMode_All) {
                               
                                   [self connectivityCheck];
                                   
                               } else {
                                   
                                   _stepsLabel.text = @"Gateway connected";
                                   
                                   _gatewayEntity.state = @2;
                                   [self setCurrentGatewayAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                   [[CSRDatabaseManager sharedInstance] saveContext];
                                   
                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                       
                                       [self dismissViewControllerAnimated:YES completion:nil];
                                       
                                   });
                                   
                               }
                               
                           }
                           
                       }
                       failure:^(NSError *error) {
                           
                           NSLog(@"Error while creating site at cloud: %@", error);
                           
                           _stepsLabel.text = @"ERROR: Cannot create site\n in gateway";
                           
                       }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            [tenant createSite:kAppCode
                      siteName:[CSRAppStateManager sharedInstance].selectedPlace.name
                        meshId:[CSRMeshUserManager sharedInstance].meshId
                  gatewayUUIDs:@[gatewayUUID]
                       success:^(NSString *siteId) {
                           
                           if (![CSRUtilities isStringEmpty:siteId]) {
                               place.cloudSiteID = siteId;
                           }
                           
                       }
                       failure:^(NSError *error) {
                           
                           NSLog(@"Error while creating site at cloud: %@", error);
                           
                           _stepsLabel.text = @"ERROR: Cannot create site\n in cloud";
                           
                       }];
        }
            break;
            
        default:
            break;
    }
    
}

#pragma mark - Get methods

- (void)getTenantsAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            _stepsLabel.text = @"Getting data from gateway";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] getTenants:kAppCode
                                                    queryType:@"find_all"
                                                      pattern:nil
                                                        state:nil
                                                     pageSize:nil
                                                         page:nil
                                                      maximum:nil
                                              responseHandler:^(NSNumber *meshRequestId, CSRRestGetTenantsResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                  
                                                  if (!error) {
                                                      
                                                      NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output.tenants);
                                                      
                                                      
                                                      if ([output.tenants count] > 0) {
                                                          
                                                          if (_mode == CSRGatewayConnectionMode_DeleteCloud || _mode == CSRGatewayConnectionMode_DeleteGateway) {
                                                              
                                                              [self deleteTenantAtEndpoint:endpoint];
                                                              
                                                          }
                                                          
                                                          
                                                      } else {
                                                          
                                                          [self createTenantAtEndpoint:endpoint];
                                                          
                                                      }
                                                      
                                                      
                                                  } else {
                                                      
                                                      NSLog(@"%@", error);
                                                      
                                                      if (_mode == CSRGatewayConnectionMode_DeleteGateway || _mode == CSRGatewayConnectionMode_DeleteCloud) {
                                                          
                                                          [self deleteTenantAtEndpoint:endpoint];
                                                          
                                                      } else {
                                                          
                                                          tenantID = @"";
                                                          _stepsLabel.text = @"ERROR: Cannot get tenants from gateway";
                                                          [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint
                                                                                                             withMode:CSRMeshRestMode_CNC];
                                                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                              
                                                              [self dismissViewControllerAnimated:YES completion:nil];
                                                          });
                                                          
                                                      }
                                                      
                                                  }
                                                  
                                              }];
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] getTenants:kAppCode
                                                    queryType:@"find_all"
                                                      pattern:nil
                                                        state:nil
                                                     pageSize:nil
                                                         page:nil
                                                      maximum:nil
                                              responseHandler:^(NSNumber *meshRequestId, CSRRestGetTenantsResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                  
                                                  if (!error) {
                                                      NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output);
                                                      
//                                                      tenantID = ((CSRRestTenantInfoResponse *)[output.tenants firstObject]).tenantId;
                                                      
//                                                      [self getSitesAtEndpoint:endpoint];
                                                      
                                                  } else {
                                                      
                                                      NSLog(@"%@", error);
                                                      tenantID = @"";
                                                      _stepsLabel.text = @"ERROR: Cannot get tenants from cloud";
                                                      
                                                  }
                                                  
                                              }];
        }
            break;
            
        default:
            break;
    }
    
}

- (void)getSitesAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] getSites:kAppCode
                                                   tenantId:settings.cloudTenancyID
                                                  queryType:@"find_all"
                                                    pattern:nil
                                                      state:nil
                                                   pageSize:nil
                                                       page:nil
                                                    maximum:nil
                                            responseHandler:^(NSNumber *meshRequestId, CSRRestGetSitesResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                
                                                if (!error) {
                                                    NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output);
                                                    
                                                    _stepsLabel.text = @"Deleting gateway from cloud";
                                                    
                                                    if ([output.sites count] > 0) {
                                                        
                                                        siteID = ((CSRRestSiteInfoResponse *)[output.sites firstObject]).siteId;
                                                        siteName = ((CSRRestSiteInfoResponse *)[output.sites firstObject]).name;
                                                        
                                                        if (_mode == CSRGatewayConnectionMode_DeleteCloud) {
                                                            
                                                            [self deleteTenantAtEndpoint:endpoint];
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                } else {
                                                    
                                                    NSLog(@"Error: %@", error);
                                                    siteID = @"";
                                                    siteName = @"";
                                                    _stepsLabel.text = @"ERROR: Cannot get sites from gateway";
                                                    
                                                }
                                                
                                            }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] getSites:kAppCode
                                                   tenantId:settings.cloudTenancyID
                                                  queryType:@"find_all"
                                                    pattern:nil
                                                      state:nil
                                                   pageSize:nil
                                                       page:nil
                                                    maximum:nil
                                            responseHandler:^(NSNumber *meshRequestId, CSRRestGetSitesResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                
                                                if (!error) {
                                                    NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output);
                                                    
                                                    siteID = ((CSRRestSiteInfoResponse *)[output.sites firstObject]).siteId;
                                                    siteName = ((CSRRestSiteInfoResponse *)[output.sites firstObject]).name;
                                                    
                                                    if (_mode == CSRGatewayConnectionMode_DeleteCloud) {
                                                        _stepsLabel.text = @"Deleting gateway from cloud";
                                                        [self deleteTenantAtEndpoint:endpoint];
                                                    }
                                                    
                                                } else {
                                                    
                                                    NSLog(@"Error: %@", error);
                                                    siteID = @"";
                                                    siteName = @"";
                                                    _stepsLabel.text = @"ERROR: Cannot get sites from cloud";
                                                    
                                                }
                                                
                                            }];
            
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - Set methods

- (void)setTenantAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway withMode:CSRMeshRestMode_Config];
            
            [[CSRMeshUserManager sharedInstance] setTenant:kAppCode
                                                  tenantId:settings.cloudTenancyID
                                                   success:^(CSRMeshTenant *tenant) {
                                                       
                                                       if (tenant) {
                                                           
//                                                           if (isUpdateRequired) {
//                                                               
//                                                               [self updateSiteGatewayRequestWithTenant:tenant];
//                                                               
//                                                           } else {
//                                                               
                                                               [self setSiteForTenant:tenant atEndpoint:CSRMeshRestEndpoint_Gateway];
//
//                                                           }
                                                           
                                                       }
                                                       
                                                   } failure:^(NSError *error) {
                                                       
                                                       NSLog(@"Error while creating tenant at gateway: %@", error);
                                                       
                                                       _stepsLabel.text = @"ERROR: Cannot create tenant in gateway";
                                                       
                                                   }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            
            _stepsLabel.text = @"Setting up cloud";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud withMode:CSRMeshRestMode_Config];
            
            [[CSRMeshUserManager sharedInstance] setTenant:kAppCode
                                                  tenantId:settings.cloudTenancyID
                                                   success:^(CSRMeshTenant *tenant) {
                                                       
                                                       if (tenant) {
                                                           [self setSiteForTenant:tenant atEndpoint:CSRMeshRestEndpoint_Cloud];
                                                           
                                                       }
                                                       
                                                   } failure:^(NSError *error) {
                                                       
                                                       NSLog(@"Error while creating tenant at cloud: %@", error);
                                                       
                                                       _stepsLabel.text = @"ERROR: Cannot create tenant in cloud";
                                                       
                                                       [self setCurrentGatewayAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                                       
                                                   }];
            
        }
            break;
            
        default:
            break;
    }
}

- (void)setSiteForTenant:(CSRMeshTenant *)tenant atEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    NSString *gatewayUUID;
    
    if (_gateway) {
        
        gatewayUUID = _gateway.gatewayUUID;
        
    } else {
        
        gatewayUUID = _gatewayEntity.uuid;
        
    }
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint
                                                               withMode:CSRMeshRestMode_Config];
            
            [tenant setSite:kAppCode
                     siteId:place.cloudSiteID
                     meshId:[CSRMeshUserManager sharedInstance].meshId
               gatewayUUIDs:@[gatewayUUID]
                    success:^(NSString *siteId) {
                        
                        _gatewayEntity.state = @2;
                        [[CSRDatabaseManager sharedInstance] saveContext];
                        
                        if (![CSRUtilities isStringEmpty:siteId]) {

                            if (_mode == CSRGatewayConnectionMode_All) {
                                
                                [self connectivityCheck];
                                
                            } else {
                                
                                _stepsLabel.text = @"Gateway connected";
                                
                                _gatewayEntity.state = @2;
                                [self setCurrentGatewayAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                [[CSRDatabaseManager sharedInstance] saveContext];
                                
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                    
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                    
                                });
                                
                            }
                        }

                        
                    } failure:^(NSError *error) {
                        
                        NSLog(@"Error while creating site at gateway: %@", error);
                        
                        _stepsLabel.text = @"ERROR: Cannot set tenant in gateway";
                        
                    }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint withMode:CSRMeshRestMode_Config];
            
            [tenant setSite:kAppCode
                     siteId:[place.cloudSiteID lowercaseString]
                     meshId:[CSRMeshUserManager sharedInstance].meshId
               gatewayUUIDs:@[gatewayUUID]
                    success:^(NSString *siteId) {
                        
                        
                        if (![CSRUtilities isStringEmpty:siteId]) {
                            
                            _stepsLabel.text = @"Cloud configured";
                            _gatewayEntity.state = @3;
                            [self setCurrentGatewayAtEndpoint:endpoint];
                            [[CSRDatabaseManager sharedInstance] saveContext];
                            
                        }
                        
                    } failure:^(NSError *error) {
                        
                        NSLog(@"Error while creating site on cloud: %@", error);
                        
                        _stepsLabel.text = @"ERROR: Cannot set tenant in cloud";
                        
                    }];
        }
            break;
            
        default:
            break;
    }
    
}


#pragma mark - Update methods

- (void)updateSiteAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    if (!meshTenant) {
        
        meshTenant = [[CSRMeshTenant alloc] initWith:settings.cloudTenancyID name:kGatewayDefaultTenantName state:@"active"];
        
    }
    
    NSString *gatewayUUID;
    
    if (_gateway) {
        
        gatewayUUID = _gateway.gatewayUUID;
        
    } else {
        
        gatewayUUID = _gatewayEntity.uuid;
        
    }
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway withMode:CSRMeshRestMode_Config];
            
            _stepsLabel.text = @"Update Gateway with UUID";
            
            [[CSRRestMeshConfigApi sharedInstance] updateSite:kAppCode
                                                     tenantId:settings.cloudTenancyID
                                                       siteId:place.cloudSiteID
                                        updateSiteInfoRequest:[[CSRRestUpdateSiteInfoRequest alloc] initWithValues:@{@"name":[CSRAppStateManager sharedInstance].selectedPlace.name, @"state":@"active", @"meshes":@[@{@"mesh_id": [CSRMeshUserManager sharedInstance].meshId, @"gateways_uuid":@[gatewayUUID]}]}]
                                              responseHandler:^(NSNumber *meshRequestId, CSRRestSiteInfoResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                  
                                                  if (!error) {
                                                      
                                                      NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output);
                                                      
                                                  } else {
                                                      
                                                      NSLog(@"Error while updating site at gateway: %@", error);
                                                      
                                                      _stepsLabel.text = @"ERROR: Cannot update site in gateway";
                                                      
                                                  }
                                              }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud withMode:CSRMeshRestMode_Config];
            
            _stepsLabel.text = @"Update Cloud with UUID";
            NSSet *gatewaysSet = [CSRAppStateManager sharedInstance].selectedPlace.gateways;
            [gatewaysSet enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
                CSRGatewayEntity *gE = (CSRGatewayEntity *)obj;
                    [gatewayUUIDArray addObject:gE.uuid];
            }];
           
            NSDictionary *meshDict = @{@"mesh_id": [CSRMeshUserManager sharedInstance].meshId, @"gateways_uuid":gatewayUUIDArray};
           
            [[CSRRestMeshConfigApi sharedInstance] updateSite:kAppCode
                                                     tenantId:settings.cloudTenancyID
                                                       siteId:place.cloudSiteID
                                        updateSiteInfoRequest:[[CSRRestUpdateSiteInfoRequest alloc] initWithValues:@{@"name":kGatewayDefaultSiteName, @"state":@"active", @"meshes":@[meshDict]}]
                                              responseHandler:^(NSNumber *meshRequestId, CSRRestSiteInfoResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                  
                                                  
                                                  if (!error) {
                                                      if (_mode == CSRGatewayConnectionMode_DeleteCloud) {
                                                          
                                                      } else {
                                                          _gatewayEntity.state = @3;
                                                          [self setCurrentGatewayAtEndpoint:endpoint];
                                                          [[CSRDatabaseManager sharedInstance] saveContext];
                                                          
                                                      }

                                                  
                                                  } else {
                                                      
                                                      NSLog(@"Error while updating site at gateway: %@", error);
                                                      
                                                      _stepsLabel.text = @"ERROR: Cannot update site in cloud";
                                                      
                                                  }
                                              }];
            
        }
            break;
            
        default:
            break;
    }
    
}



- (void)updateTenantAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    if (!meshTenant) {
        
        meshTenant = [[CSRMeshTenant alloc] initWith:settings.cloudTenancyID
                                                name:kGatewayDefaultTenantName
                                               state:@"active"];
    }
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
            _stepsLabel.text = @"Updating tenant [gateway]";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Gateway
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] updateTenant:kAppCode
                                                       tenantId:settings.cloudTenancyID
                                        updateTenantInfoRequest:[[CSRRestUpdateTenantInfoRequest alloc] initWithValues:@{@"name":kGatewayDefaultTenantName, @"state": @"active"}]
                                                responseHandler:^(NSNumber *meshRequestId, CSRRestTenantInfoResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                    
                                                    if (!error) {
                                                        
                                                        NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output);
                                                        
//                                                        [self updateSiteGatewayRequestWithTenant:meshTenant];
                                                        
                                                    } else {
                                                        
                                                        NSLog(@"Error: %@", error);
                                                        
                                                        NSLog(@"Error while updating tenant at gateway: %@ | \n Trying creating tenant ...", error);
                                                        
                                                        _stepsLabel.text = @"ERROR: Cannot update tenant in gateway, trying to create one...";
                                                        
//                                                        [self createSiteGatewayRequestWithTenant:meshTenant];
                                                        
                                                    }
                                                    
                                                }];
        }
            break;
             
             
        case CSRMeshRestEndpoint_Cloud:
        {
            _stepsLabel.text = @"Updating tenant [cloud]";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud
                                                               withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] updateTenant:kAppCode
                                                       tenantId:settings.cloudTenancyID
                                        updateTenantInfoRequest:[[CSRRestUpdateTenantInfoRequest alloc] initWithValues:@{@"name":kGatewayDefaultTenantName, @"state": @"active"}]
                                                responseHandler:^(NSNumber *meshRequestId, CSRRestTenantInfoResponse *output, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                    
                                                    if (!error) {
                                                        
                                                        NSLog(@"meshRequestId: %@, response: %@", meshRequestId, output);
                                                        
//                                                        [self updateSiteGatewayRequestWithTenant:meshTenant];
                                                        
                                                    } else {
                                                        
                                                        NSLog(@"Error: %@", error);
                                                        
                                                        NSLog(@"Error while updating tenant at gateway: %@ | \n Trying creating tenant ...", error);
                                                        
                                                        _stepsLabel.text = @"ERROR: Cannot update tenant in gateway, trying to create one...";
                                                        
//                                                        [self createSiteGatewayRequestWithTenant:meshTenant];
                                                        
                                                    }
                                                    
                                                }];
        }
            break;
            
        default:
            break;
    }
    
}




#pragma mark - Delete methods

- (void)deleteTenantAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    
    switch (endpoint) {
            
        case CSRMeshRestEndpoint_Gateway:
        {
//            _stepsLabel.text = @"Deleting tenant in gateway";
            
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] deleteTenant:kAppCode
                                                       tenantId:settings.cloudTenancyID
                                                responseHandler:^(NSNumber *meshRequestId, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                    
                                                    if (!error) {
                                                        
                                                        NSLog(@"meshRequestId: %@", meshRequestId);
                                                        
                                                        if ([_gatewayEntity.state intValue] == 3) {
                                                            NSSet *gateways = [CSRAppStateManager sharedInstance].selectedPlace.gateways;
                                                            if (gateways.count > 1) {
                                                                [self removeNetworkAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                                                [[CSRAppStateManager sharedInstance].selectedPlace removeGatewaysObject:_gatewayEntity];
                                                                [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_gatewayEntity];
                                                                [[CSRDatabaseManager sharedInstance] saveContext];

                                                                [self updateSiteAtEndpoint:CSRMeshRestEndpoint_Cloud];
                                                            } else {
                                                                [self deleteTenantAtEndpoint:CSRMeshRestEndpoint_Cloud];
                                                            }
                                                        } else {
                                                            
                                                            [self removeNetworkAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                                            [[CSRAppStateManager sharedInstance].selectedPlace removeGatewaysObject:_gatewayEntity];
                                                            [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_gatewayEntity];
                                                            [[CSRDatabaseManager sharedInstance] saveContext];
                                                            
                                                            [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                                                                                object:nil
                                                                                                              userInfo:nil];
                                                            
                                                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                
                                                                [self dismissViewControllerAnimated:YES completion:nil];
                                                                
                                                                [self.presentingViewController dismissViewControllerAnimated:NO completion: ^{
                                                                    
                                                                    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                                                                    
                                                                }];
                                                                
                                                            });

                                                        }
                                                        
//
                                                       
//                                                        [self removeNetworkAtEndpoint:CSRMeshRestEndpoint_Cloud];
                                                        
                                                    } else {
                                                        
                                                        NSLog(@"Error: %@ response: %@", error, errorResponse);
                                                        
                                                        _stepsLabel.text = @"ERROR: Cannot delete tenant in gateway";
                                                        
                                                        [self removeNetworkAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                                        
                                                    }
                                                    
                                                }];
            
        }
            break;
            
        case CSRMeshRestEndpoint_Cloud:
        {
            [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:endpoint withMode:CSRMeshRestMode_Config];
            
            [[CSRRestMeshConfigApi sharedInstance] deleteTenant:kAppCode
                                                       tenantId:settings.cloudTenancyID
                                                responseHandler:^(NSNumber *meshRequestId, NSError *error, CSRRestErrorResponse *errorResponse) {
                                                    
                                                    if (!error) {
                                                        
                                                        _stepsLabel.text = @"Gateway removed";
                                                        
                                                        [self removeNetworkAtEndpoint:CSRMeshRestEndpoint_Gateway];
                                                        [[CSRAppStateManager sharedInstance].selectedPlace removeGatewaysObject:_gatewayEntity];
                                                        [[CSRDatabaseManager sharedInstance].managedObjectContext deleteObject:_gatewayEntity];
                                                        [[CSRDatabaseManager sharedInstance] saveContext];
                                                        
                                                        [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                                                                            object:nil
                                                                                                          userInfo:nil];
                                                        
                                                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                        
                                                        [self dismissViewControllerAnimated:YES completion:nil];
                                                        
                                                            [self.presentingViewController dismissViewControllerAnimated:NO completion: ^{
                                                                
                                                                [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                                                                
                                                            }];
                                                            
                                                        });
                                                        
                                                    } else {
                                                        
                                                        NSLog(@"Error: %@ response: %@", error, errorResponse);
                                                        _stepsLabel.text = @"ERROR: Cannot delete tenant in cloud";
                                                        
                                                    }
                                                    
                                                }];
        }
            break;
            
        default:
            break;
    }
    
    
    
}

#pragma mark - Saving

- (void)saveGatewaytoDBWithDeviceID:(NSNumber *)deviceID andDeviceHash:(NSData *)deviceHash andDHMKey:(NSData *)dhmKey
{
    _stepsLabel.text = @"Saving gateway";
    
    if (_gateway) {

        _gatewayEntity = [NSEntityDescription insertNewObjectForEntityForName:@"CSRGatewayEntity" inManagedObjectContext:[CSRDatabaseManager sharedInstance].managedObjectContext];

        _gatewayEntity.uuid = [((CBUUID *)[CSRMeshUtilities CBUUIDWithFlatUUIDString:_gateway.gatewayUUID]).UUIDString lowercaseString]; //convert CBUUID to UUID NSString
        _gatewayEntity.basePath = _gateway.basePath;
        _gatewayEntity.host = ((CSRIPAddress *)[_gateway.addresses firstObject]).ipAddress;
        _gatewayEntity.name = _gateway.name;
        _gatewayEntity.port = @(((CSRIPAddress *)[_gateway.addresses firstObject]).portNumber);
        _gatewayEntity.deviceId = deviceID;
        _gatewayEntity.state = @1;
        _gatewayEntity.deviceHash = deviceHash;
        _gatewayEntity.dhmKey = dhmKey;

        [place addGatewaysObject:_gatewayEntity];

        [[CSRDatabaseManager sharedInstance] saveContext];
        
    }
    [CSRAppStateManager sharedInstance].currentGateway = nil;
    [[CSRAppStateManager sharedInstance] setCurrentGateway:_gatewayEntity];

}

- (void)setCurrentGatewayAtEndpoint:(CSRMeshRestEndpoint)endpoint
{
    _stepsLabel.text = @"Almost there";
    
   [self getSitesAtEndpoint:CSRMeshRestEndpoint_Cloud];
    
    [[CSRAppStateManager sharedInstance] setupCloudWithEndpoint:CSRMeshRestEndpoint_Cloud withMode:CSRMeshRestMode_CNC];

    
    _stepsLabel.text = @"Ready for use";
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                        object:nil
                                                      userInfo:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        
    });
    
}

#pragma mark - Notifications

- (void)associationStatus:(NSNotification *)notification
{
    
    NSNumber *completedSteps = notification.userInfo[kStepsCompletedString];
    NSNumber *totalSteps = notification.userInfo[kTotalStepsString];
    
    if ([completedSteps floatValue] <= [totalSteps floatValue] && [completedSteps floatValue] > 0) {
        
        _stepsLabel.text = [NSString stringWithFormat:@"Associating gateway: %.0f%%", ([completedSteps floatValue]/[totalSteps floatValue] * 100)];
        
    }
    
}

- (void)didAssociateGateway:(NSNotification *)notification
{
    
    NSNumber *deviceID = notification.userInfo[kDeviceIdString];
    NSData *devicehash = notification.userInfo[kDeviceHashString];
    NSData *dhmKey = notification.userInfo[kDeviceDHMString];
    
    [self saveGatewaytoDBWithDeviceID:deviceID andDeviceHash:devicehash andDHMKey:dhmKey];
    
    [self authenticateGateway];
    
}

- (void)associationFailed:(NSNotification *)notification
{
    _stepsLabel.text = @"Association failed. Please reset gateway.";
    [_activityIndicator stopAnimating];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    });
    
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSRGatewayConnectionStatusChangedNotification
                                                        object:nil
                                                      userInfo:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
