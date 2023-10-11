using System;
using System.Threading.Tasks;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

using Azure;
using Azure.AI.OpenAI;
using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.DependencyCollector;
using Microsoft.ApplicationInsights.Extensibility;


namespace client_app
{
    public class MyTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            telemetry.Context.Cloud.RoleName = "client_app";
        }
    }
}