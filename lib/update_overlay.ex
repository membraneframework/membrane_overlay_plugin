defmodule Membrane.OverlayFilter.UpdateOverlay do
  @moduledoc """
  Specifies the overlay update notification.
  """

  @enforce_keys [:overlay, :x, :y, :blend_mode]
  defstruct @enforce_keys

  @typedoc """
  Specifies the overlay update.
  """
  @type t :: %__MODULE__{
          overlay: Path.t() | Vix.Vips.Image.t(),
          x: integer() | :center | :left | :right,
          y: integer() | :middle | :top | :bottom,
          blend_mode: Image.BlendMode.t()
        }
end
