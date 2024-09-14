configfile: "config/modules/demand_electricity.yaml"

module module_demand_electricity:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/demand_electricity/workflow/Snakefile",
            branch="fix-demand-module" # FIXME: replace tag="vXXX"
        )
    config: config["module_demand_electricity"]
    prefix: "module_demand_electricity"

use rule * from module_demand_electricity as module_demand_electricity_*

rule demand_electricity_input:
    message: "Input the desired resolution to the demand module."
    input: "build/data/units.geojson"
    output: "module_demand_electricity/resources/user/shapes_national.geojson"
    conda: "../envs/shell.yaml"
    shell: "cp {input} {output}"

rule demand_electricity_output:
    message: "Move into place the electricity demand timeseries."
    input: f"module_demand_electricity/results/national/{config['scope']['temporal']['final-year']}/demand_electricity.csv"
    output: f"build/model/timeseries/demand/electricity.csv"
    conda: "../envs/shell.yaml"
    shell: "cp '{input}' '{output}'"
