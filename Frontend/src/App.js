import React, { useState, useEffect } from 'react';
import './App.css';
import TTSService from './services/TTSService';

function App() {
  const [text, setText] = useState('');
  const [voice, setVoice] = useState('Joanna');
  const [audioUrl, setAudioUrl] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [hearts, setHearts] = useState([]);

  // Floating hearts animation
  useEffect(() => {
    const interval = setInterval(() => {
      const newHeart = {
        id: Date.now(),
        left: Math.random() * 100,
        fontSize: Math.random() * 20 + 15,
        duration: Math.random() * 4 + 3
      };
      
      setHearts(prev => [...prev, newHeart]);
      
      // Remove heart after animation
      setTimeout(() => {
        setHearts(prev => prev.filter(heart => heart.id !== newHeart.id));
      }, 6000);
    }, 700);

    return () => clearInterval(interval);
  }, []);

  const handleConvertText = async () => {
    if (!text.trim()) {
      setError('Please type some text!');
      return;
    }

    setIsLoading(true);
    setError('');
    setAudioUrl('');

    try {
      const result = await TTSService.convertText(text, voice);
      
      if (result.audio_url) {
        setAudioUrl(result.audio_url);
      } else if (result.isBase64Encoded) {
        // Handle base64 audio
        const audioBlob = new Blob([result.body], { type: 'audio/mpeg' });
        const url = URL.createObjectURL(audioBlob);
        setAudioUrl(url);
      } else {
        throw new Error('Unexpected response format');
      }
    } catch (err) {
      console.error('Error converting text:', err);
      setError(`Failed to generate audio: ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  const voices = [
    { value: 'Joanna', label: 'Joanna' },
    { value: 'Matthew', label: 'Matthew' },
    { value: 'Amy', label: 'Amy' },
    { value: 'Brian', label: 'Brian' }
  ];

  return (
    <div className="app">
      <div id="hearts">
        {hearts.map(heart => (
          <div
            key={heart.id}
            className="heart"
            style={{
              left: `${heart.left}vw`,
              fontSize: `${heart.fontSize}px`,
              animationDuration: `${heart.duration}s`
            }}
          >
            💖
          </div>
        ))}
      </div>

      <div className="container">
        <h2>🌸 Text to Speech 🎀</h2>

        <textarea
          id="textInput"
          rows="5"
          placeholder="Type something cute..."
          value={text}
          onChange={(e) => setText(e.target.value)}
        />

        <label htmlFor="voice">💖 Choose a voice:</label>
        <select
          id="voice"
          value={voice}
          onChange={(e) => setVoice(e.target.value)}
        >
          {voices.map(voiceOption => (
            <option key={voiceOption.value} value={voiceOption.value}>
              {voiceOption.label}
            </option>
          ))}
        </select>

        <button
          id="speakBtn"
          onClick={handleConvertText}
          disabled={isLoading}
        >
          {isLoading ? (
            <>
              <span className="loading-spinner"></span> Generating...
            </>
          ) : (
            '✨ Speak ✨'
          )}
        </button>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        <h3>🎧 Output:</h3>
        {audioUrl && (
          <audio
            id="audioPlayer"
            controls
            src={audioUrl}
            autoPlay
          />
        )}
      </div>
    </div>
  );
}

export default App;
