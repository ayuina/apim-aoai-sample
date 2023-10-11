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

        private static async Task CallOpenAIHello(int loop)
        {
            var prompt = new ChatCompletionsOptions()
            {
                Messages = {
                    new ChatMessage(ChatRole.System, @"You are an AI assistant that helps people find information."),
                    new ChatMessage(ChatRole.User, @"Hello"),
                }
            };

            Console.WriteLine("Calling {0}", _endpoint);

            if(loop == 1)
            {
                var response = await CallOpenAI(prompt);
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
            else
            {
                for (int idx = 0; idx < loop; idx++)
                {
                    var response = await CallOpenAI(prompt);
                    var raw = response.GetRawResponse();
                    Console.WriteLine("{0} {1} from {2} region",
                        raw.Status,
                        raw.ReasonPhrase,
                        raw.Headers.Where(h => h.Name == "x-ms-region").First().Value);

                }
            }

        }

    }
}