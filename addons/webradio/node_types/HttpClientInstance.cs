using Godot;
using System.Collections.Generic;
using System.Text.RegularExpressions;

[GlobalClass]
public partial class HttpClientInstance : Node
{
    [Signal]
    public delegate void PcmReadyEventHandler(byte[] pcm);

    [Export]
    public string RadioUrl { get; set; } = "";

    private List<byte> _buffer = new List<byte>();
    private HttpClient _httpClient;
    private Mp3Decoder _decoder = new Mp3Decoder();

    private const float BufferTime = 5f;
    private const int BufferSize = 320 * 1000 / 8 * (int)BufferTime * 2;
    private const int BufferEmitThreshold = 320 * 1000 / 8 * (int)BufferTime;

    public override void _Ready()
    {
        _httpClient = new HttpClient();
        _httpClient.ReadChunkSize = BufferSize;

        var parsed = ParseUrl(RadioUrl);
        if (parsed.Error)
        {
            QueueFree();
            return;
        }

        string host = parsed.Domain;
        int port = parsed.Port;

        if (parsed.Scheme == "https")
        {
            var tls = TlsOptions.Client();
            _httpClient.ConnectToHost(host, port, tls);
        }
        else
        {
            _httpClient.ConnectToHost(host, port);
        }
    }

    public override void _Process(double delta)
    {
        if (_httpClient == null)
            return;

        _httpClient.Poll();
        var status = _httpClient.GetStatus();

        if (status == HttpClient.Status.Body)
        {
            BufferData();
        }
        else if (status == HttpClient.Status.Connected)
        {
            var path = ParseUrl(RadioUrl).Path;
            _httpClient.Request(HttpClient.Method.Get, path, new string[]{});
        }
        else if (status == HttpClient.Status.CantConnect ||
                 status == HttpClient.Status.CantResolve ||
                 status == HttpClient.Status.ConnectionError ||
                 status == HttpClient.Status.TlsHandshakeError ||
                 status == HttpClient.Status.Disconnected)
        {
            GD.PushError($"Error with connection to stream: {RadioUrl}");
            QueueFree();
        }
    }

    private void BufferData()
    {
        if (!_httpClient.HasResponse())
            return;

        var data = _httpClient.ReadResponseBodyChunk();
        if (data.Length == 0)
            return;
        _buffer.AddRange(data);

        if (_buffer.Count >= BufferEmitThreshold)
            EmitBuffer();
    }

    private void EmitBuffer()
    {
        var chunk = _buffer.ToArray();
        _buffer.Clear();
        if (chunk.Length > 0)
        {
            byte[] pcmBytes = _decoder.Decode(chunk);
            if (pcmBytes.Length > 0)
            {
                EmitSignal(SignalName.PcmReady, pcmBytes);
            }
        }
    }

    private (string Scheme, string Domain, int Port, string Path, bool Error) ParseUrl(string url)
    {
        var result = (Scheme: "", Domain: "", Port: 0, Path: "", Error: false);
        var regex = new Regex(@"^(https?)://([^/:]+)(?::(\d+))?(.*)$");
        var match = regex.Match(url);
        if (match.Success)
        {
            result.Scheme = match.Groups[1].Value;
            result.Domain = match.Groups[2].Value;
            result.Port = match.Groups[3].Success && match.Groups[3].Value != "" ? int.Parse(match.Groups[3].Value) : (result.Scheme == "https" ? 443 : 80);
            result.Path = match.Groups[4].Success && match.Groups[4].Value != "" ? match.Groups[4].Value : "/";
        }
        else
        {
            GD.PushError($"Invalid URL format: {url}");
            result.Error = true;
        }
        return result;
    }
}
