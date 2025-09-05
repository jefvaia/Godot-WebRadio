using Godot;
using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using FFMpegCore;
using FFMpegCore.Pipes;

[GlobalClass]
public partial class HttpClientInstance : Node
{
    [Signal]
    public delegate void PcmReadyEventHandler(byte[] pcm);

    [Export]
    public string RadioUrl { get; set; } = "";

    public override void _Ready()
    {
        ConfigureFfmpeg();
        _ = StreamWithFfmpeg();
    }

    private static void ConfigureFfmpeg()
    {
        var osName = OS.GetName().ToLowerInvariant();
        var baseDir = AppContext.BaseDirectory;
        var folder = Path.Combine(baseDir, "thirdparty", "ffmpeg", osName);
        var ffmpegExePath = Path.Combine(folder, "ffmpeg.exe");

        if (osName != "windows")
        {
            var ffmpegNoExt = Path.Combine(folder, "ffmpeg");
            if (!File.Exists(ffmpegNoExt))
            {
                try
                {
                    File.CreateSymbolicLink(ffmpegNoExt, ffmpegExePath);
                }
                catch
                {
                    File.Copy(ffmpegExePath, ffmpegNoExt, true);
                }
            }
        }

        GlobalFFOptions.Configure(new FFOptions
        {
            BinaryFolder = folder
        });
    }

    private async Task StreamWithFfmpeg()
    {
        var pcmStream = new PcmPipeStream(chunk =>
            CallDeferred(nameof(EmitPcm), chunk));

        await FFMpegArguments
            .FromUrlInput(new Uri(RadioUrl))
            .OutputToPipe(new StreamPipeSink(pcmStream), options => options
                .WithAudioCodec("pcm_s16le")
                .WithCustomArgument("-ac 2")
                .WithAudioSamplingRate(48000)
                .ForceFormat("s16le"))
            .ProcessAsynchronously();
    }

    private void EmitPcm(byte[] pcm)
    {
        EmitSignal(SignalName.PcmReady, pcm);
    }

    private class PcmPipeStream : Stream
    {
        private readonly Action<byte[]> _onChunk;
        private readonly List<byte> _buffer = new();
        private const int EmitSize = 4096;

        public PcmPipeStream(Action<byte[]> onChunk)
        {
            _onChunk = onChunk;
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            for (int i = offset; i < offset + count; i++)
            {
                _buffer.Add(buffer[i]);
                if (_buffer.Count >= EmitSize)
                {
                    EmitChunk();
                }
            }
        }

        public override Task WriteAsync(byte[] buffer, int offset, int count, CancellationToken cancellationToken)
        {
            Write(buffer, offset, count);
            return Task.CompletedTask;
        }

        private void EmitChunk()
        {
            var chunk = _buffer.GetRange(0, EmitSize).ToArray();
            _buffer.RemoveRange(0, EmitSize);
            _onChunk(chunk);
        }

        public override void Flush()
        {
            if (_buffer.Count > 0)
            {
                var chunk = _buffer.ToArray();
                _buffer.Clear();
                _onChunk(chunk);
            }
        }

        public override bool CanRead => false;
        public override bool CanSeek => false;
        public override bool CanWrite => true;
        public override long Length => 0;
        public override long Position { get => 0; set { } }

        public override int Read(byte[] buffer, int offset, int count) => 0;
        public override long Seek(long offset, SeekOrigin origin) => 0;
        public override void SetLength(long value) { }
    }
}

