if config["download-hydro"]:

    rule module_hydro_prebuilt:
        message: "Download pre-built capacity assumptions and capacityfactor time series for hydro electricity."
        params:
            url = config["download-hydro-url"],
        output: "data/automatic/hydro-data.zip"
        conda: "../envs/shell.yaml"
        shell:
            """
            curl -sSLo {output} {params.url}
            """


    rule data_hydro:
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

else:  # config["download-hydro"] is False

    module module_hydro:
        snakefile:
            github(
            "calliope-project/ec_modules", path="modules/hydro/workflow/Snakefile", branch="feature-hydro" # FIXME: replace branch= with tag="vXXX"
            )
        config: config["module-hydro"]
        prefix: "module-hydro"

    use rule * from module_hydro as module_hydro_*


    rule data_hydro:
        message: "Move into place the capacity assumptions and capacityfactor time series for hydro electricity."
        input: # the files produced by hydro module
            supply = expand("module-hydro/results/{resolution}/supply-hydro.csv", resolution=config["resolution"]),
            storage = expand("module-hydro/results/{resolution}/storage-hydro.csv", resolution=config["resolution"]),
            ror = expand("module-hydro/results/{resolution}/capacityfactors-hydro-run-of-river-{first_year}-{final_year}.csv",
                resolution=config["resolution"],
                first_year=config["scope"]["temporal"]["first-year"],
                final_year=config["scope"]["temporal"]["final-year"]),
            reservoir = expand("module-hydro/results/{resolution}/capacityfactors-hydro-reservoir-{first_year}-{final_year}.csv",
                resolution=config["resolution"],
                first_year=config["scope"]["temporal"]["first-year"],
                final_year=config["scope"]["temporal"]["final-year"]),
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
