#include "ha_dynamic_sensor.h"
#include "esphome/components/api/api_server.h"
#include "esphome/core/application.h"
#include "esphome/core/helpers.h"
#include "esphome/core/log.h"
#include "esphome/core/string_ref.h"

namespace esphome {
namespace ha_dynamic {

static const char *const TAG = "ha_dynamic.sensor";

// Lets a few fields be edited in a row before the reboot
static const uint32_t REBOOT_DELAY_MS = 5000;

void HaDynamicSensor::setup() {
  this->entity_id_ = this->entity_id_text_->state;

  if (this->entity_id_.find('.') == std::string::npos) {
    // An empty or malformed ID would be sent to HA as is; leave the sensor unknown instead
    ESP_LOGW(TAG, "'%s': no entity ID set ('%s')", this->get_name().c_str(), this->entity_id_.c_str());
  } else {
    api::global_api_server->subscribe_home_assistant_state(
        this->entity_id_.c_str(), nullptr, [this](StringRef state) {
          auto val = parse_number<float>(state.c_str());
          if (!val.has_value()) {
            ESP_LOGW(TAG, "'%s': Can't convert '%s' to number!", this->entity_id_.c_str(), state.c_str());
            this->publish_state(NAN);
            return;
          }
          ESP_LOGV(TAG, "'%s': Got state %.2f", this->entity_id_.c_str(), *val);
          this->publish_state(*val);
        });
    // HA sends values in its own unit system; lets lambdas convert (e.g. °F from a US install)
    api::global_api_server->subscribe_home_assistant_state(
        this->entity_id_.c_str(), "unit_of_measurement", [this](StringRef unit) {
          if (this->source_unit_ == unit.c_str())
            return;
          this->source_unit_ = unit.c_str();
          ESP_LOGD(TAG, "'%s': unit '%s'", this->entity_id_.c_str(), this->source_unit_.c_str());
        });
  }

  this->entity_id_text_->add_on_state_callback([this](const std::string &value) {
    if (value == this->entity_id_)
      return;
    ESP_LOGI(TAG, "'%s': entity ID changed to '%s', rebooting in %us to resubscribe", this->get_name().c_str(),
             value.c_str(), (unsigned) (REBOOT_DELAY_MS / 1000));
    // safe_reboot() runs on_shutdown, which flushes the new value to flash
    this->set_timeout("reboot", REBOOT_DELAY_MS, []() { App.safe_reboot(); });
  });
}

void HaDynamicSensor::dump_config() {
  LOG_SENSOR("", "HA Dynamic Sensor", this);
  ESP_LOGCONFIG(TAG, "  Entity ID: '%s'", this->entity_id_.c_str());
}

}  // namespace ha_dynamic
}  // namespace esphome
