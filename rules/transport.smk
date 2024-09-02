"""Rules related to the transport module."""

configfile: "config/modules/transport_road.yaml"

module module_transport_road:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/transport_road/workflow/Snakefile",
            tag="v0.0.4"
        )
    config: config["module_transport_road"]
    prefix: "module_transport_road"

use rule * from module_transport_road as module_transport_road_*
