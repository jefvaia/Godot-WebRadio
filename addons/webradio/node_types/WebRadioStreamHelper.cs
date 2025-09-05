using System.Dynamic;
using Godot;

[GlobalClass]
public partial class WebRadioStreamHelper : Node
{
    public static WebRadioStreamHelper Instance = null;

    public static void CreateInstance()
    {
        WebRadioStreamHelper newInstance = new WebRadioStreamHelper();
        newInstance.Name = "WebRadioStreamHelper";
        (Engine.GetMainLoop() as SceneTree).Root.CallDeferred("add_child", newInstance, true);
        WebRadioStreamHelper.Instance = newInstance;
    }

    public static HttpClientInstance AddRadio(string url)
    {
        if (WebRadioStreamHelper.Instance == null)
        {
            CreateInstance();
        }

        var newClient = new HttpClientInstance();
        newClient.RadioUrl = url;
        newClient.Name = GD.Hash(url).ToString();
        WebRadioStreamHelper.Instance.AddChild(newClient, true);
        GD.Print("Created new radio client");
        return newClient;
    }

    public static HttpClientInstance GetRadio(string url)
    {
        if (WebRadioStreamHelper.Instance == null)
        {
            return null;
        }
        string hashName = GD.Hash(url).ToString();
        return WebRadioStreamHelper.Instance.GetNodeOrNull<HttpClientInstance>(hashName);
    }
}
