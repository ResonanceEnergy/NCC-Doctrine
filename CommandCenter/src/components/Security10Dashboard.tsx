import { useState, useEffect } from 'react';
import Panel from './Panel';

interface SecurityIncident {
  id: string;
  department: string;
  category: 'A' | 'B' | 'C' | 'D' | 'E';
  description: string;
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM';
  status: 'ACTIVE' | 'INVESTIGATING' | 'RESOLVED';
  reportedAt: string;
  reportedBy?: string;
  containmentActions?: string[];
  resolution?: string;
}

interface SecurityData {
  incidents: SecurityIncident[];
  summary: {
    total: number;
    active: number;
    critical: number;
    resolved: number;
  };
}

const Security10Dashboard = () => {
  const [securityData, setSecurityData] = useState<SecurityData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedIncident, setSelectedIncident] = useState<SecurityIncident | null>(null);
  const [newIncident, setNewIncident] = useState({
    department: '',
    category: 'A' as 'A' | 'B' | 'C' | 'D' | 'E',
    description: '',
    reportedBy: ''
  });

  const fetchSecurityData = async () => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000';
      const response = await fetch(`${apiUrl}/api/security-incidents`);
      const data = await response.json();
      setSecurityData(data);
    } catch (error) {
      console.error('Failed to fetch security data:', error);
    } finally {
      setLoading(false);
    }
  };

  const reportIncident = async () => {
    if (!newIncident.department || !newIncident.description) return;

    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000';
      await fetch(`${apiUrl}/api/security-incident`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newIncident)
      });
      await fetchSecurityData();
      setNewIncident({ department: '', category: 'A', description: '', reportedBy: '' });
    } catch (error) {
      console.error('Failed to report incident:', error);
    }
  };

  useEffect(() => {
    fetchSecurityData();
    const interval = setInterval(fetchSecurityData, 15000); // Refresh every 15 seconds
    return () => clearInterval(interval);
  }, []);

  const getCategoryDescription = (category: string) => {
    switch (category) {
      case 'A': return 'Information Cross-Contamination';
      case 'B': return 'Operational Spills';
      case 'C': return 'Physical Contamination';
      case 'D': return 'Digital Leaks';
      case 'E': return 'Human Factors';
      default: return 'Unknown';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'CRITICAL': return 'text-red-400 border-red-400 bg-red-900 bg-opacity-20';
      case 'HIGH': return 'text-orange-400 border-orange-400 bg-orange-900 bg-opacity-20';
      case 'MEDIUM': return 'text-yellow-400 border-yellow-400 bg-yellow-900 bg-opacity-20';
      default: return 'text-gray-400 border-gray-400 bg-gray-900 bg-opacity-20';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ACTIVE': return 'text-red-400';
      case 'INVESTIGATING': return 'text-yellow-400';
      case 'RESOLVED': return 'text-green-400';
      default: return 'text-gray-400';
    }
  };

  if (loading) {
    return (
      <Panel title="Security 10 Directive Dashboard" accentColor="red" className="w-full">
        <div className="text-center text-red-400">Loading security data...</div>
      </Panel>
    );
  }

  return (
    <div className="w-full space-y-6">
      {/* Security Overview */}
      <Panel title="Security 10 Directive - Containment Status" accentColor="red" className="w-full">
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="text-center p-4 border border-red-400 rounded">
            <div className="text-3xl font-bold text-red-400">{securityData?.summary.total || 0}</div>
            <div className="text-sm text-gray-400">Total Incidents</div>
          </div>
          <div className="text-center p-4 border border-orange-400 rounded">
            <div className="text-3xl font-bold text-orange-400">{securityData?.summary.active || 0}</div>
            <div className="text-sm text-gray-400">Active</div>
          </div>
          <div className="text-center p-4 border border-red-400 rounded">
            <div className="text-3xl font-bold text-red-400">{securityData?.summary.critical || 0}</div>
            <div className="text-sm text-gray-400">Critical</div>
          </div>
          <div className="text-center p-4 border border-green-400 rounded">
            <div className="text-3xl font-bold text-green-400">{securityData?.summary.resolved || 0}</div>
            <div className="text-sm text-gray-400">Resolved</div>
          </div>
        </div>

        {/* System Status */}
        <div className="text-center">
          <div className="inline-block px-4 py-2 border border-red-400 rounded bg-red-900 bg-opacity-20">
            <span className="text-red-400 font-bold">SECURITY 10 DIRECTIVE: ACTIVE</span>
          </div>
          <div className="mt-2 text-sm text-gray-400">
            Zero-tolerance containment protocols enforced across all NCC departments
          </div>
        </div>
      </Panel>

      {/* Report New Incident */}
      <Panel title="Report Security Incident" accentColor="red" className="w-full">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <select
            value={newIncident.department}
            onChange={(e) => setNewIncident({...newIncident, department: e.target.value})}
            className="bg-gray-700 text-white p-2 rounded border border-red-400"
          >
            <option value="">Select Department</option>
            <option value="resonance-energy">Resonance Energy</option>
            <option value="big-brain-intelligence">Big Brain Intelligence</option>
            <option value="augmented-arbitrage-corp">Augmented Arbitrage Corp</option>
            <option value="faraday-financial-corp">Faraday Financial Corp</option>
            <option value="quantum-computing-division">Quantum Computing Division</option>
            <option value="biotech-corporation">BUSY BEE BIO TECH</option>
            <option value="space-operations-division">Space Operations Division</option>
            <option value="robotics-automation-division">Robotics & Automation Division</option>
            <option value="ai-governance-council">AI Governance Council</option>
            <option value="global-talent-acquisition">Global Talent Acquisition</option>
            <option value="innovation-labs-division">Innovation Labs Division</option>
            <option value="international-operations-division">International Operations Division</option>
            <option value="cybersecurity-command-center">Cybersecurity Command Center</option>
          </select>

          <select
            value={newIncident.category}
            onChange={(e) => setNewIncident({...newIncident, category: e.target.value as 'A' | 'B' | 'C' | 'D' | 'E'})}
            className="bg-gray-700 text-white p-2 rounded border border-red-400"
          >
            <option value="A">Category A: Information Cross-Contamination</option>
            <option value="B">Category B: Operational Spills</option>
            <option value="C">Category C: Physical Contamination</option>
            <option value="D">Category D: Digital Leaks</option>
            <option value="E">Category E: Human Factors</option>
          </select>

          <input
            type="text"
            placeholder="Reported by..."
            value={newIncident.reportedBy}
            onChange={(e) => setNewIncident({...newIncident, reportedBy: e.target.value})}
            className="bg-gray-700 text-white p-2 rounded border border-red-400"
          />

          <button
            onClick={reportIncident}
            className="px-4 py-2 bg-red-600 hover:bg-red-500 text-white rounded border border-red-400"
          >
            Report Incident
          </button>
        </div>

        <textarea
          placeholder="Incident description..."
          value={newIncident.description}
          onChange={(e) => setNewIncident({...newIncident, description: e.target.value})}
          className="w-full mt-4 p-2 bg-gray-700 text-white rounded border border-red-400"
          rows={3}
        />
      </Panel>

      {/* Active Incidents */}
      <Panel title="Active Security Incidents" accentColor="red" className="w-full">
        <div className="space-y-4">
          {securityData && securityData.incidents.filter(i => i.status !== 'RESOLVED').map(incident => (
            <div
              key={incident.id}
              className={`p-4 border rounded cursor-pointer transition ${getSeverityColor(incident.severity)}`}
              onClick={() => setSelectedIncident(selectedIncident?.id === incident.id ? null : incident)}
            >
              <div className="flex justify-between items-start mb-2">
                <div>
                  <h3 className="font-bold">{incident.id}</h3>
                  <p className="text-sm">{incident.description}</p>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold">{incident.department.toUpperCase()}</div>
                  <div className={`text-sm ${getStatusColor(incident.status)}`}>
                    {incident.status}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-4 text-sm">
                <div>
                  <strong>Category:</strong> {incident.category} - {getCategoryDescription(incident.category)}
                </div>
                <div>
                  <strong>Severity:</strong> {incident.severity}
                </div>
                <div>
                  <strong>Reported:</strong> {new Date(incident.reportedAt).toLocaleString()}
                </div>
              </div>

              {incident.reportedBy && (
                <div className="text-sm mt-1">
                  <strong>Reported By:</strong> {incident.reportedBy}
                </div>
              )}
            </div>
          ))}

          {securityData && securityData.incidents.filter(i => i.status !== 'RESOLVED').length === 0 && (
            <div className="text-center text-green-400 py-8">
              ✅ No active security incidents. All containment protocols nominal.
            </div>
          )}
        </div>
      </Panel>

      {/* Incident Details Modal */}
      {selectedIncident && (
        <Panel title={`Incident Details: ${selectedIncident.id}`} accentColor="red" className="w-full">
          <div className="grid grid-cols-2 gap-6">
            <div>
              <h4 className="font-bold text-red-400 mb-2">Incident Information</h4>
              <div className="space-y-2 text-sm">
                <div><strong>ID:</strong> {selectedIncident.id}</div>
                <div><strong>Department:</strong> {selectedIncident.department}</div>
                <div><strong>Category:</strong> {selectedIncident.category} - {getCategoryDescription(selectedIncident.category)}</div>
                <div><strong>Severity:</strong> {selectedIncident.severity}</div>
                <div><strong>Status:</strong> {selectedIncident.status}</div>
                <div><strong>Reported:</strong> {new Date(selectedIncident.reportedAt).toLocaleString()}</div>
                {selectedIncident.reportedBy && <div><strong>Reported By:</strong> {selectedIncident.reportedBy}</div>}
              </div>
            </div>

            <div>
              <h4 className="font-bold text-red-400 mb-2">Description</h4>
              <p className="text-sm mb-4">{selectedIncident.description}</p>

              {selectedIncident.containmentActions && (
                <div>
                  <h5 className="font-bold text-orange-400 mb-1">Containment Actions</h5>
                  <ul className="text-sm list-disc list-inside">
                    {selectedIncident.containmentActions.map((action, index) => (
                      <li key={index}>{action}</li>
                    ))}
                  </ul>
                </div>
              )}

              {selectedIncident.resolution && (
                <div className="mt-4">
                  <h5 className="font-bold text-green-400 mb-1">Resolution</h5>
                  <p className="text-sm">{selectedIncident.resolution}</p>
                </div>
              )}
            </div>
          </div>

          <div className="mt-6 text-center">
            <button
              onClick={() => setSelectedIncident(null)}
              className="px-4 py-2 bg-gray-600 hover:bg-gray-500 text-white rounded"
            >
              Close Details
            </button>
          </div>
        </Panel>
      )}

      {/* Security 10 Directive Reference */}
      <Panel title="Security 10 Directive Reference" accentColor="red" className="w-full">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 text-sm">
          <div>
            <h4 className="font-bold text-red-400 mb-2">Containment Categories</h4>
            <ul className="space-y-1">
              <li><strong>A:</strong> Information Cross-Contamination</li>
              <li><strong>B:</strong> Operational Spills</li>
              <li><strong>C:</strong> Physical Contamination</li>
              <li><strong>D:</strong> Digital Leaks</li>
              <li><strong>E:</strong> Human Factors</li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold text-red-400 mb-2">Response Protocols</h4>
            <ul className="space-y-1">
              <li><strong>Detection:</strong> Automated monitoring</li>
              <li><strong>Containment:</strong> Immediate isolation</li>
              <li><strong>Investigation:</strong> Forensic analysis</li>
              <li><strong>Recovery:</strong> Secure restoration</li>
            </ul>
          </div>
        </div>

        <div className="mt-4 text-center text-xs text-gray-400">
          Security 10 Directive: Zero-tolerance containment protocols for all cross-contamination, leaks, and spills.
          All NCC personnel must maintain absolute containment integrity.
        </div>
      </Panel>
    </div>
  );
};

export default Security10Dashboard;