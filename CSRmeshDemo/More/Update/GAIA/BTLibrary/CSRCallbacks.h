//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>

/*!
 @header CSRCallbacks
 Internal typedefs for managing callbacks
 */

/// @typedef CSRGetStringCompletion handler for returning strings
typedef void (^CSRGetStringCompletion)(NSString *);

/// @typedef CSRGetBoolCompletion handler for returning booleans
typedef void (^CSRGetBoolCompletion)(BOOL);

/// @typedef CSRGetIntCompletion handler for returning integers
typedef void (^CSRGetIntCompletion)(NSInteger);

/// @typedef CSRGetIntCompletion handler for returning doubles
typedef void (^CSRGetDoubleCompletion)(double);

/// @typedef CSRGetIntCompletion handler for returning binary NSData
typedef void (^CSRGetDataCompletion)(NSData *);

/// @typedef CSRErrorCompletion handler for returning NSError objects
typedef void (^CSRErrorCompletion)(NSError *);

/// @typedef CSRSetValueCompletion handler for setting values
typedef void (^CSRSetValueCompletion)(void);

/*!
 @enum CSRCallbackType
 @brief Specify the return type of the block
 */
typedef NS_ENUM(NSInteger, CSRCallbackType) {
    /// @brief CSRCallbackType_Bool Boolean result
    CSRCallbackType_Bool,
    /// @brief CSRCallbackType_Int Int result
    CSRCallbackType_Int,
    /// @brief CSRCallbackType_Double Double result
    CSRCallbackType_Double,
    /// @brief CSRCallbackType_String String result
    CSRCallbackType_String,
    /// @brief CSRCallbackType_Data NSData result
    CSRCallbackType_Data,
    /// @brief CSRCallbackType_SetBool Void result
    CSRCallbackType_SetBool,
    /// @brief CSRCallbackType_SetInt Void result
    CSRCallbackType_SetInt,
    /// @brief CSRCallbackType_SetString Void result
    CSRCallbackType_SetString,
    /// @brief CSRCallbackType_SetData Void result
    CSRCallbackType_SetData,
};

/*!
 @class CSRCallbacks
 @abstract Manage callbacks to CBPeripheralDelegate methods
 */
@interface CSRCallbacks : NSObject

/// @brief The callback type
@property (nonatomic) CSRCallbackType callbackType;

/// @brief the success callback reference
@property (nonatomic) id successCallback;

/// @brief the failure callback reference
@property (nonatomic) id failureCallback;

/*!
 @brief Initialise the callback
 @param success The success callback
 @param failure The failure callback
 @param type The callback type
 */
- (id)initWith:(id)success failure:(id)failure type:(CSRCallbackType)type;

@end
