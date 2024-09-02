configfile: "config/modules/hydropower.yaml"

module module_hydropower:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/hydropower/workflow/Snakefile",
            branch="feature-standard-io" # FIXME: replace branch= with tag="vXXX"
        )
    config: config["module_hydropower"]
    prefix: "module_hydropower"

use rule * from module_hydropower as module_hydropower_*

rule hydropower_input:
    message: "Input the desired resolution to the hydropower module."
    input: "build/data/units.geojson"
    output: "module_hydropower/resources/user_input/units.geojson"
    conda: "../envs/shell.yaml"
    shell: "cp {input} {output}"


rule data_hydro:
    message: "Move into place the capacity assumptions and capacityfactor time series for hydro electricity."
    input: # the files produced by hydro module
        supply = "module_hydropower/results/shapes/units/supply_capacity.csv",
        storage = "module_hydropower/results/shapes/units/storage_capacity.csv",
        ror = f"module_hydropower/results/shapes/units/{config['scope']['temporal']['final-year']}/capacity_factors_ror.csv",
        reservoir = f"module_hydropower/results/shapes/units/{config['scope']['temporal']['final-year']}/capacity_factors_reservoir.csv",
    output: # the desired locations of the files in the main workflow
        supply = "build/data/supply/hydro.csv",
        storage = "build/data/storage/hydro.csv",
        ror = "build/model/timeseries/supply/capacityfactors-hydro-run-of-river.csv",
        reservoir = "build/model/timeseries/supply/capacityfactors-hydro-reservoir.csv",
    conda: "../envs/shell.yaml"
    shell:
        """
        cp {input.supply} {output.supply}
        cp {input.storage} {output.storage}
        cp {input.ror} {output.ror}
        cp {input.reservoir} {output.reservoir}
        """
