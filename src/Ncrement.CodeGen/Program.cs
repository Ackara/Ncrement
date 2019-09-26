using NJsonSchema.Generation;
using System.IO;

namespace Acklann.Ncrement
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            string schemaFile = Path.Combine(Path.GetDirectoryName(typeof(Program).Assembly.Location), $"{nameof(Ncrement)}-schema.json".ToLowerInvariant());
            if (args.Length > 0 && string.IsNullOrEmpty(args[0]) == false) schemaFile = args[0];

            string folder = Path.GetDirectoryName(schemaFile);
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

            var settings = new JsonSchemaGeneratorSettings()
            {
                ContractResolver = new Newtonsoft.Json.Serialization.DefaultContractResolver() { NamingStrategy = new Newtonsoft.Json.Serialization.CamelCaseNamingStrategy() }
            };
            var generator = new JsonSchemaGenerator(settings);
            var schema = generator.Generate(typeof(Manifest));
            File.WriteAllText(schemaFile, schema.ToJson());
        }
    }
}