import React from 'react';

// Example: Animated glowing circular widget with HUD panel and neon details
const ExampleHudWidget: React.FC = () => {
  return (
    <div className="relative flex flex-col items-center justify-center bg-[#10131a]/90 rounded-2xl border-4 border-cyan-400/60 shadow-2xl p-8 max-w-md mx-auto mt-12 overflow-hidden">
      {/* HUD crosshair overlay */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 320 320">
        <circle cx="160" cy="160" r="120" fill="none" stroke="#00fff7" strokeWidth="2" opacity="0.18" />
        <circle cx="160" cy="160" r="80" fill="none" stroke="#00fff7" strokeWidth="1.5" opacity="0.12" />
        <line x1="160" y1="40" x2="160" y2="280" stroke="#00fff7" strokeWidth="1" opacity="0.18" />
        <line x1="40" y1="160" x2="280" y2="160" stroke="#00fff7" strokeWidth="1" opacity="0.18" />
      </svg>
      {/* Animated glowing circular progress */}
      <div className="relative z-10">
        <svg width="200" height="200" className="block mx-auto animate-spin-slow">
          <circle
            cx="100"
            cy="100"
            r="85"
            fill="none"
            stroke="#222b3a"
            strokeWidth="18"
            opacity="0.25"
          />
          <circle
            cx="100"
            cy="100"
            r="85"
            fill="none"
            stroke="#00fff7"
            strokeWidth="18"
            strokeDasharray={2 * Math.PI * 85}
            strokeDashoffset={2 * Math.PI * 85 * 0.32}
            strokeLinecap="round"
            style={{ filter: 'drop-shadow(0 0 16px #00fff7)' }}
            transform="rotate(-90 100 100)"
          />
          <text
            x="50%"
            y="50%"
            textAnchor="middle"
            dominantBaseline="central"
            fontSize="64"
            fill="#00fff7"
            fontFamily="Orbitron, monospace"
            style={{ filter: 'drop-shadow(0 0 8px #00fff7)' }}
          >
            54
          </text>
        </svg>
        {/* Neon label */}
        <div className="text-cyan-300 text-lg font-orbitron font-bold tracking-widest text-center mt-2 drop-shadow-glow">
          ACTIVE PROJECTS
        </div>
      </div>
      {/* Neon stat panels */}
      <div className="flex gap-6 mt-8 z-10">
        <div className="bg-[#181a20] rounded-xl px-6 py-3 border-2 border-yellow-400/60 shadow-inner flex flex-col items-center">
          <span className="text-3xl font-bold text-yellow-400 drop-shadow-glow">0</span>
          <span className="text-xs text-yellow-300 mt-1 tracking-widest">ALERTS</span>
        </div>
        <div className="bg-[#181a20] rounded-xl px-6 py-3 border-2 border-cyan-400/60 shadow-inner flex flex-col items-center">
          <span className="text-3xl font-bold text-cyan-400 drop-shadow-glow">7</span>
          <span className="text-xs text-cyan-300 mt-1 tracking-widest">OPS PACKETS</span>
        </div>
      </div>
      {/* HUD panel bottom bar */}
      <div className="absolute bottom-0 left-0 w-full h-2 bg-gradient-to-r from-cyan-400/40 via-transparent to-yellow-400/40 blur-sm opacity-70" />
    </div>
  );
};

export default ExampleHudWidget;
