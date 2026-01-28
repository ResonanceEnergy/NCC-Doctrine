import React, { useRef } from 'react';

interface AvatarBuilderProps {
  avatarUrl: string;
  personaName?: string;
  onImageChange?: (file: File) => void;
}

const AvatarBuilder: React.FC<AvatarBuilderProps> = ({ avatarUrl, personaName = 'AZ PRIME', onImageChange }) => {
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      onImageChange?.(e.target.files[0]);
    }
  };

  return (
    <div className="flex flex-col items-center gap-2">
      <div className="relative w-32 h-32 rounded-full border-4 border-cyan-400 shadow-lg overflow-hidden bg-[#181a20] animate-pulse-slow">
        <img src={avatarUrl} alt={personaName} className="object-cover w-full h-full" />
        {/* Overlay for edit */}
        <button
          className="absolute bottom-2 right-2 bg-cyan-700/80 text-white text-xs px-2 py-1 rounded shadow hover:bg-cyan-500 transition"
          onClick={() => fileInputRef.current?.click()}
        >
          Change
        </button>
        <input
          type="file"
          accept="image/*"
          ref={fileInputRef}
          className="hidden"
          onChange={handleFileChange}
        />
      </div>
      <span className="text-cyan-400 mt-1 font-orbitron tracking-widest text-sm">{personaName}</span>
    </div>
  );
};

export default AvatarBuilder;
