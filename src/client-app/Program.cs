using System;
using System.Text.Json;

using Azure;
using Azure.AI.OpenAI;
using dotenv.net;
using dotenv.net.Utilities;

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
            DotEnv.Load(new DotEnvOptions(probeForEnv: true));

            // var aoaiurl = string.Format("https://{0}.openai.azure.com/", EnvReader.GetStringValue("AOAI_NAME"));
            // var aoaikey = EnvReader.GetStringValue("AOAI_KEY");
            // await CallOpenAI(aoaiurl, aoaikey);

            var apimurl = string.Format("https://{0}.azure-api.net/", EnvReader.GetStringValue("APIM_NAME"));
            var apimkey = EnvReader.GetStringValue("APIM_KEY");
            await CallOpenAI(apimurl, apimkey);

        }

        //https://learn.microsoft.com/ja-jp/dotnet/api/overview/azure/ai.openai-readme?view=azure-dotnet-preview
        private static async Task CallOpenAI(string endpoint, string apikey)
        {
            Console.WriteLine("Calling {0}", endpoint);

            var uri = new Uri(endpoint);
            var cred = new AzureKeyCredential(apikey);
            var client = new OpenAIClient(uri, cred);

            var prompt = new ChatCompletionsOptions()
            {
                Messages = {
                    new ChatMessage(ChatRole.System, @"You are an AI assistant that helps people find information."),
                    new ChatMessage(ChatRole.User, @"hoge"),
                    new ChatMessage(ChatRole.Assistant, @"Hello! How can I assist you today?"),
                }
            };

            var response = await client.GetChatCompletionsAsync("g35t", prompt);

            Console.WriteLine("{0} {1}", response.GetRawResponse().Status, response.GetRawResponse().ReasonPhrase);
            response.GetRawResponse().Headers.OrderBy(h => h.Name).ToList().ForEach(h =>
            {
                Console.WriteLine($"{h.Name}: {h.Value}");
            });

            Console.WriteLine();

            using (var writer = new Utf8JsonWriter(Console.OpenStandardOutput(), new JsonWriterOptions() { Indented = true }))
            {
                JsonSerializer.Serialize(writer, response.Value);
            }

            Console.WriteLine();
            Console.WriteLine();

        }

    }
}