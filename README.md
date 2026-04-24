# PINET

Minimal user-facing MATLAB package for the final PINET figure set.

## Main files

- `pinet_export_final_results.m` - export the approved final figure set
- `pinet_paper_reference_demo.m` - run the figure-generation pipeline
- `pinet_recreate_reference_set.m` - internal export pipeline
- `pinet_simulate_wire_field.m` - analytic field model
- `pinet_generate_projections.m` - validated projection step
- `pinet_reconstruct_field.m` - reconstruction core
- `cm.mat`, `sunset_cm.mat` - bundled colormaps

## Run

In MATLAB, open this folder and run:

```matlab
out = pinet_export_final_results;
```

This writes a fresh export to `results_paper_reference_demo`.

The folder `approved_results_paper_reference_demo` contains the approved reference exports bundled with this package.
