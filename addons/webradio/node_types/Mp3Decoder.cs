using System.IO;
using Godot;
using FFMpegCore;
using FFMpegCore.Pipes;

[GlobalClass]
public partial class Mp3Decoder : RefCounted
{
    public byte[] Decode(byte[] buffer)
    {
        using var inputStream = new MemoryStream(buffer);
        using var outputStream = new MemoryStream();

        FFMpegArguments
            .FromPipeInput(new StreamPipeSource(inputStream))
            .OutputToPipe(new StreamPipeSink(outputStream), options => options
                .WithAudioCodec("pcm_s16le")
                .WithCustomArgument("-ac 2")
                .WithAudioSamplingRate(48000)
                .ForceFormat("s16le"))
            .ProcessSynchronously();

        return outputStream.ToArray();
    }
}
