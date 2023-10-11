using System;
using System.Threading.Tasks;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Configuration;

using Azure;
using Azure.AI.OpenAI;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DependencyCollector;
using Microsoft.ApplicationInsights.Extensibility;
using System.Runtime.CompilerServices;
using System.ComponentModel.DataAnnotations;


namespace client_app // Note: actual namespace depends on the project name.
{
    internal partial class Program
    {
        private static void AddFunctionDefinition(ChatCompletionsOptions prompt)
        {
            prompt.Functions = new[]{
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
                    }")
                },
                new FunctionDefinition("prompt_location"){
                    Description = "天気予報を知りたい場所についてユーザーの入力を促します。",
                    Parameters = BinaryData.FromString(@"{
                        ""type"": ""object"",
                        ""properties"": {},
                        ""required"": []
                    }")
                },
                new FunctionDefinition("prompt_date"){
                    Description = "天気予報を知りたい日付についてユーザーの入力を促します。",
                    Parameters = BinaryData.FromString(@"{
                        ""type"": ""object"",
                        ""properties"": {},
                        ""required"": []
                    }")
                }
            };
        }

        private static async Task CallOpenAIFuncCalling(string endpoint, string apikey)
        {
            var prompt = new ChatCompletionsOptions()
            {
                Messages = {
                    new ChatMessage(ChatRole.System, @"天気予報ボットです。ユーザーの問い合わせに含まれる場所と日付に応じた天気を取得して回答してください。必要な情報が不足する場合にはユーザー入力を促すための prompt_location 関数および prompt_location 関数が利用可能です。関数名について仮定を立てないでください。"),
                    new ChatMessage(ChatRole.Assistant, @"天気予報を知りたい日付と場所を教えてください"),
                },
                FunctionCall = FunctionDefinition.Auto,
            };
            AddFunctionDefinition(prompt);
            
            var choice = await CallOpenAIFuncCalling(endpoint, apikey, prompt);
            while(choice.FinishReason == CompletionsFinishReason.FunctionCall)
            {
                var funcResponse = await CallFunction(choice.Message.FunctionCall);
                prompt.Messages.Add(
                    new ChatMessage(){
                        Role = ChatRole.Function,
                        Name = choice.Message.FunctionCall.Name,
                        Content = funcResponse
                    }
                );
                choice = await CallOpenAIFuncCalling(endpoint, apikey, prompt);
            }
        }

        private static async Task<ChatChoice> CallOpenAIFuncCalling(string endpoint, string apikey, ChatCompletionsOptions prompt)
        {
            Console.WriteLine("===== Calling {0} =====", endpoint);
            prompt.Messages.ToList().ForEach(m => {
                Console.WriteLine("{0} > {1}", m.Role, m.Content);
            });

            var response = await CallOpenAI(endpoint, apikey, prompt);
            var raw = response.GetRawResponse();
            Console.WriteLine("{0} {1} from {2} region",
                raw.Status,
                raw.ReasonPhrase,
                raw.Headers.Where(h => h.Name == "x-ms-region").First().Value);
            
            var choice = response.Value.Choices.First();
            if(choice.FinishReason == CompletionsFinishReason.FunctionCall)
            {
                Console.WriteLine("need to call {0}", choice.Message.FunctionCall.Name);
            }
            else
            {
                Console.WriteLine("{0} > {1}", choice.Message.Role, choice.Message.Content);
            }

            return choice;
        }

        private static async Task<string> CallFunction(FunctionCall functionCall)
        {
            Console.WriteLine("===== Calling {0} =====", functionCall.Name);
            Console.WriteLine("{0}", functionCall.Arguments);
            string result = "";
            switch (functionCall.Name) 
            {
                case "get_weather_forecast":
                    result = await GetWeatherForecast(functionCall);
                    break;
                case "prompt_location":
                    result = await PromptLocation(functionCall);
                    break;
                case "prompt_date":
                    result = await PromptDate(functionCall);
                    break;
                default:
                    throw new InvalidOperationException($"function {functionCall.Name} is not defined.");
            }

            Console.WriteLine("result:\r\n{0}", result);
            return result;
        }

        private static async Task<string> GetWeatherForecast(FunctionCall functionCall)
        {
            var funcResponse = JsonNode.Parse(functionCall.Arguments);
            funcResponse!["weather"] = "曇り";
            funcResponse!["temperature"] = 27.0;
            return await Task.FromResult(
                funcResponse.ToJsonString(new JsonSerializerOptions() { WriteIndented = true })
            );
        }

        private static async Task<string> PromptLocation(FunctionCall functionCall)
        {
            if(Environment.OSVersion.Platform == PlatformID.Win32NT)
            {
                Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
                Console.InputEncoding = Encoding.GetEncoding("shift-jis");
            }

            string location = string.Empty;
            while(string.IsNullOrEmpty(location))
            {
                Console.Write("場所を入力してください > ");
                location = Console.ReadLine() ?? string.Empty;
            }

            var result = new JsonObject
            {
                ["location"] = location
            };

            return await Task.FromResult( result.ToJsonString() );
        }

        private static async Task<string> PromptDate(FunctionCall functionCall)
        {
            if(Environment.OSVersion.Platform == PlatformID.Win32NT)
            {
                Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
                Console.InputEncoding = Encoding.GetEncoding("shift-jis");
            }

            string date = string.Empty;
            while(string.IsNullOrEmpty(date))
            {
                Console.Write("日付を入力してください > ");
                date = Console.ReadLine() ?? string.Empty;
            }
            var result = new JsonObject
            {
                ["date"] = date
            };

            return await Task.FromResult( result.ToJsonString() );
        }

    }
}