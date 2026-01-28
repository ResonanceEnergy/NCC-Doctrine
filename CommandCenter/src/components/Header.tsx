import React from 'react';

interface HeaderProps {
  bankAccount: string;
  avatarUrl: string;
  corpName?: string;
  personaName?: string;
}

const Header: React.FC<HeaderProps> = ({ bankAccount, avatarUrl, corpName = 'NCC CORP.', personaName = 'AZ PRIME' }) => {
  return (
    <header className="w-full flex items-center justify-between bg-[#10131a]/80 px-8 py-4 border-b border-cyan-400/30 shadow-lg relative z-10">
      {/* Bank Account */}
      <div className="flex flex-col items-start">
        <span className="text-xs text-gray-400 tracking-widest">BANK ACCOUNT</span>
        <span className="text-2xl font-bold text-yellow-300 drop-shadow-glow">{bankAccount}</span>
      </div>
      {/* Corp Name */}
      <div className="flex flex-col items-center">
        <span className="text-3xl font-orbitron font-bold text-cyan-300 tracking-widest drop-shadow-glow">{corpName}</span>
        <span className="text-xs text-cyan-500 tracking-widest mt-1">COMMAND CONSOLE</span>
      </div>
      {/* Avatar */}
      <div className="flex flex-col items-center">
        <div className="w-16 h-16 rounded-full border-4 border-cyan-400 shadow-lg overflow-hidden animate-pulse-slow bg-[#181a20]">
          <img src={avatarUrl} alt={personaName} className="object-cover w-full h-full" />
        </div>
        <span className="text-xs text-cyan-400 mt-1 font-orbitron tracking-widest">{personaName}</span>
      </div>
    </header>
  );
};

export default Header;
