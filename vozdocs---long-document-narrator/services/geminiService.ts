
import { GoogleGenAI, Modality } from "@google/genai";
import { decode } from "../utils/audioUtils";

const API_KEY = process.env.API_KEY;

export const generateSpeech = async (text: string, voiceName: string = 'Kore'): Promise<Uint8Array> => {
  if (!API_KEY) throw new Error("API Key is missing");

  const ai = new GoogleGenAI({ apiKey: API_KEY });
  
  // Using gemini-2.5-flash-preview-tts as requested
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash-preview-tts",
    contents: [{ 
      parts: [{ 
        text: `Narre o seguinte texto em português do Brasil com uma voz natural, clara e profissional:\n\n${text}` 
      }] 
    }],
    config: {
      responseModalities: [Modality.AUDIO],
      speechConfig: {
        voiceConfig: {
          prebuiltVoiceConfig: { voiceName },
        },
      },
    },
  });

  const base64Audio = response.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
  if (!base64Audio) {
    throw new Error("No audio data returned from Gemini");
  }

  return decode(base64Audio);
};
