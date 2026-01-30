import React from 'react';

const AzPrimeSVGAvatar: React.FC = () => (
  <div className="flex flex-col items-center">
    <div className="relative w-40 h-40">
      {/* Glowing neon ring */}
      <svg className="absolute inset-0 w-full h-full animate-spin-slow" viewBox="0 0 160 160">
        <circle
          cx="80"
          cy="80"
          r="74"
          fill="none"
          stroke="#00fff7"
          strokeWidth="4"
          opacity="0.5"
          style={{ filter: 'drop-shadow(0 0 16px #00fff7)' }}
        />
      </svg>
      {/* Face (stylized, simple) */}
      <svg className="absolute inset-0 w-full h-full" viewBox="0 0 160 160">
        {/* Head */}
        <ellipse cx="80" cy="80" rx="60" ry="70" fill="#232b3a" stroke="#00fff7" strokeWidth="2" />
        {/* Eyes */}
        <ellipse className="azprime-eye" cx="60" cy="90" rx="8" ry="12" fill="#00eaff" />
        <ellipse className="azprime-eye" cx="100" cy="90" rx="8" ry="12" fill="#00eaff" />
        {/* Mouth */}
        <ellipse cx="80" cy="120" rx="18" ry="6" fill="#00fff7" opacity="0.2" />
        {/* Tech lines */}
        <rect x="75" y="40" width="10" height="30" fill="#00fff7" opacity="0.08" rx="5" />
        <rect x="50" y="60" width="6" height="18" fill="#00fff7" opacity="0.08" rx="3" />
        <rect x="104" y="60" width="6" height="18" fill="#00fff7" opacity="0.08" rx="3" />
      </svg>
    </div>
    <span className="text-cyan-400 mt-2 font-orbitron tracking-widest text-lg">AZ PRIME</span>
    <style>{`
      .azprime-eye {
        animation: azprime-blink 4s infinite;
        -webkit-animation: azprime-blink 4s infinite;
        transform-origin: center;
      }
      @keyframes azprime-blink {
        0%, 92%, 100% { ry: 12; }
        94%, 98% { ry: 2; }
      }
      @-webkit-keyframes azprime-blink {
        0%, 92%, 100% { ry: 12; }
        94%, 98% { ry: 2; }
      }
    `}</style>
  </div>
);

export default AzPrimeSVGAvatar;
