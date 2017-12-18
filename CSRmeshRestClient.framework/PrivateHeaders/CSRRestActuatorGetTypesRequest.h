/*!
    Copyright [2015] Qualcomm Technologies International, Ltd.
*/
/* Note: this is an auto-generated file. */


#import <Foundation/Foundation.h>
#import "CSRRestBaseObject.h"


/*!
    Request Object for GetTypes API for the Actuator model
*/

@interface CSRRestActuatorGetTypesRequest : CSRRestBaseObject


/*!
    First type to fetch. The FirstType field is a 16-bit unsigned integer that determines the first Type that can be returned in the corresponding ACTUATOR_TYPES message.
*/
 typedef NS_OPTIONS(NSInteger, CSRRestActuatorGetTypesRequestFirstTypeEnum) {
  CSRRestActuatorGetTypesRequestFirstTypeEnumunknown,
  CSRRestActuatorGetTypesRequestFirstTypeEnuminternal_air_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumexternal_air_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_air_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnuminternal_humidity,
  CSRRestActuatorGetTypesRequestFirstTypeEnumexternal_humidity,
  CSRRestActuatorGetTypesRequestFirstTypeEnumexternal_dewpoint,
  CSRRestActuatorGetTypesRequestFirstTypeEnuminternal_door,
  CSRRestActuatorGetTypesRequestFirstTypeEnumexternal_door,
  CSRRestActuatorGetTypesRequestFirstTypeEnuminternal_window,
  CSRRestActuatorGetTypesRequestFirstTypeEnumexternal_window,
  CSRRestActuatorGetTypesRequestFirstTypeEnumsolar_energy,
  CSRRestActuatorGetTypesRequestFirstTypeEnumnumber_of_activations,
  CSRRestActuatorGetTypesRequestFirstTypeEnumfridge_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_fridge_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumfreezer_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_freezer_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumoven_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_oven_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumseat_occupied,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwashing_machine_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdish_washer_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumclothes_dryer_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumtoaster_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcarbon_dioxide,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcarbon_monoxide,
  CSRRestActuatorGetTypesRequestFirstTypeEnumsmoke,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwater_level,
  CSRRestActuatorGetTypesRequestFirstTypeEnumhot_water_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcold_water_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_water_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcooker_hob_back_left_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_cooker_hob_back_left_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcooker_hob_front_left_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_cooker_hob_front_left_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcooker_hob_back_middle_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_cooker_hob_back_middle_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcooker_hob_front_middle_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_cooker_hob_front_middle_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcooker_hob_back_right_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_cooker_hob_back_right_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumcooker_hob_front_right_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_cooker_hob_front_right_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_wakeup_alarm_time,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_second_wakeup_alarm_time,
  CSRRestActuatorGetTypesRequestFirstTypeEnumpassive_infrared_state,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwater_flowing,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_water_flow,
  CSRRestActuatorGetTypesRequestFirstTypeEnumaudio_level,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_audio_level,
  CSRRestActuatorGetTypesRequestFirstTypeEnumfan_speed,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_fan_speed,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwind_speed,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwind_speed_gust,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwind_direction,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwind_direction_gust,
  CSRRestActuatorGetTypesRequestFirstTypeEnumrain_fall_last_hour,
  CSRRestActuatorGetTypesRequestFirstTypeEnumrain_fall_today,
  CSRRestActuatorGetTypesRequestFirstTypeEnumbarometric_pressure,
  CSRRestActuatorGetTypesRequestFirstTypeEnumsoil_temperature,
  CSRRestActuatorGetTypesRequestFirstTypeEnumsoil_moisure,
  CSRRestActuatorGetTypesRequestFirstTypeEnumwindow_cover_position,
  CSRRestActuatorGetTypesRequestFirstTypeEnumdesired_window_cover_position,
  CSRRestActuatorGetTypesRequestFirstTypeEnumgeneric_1_byte,
  CSRRestActuatorGetTypesRequestFirstTypeEnumgeneric_2_byte,
  CSRRestActuatorGetTypesRequestFirstTypeEnumgeneric_1_byte_typed,
  CSRRestActuatorGetTypesRequestFirstTypeEnumgeneric_2_byte_typed,
  CSRRestActuatorGetTypesRequestFirstTypeEnumgeneric_3_byte_typed,

};



/*!
    First type to fetch. The FirstType field is a 16-bit unsigned integer that determines the first Type that can be returned in the corresponding ACTUATOR_TYPES message.
*/
@property(nonatomic) CSRRestActuatorGetTypesRequestFirstTypeEnum firstType;

/*!
  Constructs instance of CSRRestActuatorGetTypesRequest

  @param firstType - (CSRRestActuatorGetTypesRequestFirstTypeEnum) First type to fetch. The FirstType field is a 16-bit unsigned integer that determines the first Type that can be returned in the corresponding ACTUATOR_TYPES message.
  
  @return instance of CSRRestActuatorGetTypesRequest
*/
- (id) initWithfirstType: (CSRRestActuatorGetTypesRequestFirstTypeEnum) firstType;
       

@end
