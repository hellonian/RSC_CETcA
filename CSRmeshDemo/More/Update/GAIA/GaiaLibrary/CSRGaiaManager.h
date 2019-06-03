//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import "CSRGaia.h"
#import "CSRBluetoothLE.h"

#define CSRGaiaError                    @"Aborting the Update"
#define CSRGaiaError_1                  @"Unknown command"
#define CSRGaiaError_2                  @"Bad length"
#define CSRGaiaError_3                  @"Wrong variant"
#define CSRGaiaError_4                  @"Wrong partition number"
#define CSRGaiaError_5                  @"Partition size mismatch"
#define CSRGaiaError_6                  @"Partition type not found"
#define CSRGaiaError_7                  @"Partition open failed"
#define CSRGaiaError_8                  @"Partition write failed"
#define CSRGaiaError_9                  @"Partition close failed"
#define CSRGaiaError_10                 @"SFS validation failed"
#define CSRGaiaError_11                 @"OEM validation failed"
#define CSRGaiaError_12                 @"Update failed"
#define CSRGaiaError_13                 @"App not ready"
#define CSRGaiaError_14                 @"App configuration version incompatible"
#define CSRGaiaError_15                 @"Loader error"
#define CSRGaiaError_16                 @"Unexpected loader error"
#define CSRGaiaError_17                 @"Missing loader error"
#define CSRGaiaError_18                 @"Battery low error"
#define CSRGaiaError_Unknown            @"Unknown error: %ld"
#define CSRGaiaError_UnknownResponse    @"Unknown response from Sync Request: %ld"

#define CSRGaiaCommandError_1           @"An invalid Command ID was specified"
#define CSRGaiaCommandError_2           @"The host is not authenticated to use a Command ID orcontrol a Feature Type"
#define CSRGaiaCommandError_3           @"The command was valid, but the device could not successfully carry out the command"
#define CSRGaiaCommandError_4           @"The device is in the process of authenticating the host"
#define CSRGaiaCommandError_5           @"An invalid parameter was used in the command"
#define CSRGaiaCommandError_6           @"The device is not in the correct state to process the command"
#define CSRGaiaCommandError_7           @"The command is already in progress"

#define CSRStatusReconnectingString     @"Reconnecting..."
#define CSRStatusReconnectedString      @"Reconnected. Initialising..."
#define CSRStatusPairingString          @"Initialised."
#define CSRStatusFinalisingString       @"Finalising..."
#define CSRStatusReStartingString       @"Restarting update..."

/*!
 @header CSRGaiaManager
 Manage long running operations
 */

@protocol CSRUpdateManagerDelegate;

/*!
 @class CSRGaiaManager
 @abstract Singleton class that manages long running operations
 @discussion The connection manager implements CSRGaiaDelegate and CSRConnectionManagerDelegate
 */
@interface CSRGaiaManager : NSObject <CSRGaiaDelegate, CSRBluetoothLEDelegate>

/// @brief True of an OTAU is in progress
@property (nonatomic) BOOL updateInProgress;

/// @brief The name of the file being used for OTAU
@property (nonatomic) NSString *updateFileName;

/// @brief A percentage complete value
@property (nonatomic) double updateProgress;

/// @brief Delegate class for callbacks.
@property (nonatomic, weak) id<CSRUpdateManagerDelegate> delegate;

/*!
 @brief The singleton instance
 @return sharedInstance - The id of the singleton object.
 */
+ (CSRGaiaManager *)sharedInstance;

/*!
 @brief Start an OTAU
 @param fileName The file name to use.
 @param useDataEndpoint True if the upgrade should use RWCP
 */
- (void)start:(NSString *)fileName useDataEndpoint:(BOOL)useDataEndpoint;

/*!
 @brief Stop the current OTAU. An abort message will be sent and acknowledged.
 */
- (void)stop;

/*!
 @brief The OTAU data transfer is complete. The user can choose not to apply the new data.
 @param value True to go ahead and apply the update.
 */
- (void)commitConfirm:(BOOL)value;

/*!
 @brief The OTAU protocol can ask the user can stop and wait for the user to OK.
 OTAU will continue after calling this method.
 */
- (void)eraseSqifConfirm;

/*!
 @brief The OTAU protocol can ask the user to confirm an error.
 OTAU will continue after calling this method.
 */
- (void)confirmError;

/*!
 @brief If you want to cancel the upgrade.
 */
- (void)abort;

/*!
 @brief If there is a problem with the update the user can force the process to reset and try again.
 */
- (void)abortAndRestart;

/*!
 @brief The OTAU protocol can ask the user can stop and wait once the file transfer is complete.
 OTAU will continue after calling this method.
 */
- (void)updateTransferComplete;

/*!
 @brief The OTAU protocol can raise low battery warnings.
 OTAU will continue after calling this method.
 */
- (void)syncRequest;


/// @brief Prepare CSRGaiaManager by set up delegates and listeners.
- (void)connect;

/// @brief Clear delegates and listeners.
- (void)disconnect;

/// @brief Get the current LED state
- (void)getLED;

/*!
 @brief Control the device LED
 @param value On or off value
 */
- (void)setLED:(BOOL)value;

/*!
 @brief Control the device volume
 @param value Volume valid values are 0 to 10
 */
- (void)setVolume:(NSInteger)value;

/*!
 @brief Execute AV commands on the device
 @param operation Operation to perform. @see //apple_ref/doc/GaiaAVControlOperation
 */
- (void)avControl:(GaiaAVControlOperation)operation;

/*!
 @brief Get power status for the device
 0 - The device is off
 1 - The device is on
 */
- (void)getPower;

/*!
 @brief Get power status for the device
 @param value 0 - The device is off
 1 - The device is on
 */
- (void)setPowerOn:(BOOL)value;

/// @brief Get the current battery level
- (void)getBattery;

/// @brief Get the on chip application version
- (void)getApiVersion;

/*!
 @brief Get the bass boost
 0 - Bass boost is disabled
 1 - Bass boost is enabled
 */
- (void)getBassBoost;

/*!
 @brief Get the bass boost
 @param value 0 - Bass boost is disabled
 1 - Bass boost is enabled
 */
- (void)setBassBoost:(BOOL)value;

/*!
 @brief Get the 3D enhancement
 0 - 3D enhancement is disabled
 1 - 3D enhancement is enabled
 */
- (void)get3DEnhancement;

/*!
 @brief Get the 3D enhancement
 @param value 0 - 3D enhancement is disabled
 1 - 3D enhancement is enabled
 */
- (void)set3DEnhancement:(BOOL)value;

/// @brief Get the current audio source
- (void)getAudioSource;

/*!
 @brief Requests the device send a "Find Me" request to the HID remote connected to it.
 @param value 0 - None, 1 - Mid alert, 2 - High alert
 */
- (void)findMe:(NSUInteger)value;

/*!
 @brief Get the audio source
 @param value GaiaAudioSource
 */
- (void)setAudioSource:(GaiaAudioSource)value;

/*!
 @brief Get the Group EQ param values
 @param data parameter data
 */
- (void)getGroupEQParam:(NSData *)data;

/*!
 @brief Set the Group EQ param values
 @param data parameter data
 */
- (void)setGroupEQParam:(NSData *)data;

/*!
 @brief Get the EQ param values
 */
- (void)getEQControl;

/*!
 @brief Get the EQ param values
 @param value bank to get
 */
- (void)setEQControl:(NSInteger)value;

/*!
 @brief Get the EQ param values
 */
- (void)getUserEQ;

/*!
 @brief Get the EQ param values
 @param value bank to get
 */
- (void)setUserEQ:(BOOL)value;

/*!
 @brief Get the EQ param values
 @param data parameter data to get
 */
- (void)getEQParam:(NSData *)data;

/*!
 @brief Get the EQ param values
 @param data parameter data
 */
- (void)setEQParam:(NSData *)data;

/*!
 @brief Set the TWS trim volume for a device
 @param device Master is 0 and slave is 1.
 @param value Volume valid values are 0 to 10
 */
- (void)trimTWSVolume:(NSInteger)device volume:(NSInteger)value;

/*!
 @brief Get the device volume
 @param device Master is 0 and slave is 1.
 */
- (void)getTWSVolume:(NSInteger)device;

/*!
 @brief Set the device volume
 @param device Master is 0 and slave is 1.
 @param value Volume valid values are 0 to 10
 */
- (void)setTWSVolume:(NSInteger)device volume:(NSInteger)value;

/*!
 @brief Get the device routing.
 0 - Routing both stereo channels
 1 - Routing left channel
 2 - Routing right channel
 3 - Mixing left and right channels to mono
 @param device Master is 0 and slave is 1.
 */
- (void)getTWSRouting:(NSInteger)device;

/*!
 @brief Get the device routing
 @param device Master is 0 and slave is 1.
 @param value 0 - Routing both stereo channels
 1 - Routing left channel
 2 - Routing right channel
 3 - Mixing left and right channels to mono
 */
- (void)setTWSRouting:(NSInteger)device routing:(NSInteger)value;

/*!
 @brief Get the end point mode
 */
- (void)getDataEndPointMode;

/*!
 @brief Get the end point mode
 @param value 0 - The device does not support the data end point
 1 - The device supports the use of the Data end point
 */
- (void)setDataEndPointMode:(BOOL)value;

@end

/*!
 @protocol CSRUpdateManagerDelegate
 @discussion Callbacks from changes to state
 */
@protocol CSRUpdateManagerDelegate <NSObject>

/*!
 @brief The upgrade aborted.
 @param error Look at the error so see what went wrong
*/
- (void)didAbortWithError:(NSError *)error;

@optional
/// @brief The upgrade completed successfully
- (void)didCompleteUpgrade;

/// @brief The upgrade was aborted
- (void)didAbortUpgrade;

/*!
 @brief The upgrade made some progress
 @param value Percentage complete
 @param eta Estimaged time of completion
 */
- (void)didMakeProgress:(double)value eta:(NSString *)eta;

/// @brief The device rebooted after the upgrade
- (void)didWarmBoot;

/*!
 @brief State information about the device. Used when the device is in it's reboot cycle.
 @param value A string with some status information
 */
- (void)didUpdateStatus:(NSString *)value;

/*!
 @brief A response was recieved
 @param command The command response. @see //apple_ref/doc/CSRGaiaGattCommand
 */
- (void)didReceiveGaiaGattResponse:(CSRGaiaGattCommand *)command;

/// @brief Present the user with a yes no choice
- (void)confirmRequired;

/// @brief Present the user with an okay
- (void)okayRequired;

/// @brief Present the user with a yes no choice about forcing the upgrade
- (void)confirmForceUpgrade;

/// @brief Present the user with a yes no choice about the file transfer
- (void)confirmTransferRequired;

/// @brief Present the user with an okay about plugging their device into mains
- (void)confirmBatteryOkay;

/*!
 @brief Called when the service is setup and the characterists are ready to use.
 */
- (void)gaiaReady;

@end
