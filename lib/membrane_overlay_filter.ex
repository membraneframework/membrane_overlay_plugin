defmodule Membrane.OverlayFilter do
  @moduledoc """
  Applies image or text overlay to video.

  Based on `Image`.
  """
  use Membrane.Filter

  alias Membrane.RawVideo

  def_input_pad :input, accepted_format: %RawVideo{pixel_format: :I420}
  def_output_pad :output, accepted_format: %RawVideo{pixel_format: :I420}

  alias Vix.Vips.Image, as: Vimage
  alias Vix.Vips.Operation

  def_options overlay: [
                spec: Path.t() | Vix.Vips.Image.t(),
                description: """
                Path to the overlay image or a `Vix` image.

                You can get a `Vix` image for example by calling `Image.open/2`,
                `Image.Text.text/2` or `Vix.Vips.Image.new_from_buffer/2`.
                """
              ],
              x: [
                spec: integer() | :center | :left | :right,
                default: :center,
                description: """
                Distance of the overlay image from the left (or right if negative)
                border of the frame. Can be also set to center, left or right.
                """
              ],
              y: [
                spec: integer() | :middle | :top | :bottom,
                default: :middle,
                description: """
                Distance of the overlay image from the top (or bottom if negative)
                border of the frame. Can be also set to middle, top or bottom.
                """
              ],
              blend_mode: [
                spec: Image.BlendMode.t(),
                default: :over,
                description: """
                The manner in which the overlay is composed on the frame.
                """
              ]

  @impl true
  def handle_init(_ctx, options) do
    state = %{
      overlay_planes: open_overlay(options.overlay),
      compose_options: options |> Map.take([:x, :y, :blend_mode]) |> Enum.to_list()
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, buffer, ctx, state) do
    %RawVideo{width: width, height: height} = ctx.pads.input.stream_format
    %{overlay_planes: overlay_planes, compose_options: compose_options} = state
    image_planes = open_planes(buffer.payload, width, height)
    composed = compose_planes(image_planes, overlay_planes, compose_options)
    {[buffer: {:output, %{buffer | payload: composed}}], state}
  end

  defp open_overlay(overlay) do
    overlay = if is_binary(overlay), do: Image.open!(overlay), else: overlay
    {:ok, overlay_yuv} = Image.YUV.write_to_binary(overlay, :C420)
    planes = open_planes(overlay_yuv, Image.width(overlay), Image.height(overlay))
    add_alpha(planes, overlay)
  end

  defp open_planes(yuv, width, height) do
    half_width = div(width, 2)
    half_height = div(height, 2)
    y_size = width * height
    uv_size = half_width * half_height
    <<y::binary-size(y_size), u::binary-size(uv_size), v::binary-size(uv_size)>> = yuv

    {:ok, y} = Vimage.new_from_binary(y, width, height, 1, :VIPS_FORMAT_UCHAR)
    {:ok, u} = Vimage.new_from_binary(u, half_width, half_height, 1, :VIPS_FORMAT_UCHAR)
    {:ok, v} = Vimage.new_from_binary(v, half_width, half_height, 1, :VIPS_FORMAT_UCHAR)
    {y, u, v}
  end

  defp add_alpha(planes, image) do
    alpha = image[3]
    downsized_alpha = Operation.subsample!(alpha, 2, 2)

    {y, u, v} = planes

    y = Operation.bandjoin!([y, alpha])
    u = Operation.bandjoin!([u, downsized_alpha])
    v = Operation.bandjoin!([v, downsized_alpha])

    {y, u, v}
  end

  defp compose_planes({image_y, image_u, image_v}, {overlay_y, overlay_u, overlay_v}, opts) do
    uv_x = if is_integer(opts[:x]), do: div(opts[:x], 2), else: opts[:x]
    uv_y = if is_integer(opts[:y]), do: div(opts[:y], 2), else: opts[:y]
    opts_uv = [x: uv_x, y: uv_y]
    composed_y = compose_plane(image_y, overlay_y, opts)
    composed_u = compose_plane(image_u, overlay_u, opts_uv)
    composed_v = compose_plane(image_v, overlay_v, opts_uv)
    composed_y <> composed_u <> composed_v
  end

  defp compose_plane(image, overlay, opts) do
    composed = Image.compose!(image, overlay, opts)
    {:ok, binary} = Vimage.write_to_binary(composed[0])
    binary
  end
end
