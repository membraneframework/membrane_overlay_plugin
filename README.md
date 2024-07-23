# Membrane Overlay Plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_overlay_plugin.svg)](https://hex.pm/packages/membrane_overlay_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_overlay_plugin)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_overlay_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_overlay_plugin)

Filter for applying overlay or text over video. Based on the [Image](https://github.com/elixir-image/image) library.

It's a part of the [Membrane Framework](https://membrane.stream).

## Installation

The package can be installed by adding `membrane_overlay_plugin` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_overlay_plugin, "~> 0.2.0"}
  ]
end
```

## Usage

To overlay an image in the top-right corner of an H264 video, use the following spec:

```elixir
child(%Membrane.File.Source{location: "input.h264"})
|> child(Membrane.H264.Parser)
|> child(Membrane.H264.FFmpeg.Decoder)
|> child(%Membrane.OverlayFilter{overlay: "image.png", x: :right, y: :top})
|> child(Membrane.H264.FFmpeg.Encoder)
|> child(%Membrane.File.Sink{location: "output.h264"})
```

See the `example.exs` file for a complete example.

## Copyright and License

Copyright 2024, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)
