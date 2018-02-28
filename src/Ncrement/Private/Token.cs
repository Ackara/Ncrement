namespace Ncrement
{
    public struct Token
    {
        public Token(string tagName, string value)
        {
            TagName = tagName;
            Value = value;
        }

        public readonly string TagName, Value;
    }
}