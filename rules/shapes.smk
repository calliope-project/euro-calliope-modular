rule units:
    message: "Download spatial zones."
    params:
        url = config["spatial-zones"][config["resolution"]],
    output: "build/data/units.geojson"
    conda: "../envs/shell.yaml"
    shell: "curl -sSLo {output} '{params.url}'"
