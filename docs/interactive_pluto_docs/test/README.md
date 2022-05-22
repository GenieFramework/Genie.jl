* All the pluto-notebooks(guides, tutorials) are in `PlutoNotebooks`
* `runtest_*.jl` contains the testing logic for PlutoNotebooks
* `html.jl` takes `.html` notebooks and add genieframework.com styles to all `.html` outputs
* `update_packages.jl` contains the logic to update all the packages in Pluto Notebooks to latest --- [NOUSED YET - TODO - Add in build process]
* `cleanup.jl` gets rid of Pluto Notebook outputs(files and folders) so the notebook doesn't crash on subsequent runs
