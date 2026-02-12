//+------------------------------------------------------------------+
//|                                              CConfigProvider.mqh |
//|                                  Copyright 2026, Project Talos . |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Project Talos."
#property link      "https://www.mql5.com"

class CConfigProvider
{
public:
    static string ReadFile(string filename)
    {
        // Removido FILE_COMMON para ler da pasta local do terminal
        int handle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_ANSI);
        if(handle == INVALID_HANDLE) return "";
        
        string content = "";
        while(!FileIsEnding(handle))
            content += FileReadString(handle);
            
        FileClose(handle);
        return content;
    }

    // Parse corrigido com sequências de escape MQL5
    static string ParseString(string json, string key)
    {
        string search = "\"" + key + "\":\"";
        int pos = StringFind(json, search);
        if(pos < 0) return "";
        
        int start = pos + StringLen(search);
        int end = StringFind(json, "\"", start);
        if(end < 0) return "";
        
        return StringSubstr(json, start, end - start);
    }

    static double ParseDouble(string json, string key)
    {
        string search = "\"" + key + "\":";
        int pos = StringFind(json, search);
        if(pos < 0) return 0.0;
        
        int start = pos + StringLen(search);
        int end = StringFind(json, ",", start);
        if(end < 0) end = StringFind(json, "}", start);
        
        string val = StringSubstr(json, start, end - start);
        StringTrimLeft(val);
        StringTrimRight(val);
        
        return StringToDouble(val);
    }
};
