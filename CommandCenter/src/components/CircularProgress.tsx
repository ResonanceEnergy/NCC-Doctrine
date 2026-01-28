import React from 'react';

interface CircularProgressProps {
  value: number;
  max: number;
  size?: number;
  strokeWidth?: number;
  color?: string;
  bgColor?: string;
  label?: string;
}

const CircularProgress: React.FC<CircularProgressProps> = ({
  value,
  max,
  size = 180,
  strokeWidth = 14,
  color = '#00fff7',
  bgColor = '#222b3a',
  label,
}) => {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const progress = Math.min(value / max, 1);
  const offset = circumference * (1 - progress);

  return (
    <svg width={size} height={size} className="block mx-auto">
      <circle
        cx={size / 2}
        cy={size / 2}
        r={radius}
        fill="none"
        stroke={bgColor}
        strokeWidth={strokeWidth}
        opacity={0.25}
      />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={radius}
        fill="none"
        stroke={color}
        strokeWidth={strokeWidth}
        strokeDasharray={circumference}
        strokeDashoffset={offset}
        strokeLinecap="round"
        style={{ filter: 'drop-shadow(0 0 8px ' + color + ')' }}
        transform={`rotate(-90 ${size / 2} ${size / 2})`}
      />
      <text
        x="50%"
        y="50%"
        textAnchor="middle"
        dominantBaseline="central"
        fontSize={size * 0.32}
        fill={color}
        fontFamily="Orbitron, monospace"
        style={{ filter: 'drop-shadow(0 0 4px ' + color + ')' }}
      >
        {value}
      </text>
      {label && (
        <text
          x="50%"
          y={size * 0.78}
          textAnchor="middle"
          fontSize={size * 0.13}
          fill="#fff"
          opacity={0.7}
          fontFamily="Orbitron, monospace"
        >
          {label}
        </text>
      )}
    </svg>
  );
};

export default CircularProgress;
