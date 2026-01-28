import React from 'react';

// Replace the src URL with your Ready Player Me avatar link after creation
const READY_PLAYER_ME_URL = "https://readyplayer.me/avatar?frameApi";

const Avatar3D: React.FC = () => {
  return (
    <div className="w-full flex justify-center items-center bg-[#181a20] rounded-xl p-4 shadow-inner border border-cyan-700/30">
      <iframe
        src={READY_PLAYER_ME_URL}
        title="AZ PRIME 3D Avatar"
        width="320"
        height="480"
        style={{ border: 'none', borderRadius: '1rem', background: '#10131a' }}
        allow="camera; microphone; fullscreen; autoplay"
      />
    </div>
  );
};

export default Avatar3D;
