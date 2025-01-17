"""Rules related to wind and solar."""

ALL_WIND_AND_SOLAR_TECHNOLOGIES = [
    "wind-onshore", "wind-offshore", "open-field-pv",
    "rooftop-pv", "rooftop-pv-n", "rooftop-pv-e-w", "rooftop-pv-s-flat"
]


rule download_potentials:
    message: "Download potential data."
    params: url = config["data-sources"]["potentials"]
    output: protected("data/automatic/raw-potentials.zip")
    conda: "../envs/shell.yaml"
    localrule: True
    shell: "curl -sSLo {output} '{params.url}'"


rule potentials:
    message: "Unzip potentials."
    input: rules.download_potentials.output[0]
    shadow: "minimal"
    params:
        resolution = config["resolution"],
        scenario = config["parameters"]["wind-and-solar-potential-scenario"],
    output:
        land_eligibility_km2 = "build/data/areas.csv",
        demand = "build/data/demand.csv",
        population = "build/data/population.csv",
        land_cover = "build/data/land-cover.csv"
    conda: "../envs/shell.yaml"
    shell:
        """
        unzip -j {input} {params.resolution}/{params.scenario}/areas.csv -d build/data
        unzip -j {input} {params.resolution}/demand.csv -d build/data
        unzip -j {input} {params.resolution}/population.csv -d build/data
        unzip -j {input} {params.resolution}/land-cover.csv -d build/data
        """


rule download_capacity_factors_wind_and_solar:
    message: "Download data/automatic/capacityfactors/{wildcards.filename}."
    params: url = lambda wildcards: config["data-sources"]["capacity-factors"].format(filename=wildcards.filename)
    output: protected("data/automatic/capacityfactors/{filename}")
    conda: "../envs/shell.yaml"
    localrule: True
    shell: "curl -sSLo {output} '{params.url}'"


rule area_to_capacity_limits:
    message: "Use technology densities to convert wind & solar available area to capacity limits."
    input:
        units = rules.units_without_shape.output[0],
        land_eligibility_km2 = rules.potentials.output.land_eligibility_km2,
    params:
        max_power_densities = config["parameters"]["maximum-installable-power-density"],
        roof_shares = config["parameters"]["roof-share"],
    output:
        rooftop = "build/data/supply/rooftop-solar.csv",
        offshore = "build/data/supply/wind-offshore.csv",
        onshore_and_open_field = "build/data/supply/open-field-solar-and-wind-onshore.csv"
    conda: "../envs/default.yaml"
    script: "../scripts/wind-and-solar/capacity_limits.py"


rule capacity_factors_onshore_wind_and_solar:
    message: "Generate capacityfactor time series disaggregated by location for {wildcards.technology}."
    input:
        locations = rules.units.output[0],
        timeseries = ancient("data/automatic/capacityfactors/{technology}-timeseries.nc"),
        coordinates = ancient("data/automatic/capacityfactors/wind-onshore-timeseries.nc")
    params:
        cf_threshold = config["capacity-factors"]["min"],
        gridcell_overlap_threshold=config["quality-control"]["capacity-factor-gridcell-overlap-threshold"],
        first_year = config["scope"]["temporal"]["first-year"],
        final_year = config["scope"]["temporal"]["final-year"],
        trim_ts = config["capacity-factors"]["trim-ninja-timeseries"]
    wildcard_constraints:
        technology = "wind-onshore|rooftop-pv|open-field-pv|rooftop-pv-n|rooftop-pv-e-w|rooftop-pv-s-flat"
    output: "build/model/timeseries/supply/capacityfactors-{technology}.csv"
    conda: "../envs/geo.yaml"
    resources:
        runtime = 30
    script: "../scripts/wind-and-solar/capacityfactors.py"


rule download_eez:
    message: "Download Exclusive Economic Zones as zip"
    output: protected("data/automatic/eez.gpkg.zip")
    params: url = config["data-sources"]["eez"]
    conda: "../envs/shell.yaml"
    localrule: True
    shell: "curl -sSLo {output} '{params.url}'"


rule eez:
    message: "Clip exclusive economic zones to study area."
    input: rules.download_eez.output[0]
    output: "build/data/eez.geojson"
    params:
        bounds="{x_min},{y_min},{x_max},{y_max}".format(**config["scope"]["spatial"]["bounds"]),
        countries=",".join(["'{}'".format(country) for country in config["scope"]["spatial"]["countries"]]),
    conda: "../envs/geo.yaml"
    shadow: "minimal"
    shell:
        """
        fio cat --bbox {params.bounds} "zip://{input}"\
        | fio filter "f.properties.TERRITORY1 in [{params.countries}]"\
        | fio collect > {output}
        """


rule shared_coast:
    message: "Determine share of coast length between EEZ and spatial units using {threads} threads."
    input:
        units = rules.units.output[0],
        eez = rules.eez.output[0],
    params:
        polygon_area_share_threshold = config["quality-control"]["shared-coast-polygon-area-share-threshold"],
        resolution = config["resolution"],
    output: "build/data/shared-coast.csv"
    threads: 4
    conda: "../envs/geo.yaml"
    script: "../scripts/wind-and-solar/shared_coast.py"


rule capacity_factors_offshore:
    message: "Generate capacityfactor time series disaggregated by location for wind-offshore."
    input:
        eez = rules.eez.output[0],
        shared_coast = rules.shared_coast.output[0],
        timeseries = ancient("data/automatic/capacityfactors/wind-offshore-timeseries.nc")
    params:
        cf_threshold = config["capacity-factors"]["min"],
        gridcell_overlap_threshold=config["quality-control"]["capacity-factor-gridcell-overlap-threshold"],
        first_year = config["scope"]["temporal"]["first-year"],
        final_year = config["scope"]["temporal"]["final-year"],
        trim_ts = config["capacity-factors"]["trim-ninja-timeseries"],
    output: "build/model/timeseries/supply/capacityfactors-wind-offshore.csv"
    conda: "../envs/geo.yaml"
    resources:
        runtime = 30
    script: "../scripts/wind-and-solar/capacityfactors_offshore.py"
