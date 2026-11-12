from esphome.components import sensor, text
import esphome.config_validation as cv
import esphome.codegen as cg
from esphome.const import CONF_INTERNAL
from .. import ha_dynamic_ns

DEPENDENCIES = ["api", "text"]

HaDynamicSensor = ha_dynamic_ns.class_("HaDynamicSensor", sensor.Sensor, cg.Component)

CONF_ENTITY_ID_TEXT = "entity_id_text"

CONFIG_SCHEMA = sensor.sensor_schema(HaDynamicSensor, accuracy_decimals=1).extend(
    {
        cv.Required(CONF_ENTITY_ID_TEXT): cv.use_id(text.Text),
        # Same default as the stock homeassistant sensor: a mirror, not a new HA entity
        cv.Optional(CONF_INTERNAL, default=True): cv.boolean,
    }
)


async def to_code(config):
    var = await sensor.new_sensor(config)
    await cg.register_component(var, config)
    t = await cg.get_variable(config[CONF_ENTITY_ID_TEXT])
    cg.add(var.set_entity_id_text(t))
    # Normally set by the homeassistant platforms; compiles in the API's state subscription code
    cg.add_define("USE_API_HOMEASSISTANT_STATES")
