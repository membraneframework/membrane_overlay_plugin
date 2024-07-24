defmodule Membrane.OverlayFilter.OverlayDescription do
  @moduledoc """
  Specifies the overlay, its position on the underlay image
  and the blend mode.
  """

  @enforce_keys [:overlay]
  defstruct @enforce_keys ++ [x: :center, y: :middle, blend_mode: :over]

  @typedoc """
  Specifies the overlay, its position on the underlay image
  and the blend mode.
  The following fields can be specified:
  * `overlay` - Path to the overlay image or a `Vix` image.
                You can get a `Vix` image for example by calling `Image.open/2`,
                `Image.Text.text/2` or `Vix.Vips.Image.new_from_buffer/2`.
  * `x` - Distance of the overlay image from the left (or right if negative)
          border of the frame. Can be also set to center, left or right.
          Defaults to `:center`.
  * `y` - Distance of the overlay image from the top (or bottom if negative)
          border of the frame. Can be also set to middle, top or bottom.
          Defaults to `:middle`.
  * `blend_mode` - The manner in which the overlay is composed on the frame.
                   Defaults to `:over`.

  """
  @type t :: %__MODULE__{
          overlay: Path.t() | Vix.Vips.Image.t(),
          x: integer() | :center | :left | :right,
          y: integer() | :middle | :top | :bottom,
          blend_mode: Image.BlendMode.t()
        }
end
