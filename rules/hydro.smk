# FIXME: temporary download of hydro data, to be replaced by a hydro module
# Hardcoded to 2016 national data

rule download_data_hydro:
    message: "Download capacity assumptions and capacityfactor time series for hydro electricity."
    params:
        url = config["module-data-sources"]["hydro-data"],
    output: "data/automatic/hydro-data.zip"
    conda: "../envs/shell.yaml"
    shell:
        """
        curl -sSLo {output} {params.url}
        """


rule unzip_data_hydro:
    message: "Unzip capacity assumptions and capacityfactor time series for hydro electricity."
    input: rules.download_data_hydro.output[0]
    output:
        supply = "build/data/supply/hydro.csv",
        storage = "build/data/storage/hydro.csv",
        ror = "build/model/timeseries/supply/capacityfactors-hydro-run-of-river.csv",
        reservoir = "build/model/timeseries/supply/capacityfactors-hydro-reservoir.csv",
    conda: "../envs/shell.yaml"
    shell:
        """
        unzip -j {input} supply-hydro.csv -d build/data/supply
        mv build/data/supply/supply-hydro.csv build/data/supply/hydro.csv
        unzip -j {input} storage-hydro.csv -d build/data/storage
        mv build/data/storage/storage-hydro.csv build/data/storage/hydro.csv
        unzip -j {input} capacityfactors-hydro-run-of-river.csv -d build/model/timeseries/supply
        unzip -j {input} capacityfactors-hydro-reservoir.csv -d build/model/timeseries/supply
        """
