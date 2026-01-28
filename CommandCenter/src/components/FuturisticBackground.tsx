import React from 'react';

// A full-screen SVG background with animated glowing grid and moving lines
const FuturisticBackground: React.FC = () => (
  <div className="absolute inset-0 w-full h-full -z-10 overflow-hidden">
    <svg
      className="w-full h-full"
      viewBox="0 0 1920 1080"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ position: 'absolute', width: '100%', height: '100%' }}
    >
      {/* Glowing grid */}
      <g>
        {[...Array(20)].map((_, i) => (
          <line
            key={`v-${i}`}
            x1={(i * 96)}
            y1={0}
            x2={(i * 96)}
            y2={1080}
            stroke="#00fff7"
            strokeWidth="1"
            opacity="0.08"
          />
        ))}
        {[...Array(12)].map((_, i) => (
          <line
            key={`h-${i}`}
            x1={0}
            y1={(i * 90)}
            x2={1920}
            y2={(i * 90)}
            stroke="#00fff7"
            strokeWidth="1"
            opacity="0.08"
          />
        ))}
      </g>
      {/* Animated moving lines */}
      <g>
        <rect>
          <animate attributeName="x" from="0" to="1920" dur="8s" repeatCount="indefinite" />
        </rect>
        <line x1="0" y1="200" x2="1920" y2="220" stroke="#00fff7" strokeWidth="2" opacity="0.12">
          <animate attributeName="y1" from="200" to="1080" dur="6s" repeatCount="indefinite" />
          <animate attributeName="y2" from="220" to="1100" dur="6s" repeatCount="indefinite" />
        </line>
        <line x1="0" y1="800" x2="1920" y2="820" stroke="#00fff7" strokeWidth="2" opacity="0.12">
          <animate attributeName="y1" from="800" to="0" dur="7s" repeatCount="indefinite" />
          <animate attributeName="y2" from="820" to="20" dur="7s" repeatCount="indefinite" />
        </line>
      </g>
      {/* Neon glow overlay */}
      <rect x="0" y="0" width="1920" height="1080" fill="url(#glow)" opacity="0.18" />
      <defs>
        <radialGradient id="glow" cx="50%" cy="50%" r="80%" fx="50%" fy="50%">
          <stop offset="0%" stopColor="#00fff7" stopOpacity="0.5" />
          <stop offset="100%" stopColor="#0f2027" stopOpacity="0" />
        </radialGradient>
      </defs>
    </svg>
    {/* Extra CSS for subtle animated glow */}
    <style>{`
      .futuristic-bg-glow {
        animation: bg-glow-pulse 6s ease-in-out infinite alternate;
      }
      @keyframes bg-glow-pulse {
        0% { filter: blur(0px) brightness(1); }
        100% { filter: blur(4px) brightness(1.2); }
      }
    `}</style>
  </div>
);

export default FuturisticBackground;
