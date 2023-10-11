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

            if(loop == 1)
            {
                var response = await CallOpenAI(endpoint, apikey, prompt);
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

                return;
            }
            

            await foreach(var response in CallOpenAI(endpoint, apikey, prompt, loop))
            {
                var raw = response.GetRawResponse();
                Console.WriteLine("{0} {1} from {2} region",
                    raw.Status,
                    raw.ReasonPhrase,
                    raw.Headers.Where(h => h.Name == "x-ms-region").First().Value);

            };
        }

        //https://learn.microsoft.com/ja-jp/dotnet/api/overview/azure/ai.openai-readme?view=azure-dotnet-preview
        private static async IAsyncEnumerable<Response<ChatCompletions>> CallOpenAI(string endpoint, string apikey, ChatCompletionsOptions prompt, int loop)
        {
            for (int idx = 0; idx < loop; idx++)
            {
                yield return await CallOpenAI(endpoint, apikey, prompt);
            }
        }

    }
}