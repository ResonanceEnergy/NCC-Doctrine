import React from 'react';

// Futuristic HUD-style SVG background inspired by your reference
const FuturisticHUDBackground: React.FC = () => (
  <div className="absolute inset-0 w-full h-full -z-10 overflow-hidden bg-[#0a1018]">
    <svg
      className="w-full h-full"
      viewBox="0 0 1920 1080"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ position: 'absolute', width: '100%', height: '100%' }}
    >
      {/* Subtle grid lines */}
      <g>
        {[...Array(20)].map((_, i) => (
          <line
            key={`v-${i}`}
            x1={i * 96}
            y1={0}
            x2={i * 96}
            y2={1080}
            stroke="#00fff7"
            strokeWidth="1"
            opacity="0.04"
          />
        ))}
        {[...Array(12)].map((_, i) => (
          <line
            key={`h-${i}`}
            x1={0}
            y1={i * 90}
            x2={1920}
            y2={i * 90}
            stroke="#00fff7"
            strokeWidth="1"
            opacity="0.04"
          />
        ))}
      </g>
      {/* Central glowing rings and arcs */}
      <g filter="url(#glow)">
        <circle cx="960" cy="540" r="320" stroke="#00fff7" strokeWidth="2" opacity="0.12" />
        <circle cx="960" cy="540" r="220" stroke="#ffb300" strokeWidth="2" opacity="0.10" />
        <circle cx="960" cy="540" r="140" stroke="#ff4e00" strokeWidth="2" opacity="0.10" />
        <circle cx="960" cy="540" r="80" stroke="#00fff7" strokeWidth="2" opacity="0.18" />
        {/* Progress arc */}
        <path d="M960 220 A320 320 0 1 1 1270 900" stroke="#00fff7" strokeWidth="6" opacity="0.25" fill="none" />
        <path d="M960 320 A220 220 0 1 1 1160 800" stroke="#ffb300" strokeWidth="4" opacity="0.18" fill="none" />
        <path d="M960 400 A140 140 0 1 1 1100 700" stroke="#ff4e00" strokeWidth="3" opacity="0.18" fill="none" />
      </g>
      {/* Accent marks and ticks */}
      <g>
        {[...Array(12)].map((_, i) => (
          <rect
            key={`tick-${i}`}
            x={960 + 320 * Math.cos((i * 30) * Math.PI / 180) - 2}
            y={540 + 320 * Math.sin((i * 30) * Math.PI / 180) - 12}
            width="4"
            height="24"
            fill="#00fff7"
            opacity="0.12"
            rx="2"
            transform={`rotate(${i * 30},${960},${540})`}
          />
        ))}
      </g>
      <defs>
        <filter id="glow" x="0" y="0" width="1920" height="1080" filterUnits="userSpaceOnUse">
          <feGaussianBlur stdDeviation="8" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>
    </svg>
    {/* Extra CSS for subtle animated glow */}
    <style>{`
      .hud-bg-glow {
        animation: hud-glow-pulse 6s ease-in-out infinite alternate;
      }
      @keyframes hud-glow-pulse {
        0% { filter: blur(0px) brightness(1); }
        100% { filter: blur(4px) brightness(1.2); }
      }
    `}</style>
  </div>
);

export default FuturisticHUDBackground;
