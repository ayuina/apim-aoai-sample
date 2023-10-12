using System;
using System.Threading.Tasks;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

using Azure;
using Azure.AI.OpenAI;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DependencyCollector;
using Microsoft.ApplicationInsights.Extensibility;


namespace client_app // Note: actual namespace depends on the project name.
{
    internal partial class Program
    {
        static async Task Main(string[] args)
        {
            try
            {
                await Run(args);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex);
            }
        }

        private static async Task Run(string[] args)
        {
            var config = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json", optional: false)
                .AddJsonFile("appsettings.secrets.json", optional: true)
                .AddCommandLine(args)
                .Build();

            var appiConfig = new TelemetryConfiguration()
            {
                ConnectionString = config["APPI_CONSTR"],
                TelemetryInitializers = { new MyTelemetryInitializer() }
            };
            DependencyTrackingTelemetryModule depModule = new DependencyTrackingTelemetryModule();
            depModule.Initialize(appiConfig);

            _endpoint = string.Format("https://{0}.azure-api.net/", config["APIM_NAME"]);
            _apikey = config["APIM_KEY"] ?? "";
            _model = config["AOAI_MODEL"] ?? "";

            var mode = config["mode"];
            var loop = string.IsNullOrEmpty(config["loop"]) ? 1 : int.Parse(config["loop"]?? "");

            switch (config["mode"]?.ToUpper())
            {
                case "APIM":
                    await CallOpenAIHello(loop);
                    break;
                case "AOAI":
                    _endpoint = string.Format("https://{0}.openai.azure.com/", config["AOAI_NAME"]);
                    _apikey = config["AOAI_KEY"] ?? "";
                    await CallOpenAIHello(loop);
                    break;
                case "FUNCCALL":
                    await CallOpenAIFuncCalling();
                    break;
                default:
                    Console.WriteLine("Please specify mode as APIM or AOAI");
                    break;
            }
        }

        private static string _endpoint = string.Empty;
        private static string _apikey = string.Empty;
        private static string _model = string.Empty;

        private static async Task<Response<ChatCompletions>> CallOpenAI(ChatCompletionsOptions prompt)
        {
            return await CallOpenAI(_endpoint, _apikey, _model, prompt);
        }

        private static async Task<Response<ChatCompletions>> CallOpenAI(string endpoint, string apikey, string modelName, ChatCompletionsOptions prompt)
        {
            var uri = new Uri(endpoint);
            var cred = new AzureKeyCredential(apikey);
            var client = new OpenAIClient(uri, cred);

            var response = await client.GetChatCompletionsAsync(modelName, prompt);
            return response;
        }

    }

}