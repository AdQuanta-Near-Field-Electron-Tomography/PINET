# PINET

Minimal user-facing MATLAB package for the final PINET figure set.

## Main files

- `pinet_standalone_final.m` - export the standalone final figure set
- `pinet_final_config.m` - final figure specification and locked-output config
- `pinet_paper_reference_demo.m` - run the figure-generation pipeline
- `pinet_recreate_reference_set.m` - internal export pipeline
- `pinet_simulate_wire_field.m` - analytic field model
- `pinet_generate_projections.m` - validated projection step
- `pinet_reconstruct_field.m` - reconstruction core
- `cm.mat`, `sunset_cm.mat` - bundled colormaps

## Run

In MATLAB, open this folder and run:

```matlab
out = pinet_standalone_final;
```

This writes a fresh export to `results_pinet_standalone`.

The folder `final_output_assets` contains the packaged final assets used by the standalone export.
