using Godot;

[GlobalClass]
public partial class WebRadioStreamHelper : Node
{
    public HttpClientInstance AddRadio(string url)
    {
        var newClient = new HttpClientInstance();
        newClient.RadioUrl = url;
        newClient.Name = GD.Hash(url).ToString();
        AddChild(newClient, true);
        GD.Print("Created new radio client");
        return newClient;
    }

    public HttpClientInstance GetRadio(string url)
    {
        string hashName = GD.Hash(url).ToString();
        return GetNodeOrNull<HttpClientInstance>(hashName);
    }
}
