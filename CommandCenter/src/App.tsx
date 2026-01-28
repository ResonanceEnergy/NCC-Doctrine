
import { useState, useEffect } from 'react';
import Panel from './components/Panel';
import Header from './components/Header';
import AnimatedCircularMetric from './components/AnimatedCircularMetric';
import AzPrimeSVGAvatar from './components/AzPrimeSVGAvatar';
import FuturisticHUDBackground from './components/FuturisticHUDBackground';

function App() {
  // State for live data
  const [priorities, setPriorities] = useState<string[] | null>(null);
  const [analytics, setAnalytics] = useState<any>(null);
  const [timeline, setTimeline] = useState<any[] | null>(null);
  const [loading, setLoading] = useState(true);
  // Avatar state
  const [avatarUrl] = useState<string>("/image-futuristic-man-with-blue-eyes_893012-105705.avif");
  // Export preview mode
  const [exportPreview, setExportPreview] = useState(false);

  useEffect(() => {
    async function fetchData() {
      setLoading(true);
      try {
        const [pRes, aRes, tRes] = await Promise.all([
          fetch('/api/priorities'),
          fetch('/api/analytics'),
          fetch('/api/timeline'),
        ]);
        const pData = await pRes.json();
        const aData = await aRes.json();
        const tData = await tRes.json();
        setPriorities(pData.priorities);
        setAnalytics(aData);
        setTimeline(tData.timeline);
      } catch (err) {
        setPriorities([]);
        setAnalytics({});
        setTimeline([]);
      }
      setLoading(false);
    }
    fetchData();
  }, []);

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
          />
          {/* AZ PRIME Avatar with emoji expression (placeholder) */}
          <div className="flex flex-col items-center">
            <AzPrimeSVGAvatar />
            <span className="text-cyan-300 text-xs mt-1">AZ PRIME</span>
          </div>
          {/* Futuristic Action Buttons */}
          <div className="flex gap-4">
            <button className="px-4 py-2 rounded-lg bg-cyan-900 bg-opacity-60 text-cyan-200 border border-cyan-400 shadow-lg hover:bg-cyan-700 hover:text-white transition-all neon-glow">Refresh</button>
            <button className="px-4 py-2 rounded-lg bg-yellow-900 bg-opacity-60 text-yellow-200 border border-yellow-400 shadow-lg hover:bg-yellow-700 hover:text-white transition-all neon-glow">Add Widget</button>
            <button className="px-4 py-2 rounded-lg bg-pink-900 bg-opacity-60 text-pink-200 border border-pink-400 shadow-lg hover:bg-pink-700 hover:text-white transition-all neon-glow">Settings</button>
            <button className="px-4 py-2 rounded-lg bg-blue-900 bg-opacity-60 text-blue-200 border border-blue-400 shadow-lg hover:bg-blue-700 hover:text-white transition-all neon-glow">AZ Emoji</button>
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
          <div className="col-span-2 row-span-2 flex flex-col items-center justify-center">
            <AnimatedCircularMetric
              value={analytics?.activeProjects ?? 0}
              max={100}
              label="ACTIVE PROJECTS"
              color="#00fff7"
              glowColor="#00fff7"
            />
          </div>
          {/* Priority List */}
          <div className="col-span-1 row-span-1 flex flex-col">
            <Panel title="Priority List" accentColor="cyan" className="w-full flex-1">
              <ul className="mt-2 text-white text-sm space-y-1">
                {loading && <li>Loading...</li>}
                {!loading && priorities && priorities.length === 0 && <li>No priorities.</li>}
                {!loading && priorities && priorities.map((p, i) => (
                  <li key={i}>{i + 1}. {p}</li>
                ))}
              </ul>
            </Panel>
          </div>
          {/* Timeline / Activity */}
          <div className="col-span-1 row-span-1 flex flex-col">
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
