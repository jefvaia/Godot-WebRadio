using Godot;
using System.Collections.Generic;

[GlobalClass]
public partial class WebRadioStreamPlayer3D : AudioStreamPlayer3D
{
    [Export]
    public string Url { get; set; } = "";

    private HttpClientInstance _httpInstance;
    private AudioStreamGeneratorPlayback _playback;
    private Queue<Vector2> _frameQueue = new();
    private Mutex _queueMutex = new();
    private System.Threading.Thread _pushThread;
    private bool _threadRunning = false;

    private const int REFILL_THRESHOLD = 1024;

    public override void _Ready()
    {
        var helper = GetNode<WebRadioStreamHelper>("/root/WebRadioStreamHelper");
        _httpInstance = helper.GetRadio(Url);
        if (_httpInstance == null)
            _httpInstance = helper.AddRadio(Url);

        var generator = new AudioStreamGenerator
        {
            MixRate = 48000,
            BufferLength = 5.0f
        };
        Stream = generator;
        Play();
        _playback = (AudioStreamGeneratorPlayback)GetStreamPlayback();

        int initialFrames = (int)(generator.MixRate * 0.5f);
        for (int i = 0; i < initialFrames; i++)
            _playback.PushFrame(Vector2.Zero);

        _threadRunning = true;
        _pushThread = new System.Threading.Thread(PushFrames);
        _pushThread.Start();

        _httpInstance.PcmReady += RefreshStream;
    }

    private void RefreshStream(byte[] pcm)
    {
        if (_playback == null || pcm.Length == 0)
            return;
        List<Vector2> localQueue = new();
        for (int i = 0; i + 3 < pcm.Length; i += 4)
        {
            short lS = System.BitConverter.ToInt16(pcm, i);
            short rS = System.BitConverter.ToInt16(pcm, i + 2);
            float left = lS / 32768f;
            float right = rS / 32768f;
            localQueue.Add(new Vector2(left, right));
        }
        _queueMutex.Lock();
        foreach (var frame in localQueue)
            _frameQueue.Enqueue(frame);
        _queueMutex.Unlock();
    }

    private void PushFrames()
    {
        while (_threadRunning)
        {
            if (_playback == null)
            {
                OS.DelayMsec(10);
                continue;
            }
            int avail = _playback.GetFramesAvailable();
            if (avail > REFILL_THRESHOLD)
            {
                _queueMutex.Lock();
                while (avail > 0 && _frameQueue.Count > 0)
                {
                    _playback.PushFrame(_frameQueue.Dequeue());
                    avail--;
                }
                _queueMutex.Unlock();
                while (avail > 0)
                {
                    _playback.PushFrame(Vector2.Zero);
                    avail--;
                }
            }
            else
            {
                OS.DelayMsec(5);
            }
        }
    }

    public override void _ExitTree()
    {
        _threadRunning = false;
        _pushThread?.Join();
    }
}
