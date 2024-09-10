"""Rules used for Calliope templating."""

ALL_CF_TECHNOLOGIES = [
    "wind-onshore", "wind-offshore", "open-field-pv",
    "rooftop-pv", "rooftop-pv-n", "rooftop-pv-e-w", "rooftop-pv-s-flat", "hydro-run-of-river",
    "hydro-reservoir"
]

wildcard_constraints:
    group_and_tech = "(demand|storage|supply|transmission)\/\w+"

ruleorder: module_with_location_specific_data > module_without_location_specific_data

# rule module_without_specific_data:
#     message: "Create configuration files from templates where no parameterisation is required."
#     input:
#         template = "templates/model/{template}",
#     output: "build/model/{template}"
#     wildcard_constraints:
#         template = "interest-rate.yaml"
#     conda: "../envs/shell.yaml"
#     shell: "cp {input.template} {output}"


rule module_with_location_specific_data:
    message: "Create definition file for {wildcards.group_and_tech}."
    input:
        template = "templates/model/techs/{group_and_tech}.yaml.jinja",
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
    conda: "../envs/default.yaml"
    output: "build/model/techs/{group_and_tech}.yaml"
    script: "../scripts/template_techs.py"


use rule module_with_location_specific_data as module_without_location_specific_data with:
    # For all cases where we don't have any location-specific data that we want to supply to the template
    input:
        template = "templates/model/techs/{group_and_tech}.yaml.jinja",
        locations = rules.model_input_locations.output.csv


rule auxiliary_files:
    message: "Create auxiliary output files (i.e. those not used to define a Calliope model) from templates where no parameterisation is required."
    input:
        template = "templates/{template}",
    output: "build/model/{template}"
    wildcard_constraints:
        template = "environment.yaml|README.md"
    conda: "../envs/shell.yaml"
    shell: "cp {input.template} {output}"


rule model:
    message: "Generate top-level model configuration file from template"
    input:
        template = "templates/model/model.yaml.jinja",
        auxiliary_files = expand(
            "build/model/{template}", template=["environment.yaml", "README.md"]
        ),
        modules = expand(
            "build/model/{module}",
            module=[
                # "interest-rate.yaml",
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
    conda: "../envs/default.yaml"
    output: "build/model/model.yaml"
    script: "../scripts/template_model.py"
