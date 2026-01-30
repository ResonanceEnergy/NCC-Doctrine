import React, { useState } from 'react';

interface CSuiteAgentsProps {}

const CSuiteAgents: React.FC<CSuiteAgentsProps> = () => {
  const [query, setQuery] = useState('');
  const [responses, setResponses] = useState<any>({});
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

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

  // Organize agents by C33 Doctrine structure (3 Teams of 11)
  const agentCategories = {
    teamAlpha: {
      title: 'Team Alpha - Command & Control (11 Agents)',
      agents: [
        'CEO - Vision & Strategy (CDR)',
        'CEO - Financial Operations',
        'CEO - Technology Innovation', 
        'CEO - Operational Excellence',
        'CEO - Market Leadership',
        'XO - Chief of Staff',
        'COO - Operations Control',
        'CFO - Financial Control',
        'CHRO - Human Resources Control',
        'CLO - Legal Control',
        'CCO - Communications Control'
      ]
    },
    teamBravo: {
      title: 'Team Bravo - Communications & Operations (11 Agents)',
      agents: [
        'CTO - Technology Communications',
        'CIO - IT Infrastructure',
        'CDO - Data Communications',
        'CMO - Digital Marketing',
        'CPO - Procurement Systems',
        'CQO - Quality Communications',
        'CEO - Innovation Labs',
        'COO - Supply Chain Operations',
        'CRO - Revenue Operations',
        'CEO - Customer Success',
        'CEO - Corporate Development'
      ]
    },
    teamCharlie: {
      title: 'Team Charlie - Intelligence/Security & Logistics (11 Agents)',
      agents: [
        'CSO - Corporate Security',
        'CEO - Risk Analytics',
        'CEO - Crisis Management',
        'CEO - Diversity & Inclusion',
        'CEO - Sustainability Operations',
        'CPO - Procurement Logistics',
        'CQO - Quality Assurance',
        'Security Captain',
        'Security 10 Division Lead', 
        'Security IT Specialist',
        'EMP Response Coordinator'
      ]
    }
  };

  const getFilteredResponses = () => {
    if (selectedCategory === 'all') return responses;
    
    const categoryAgents = agentCategories[selectedCategory as keyof typeof agentCategories]?.agents || [];
    const filtered: any = {};
    
    Object.entries(responses).forEach(([agent, response]) => {
      if (categoryAgents.includes(agent)) {
        filtered[agent] = response;
      }
    });
    
    return filtered;
  };

  const filteredResponses = getFilteredResponses();

  return (
    <div className="bg-cyan-900 bg-opacity-80 p-4 rounded-lg border border-cyan-400 shadow-lg">
      <h3 className="text-cyan-300 text-lg mb-4">C33 Doctrine Executive Council (33 Agents)</h3>
      <p className="text-cyan-400 text-sm mb-4">
        Consult the complete C33 Doctrine executive structure: 3 Teams of 11 Agents each.
        Team Alpha (Command & Control), Team Bravo (Communications & Operations), Team Charlie (Intelligence/Security & Logistics).
        Aligned with NCC Doctrine military command hierarchy and EMP response protocols.
      </p>
      
      {/* Category Filter */}
      <div className="mb-4">
        <label className="text-cyan-300 text-sm mr-2">Filter by Category:</label>
        <select
          value={selectedCategory}
          onChange={(e) => setSelectedCategory(e.target.value)}
          className="bg-cyan-800 text-cyan-300 border border-cyan-400 rounded px-2 py-1 text-sm"
        >
          <option value="all">All C33 Agents (33)</option>
          <option value="teamAlpha">Team Alpha - Command & Control (11)</option>
          <option value="teamBravo">Team Bravo - Communications & Operations (11)</option>
          <option value="teamCharlie">Team Charlie - Intelligence/Security & Logistics (11)</option>
        </select>
      </div>
      
      <form onSubmit={handleSubmit} className="mb-4">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Consult the C33 Doctrine executive council..."
          className="w-full p-2 bg-cyan-800 text-white border border-cyan-400 rounded mb-2"
        />
        <button
          type="submit"
          className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 text-white rounded transition"
        >
          Consult Executive Council
        </button>
      </form>
      
      <div className="space-y-2 max-h-96 overflow-y-auto">
        {Object.keys(filteredResponses).length === 0 && query && !responses.error && (
          <div className="text-cyan-400 text-sm text-center py-4">
            No responses in selected category. Try selecting "All Agents" or submit a new query.
          </div>
        )}
        
        {Object.entries(filteredResponses).map(([agent, response]) => {
          // Determine category for styling
          let categoryClass = 'border-cyan-600';
          if (agentCategories.teamAlpha.agents.includes(agent)) categoryClass = 'border-red-500';
          else if (agentCategories.teamBravo.agents.includes(agent)) categoryClass = 'border-blue-500';
          else if (agentCategories.teamCharlie.agents.includes(agent)) categoryClass = 'border-green-500';
          
          return (
            <div key={agent} className={`bg-cyan-800 p-3 rounded border ${categoryClass}`}>
              <div className="text-cyan-200 font-semibold mb-1 flex items-center">
                <span className="mr-2">
                  {agentCategories.teamAlpha.agents.includes(agent) && '🎖️'}
                  {agentCategories.teamBravo.agents.includes(agent) && '📡'}
                  {agentCategories.teamCharlie.agents.includes(agent) && '🛡️'}
                </span>
                {agent}
              </div>
              <div className="text-cyan-300 text-sm">{response as string}</div>
            </div>
          );
        })}
        
        {responses.error && (
          <div className="bg-red-800 p-3 rounded border border-red-600">
            <div className="text-red-200 font-semibold mb-1">Error:</div>
            <div className="text-red-300 text-sm">{responses.error}</div>
          </div>
        )}
      </div>
      
      {/* Agent Count Summary */}
      <div className="mt-4 text-xs text-cyan-400 text-center">
        Total C33 Executive Council: 38 agents | Command: 10 | Control: 8 | Communications: 7 | Operations: 6 | Intelligence: 4 | Logistics: 3 | Security: 4
      </div>
    </div>
  );
};

export default CSuiteAgents;