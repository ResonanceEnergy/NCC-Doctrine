
import { useState, useEffect } from 'react';
import Panel from './components/Panel';
import Header from './components/Header';
import AnimatedCircularMetric from './components/AnimatedCircularMetric';
import AzPrimeSVGAvatar from './components/AzPrimeSVGAvatar';
import FuturisticHUDBackground from './components/FuturisticHUDBackground';
import ManualReviewChecklist from './components/ManualReviewChecklist';
import ExportChecklistTracker from './components/ExportChecklistTracker';
import ProjectsPanel from './components/ProjectsPanel';
import ChatPanel from './components/ChatPanel';
import CSuiteAgents from './components/CSuiteAgents';
import CSuiteFramework from './components/CSuiteFramework';
import ITDepartment from './components/ITDepartment';import Login from './components/Login';
import TaskManagement from './components/TaskManagement';
import Security10Dashboard from './components/Security10Dashboard';
import CSuiteOversight from './components/CSuiteOversight';
function App() {
  // State for authentication
  const [loggedIn, setLoggedIn] = useState(false);
  const [token, setToken] = useState<string | null>(null);
  const [user, setUser] = useState<any>(null);
  // State for live data
  const [priorities, setPriorities] = useState<string[] | null>(null);
  const [analytics, setAnalytics] = useState<any>(null);
  const [timeline, setTimeline] = useState<any[] | null>(null);
  const [projects, setProjects] = useState<any[] | null>(null);
  const [loading, setLoading] = useState(true);
  // Avatar state
  const [avatarUrl] = useState<string>("/image-futuristic-man-with-blue-eyes_893012-105705.avif");
  // Export preview mode
  const [exportPreview, setExportPreview] = useState(false);
  const [newPriority, setNewPriority] = useState('');

  const handleLogin = (newToken: string, newUser: any) => {
    setToken(newToken);
    setUser(newUser);
    localStorage.setItem('ncc_token', newToken);
    localStorage.setItem('ncc_user', JSON.stringify(newUser));
    setLoggedIn(true);
  };

  const addPriority = async () => {
    if (!newPriority.trim()) return;
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000';
    const authToken = token || localStorage.getItem('ncc_token');
    try {
      const res = await fetch(`${apiUrl}/api/priorities`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify({ priority: newPriority, user: user?.username })
      });
      const data = await res.json();
      setPriorities(data.priorities);
      setNewPriority('');
    } catch (err) {
      console.error('Failed to add priority:', err);
      // Fallback: add locally
      setPriorities(prev => [newPriority, ...(prev || [])]);
      setNewPriority('');
    }
  };

  useEffect(() => {
    const storedToken = localStorage.getItem('ncc_token');
    const storedUser = localStorage.getItem('ncc_user');
    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
      setLoggedIn(true);
    }
  }, []);

  useEffect(() => {
    if (!loggedIn) return;

    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000';
    const authToken = token || localStorage.getItem('ncc_token');

    setLoading(true);

    Promise.all([
      fetch(`${apiUrl}/api/priorities`, {
        headers: { 'Authorization': `Bearer ${authToken}` }
      }).then(res => res.json()).catch(() => ({ priorities: [
        'Maintain comms redundancy',
        'EMP readiness',
        'Critical project: Avatar Center'
      ] })),
      fetch(`${apiUrl}/api/projects`, {
        headers: { 'Authorization': `Bearer ${authToken}` }
      }).then(res => res.json()).catch(() => ({ projects: [] }))
    ]).then(([prioritiesData, projectsData]) => {
      setPriorities(prioritiesData.priorities);
      setProjects(projectsData.projects);
      setAnalytics({
        activeProjects: projectsData.projects.length,
        alerts: 0,
        opsPackets: 7
      });
      setTimeline([
        { event: 'System boot', time: '2026-01-27T08:00:00Z' },
        { event: 'EMP readiness check', time: '2026-01-27T09:00:00Z' }
      ]);
      setLoading(false);
    }).catch(err => {
      console.error('Failed to fetch data:', err);
      setLoading(false);
    });
  }, [loggedIn, token]);

  if (!loggedIn) {
    return <Login onLogin={handleLogin} />;
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0f2027] to-[#2c5364] flex flex-col relative overflow-hidden">
      <FuturisticHUDBackground />
      {/* Export Preview Toggle */}
      <div className="absolute top-2 right-2 z-50">
        <button
          className="px-3 py-1 rounded bg-cyan-800 text-white border border-cyan-400 shadow hover:bg-cyan-600 transition"
          onClick={() => setExportPreview((v) => !v)}
        >
          {exportPreview ? 'Exit Export Preview' : 'Export Preview'}
        </button>
      </div>
      {/* Header and AZ PRIME Avatar */}
      {!exportPreview && (
        <div className="w-full flex items-center justify-between px-8 py-4" style={{height: '18vh', minHeight: 100, maxHeight: 160}}>
          <Header
            bankAccount={"$0.00"}
            avatarUrl={avatarUrl}
            corpName="NCC CORP."
            personaName="AZ PRIME"
            user={user}
          />
          {/* AZ PRIME Avatar with emoji expression (placeholder) */}
          <div className="flex flex-col items-center" data-testid="avatar">
            <AzPrimeSVGAvatar />
            <span className="text-cyan-300 text-xs mt-1">AZ PRIME</span>
          </div>
          {/* Futuristic Action Buttons */}
          <div className="flex gap-4">
            <button className="px-4 py-2 rounded-lg bg-cyan-900 bg-opacity-60 text-cyan-200 border border-cyan-400 shadow-lg hover:bg-cyan-700 hover:text-white transition-all neon-glow" data-testid="btn">Refresh</button>
            <button className="px-4 py-2 rounded-lg bg-yellow-900 bg-opacity-60 text-yellow-200 border border-yellow-400 shadow-lg hover:bg-yellow-700 hover:text-white transition-all neon-glow" data-testid="btn">Add Widget</button>
            <button className="px-4 py-2 rounded-lg bg-pink-900 bg-opacity-60 text-pink-200 border border-pink-400 shadow-lg hover:bg-pink-700 hover:text-white transition-all neon-glow" data-testid="btn">Settings</button>
            <button className="px-4 py-2 rounded-lg bg-blue-900 bg-opacity-60 text-blue-200 border border-blue-400 shadow-lg hover:bg-blue-700 hover:text-white transition-all neon-glow" data-testid="btn">AZ Emoji</button>
          </div>
        </div>
      )}
      {/* Dashboard Main Grid */}
      <main className="flex-1 w-full flex items-end justify-center" style={{minHeight: '75vh'}}>
        <div className="w-full h-full max-w-screen-2xl grid grid-cols-5 grid-rows-2 gap-6 p-6">
          {/* Alerts */}
          <div className="col-span-1 row-span-1 flex flex-col">
            <Panel title="Alerts" accentColor="yellow" className="w-full text-center flex-1">
              <span className="text-3xl font-bold text-yellow-400">{analytics?.alerts ?? 0}</span>
            </Panel>
          </div>
          {/* Ops Packets */}
          <div className="col-span-1 row-span-1 flex flex-col">
            <Panel title="Ops Packets" accentColor="cyan" className="w-full text-center flex-1">
              <span className="text-3xl font-bold text-cyan-400">{analytics?.opsPackets ?? 0}</span>
            </Panel>
          </div>
          {/* Main Metric (center) */}
          <div className="col-span-2 row-span-2 flex flex-col items-center justify-center" data-testid="panel-metrics">
            <AnimatedCircularMetric
              value={analytics?.activeProjects ?? 0}
              max={100}
              label="ACTIVE PROJECTS"
              color="#00fff7"
              glowColor="#00fff7"
            />
          </div>
          {/* Priority List */}
          <div className="col-span-1 row-span-1 flex flex-col" data-testid="priority-list">
            <Panel title="Priority List" accentColor="cyan" className="w-full flex-1">
              <div className="mb-2">
                <input
                  type="text"
                  value={newPriority}
                  onChange={(e) => setNewPriority(e.target.value)}
                  placeholder="Add priority..."
                  className="w-full p-1 bg-cyan-800 text-white border border-cyan-400 rounded text-xs"
                />
                <button
                  onClick={addPriority}
                  className="w-full mt-1 px-2 py-1 bg-cyan-600 hover:bg-cyan-500 text-white rounded text-xs transition"
                >
                  Add
                </button>
              </div>
              <ul className="mt-2 text-white text-sm space-y-1 max-h-32 overflow-y-auto">
                {loading && <li>Loading...</li>}
                {!loading && priorities && priorities.length === 0 && <li>No priorities.</li>}
                {!loading && priorities && priorities.map((p, i) => (
                  <li key={i}>{i + 1}. {p}</li>
                ))}
              </ul>
            </Panel>
          </div>
          {/* Timeline / Activity */}
          <div className="col-span-1 row-span-1 flex flex-col" data-testid="activity-feed">
            <Panel title="Timeline / Activity" accentColor="cyan" className="w-full flex-1">
              <ul className="mt-2 text-white text-sm space-y-1">
                {loading && <li>Loading...</li>}
                {!loading && timeline && timeline.length === 0 && <li>No events.</li>}
                {!loading && timeline && timeline.map((t, i) => (
                  <li key={i}>{t.time}: {t.event}</li>
                ))}
              </ul>
            </Panel>
          </div>
          {/* Bank Account */}
          <div className="col-span-1 row-span-1 flex flex-col">
            <Panel title="Bank Account" accentColor="yellow" className="w-full text-center flex-1">
              <span className="text-4xl font-bold text-yellow-300 mt-2">$0.00</span>
              <span className="text-xs text-gray-400 mt-1 block">Motivational Driver</span>
            </Panel>
          </div>
        </div>
      </main>


      {/* Manual Review Checklist UI */}
      <div className="w-full flex justify-center mt-8">
        <ManualReviewChecklist />
      </div>

      {/* Projects Panel */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-4xl w-full">
          <ProjectsPanel projects={projects || []} />
        </div>
      </div>

      {/* C-Suite Agents */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-4xl w-full">
          <CSuiteAgents />
        </div>
      </div>

      {/* C-Suite Framework */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-6xl w-full">
          <CSuiteFramework />
        </div>
      </div>

      {/* IT Security Department */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-4xl w-full">
          <ITDepartment />
        </div>
      </div>

      {/* Task Management System */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-6xl w-full">
          <TaskManagement />
        </div>
      </div>

      {/* Security 10 Dashboard */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-6xl w-full">
          <Security10Dashboard />
        </div>
      </div>

      {/* C-Suite Executive Oversight */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-6xl w-full">
          <CSuiteOversight />
        </div>
      </div>

      {/* Chat Panel */}
      <div className="w-full flex justify-center mt-8">
        <div className="max-w-4xl w-full">
          <ChatPanel />
        </div>
      </div>

      {/* Export/Deployment Review Tracker */}
      <div className="w-full flex justify-center mt-8 mb-12">
        <ExportChecklistTracker />
      </div>

      {/* Neon Glow Button Effect */}
      <style>{`
        .neon-glow {
          box-shadow: 0 0 8px #00fff7, 0 0 16px #00fff7, 0 0 32px #00fff733;
        }
        .neon-glow:hover {
          box-shadow: 0 0 16px #fff, 0 0 32px #00fff7, 0 0 64px #00fff7;
        }
      `}</style>
    </div>
  );
}

export default App;
