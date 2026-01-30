import React from 'react';

interface PanelProps {
  title?: string;
  children: React.ReactNode;
  accentColor?: string;
  className?: string;
}

const Panel: React.FC<PanelProps> = ({ title, children, accentColor = 'cyan', className = '' }) => {
  const border = accentColor === 'yellow' ? 'border-yellow-400/40' : 'border-cyan-400/60';
  return (
    <div className={`bg-[#181a20] rounded-xl p-4 shadow-inner border ${border} ${className}`}>
      {title && <span className={`text-${accentColor}-400 text-lg font-semibold`}>{title}</span>}
      <div className="mt-2">{children}</div>
    </div>
  );
};

export default Panel;
