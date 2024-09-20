configfile: "config/modules/demand_electricity.yaml"

module module_demand_electricity:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/demand_electricity/workflow/Snakefile",
            tag="v0.0.6"
        )
    config: config["module_demand_electricity"]
    prefix: "module_demand_electricity"

use rule * from module_demand_electricity as module_demand_electricity_*

rule demand_electricity_input:
    message: "Input the desired resolution to the demand module."
    input: "build/data/units.geojson"
    output: f"module_demand_electricity/resources/user/shapes_{config["resolution"]}.geojson"
    conda: "../envs/shell.yaml"
    shell: "cp {input} {output}"

rule demand_electricity_output:
    message: "Move into place the electricity demand timeseries."
    input: f"module_demand_electricity/results/{config["resolution"]}/{config['scope']['temporal']['year']}/demand_electricity.csv"
    output: f"build/model/timeseries/demand/electricity.csv"
    conda: "../envs/shell.yaml"
    shell: "cp '{input}' '{output}'"
