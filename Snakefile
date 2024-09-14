import glob
from pathlib import Path

from snakemake.utils import validate, min_version, makedirs

configfile: "config/default.yaml"


include: "./rules/shapes.smk"
include: "./rules/templates.smk"
include: "./rules/wind-and-solar.smk"
include: "./rules/biofuels.smk"
include: "./rules/hydropower.smk"
include: "./rules/transport.smk"
include: "./rules/heat.smk"
include: "./rules/nuclear.smk"
include: "./rules/transmission.smk"
include: "./rules/demand_electricity.smk"

min_version("8.10")

wildcard_constraints:
    resolution = "continental|national|regional|ehighways",

rule all:
    message: "Generate euro-calliope model and run tests."
    localrule: True
    default_target: True
    input:
        "build/model/model.yaml" # TODO: add build-metadata.yaml back after modules have matured


rule clean:  # removes all generated results
    localrule: True
    shell:
        """
        rm -r build/
        echo "Data downloaded to data/automatic/ has not been cleaned."
        """


onstart:
    shell("mkdir -p build")
    temp(shell("snakemake --rulegraph | dot -Tpng > build/rulegraph.png"))
