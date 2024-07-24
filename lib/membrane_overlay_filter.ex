defmodule Membrane.OverlayFilter do
  @moduledoc """
  Applies image or text overlay to video.

  Based on `Image`.

  You need to provide the first overlay description as the `initial_overlay` option.
  To update overlay dynamically you can send {:update_overlay,`Membrane.OverlayFilter.OverlayDescription`}
  notification from parent.
  """
  use Membrane.Filter

  require Membrane.Logger

  alias Membrane.OverlayFilter.OverlayDescription
  alias Membrane.RawVideo

  def_input_pad :input, accepted_format: %RawVideo{pixel_format: :I420}
  def_output_pad :output, accepted_format: %RawVideo{pixel_format: :I420}

  alias Vix.Vips.Image, as: Vimage
  alias Vix.Vips.Operation

  def_options initial_overlay: [
                spec: OverlayDescription.t(),
                description: """
                Description of the overlay that will be initially used.
                """
              ]

  @impl true
  def handle_init(_ctx, options) do
    state = state_from_overlay_description(options.initial_overlay)

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

  @impl true
  def handle_parent_notification(
        {:update_overlay, overlay_description = %OverlayDescription{}},
        _ctx,
        _state
      ) do
    state = state_from_overlay_description(overlay_description)

    {[], state}
  end

  @impl true
  def handle_parent_notification(other, _ctx, state) do
    Membrane.Logger.warning("Unsupported parent notification: #{inspect(other)}")
    {[], state}
  end

  @spec state_from_overlay_description(OverlayDescription.t()) :: map()
  defp state_from_overlay_description(%OverlayDescription{
         x: x,
         y: y,
         overlay: overlay,
         blend_mode: blend_mode
       }) do
    opts_y = [x: x, y: y, blend_mode: blend_mode]
    uv_x = if is_integer(x), do: div(x, 2), else: x
    uv_y = if is_integer(y), do: div(y, 2), else: y
    opts_uv = [x: uv_x, y: uv_y, blend_mode: blend_mode]

    %{
      overlay_planes: open_overlay(overlay),
      compose_options: {opts_y, opts_uv}
    }
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

  defp compose_planes(
         {image_y, image_u, image_v},
         {overlay_y, overlay_u, overlay_v},
         {opts_y, opts_uv}
       ) do
    composed_y = compose_plane(image_y, overlay_y, opts_y)
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
