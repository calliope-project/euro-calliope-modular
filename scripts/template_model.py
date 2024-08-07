"""Creates Calliope top-level model file."""

from pathlib import Path

from eurocalliopelib.template import parametrise_template


def construct_model(path_to_template, path_to_output, modules, resolution, year):

    # Paths to files in the template must be relative to the main model file
    input_files = [Path(".") / i.replace("build/model/", "") for i in modules]

    return parametrise_template(
        path_to_template,
        path_to_output,
        input_files=input_files,
        resolution=resolution,
        year=year,
    )


if __name__ == "__main__":
    construct_model(
        path_to_template=snakemake.input.template,
        modules=snakemake.input.modules,
        resolution=snakemake.params.resolution,
        year=snakemake.params.year,
        path_to_output=snakemake.output[0],
    )
