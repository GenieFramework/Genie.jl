# Contributing

When contributing to this repository, please first discuss the change you wish to make via `Issue`,
`Discord`, `Github Discussion`, with the owners of this repository before making a change. If it's a new feature the ideal place to discuss is [Genie Discussion](https://github.com/GenieFramework/Genie.jl/discussions)

Please note we have a code of conduct, please follow it in all your interactions with the project.

## Docs contribution

1. To make `API` contribution directly add modify/add Docstrings in Genie.jl source code
2. Genie's Guides/Tutorials section from [genieframework.com/docs]() are converted to Interactive Pluto Notebooks, you can modify them in `docs/Guides/test/PlutoNotebooks/` (Note: Pluto version 0.17.3 -> `add Pluto@0.17.3`)
3. To run Pluto notebook, follow the video: https://youtu.be/OOjKEgbt8AI
4. To build and test all Pluto Notebooks. Use the instructions given in `docs/Guides/README.md`

## Pull Request Process

1. Ensure any install or build dependencies are removed before the end of the layer when doing a
   build.
2. Make sure you remove any OS generated configuration file like macos generates `.DS_Store` that stores custom attributes
3. Update the README.md with details of changes to the interface, this includes new environment
   variables, exposed ports, useful file locations and container parameters.
4. Increase the version numbers in any examples files and the README.md to the new version that this
   Pull Request would represent. The versioning scheme we use is [SemVer](https://semver.org).
5. You may merge the Pull Request once you have the sign-off of two other developers, or if you
   do not have permission to do that, you may request the second reviewer merge it for you.
