//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
/*!
 @header CSRBLEUtil
 Helper methods to read and write data
 */

/*!
 @class CSRBLEUtil
 @abstract CSRConnectionManager helper methods
 @discussion Helper methods to read and write data
 */
@interface CSRBLEUtil : NSObject

/*!
 @brief Read a boolean value from position zero in the data
 @param data Convert value to bool
 @return BOOL
 */
+ (BOOL)boolValue:(NSData *)data;

/*!
 @brief Read an Interger value from position zero in the data.
 @discussion The method will look at the size of the data and read the correct size.
 1 byte uint8_t, 2 bytes uint16_t and 4 bytes uint32_t.
 @param data Convert value to integer
 @return NSInteger
 */
+ (NSInteger)intValue:(NSData *)data;

/*!
 @brief Read a uint8_t value from position zero in the data
 @param data Convert value to integer
 @param offset At offset
 @return NSInteger
 */
+ (NSInteger)uint8Value:(NSData *)data offset:(NSInteger)offset;

/*!
 @brief Read a uint16_t value from position zero in the data
 @param data Convert value to integer
 @param offset At offset
 @return NSInteger
 */
+ (NSInteger)uint16Value:(NSData *)data offset:(NSInteger)offset;

/*!
 @brief Read a int16_t value from position zero in the data
 @param data Convert value to integer
 @param offset At offset
 @return NSInteger
 */
+ (NSInteger)int16Value:(NSData *)data offset:(NSInteger)offset;

/*!
 @brief Read a double value from position zero in the data
 @param data Convert value to double
 @param offset At offset
 @return double
 */
+ (double)doubleValue:(NSData *)data offset:(NSInteger)offset;

/*!
 @brief Read a uint32_t value from position zero in the data
 @param data Convert value to integer
 @param offset At offset
 @return NSInteger
 */
+ (NSInteger)uint32Value:(NSData *)data offset:(NSInteger)offset;

/*!
 @brief Read a string value from position zero in the data
 @param data Convert value to utf string
 @return NSString
 */
+ (NSString *)stringValue:(NSData *)data;

/*!
 @brief Read a characteristic
 @param peripheral the peripheral to read from
 @param uuid the Characteristic to read
 */
+ (void)readCharacteristic:(CBPeripheral *)peripheral
                      uuid:(NSString *)uuid;

/*!
 @brief Write to a a characteristic
 @param peripheral the peripheral to read from
 @param uuid the Characteristic to read
 @param data the data to write
 */
+ (void)writeCharacteristic:(CBPeripheral *)peripheral
                       uuid:(NSString *)uuid
                       data:(NSData *)data;

@end
