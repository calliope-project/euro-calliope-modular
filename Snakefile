import glob
from pathlib import Path

from snakemake.utils import validate, min_version, makedirs

configfile: "config/default.yaml"

root_dir = config["root-directory"] + "/" if config["root-directory"] not in ["", "."] else ""
__version__ = open(f"{root_dir}VERSION").readlines()[0].strip()
test_dir = f"{root_dir}tests/"
model_test_dir = f"{test_dir}model"
resources_test_dir = f"{test_dir}resources"
template_dir = f"{root_dir}templates/"
model_template_dir = f"{template_dir}model/"
techs_template_dir = f"{model_template_dir}techs/"

include: "./rules/shapes.smk"
include: "./rules/wind-and-solar.smk"
include: "./rules/biofuels.smk"
include: "./rules/hydropower.smk"
include: "./rules/transport.smk"
include: "./rules/heat.smk"
include: "./rules/demand.smk"
include: "./rules/nuclear.smk"
include: "./rules/model.smk"
include: "./rules/transmission.smk"

min_version("8.10")
localrules: all, clean
wildcard_constraints:
    resolution = "continental|national|regional|ehighways",
    group_and_tech = "(demand|storage|supply|transmission)\/\w+"
ruleorder: module_with_location_specific_data > module_without_location_specific_data

ALL_CF_TECHNOLOGIES = [
    "wind-onshore", "wind-offshore", "open-field-pv",
    "rooftop-pv", "rooftop-pv-n", "rooftop-pv-e-w", "rooftop-pv-s-flat", "hydro-run-of-river",
    "hydro-reservoir"
]


rule all:
    message: "Generate euro-calliope model and run tests."
    localrule: True
    default_target: True
    input:
        expand(
            "build/model/{file}",
            file=["model.yaml"]
        ) # TODO: add build-metadata.yaml back if necessary


rule module_with_location_specific_data:
    message: "Create definition file for {wildcards.group_and_tech}."
    input:
        template = techs_template_dir + "{group_and_tech}.yaml.jinja",
        locations = "build/data/{group_and_tech}.csv"
    params:
        scaling_factors = config["scaling-factors"],
        capacity_factors = config["capacity-factors"]["average"],
        max_power_densities = config["parameters"]["maximum-installable-power-density"],
        # heat_pump_shares = config["parameters"]["heat-pump"]["heat-pump-shares"],
        biofuel_efficiency = config["parameters"]["biofuel-efficiency"],
    wildcard_constraints:
        # Exclude all outputs that have their own `techs_and_locations_template` implementation
        group_and_tech = "(?!transmission\/|supply\/biofuel|supply\/electrified-biofuel).*"
    conda: "envs/default.yaml"
    output: "build/model/techs/{group_and_tech}.yaml"
    script: "scripts/template_techs.py"

use rule module_with_location_specific_data as module_without_location_specific_data with:
    # For all cases where we don't have any location-specific data that we want to supply to the template
    input:
        template = techs_template_dir + "{group_and_tech}.yaml.jinja",
        locations = rules.model_input_locations.output.csv

rule module_without_specific_data:
    message: "Create configuration files from templates where no parameterisation is required."
    input:
        template = model_template_dir + "{template}",
    output: "build/model/{template}"
    wildcard_constraints:
        template = "interest-rate.yaml"
    conda: "envs/shell.yaml"
    shell: "cp {input.template} {output}"


rule auxiliary_files:
    message: "Create auxiliary output files (i.e. those not used to define a Calliope model) from templates where no parameterisation is required."
    input:
        template = template_dir + "{template}",
    output: "build/model/{template}"
    wildcard_constraints:
        template = "environment.yaml|README.md"
    conda: "envs/shell.yaml"
    shell: "cp {input.template} {output}"


rule model:
    message: "Generate top-level model configuration file from template"
    input:
        template = model_template_dir + "model.yaml.jinja",
        auxiliary_files = expand(
            "build/model/{template}", template=["environment.yaml", "README.md"]
        ),
        modules = expand(
            "build/model/{module}",
            module=[
                "interest-rate.yaml",
                "locations.yaml",
                "techs/demand/electricity.yaml",
                "techs/storage/electricity.yaml",
                "techs/storage/hydro.yaml",
                "techs/supply/hydro.yaml",
                "techs/supply/load-shedding.yaml",
                "techs/supply/open-field-solar-and-wind-onshore.yaml",
                "techs/supply/rooftop-solar.yaml",
                "techs/supply/wind-offshore.yaml",
                "techs/supply/nuclear.yaml",
            ]
        ),
        capacityfactor_timeseries_data = expand(
            "build/model/timeseries/supply/capacityfactors-{technology}.csv",
            technology=ALL_CF_TECHNOLOGIES
        ),
        demand_timeseries_data = expand(
            "build/model/timeseries/demand/{filename}",
            filename=[
                "electricity.csv",
            ]
        ),
        optional_biofuel_modules = expand(
            "build/model/{module}",
            module=[
                "techs/supply/biofuel.yaml",
                "techs/supply/electrified-biofuel.yaml",
                "techs/conversion/electricity-from-biofuel.yaml"
            ]
        )
    params:
        year = config["scope"]["temporal"]["first-year"],
        resolution = config["resolution"],
    conda: "envs/default.yaml"
    output: "build/model/model.yaml"
    script: "scripts/template_model.py"


rule dag:
    message: "Plot dependency graph of the workflow."
    # Output is deliberatly omitted so rule is executed each time.
    conda: "envs/shell.yaml"
    shell:
        "snakemake --rulegraph | dot -Tpdf {input} -o build/dag.pdf"


rule clean:  # removes all generated results
    localrule: True
    shell:
        """
        rm -r build/
        echo "Data downloaded to data/automatic/ has not been cleaned."
        """
