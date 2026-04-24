# PINET

Minimal user-facing MATLAB package for the final PINET figure set.

## Main files

- `pinet_run.m` - export the final figure set
- `pinet_config.m` - output specification and final parameters
- `pinet_render_outputs.m` - run the figure-generation pipeline
- `pinet_build_outputs.m` - internal output builder
- `pinet_simulate_wire_field.m` - analytic field model
- `pinet_generate_projections.m` - validated projection step
- `pinet_reconstruct_field.m` - reconstruction core
- `cm.mat`, `sunset_cm.mat` - bundled colormaps

## Run

In MATLAB, open this folder and run:

```matlab
out = pinet_run;
```

This writes a fresh export to `results_pinet`.
