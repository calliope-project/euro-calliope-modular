"""Setup for the 'biofuels' module."""

configfile: "config/modules/biofuels.yaml"

module module_biofuels:
    snakefile:
        github(
            "calliope-project/ec_modules",
            path="modules/biofuels/workflow/Snakefile",
            branch="main" # FIXME: replace tag="vXXX"
        )
    config: config["module_biofuels"]
    prefix: "module_biofuels"

use rule * from module_biofuels as module_biofuels_*

rule biofuel_input:
    message: "Input the desired resolution to the biofuel module."
    input: "build/data/units.geojson"
    output: f"module_biofuels/resources/user/shapes_{config["resolution"]}.geojson"
    conda: "../envs/shell.yaml"
    shell: "cp {input} {output}"

rule biofuel_tech_module:
    message: "Create {wildcards.tech_module} tech definition file from template."
    input:
        template = "templates/model/techs/supply/{tech_module}.yaml.jinja",
        biofuel_cost = f"module_biofuels/results/{config["resolution"]}/{config["parameters"]["biofuel"]["scenario"]}/costs_eur_per_mwh.csv",
        locations = f"module_biofuels/results/{config["resolution"]}/{config["parameters"]["biofuel"]["scenario"]}/potential_mwh_per_year.csv"
    params:
        scaling_factors = config["scaling-factors"],
        biofuel_efficiency = config["parameters"]["biofuel"]["efficiency"]
    conda: "../envs/default.yaml"
    output: "build/model/techs/supply/{tech_module}.yaml"
    wildcard_constraints:
        tech_module = "biofuel|electrified-biofuel"
    script: "../scripts/template_bio.py"
