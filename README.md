# `euro-calliope-modular`

An experimental euro-calliope model generation workflow built around a modular approach, with a focus on improved understandability, reproducibility, and usability for non-software-developers.

Forked from [euro-calliope@3379a28](https://github.com/calliope-project/euro-calliope/commit/3379a28354548f664b35ea9194593e12d7366531)

## Main changes compared to `euro-calliope`

* Removed resolution wildcard. Resolution is in the configuration instead. This means the workflow must be run multiple times to build more than one resolution.
* Some other wildcard use reduced in favour of configuration and params (e.g. in the `potentials` rule).
* Removed all non-electric sectors from the workflow (to be re-introduced via modules).
* Hydro rules removed and replaced with a rule that downloads hydro data from a known location (to be replaced with a hydro module).
* Rules related to producing `units.geojson` removed and replaced with a rule that downloads `units.geojson` from a known location.
* Due to persistent installation issues, `eurocalliopelib` is not an editable installation any more, so environments need to be re-built every time changes to `eurocalliopelib` are made. Ideally it will be turned into a versioned, separate package that can be installed from a known remote location.
* Removed special code to deal with linking `eurocalliopelib`.
* Removed non-default profiles, sync rules, and other custom configuration.
* Default profile does not override `conda-prefix` any more, so conda envs are stored in the default location (`.snakemake/conda`).
* Reduced number of conda environments.

## Temporary changes while this is work-in-progress

* Removed documentation and tests (to be re-introduced).
* Removed main configuration schema (to be re-introduced after simplification is concluded; likely, the remaining configuration will be dramatically reduced).

## Todo and open issues

* For now, only a national-level 2016 model can be built due to hardcoded hydro data download. This will be replaced by a hydro module that replicates the existing hydro-related functionality.
* Configuration parameters need to be cleaned up - many of them are no longer used.
* `scope.spatial` in the configuration is not consistent with downloading a pre-generated units file and needs to be revised or removed

## License

Based on the original euro-calliope repository, licensed under the same MIT License.
