import React from 'react';


interface AnimatedCircularMetricProps {
  value: number;
  max: number;
  label: string;
  color?: string;
  glowColor?: string;
  minSize?: number;
  maxSize?: number;
}


const AnimatedCircularMetric: React.FC<AnimatedCircularMetricProps> = ({
  value,
  max,
  label,
  color = '#00fff7',
  glowColor = '#00fff7',
  minSize = 180,
  maxSize = 320,
}) => {
  // Responsive size based on viewport width
  const vw = typeof window !== 'undefined' ? Math.max(window.innerWidth, 320) : 1024;
  const size = Math.max(minSize, Math.min(maxSize, vw < 640 ? minSize : Math.floor(vw / 4)));
  const strokeWidth = Math.max(12, Math.floor(size / 14));
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const progress = Math.min(value / max, 1);
  const offset = circumference * (1 - progress);

  return (
    <div className="relative flex flex-col items-center justify-center w-full" style={{maxWidth: size}}>
      {/* HUD crosshair overlay */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none" width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size/2} cy={size/2} r={radius+strokeWidth/2} fill="none" stroke={color} strokeWidth="2" opacity="0.18" />
        <circle cx={size/2} cy={size/2} r={radius-strokeWidth/2} fill="none" stroke={color} strokeWidth="1.5" opacity="0.12" />
        <line x1={size/2} y1={strokeWidth/2} x2={size/2} y2={size-strokeWidth/2} stroke={color} strokeWidth="1" opacity="0.18" />
        <line x1={strokeWidth/2} y1={size/2} x2={size-strokeWidth/2} y2={size/2} stroke={color} strokeWidth="1" opacity="0.18" />
      </svg>
      {/* Animated glowing circular progress */}
      <svg width={size} height={size} className="block mx-auto animate-spin-slow" style={{zIndex:1}}>
        <circle
          cx={size/2}
          cy={size/2}
          r={radius}
          fill="none"
          stroke="#222b3a"
          strokeWidth={strokeWidth}
          opacity={0.25}
        />
        <circle
          cx={size/2}
          cy={size/2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={strokeWidth}
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          style={{ filter: `drop-shadow(0 0 16px ${glowColor})` }}
          transform={`rotate(-90 ${size/2} ${size/2})`}
        />
        <text
          x="50%"
          y="50%"
          textAnchor="middle"
          dominantBaseline="central"
          fontSize={size * 0.32}
          fill={color}
          fontFamily="Orbitron, monospace"
          style={{ filter: `drop-shadow(0 0 8px ${glowColor})` }}
        >
          {value}
        </text>
      </svg>
      {/* Neon label */}
      <div className="text-cyan-300 text-lg font-orbitron font-bold tracking-widest text-center mt-2 drop-shadow-glow">
        {label}
      </div>
    </div>
  );
};

export default AnimatedCircularMetric;
