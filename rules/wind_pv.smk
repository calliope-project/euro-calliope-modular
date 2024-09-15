configfile: "config/modules/wind_pv.yaml"

module module_wind_pv:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/wind_pv/workflow/Snakefile",
            branch="fix-cf-wind-solar" # FIXME: replace tag="vXXX"
        )
    config: config["module_wind_pv"]
    prefix: "module_wind_pv"

use rule * from module_wind_pv as module_wind_pv_*

rule wind_pv_input:
    message: "Input the desired resolution to the 'wind_pv' module."
    input: "build/data/units.geojson"
    output: "module_wind_pv/resources/user/shapes_national.geojson"
    conda: "../envs/shell.yaml"
    shell: "cp {input} {output}"

rule wind_pv_output_timeseries:
    message: "Move into place the 'wind_pv' timeseries."
    input:
        timeseries = f"module_wind_pv/results/{config["resolution"]}/{config['scope']['temporal']['final-year']}/"+"capacityfactors-{techs}.csv"
    output:
        timeseries = "build/model/timeseries/supply/capacityfactors-{techs}.csv"
    wildcard_constraints:
        techs = "wind-offshore|wind-onshore|open-field-pv|rooftop-pv|rooftop-pv-n|rooftop-pv-e-w|rooftop-pv-s-flat",
    conda: "../envs/shell.yaml"
    shell: "cp '{input.timeseries}' '{output.timeseries}'"

rule wind_pv_output_area_limits:
    message: "Move into place the 'wind_pv' area capacity limits."
    input:
        area_limit = f"module_wind_pv/results/{config["resolution"]}/{config['parameters']['wind_pv']['scenario']}/"+"{file}.csv",
    output:
        area_limit = "build/data/supply/{file}.csv"
    wildcard_constraints:
        file = "rooftop-pv|wind-offshore|open-field-pv-and-wind-onshore"
    conda: "../envs/shell.yaml"
    shell: "cp '{input.area_limit}' '{output.area_limit}'"
