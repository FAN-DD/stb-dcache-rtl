# RTL style gate waivers

The RTL gate checks all project-owned packages and synthesizable modules. The
following files remain in the compile and lint set but are excluded from
line-format checks for the stated reason:

- `ecc/prim_secded_pkg.sv`: generated lowRISC SECDED implementation. Changes
  must be made in its generator/configuration and regenerated, rather than by
  manually formatting the generated output.
- `uncore_def.sv`: established SoC-wide feature, address-map, and TileLink
  macro interface shared with blocks outside this repository snapshot.
- `dcache_def.sv`: established cache-configuration macro interface consumed by
  the top-level SRAM ports and external integration.

These waivers cover formatting only. All three files are compiled by every
supported cache-size lint run. Functional changes to them require the same
regression and review as other RTL.
