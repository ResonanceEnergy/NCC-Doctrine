import React, { useState } from 'react';

interface ITDepartmentProps {}

const ITDepartment: React.FC<ITDepartmentProps> = () => {
  const [query, setQuery] = useState('');
  const [responses, setResponses] = useState<any>({});

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) return;

    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000';
    const token = localStorage.getItem('ncc_token');
    try {
      const res = await fetch(`${apiUrl}/api/it-consult?q=${encodeURIComponent(query)}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      setResponses(data);
    } catch (err) {
      console.error('Failed to fetch IT consult:', err);
      setResponses({ error: 'Failed to get IT consultation' });
    }
  };

  return (
    <div className="bg-cyan-900 bg-opacity-80 p-4 rounded-lg border border-cyan-400 shadow-lg">
      <h3 className="text-cyan-300 text-lg mb-4">IT Security Department</h3>
      <p className="text-cyan-400 text-sm mb-4">
        Security-cleared IT consultants serving Security 10 Division. Available to C-Suite with Safety Captain + AZ PRIME approval.
      </p>

      <div className="mb-4 p-3 bg-cyan-800 rounded border border-cyan-600">
        <h4 className="text-cyan-200 font-semibold mb-2">Team Structure:</h4>
        <ul className="text-cyan-300 text-sm space-y-1">
          <li><strong>Team Captain:</strong> Strategic IT security leadership</li>
          <li><strong>Ethical Hacker 1:</strong> Offensive security expert</li>
          <li><strong>Ethical Hacker 2:</strong> Defensive security specialist</li>
        </ul>
        <p className="text-cyan-400 text-xs mt-2">
          Super nerds with unlimited toolkit, constant assessment, and C-Suite knowledge sharing.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="mb-4">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Consult IT Security Department..."
          className="w-full p-2 bg-cyan-800 text-white border border-cyan-400 rounded mb-2"
        />
        <button
          type="submit"
          className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 text-white rounded transition"
        >
          Request IT Consultation
        </button>
      </form>

      <div className="space-y-2 max-h-64 overflow-y-auto">
        {Object.entries(responses).map(([member, response]) => (
          <div key={member} className="bg-cyan-800 p-3 rounded border border-cyan-600">
            <div className="text-cyan-200 font-semibold mb-1">{member}:</div>
            <div className="text-cyan-300 text-sm">{response as string}</div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ITDepartment;