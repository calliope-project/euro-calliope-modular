rule model_input_locations:
    message: "Generate locations configuration file from template."
    input:
        template = model_template_dir + "locations.yaml.jinja",
        shapes = rules.units.output[0]
    output:
        yaml = "build/model/locations.yaml",
        csv = "build/model/locations.csv"
    conda: "../envs/geo.yaml"
    params:
        resolution = config["resolution"]
    script: "../scripts/shapes/template_locations.py"
