
import React, { useState, useCallback, useRef } from 'react';
import { AppStatus, DocumentInfo } from './types';
import { generateSpeech } from './services/geminiService';
import { decodeAudioData, audioBufferToWav } from './utils/audioUtils';
import VoiceSelector from './components/VoiceSelector';

// Note: pdfjsLib is available globally via script in index.html
declare const pdfjsLib: any;

const App: React.FC = () => {
  const [status, setStatus] = useState<AppStatus>(AppStatus.IDLE);
  const [docInfo, setDocInfo] = useState<DocumentInfo | null>(null);
  const [voice, setVoice] = useState('Kore');
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);

  const extractTextFromPdf = async (file: File): Promise<string> => {
    const arrayBuffer = await file.arrayBuffer();
    const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
    let fullText = '';
    
    setDocInfo({
      name: file.name,
      size: file.size,
      pages: pdf.numPages,
      text: ''
    });

    for (let i = 1; i <= pdf.numPages; i++) {
      const page = await pdf.getPage(i);
      const content = await page.getTextContent();
      const strings = content.items.map((item: any) => item.str);
      fullText += strings.join(' ') + '\n';
      setProgress(Math.round((i / pdf.numPages) * 100));
    }
    return fullText;
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      setStatus(AppStatus.PARSING);
      setError(null);
      setProgress(0);

      let text = '';
      if (file.type === 'application/pdf') {
        text = await extractTextFromPdf(file);
      } else if (file.type === 'text/plain') {
        text = await file.text();
        setDocInfo({
          name: file.name,
          size: file.size,
          pages: 1,
          text: text
        });
      } else {
        throw new Error("Unsupported file type. Please use PDF or TXT.");
      }

      setDocInfo(prev => prev ? { ...prev, text } : null);
      setStatus(AppStatus.IDLE);
    } catch (err: any) {
      console.error(err);
      setError(err.message || "Error reading file.");
      setStatus(AppStatus.ERROR);
    }
  };

  const handleGenerateSpeech = async () => {
    if (!docInfo?.text) return;

    try {
      setStatus(AppStatus.GENERATING);
      setProgress(0);
      setError(null);

      if (!audioContextRef.current) {
        audioContextRef.current = new (window.AudioContext || (window as any).webkitAudioContext)({ sampleRate: 24000 });
      }

      // Note: For 16+ pages, the text might be very long.
      // Gemini 2.5 Flash TTS has limits. For a production app, we should chunk the text.
      // In this simple version, we'll try to process a substantial block.
      // We will slice the text to a safe limit (e.g., ~15,000 chars) for stability in a single call.
      const textToProcess = docInfo.text.length > 20000 
        ? docInfo.text.slice(0, 20000) + " [Truncated due to TTS limits]" 
        : docInfo.text;

      const pcmData = await generateSpeech(textToProcess, voice);
      
      const audioBuffer = await decodeAudioData(pcmData, audioContextRef.current);
      const wavBlob = audioBufferToWav(audioBuffer);
      const url = URL.createObjectURL(wavBlob);

      setAudioUrl(url);
      setStatus(AppStatus.READY);
    } catch (err: any) {
      console.error(err);
      setError(err.message || "Failed to generate speech.");
      setStatus(AppStatus.ERROR);
    }
  };

  return (
    <div className="min-h-screen p-4 md:p-8 flex flex-col items-center max-w-4xl mx-auto">
      <header className="w-full mb-8 text-center">
        <h1 className="text-4xl font-bold text-blue-600 flex items-center justify-center gap-2">
          <span>🔊</span> VozDocs
        </h1>
        <p className="text-gray-500 mt-2">Convert long documents into Brazilian Portuguese narration</p>
      </header>

      <main className="w-full space-y-8 bg-white p-6 rounded-2xl shadow-sm border border-gray-100">
        {/* Upload Section */}
        <div className={`border-2 border-dashed rounded-xl p-8 text-center transition-colors ${docInfo ? 'border-green-300 bg-green-50' : 'border-gray-200 hover:border-blue-400'}`}>
          <input
            type="file"
            id="fileInput"
            className="hidden"
            accept=".pdf,.txt"
            onChange={handleFileUpload}
          />
          <label htmlFor="fileInput" className="cursor-pointer">
            {docInfo ? (
              <div className="flex flex-col items-center">
                <span className="text-3xl mb-2">📄</span>
                <p className="font-semibold text-lg">{docInfo.name}</p>
                <p className="text-sm text-gray-500">{docInfo.pages} pages found</p>
                <button 
                  onClick={(e) => { e.preventDefault(); setDocInfo(null); setAudioUrl(null); setStatus(AppStatus.IDLE); }}
                  className="mt-4 text-sm text-red-500 hover:underline"
                >
                  Change file
                </button>
              </div>
            ) : (
              <div className="flex flex-col items-center py-4">
                <span className="text-5xl mb-4">📥</span>
                <p className="text-lg font-medium">Click to upload document</p>
                <p className="text-sm text-gray-400">PDF or TXT files (16+ pages supported)</p>
              </div>
            )}
          </label>
        </div>

        {/* Configuration Section */}
        {docInfo && (
          <div className="space-y-6 animate-in fade-in duration-500">
            <VoiceSelector selectedVoice={voice} onVoiceChange={setVoice} />
            
            <div className="flex flex-col items-center gap-4">
              {status === AppStatus.PARSING && (
                <div className="w-full bg-gray-200 rounded-full h-2.5">
                  <div className="bg-blue-600 h-2.5 rounded-full" style={{ width: `${progress}%` }}></div>
                  <p className="text-xs text-center mt-2 text-gray-500">Extracting text... {progress}%</p>
                </div>
              )}

              {status === AppStatus.GENERATING && (
                <div className="flex flex-col items-center gap-2">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  <p className="text-sm text-blue-600 font-medium italic">Gemini is narrating your document in Brazilian Portuguese...</p>
                </div>
              )}

              {status !== AppStatus.GENERATING && status !== AppStatus.PARSING && (
                <button
                  onClick={handleGenerateSpeech}
                  disabled={!docInfo}
                  className="w-full sm:w-auto px-8 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-full font-bold shadow-lg shadow-blue-200 transition-all active:scale-95 disabled:opacity-50"
                >
                  {audioUrl ? 'Regenerate Narration' : 'Generate Brazilian Portuguese Audio'}
                </button>
              )}
            </div>
          </div>
        )}

        {/* Result Audio Section */}
        {audioUrl && (
          <div className="mt-8 p-6 bg-blue-50 rounded-xl border border-blue-100 flex flex-col items-center gap-4 animate-in slide-in-from-bottom-4 duration-500">
            <h3 className="font-bold text-blue-800 flex items-center gap-2">
              <span className="text-xl">✨</span> Narration Ready
            </h3>
            <audio controls src={audioUrl} className="w-full max-w-md" />
            <a
              href={audioUrl}
              download={`${docInfo?.name.split('.')[0] || 'narration'}_br_portuguese.wav`}
              className="text-sm bg-white px-4 py-2 rounded-lg border border-blue-200 text-blue-600 hover:bg-blue-100 transition-colors font-medium flex items-center gap-2"
            >
              <span>⬇️</span> Download WAV Audio
            </a>
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="mt-4 p-4 bg-red-50 text-red-700 rounded-lg border border-red-100 text-sm">
            <strong>Error:</strong> {error}
          </div>
        )}
      </main>

      <footer className="mt-auto py-8 text-gray-400 text-sm">
        Powered by Gemini 2.5 Flash TTS & PDF.js
      </footer>
    </div>
  );
};

export default App;
