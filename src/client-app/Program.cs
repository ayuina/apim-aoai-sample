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
    internal class Program
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

            var mode = config["mode"];
            var loop = string.IsNullOrEmpty(config["loop"]) ? 1 : int.Parse(config["loop"]?? "");
            var apimurl = string.Format("https://{0}.azure-api.net/", config["APIM_NAME"]);
            var apimkey = config["APIM_KEY"] ?? "";
            var aoaiurl = string.Format("https://{0}.openai.azure.com/", config["AOAI_NAME"]);
            var aoaikey = config["AOAI_KEY"] ?? "";

            switch (config["mode"]?.ToUpper())
            {
                case "APIM":
                    await CallOpenAIHello(apimurl, apimkey, loop);
                    break;
                case "AOAI":
                    await CallOpenAIHello(aoaiurl, aoaikey, loop);
                    break;
                case "FUNCCALL":
                    await CallOpenAIFuncCalling(aoaiurl, aoaikey);
                    break;
                default:
                    Console.WriteLine("Please specify mode as APIM or AOAI");
                    break;
            }

        }

        private static async Task CallOpenAIFuncCalling(string endpoint, string apikey)
        {
            var prompt = new ChatCompletionsOptions()
            {
                Messages = {
                    new ChatMessage(ChatRole.System, @"You are an AI assistant that helps people find information."),
                    new ChatMessage(ChatRole.User, @"Hello"),
                },
                FunctionCall = FunctionDefinition.Auto,
                Functions = {
                    new FunctionDefinition("get_weather_forecast"){
                        Description = "指定された日付と場所の天気予報を取得します。",
                        Parameters = BinaryData.FromString(@"{
                            ""type"": ""object"",
                            ""properties"": {
                                ""location"": {
                                    ""type"": ""string"",
                                    ""description"": ""天気予報を取得する場所の地名""
                                },
                                ""date"": {
                                    ""type"": ""string"",
                                    ""description"": ""天気予報を取得する日時""
                                }
                            },
                            ""required"": [""location"", ""datetime""]
                        }"),
                    },
                }
            };
            
            Console.WriteLine("Calling {0}", endpoint);
            await foreach(var response in CallOpenAI(endpoint, apikey, prompt, 1))
            {
                var raw = response.GetRawResponse();

                Console.WriteLine("{0} {1} from {2} region",
                raw.Status,
                raw.ReasonPhrase,
                raw.Headers.Where(h => h.Name == "x-ms-region").First().Value);

                raw.Headers.OrderBy(h => h.Name).ToList().ForEach(h =>
                {
                    Console.WriteLine($"{h.Name}: {h.Value}");
                });

                Console.WriteLine();

                using (var writer = new Utf8JsonWriter(Console.OpenStandardOutput(), new JsonWriterOptions() { Indented = true }))
                {
                    JsonSerializer.Serialize(writer, response.Value);
                }
            };
        }

        private static async Task CallOpenAIHello(string endpoint, string apikey, int loop)
        {
            var prompt = new ChatCompletionsOptions()
            {
                Messages = {
                    new ChatMessage(ChatRole.System, @"You are an AI assistant that helps people find information."),
                    new ChatMessage(ChatRole.User, @"Hello"),
                }
            };

            Console.WriteLine("Calling {0}", endpoint);

            await foreach(var response in CallOpenAI(endpoint, apikey, prompt, loop))
            {
                var raw = response.GetRawResponse();

                Console.WriteLine("{0} {1} from {2} region",
                raw.Status,
                raw.ReasonPhrase,
                raw.Headers.Where(h => h.Name == "x-ms-region").First().Value);

                if (loop == 1)
                {
                    raw.Headers.OrderBy(h => h.Name).ToList().ForEach(h =>
                    {
                        Console.WriteLine($"{h.Name}: {h.Value}");
                    });

                    Console.WriteLine();

                    using (var writer = new Utf8JsonWriter(Console.OpenStandardOutput(), new JsonWriterOptions() { Indented = true }))
                    {
                        JsonSerializer.Serialize(writer, response.Value);
                    }
                }

            };
        }

        //https://learn.microsoft.com/ja-jp/dotnet/api/overview/azure/ai.openai-readme?view=azure-dotnet-preview
        private static async IAsyncEnumerable<Response<ChatCompletions>> CallOpenAI(string endpoint, string apikey, ChatCompletionsOptions prompt, int loop)
        {
            var uri = new Uri(endpoint);
            var cred = new AzureKeyCredential(apikey);
            var client = new OpenAIClient(uri, cred);

            for (int idx = 0; idx < loop; idx++)
            {
                var response = await client.GetChatCompletionsAsync("g35t", prompt);
                yield return response;
            }
        }

    }

    public class MyTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            telemetry.Context.Cloud.RoleName = "client_app";
        }
    }
}