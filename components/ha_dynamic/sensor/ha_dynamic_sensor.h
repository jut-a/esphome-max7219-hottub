#pragma once

#include "esphome/core/component.h"
#include "esphome/components/sensor/sensor.h"
#include "esphome/components/text/text.h"

#include <string>

namespace esphome {
namespace ha_dynamic {

// Mirrors a Home Assistant sensor whose entity ID is read from a text entity at boot.
// The API sends its subscription list only when HA connects, so a changed entity ID
// takes effect after a reboot, which the sensor schedules itself.
class HaDynamicSensor : public sensor::Sensor, public Component {
 public:
  void set_entity_id_text(text::Text *t) { entity_id_text_ = t; }
  void setup() override;
  void dump_config() override;
  // Same stage as the stock homeassistant sensor; template text restores at HARDWARE, before this
  float get_setup_priority() const override { return setup_priority::AFTER_CONNECTION; }
  // The HA entity's unit_of_measurement attribute ("°C", "°F", "km/h", ...); empty until HA sends it
  const std::string &get_source_unit() const { return source_unit_; }

 protected:
  text::Text *entity_id_text_{nullptr};
  // Fixed after setup(): the API keeps a pointer to its c_str()
  std::string entity_id_;
  std::string source_unit_;
};

}  // namespace ha_dynamic
}  // namespace esphome
