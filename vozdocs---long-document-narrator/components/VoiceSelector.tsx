
import React from 'react';

interface VoiceSelectorProps {
  selectedVoice: string;
  onVoiceChange: (voice: string) => void;
}

const VOICES = [
  { id: 'Kore', name: 'Kore (Male, Professional)', description: 'Balanced and clear' },
  { id: 'Puck', name: 'Puck (Male, Warm)', description: 'Friendly and conversational' },
  { id: 'Charon', name: 'Charon (Male, Deep)', description: 'Authoritative and steady' },
  { id: 'Kore', name: 'Kore (Balanced)', description: 'Versatile narrator' },
  { id: 'Fenrir', name: 'Fenrir (Deep)', description: 'Strong narrative presence' }
];

const VoiceSelector: React.FC<VoiceSelectorProps> = ({ selectedVoice, onVoiceChange }) => {
  return (
    <div className="space-y-3">
      <label className="block text-sm font-medium text-gray-700">Choose Narrator Voice</label>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {VOICES.map((voice) => (
          <button
            key={voice.id}
            onClick={() => onVoiceChange(voice.id)}
            className={`p-3 text-left border rounded-lg transition-all ${
              selectedVoice === voice.id
                ? 'border-blue-500 bg-blue-50 ring-2 ring-blue-200'
                : 'border-gray-200 hover:border-blue-300 bg-white'
            }`}
          >
            <p className="font-semibold text-sm">{voice.name}</p>
            <p className="text-xs text-gray-500">{voice.description}</p>
          </button>
        ))}
      </div>
    </div>
  );
};

export default VoiceSelector;
