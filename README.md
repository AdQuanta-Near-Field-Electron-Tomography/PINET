# PINET

MATLAB example of the PINET pipeline for a simulated wire field.

This package simulates the scattered field of an illuminated wire, builds
the projection measurements, reconstructs the field in Fourier space, and
exports the example real-space, Fourier-space, and reconstructed results.

## Files

- `pinet_run.m` - main entry point
- `pinet_config.m` - figure list and package settings
- `pinet_render_outputs.m` - run the output pipeline
- `pinet_build_outputs.m` - build each simulation and export pass
- `pinet_simulate_wire_field.m` - analytic field model
- `pinet_generate_projections.m` - projection generation
- `pinet_reconstruct_field.m` - reconstruction core
- `pinet_postprocess_field.m` - blur, median, and Perona-Malik filtering
- `cm.mat`, `sunset_cm.mat` - bundled colormaps

The reconstruction path is:
`pinet_run -> pinet_render_outputs -> pinet_build_outputs -> pinet_reconstruct_field`

## Run

In MATLAB, open this folder and run:

```matlab
out = pinet_run;
```

This writes a fresh set of outputs to `results_pinet`.
