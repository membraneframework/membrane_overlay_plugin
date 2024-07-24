Mix.install([
  :membrane_h264_plugin,
  :membrane_h264_ffmpeg_plugin,
  :membrane_file_plugin,
  :membrane_hackney_plugin,
  :req,
  {:membrane_overlay_plugin, path: "."}
])

defmodule Example do
  import Membrane.ChildrenSpec
  require Membrane.RCPipeline, as: RCPipeline
  alias Membrane.OverlayFilter.OverlayDescription

  def run() do
    {:ok, overlay} =
      Req.get!("https://avatars.githubusercontent.com/u/25247695?s=200&v=4").body
      |> Vix.Vips.Image.new_from_buffer()

    overlay = Image.thumbnail!(overlay, 100)

    pipeline = Membrane.RCPipeline.start_link!()
    RCPipeline.subscribe(pipeline, _any)

    RCPipeline.exec_actions(pipeline,
      spec:
        child(%Membrane.Hackney.Source{
          location:
            "https://raw.githubusercontent.com/membraneframework/static/gh-pages/samples/big-buck-bunny/bun33s_720x480.h264",
          hackney_opts: [follow_redirects: true]
        })
        |> child(Membrane.H264.Parser)
        |> child(Membrane.H264.FFmpeg.Decoder)
        |> child(%Membrane.OverlayFilter{
          initial_overlay: %OverlayDescription{overlay: overlay, x: :right, y: :top}
        })
        |> child(Membrane.H264.FFmpeg.Encoder)
        |> child(:sink, %Membrane.File.Sink{location: "output.h264"})
    )

    RCPipeline.await_end_of_stream(pipeline, :sink)
    RCPipeline.terminate(pipeline)
  end
end

Example.run()
