import React, { useState } from 'react';

interface ChatPanelProps {}

const ChatPanel: React.FC<ChatPanelProps> = () => {
  const [query, setQuery] = useState('');
  const [responses, setResponses] = useState<any>({});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;

    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000';
    const token = localStorage.getItem('ncc_token');
    try {
      const res = await fetch(`${apiUrl}/api/chat?q=${encodeURIComponent(query)}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      setResponses(data);
    } catch (err) {
      console.error('Failed to fetch chat:', err);
      setResponses({ error: 'Failed to get responses' });
    }
  };

  return (
    <div className="bg-cyan-900 bg-opacity-80 p-4 rounded-lg border border-cyan-400 shadow-lg">
      <h3 className="text-cyan-300 text-lg mb-4">AI Chat Bots</h3>
      <form onSubmit={handleSubmit} className="mb-4">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Ask the AI bots..."
          className="w-full p-2 bg-cyan-800 text-white border border-cyan-400 rounded mb-2"
        />
        <button
          type="submit"
          className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 text-white rounded transition"
        >
          Ask Bots
        </button>
      </form>
      <div className="space-y-2 max-h-64 overflow-y-auto">
        {Object.entries(responses).map(([bot, response]) => (
          <div key={bot} className="bg-cyan-800 p-3 rounded border border-cyan-600">
            <div className="text-cyan-200 font-semibold mb-1">{bot}:</div>
            <div className="text-cyan-300 text-sm">{response as string}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ChatPanel;