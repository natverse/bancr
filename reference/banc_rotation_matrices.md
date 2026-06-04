# Canonical BANC viewpoints as 4x4 rotation matrices

A named list of `userMatrix`-style matrices used by
[`banc_view()`](https://natverse.github.io/bancr/reference/banc_view.md)
/
[`banc_front_view()`](https://natverse.github.io/bancr/reference/banc_view.md)
/
[`banc_vnc_view()`](https://natverse.github.io/bancr/reference/banc_view.md)
etc. and by
[`banc_neuron_comparison_plot()`](https://natverse.github.io/bancr/reference/banc_neuron_comparison_plot.md)
to switch
[`nat.ggplot::geom_neuron()`](https://natverse.github.io/nat.ggplot/reference/geom_neuron.html)
between standard BANC viewpoints (`main`, `side`, `front`, `vnc`,
`vnc_side`, `brain_side`). Exposed so users can compose their own
multi-panel ggplots without re-deriving the matrices.

## Usage

``` r
banc_rotation_matrices
```

## Format

A named list of 4x4 numeric matrices.
