import React, { useState } from 'react';

// Replace the src URL with your Ready Player Me avatar link after creation
const READY_PLAYER_ME_URL = "https://readyplayer.me/avatar?frameApi";

const Avatar3D: React.FC = () => {
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  const handleLoad = () => {
    setIsLoading(false);
  };

  const handleError = () => {
    setIsLoading(false);
    setHasError(true);
  };

  return (
    <div className="w-full flex justify-center items-center bg-[#181a20] rounded-xl p-4 shadow-inner border border-cyan-700/30">
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-[#181a20] rounded-xl">
          <div className="text-cyan-400 text-sm">Loading AZ PRIME Avatar...</div>
        </div>
      )}
      
      {hasError ? (
        <div className="flex flex-col items-center justify-center text-center p-4">
          <div className="w-16 h-16 bg-cyan-900 rounded-full flex items-center justify-center mb-2">
            <span className="text-2xl">👤</span>
          </div>
          <div className="text-cyan-300 text-sm font-semibold">AZ PRIME</div>
          <div className="text-cyan-400 text-xs">Avatar Unavailable</div>
          <div className="text-cyan-500 text-xs mt-1">Resilient Fallback Active</div>
        </div>
      ) : (
        <iframe
          src={READY_PLAYER_ME_URL}
          title="AZ PRIME 3D Avatar"
          width="320"
          height="480"
          style={{ border: 'none', borderRadius: '1rem', background: '#10131a' }}
          allow="camera; microphone; fullscreen; autoplay"
          onLoad={handleLoad}
          onError={handleError}
        />
      )}
    </div>
  );
};

export default Avatar3D;
