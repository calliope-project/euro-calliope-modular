"""Rules related to the transport module."""

configfile: "config/modules/heat.yaml"

module module_heat:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/heat/workflow/Snakefile",
            tag="v0.0.4"
        )
    config: config["module_heat"]
    prefix: "module_heat"

use rule * from module_heat as module_heat_*
