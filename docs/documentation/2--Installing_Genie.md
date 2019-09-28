# How to Install Genie

Genie development moves fast. Until reaching v1, the recommended installation is to get the latest and greatest Genie, by running off the `master` branch:

```julia
pkg> add Genie#master
```

You can also install Genie from Julia's registry -- for example the latest version:

```julia
pkg> add Genie
```

Genie, just like Julia, uses semantic versioning in the form vX.Y.Z to designate:

- X : major version, introducing breaking changes
- Y : minor version, brings new features, no breaking changes
- Z : patch version, fixes bugs, no new features or breaking changes

---
**HEADS UP**

Pre version 1, changes in Genie's minor version indicate breaking changes. So a new version 0.15 will introduce breaking changes from 0.14. Patch versions indicate non-breaking changes such as new features and patch releases.

---
