using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;

namespace Acklann.Ncrement
{
    public static class ReplacementToken
    {
        public const string Year = "year";
        public const string Username = "username";

        public const string RootPath = "root-path";

        public static IDictionary<string, string> Create()
        {
            return new Dictionary<string, string>()
            {
                { Year, DateTime.Now.Year.ToString() },
                { Username, Environment.GetEnvironmentVariable("USERNAME") }
            };
        }

        public static void Append(IDictionary<string, string> map, Manifest manifest)
        {
            var properties = from x in typeof(Manifest).GetMembers()
                             where x.MemberType == MemberTypes.Property
                             select (x as PropertyInfo);

            string key;
            foreach (PropertyInfo property in properties)
            {
                key = property.Name.ToLowerInvariant();
                map[key] = Convert.ToString(property.GetValue(manifest));
            }
        }

        public static string Expand(string text, IDictionary<string, string> tokens)
        {
            if (string.IsNullOrEmpty(text) || tokens == null) return text;

            foreach (KeyValuePair<string, string> item in tokens)
            {
                text = Regex.Replace(text, string.Format("{{{0}}}", Regex.Escape(item.Key)), (item.Value ?? string.Empty), RegexOptions.IgnoreCase);
            }

            return text;
        }

        public static IEnumerable<string> GetAll()
        {
            return (from x in typeof(ReplacementToken).GetMembers()
                    where x.MemberType == MemberTypes.Field
                    let field = (x as FieldInfo)
                    where field.IsLiteral
                    select Convert.ToString(field.GetRawConstantValue()));
        }
    }
}