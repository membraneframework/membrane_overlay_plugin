defmodule Membrane.OverlayFilterTest do
  use ExUnit.Case, async: true
  import Membrane.ChildrenSpec
  import Membrane.Testing.Assertions
  alias Membrane.Testing

  test "applies overlay on top of a YUV frame" do
    pipeline =
      Testing.Pipeline.start_link_supervised!(
        spec:
          child(%Testing.Source{
            output: [File.read!("test/fixtures/frame.yuv")]
          })
          |> child(%Membrane.RawVideo.Parser{width: 1920, height: 1080, pixel_format: :I420})
          |> child(%Membrane.OverlayFilter{overlay: "test/fixtures/overlay.png"})
          |> child(:sink, Membrane.Testing.Sink)
      )

    assert_sink_buffer(pipeline, :sink, buffer)
    assert buffer.payload == File.read!("test/fixtures/output.yuv")

    Testing.Pipeline.terminate(pipeline)
  end
end
