import { useState, useEffect } from 'react';
import Panel from './Panel';

interface DepartmentStatus {
  department: string;
  ceo: string;
  compliance: {
    status: string;
    lastAudit: string;
    incidents: number;
    containmentIntegrity: number;
  };
  activeTasks: number;
  criticalTasks: number;
  lastUpdate: string;
}

interface CSuiteData {
  lastUpdate: string;
  activeAlerts: number;
  complianceScore: number;
  departmentsMonitored: number;
  departmentStatus: DepartmentStatus[];
}

const CSuiteOversight = () => {
  const [cSuiteData, setCSuiteData] = useState<CSuiteData | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedDepartment, setSelectedDepartment] = useState<string | null>(null);
  const [executiveActions, setExecutiveActions] = useState<string[]>([]);

  const fetchCSuiteData = async () => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000';
      const response = await fetch(`${apiUrl}/api/c-suite-oversight`);
      const data = await response.json();
      setCSuiteData(data);
    } catch (error) {
      console.error('Failed to fetch C-Suite data:', error);
    } finally {
      setLoading(false);
    }
  };

  const addExecutiveAction = (action: string) => {
    setExecutiveActions(prev => [action, ...prev]);
  };

  useEffect(() => {
    fetchCSuiteData();
    const interval = setInterval(fetchCSuiteData, 20000); // Refresh every 20 seconds
    return () => clearInterval(interval);
  }, []);

  const getComplianceColor = (status: string, integrity: number) => {
    if (status === 'COMPLIANT' && integrity >= 90) return 'text-green-400 border-green-400';
    if (status === 'COMPLIANT' && integrity >= 70) return 'text-yellow-400 border-yellow-400';
    return 'text-red-400 border-red-400';
  };

  const getRiskLevel = (compliance: any, activeTasks: number, criticalTasks: number) => {
    let risk = 0;
    if (compliance.status !== 'COMPLIANT') risk += 3;
    if (compliance.containmentIntegrity < 80) risk += 2;
    if (compliance.incidents > 0) risk += 1;
    if (criticalTasks > 0) risk += 2;
    if (activeTasks > 5) risk += 1;

    if (risk >= 5) return { level: 'CRITICAL', color: 'text-red-400 bg-red-900 bg-opacity-20' };
    if (risk >= 3) return { level: 'HIGH', color: 'text-orange-400 bg-orange-900 bg-opacity-20' };
    if (risk >= 1) return { level: 'MEDIUM', color: 'text-yellow-400 bg-yellow-900 bg-opacity-20' };
    return { level: 'LOW', color: 'text-green-400 bg-green-900 bg-opacity-20' };
  };

  if (loading) {
    return (
      <Panel title="C-Suite Executive Oversight" accentColor="purple" className="w-full">
        <div className="text-center text-purple-400">Loading executive oversight data...</div>
      </Panel>
    );
  }

  return (
    <div className="w-full space-y-6">
      {/* Executive Dashboard Overview */}
      <Panel title="NCC C-Suite Executive Oversight Dashboard" accentColor="purple" className="w-full">
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="text-center p-4 border border-purple-400 rounded">
            <div className="text-3xl font-bold text-purple-400">{cSuiteData?.departmentsMonitored || 0}</div>
            <div className="text-sm text-gray-400">Departments Monitored</div>
          </div>
          <div className="text-center p-4 border border-orange-400 rounded">
            <div className="text-3xl font-bold text-orange-400">{cSuiteData?.activeAlerts || 0}</div>
            <div className="text-sm text-gray-400">Active Alerts</div>
          </div>
          <div className="text-center p-4 border border-cyan-400 rounded">
            <div className="text-3xl font-bold text-cyan-400">{cSuiteData?.complianceScore || 0}%</div>
            <div className="text-sm text-gray-400">Compliance Score</div>
          </div>
          <div className="text-center p-4 border border-green-400 rounded">
            <div className="text-2xl font-bold text-green-400">
              {cSuiteData ? cSuiteData.departmentStatus.filter(d => d.compliance.status === 'COMPLIANT').length : 0}
            </div>
            <div className="text-sm text-gray-400">Compliant Depts</div>
          </div>
        </div>

        <div className="text-center">
          <div className="inline-block px-4 py-2 border border-purple-400 rounded bg-purple-900 bg-opacity-20">
            <span className="text-purple-400 font-bold">AZ PRIME EXECUTIVE OVERSIGHT: ACTIVE</span>
          </div>
          <div className="mt-2 text-sm text-gray-400">
            Last Update: {cSuiteData ? new Date(cSuiteData.lastUpdate).toLocaleString() : 'Unknown'}
          </div>
        </div>
      </Panel>

      {/* Executive Actions Log */}
      <Panel title="Executive Actions & Directives" accentColor="purple" className="w-full">
        <div className="mb-4">
          <input
            type="text"
            placeholder="Issue executive directive..."
            className="w-full p-2 bg-gray-700 text-white rounded border border-purple-400"
            onKeyPress={(e) => {
              if (e.key === 'Enter' && e.currentTarget.value.trim()) {
                addExecutiveAction(e.currentTarget.value);
                e.currentTarget.value = '';
              }
            }}
          />
        </div>

        <div className="space-y-2 max-h-40 overflow-y-auto">
          {executiveActions.length === 0 ? (
            <div className="text-center text-gray-400 py-4">No executive actions recorded</div>
          ) : (
            executiveActions.map((action, index) => (
              <div key={index} className="p-2 border border-purple-400 rounded bg-purple-900 bg-opacity-10">
                <div className="text-sm text-purple-400">
                  <strong>Directive:</strong> {action}
                </div>
                <div className="text-xs text-gray-500 mt-1">
                  Issued: {new Date().toLocaleString()}
                </div>
              </div>
            ))
          )}
        </div>
      </Panel>

      {/* Department Status Grid */}
      <Panel title="Department Executive Status" accentColor="purple" className="w-full">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {cSuiteData && cSuiteData.departmentStatus.map((dept, index) => {
            const risk = getRiskLevel(dept.compliance, dept.activeTasks, dept.criticalTasks);
            return (
              <div
                key={index}
                className={`p-4 border rounded cursor-pointer transition hover:bg-opacity-30 ${risk.color}`}
                onClick={() => setSelectedDepartment(selectedDepartment === dept.department ? null : dept.department)}
              >
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <h3 className="font-bold text-purple-400">{dept.department}</h3>
                    <p className="text-sm text-gray-400">{dept.ceo}</p>
                  </div>
                  <div className={`px-2 py-1 rounded text-xs border ${risk.color.split(' ')[0]} border-current`}>
                    {risk.level} RISK
                  </div>
                </div>

                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span>Security 10:</span>
                    <span className={getComplianceColor(dept.compliance.status, dept.compliance.containmentIntegrity)}>
                      {dept.compliance.status} ({dept.compliance.containmentIntegrity}%)
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span>Active Tasks:</span>
                    <span className="text-cyan-400">{dept.activeTasks}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Critical Tasks:</span>
                    <span className="text-red-400">{dept.criticalTasks}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Incidents:</span>
                    <span className={dept.compliance.incidents > 0 ? 'text-red-400' : 'text-green-400'}>
                      {dept.compliance.incidents}
                    </span>
                  </div>
                </div>

                <div className="mt-2 text-xs text-gray-500">
                  Last Update: {new Date(dept.lastUpdate).toLocaleString()}
                </div>
              </div>
            );
          })}
        </div>
      </Panel>

      {/* Selected Department Executive Detail */}
      {selectedDepartment && cSuiteData && (
        <Panel title={`Executive Oversight: ${selectedDepartment}`} accentColor="purple" className="w-full">
          {(() => {
            const dept = cSuiteData.departmentStatus.find(d => d.department === selectedDepartment);
            if (!dept) return <div className="text-center text-red-400">Department not found</div>;

            const risk = getRiskLevel(dept.compliance, dept.activeTasks, dept.criticalTasks);

            return (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Executive Summary */}
                <div>
                  <h4 className="font-bold text-purple-400 mb-4">Executive Summary</h4>
                  <div className="space-y-3">
                    <div className="p-3 border border-purple-400 rounded">
                      <div className="text-sm font-bold text-purple-400">CEO PERFORMANCE</div>
                      <div className="text-lg">{dept.ceo}</div>
                      <div className={`text-sm mt-1 ${risk.color.split(' ')[0]}`}>
                        Risk Level: {risk.level}
                      </div>
                    </div>

                    <div className="p-3 border border-cyan-400 rounded">
                      <div className="text-sm font-bold text-cyan-400">TASK EXECUTION</div>
                      <div className="grid grid-cols-2 gap-2 mt-1">
                        <div>
                          <div className="text-lg text-cyan-400">{dept.activeTasks}</div>
                          <div className="text-xs text-gray-400">Active Tasks</div>
                        </div>
                        <div>
                          <div className="text-lg text-red-400">{dept.criticalTasks}</div>
                          <div className="text-xs text-gray-400">Critical Tasks</div>
                        </div>
                      </div>
                    </div>

                    <div className="p-3 border border-red-400 rounded">
                      <div className="text-sm font-bold text-red-400">SECURITY 10 COMPLIANCE</div>
                      <div className="grid grid-cols-2 gap-2 mt-1">
                        <div>
                          <div className={`text-lg ${getComplianceColor(dept.compliance.status, dept.compliance.containmentIntegrity)}`}>
                            {dept.compliance.containmentIntegrity}%
                          </div>
                          <div className="text-xs text-gray-400">Integrity</div>
                        </div>
                        <div>
                          <div className={`text-lg ${dept.compliance.incidents > 0 ? 'text-red-400' : 'text-green-400'}`}>
                            {dept.compliance.incidents}
                          </div>
                          <div className="text-xs text-gray-400">Incidents</div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Executive Actions Required */}
                <div>
                  <h4 className="font-bold text-purple-400 mb-4">Required Executive Actions</h4>
                  <div className="space-y-3">
                    {dept.criticalTasks > 0 && (
                      <div className="p-3 border border-red-400 rounded bg-red-900 bg-opacity-10">
                        <div className="font-bold text-red-400">CRITICAL TASK OVERSIGHT REQUIRED</div>
                        <div className="text-sm mt-1">
                          {dept.criticalTasks} critical tasks require immediate CEO attention and resource allocation.
                        </div>
                      </div>
                    )}

                    {dept.compliance.status !== 'COMPLIANT' && (
                      <div className="p-3 border border-orange-400 rounded bg-orange-900 bg-opacity-10">
                        <div className="font-bold text-orange-400">COMPLIANCE INTERVENTION NEEDED</div>
                        <div className="text-sm mt-1">
                          Security 10 compliance issues require executive intervention and corrective action plan.
                        </div>
                      </div>
                    )}

                    {dept.compliance.incidents > 0 && (
                      <div className="p-3 border border-red-400 rounded bg-red-900 bg-opacity-10">
                        <div className="font-bold text-red-400">INCIDENT RESPONSE REQUIRED</div>
                        <div className="text-sm mt-1">
                          {dept.compliance.incidents} security incidents require investigation and containment verification.
                        </div>
                      </div>
                    )}

                    {dept.activeTasks > 5 && (
                      <div className="p-3 border border-yellow-400 rounded bg-yellow-900 bg-opacity-10">
                        <div className="font-bold text-yellow-400">RESOURCE ALLOCATION NEEDED</div>
                        <div className="text-sm mt-1">
                          High task volume ({dept.activeTasks} active) requires additional resources and priority setting.
                        </div>
                      </div>
                    )}

                    {risk.level === 'LOW' && (
                      <div className="p-3 border border-green-400 rounded bg-green-900 bg-opacity-10">
                        <div className="font-bold text-green-400">DEPARTMENT PERFORMING WELL</div>
                        <div className="text-sm mt-1">
                          Department shows strong compliance and task execution. Consider recognition and expanded responsibilities.
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Executive Controls */}
                  <div className="mt-6 space-y-2">
                    <button
                      onClick={() => addExecutiveAction(`Scheduled executive review for ${selectedDepartment} - ${risk.level} risk level`)}
                      className="w-full px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded border border-purple-400"
                    >
                      Schedule Executive Review
                    </button>
                    <button
                      onClick={() => addExecutiveAction(`Issued compliance directive to ${selectedDepartment} CEO regarding Security 10 protocols`)}
                      className="w-full px-4 py-2 bg-red-600 hover:bg-red-500 text-white rounded border border-red-400"
                    >
                      Issue Compliance Directive
                    </button>
                    <button
                      onClick={() => addExecutiveAction(`Approved additional resources for ${selectedDepartment} task execution`)}
                      className="w-full px-4 py-2 bg-cyan-600 hover:bg-cyan-500 text-white rounded border border-cyan-400"
                    >
                      Approve Resource Allocation
                    </button>
                  </div>
                </div>
              </div>
            );
          })()}
        </Panel>
      )}

      {/* Executive Command Center */}
      <Panel title="Executive Command Center" accentColor="purple" className="w-full">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="text-center p-4 border border-purple-400 rounded">
            <div className="text-lg font-bold text-purple-400">EXECUTIVE OVERSIGHT</div>
            <div className="text-sm text-gray-400 mt-1">Real-time monitoring of all department CEOs</div>
          </div>
          <div className="text-center p-4 border border-cyan-400 rounded">
            <div className="text-lg font-bold text-cyan-400">TASK MANAGEMENT</div>
            <div className="text-sm text-gray-400 mt-1">Evolving task lists with automatic updates</div>
          </div>
          <div className="text-center p-4 border border-red-400 rounded">
            <div className="text-lg font-bold text-red-400">SECURITY 10 ENFORCEMENT</div>
            <div className="text-sm text-gray-400 mt-1">Zero-tolerance containment protocols</div>
          </div>
        </div>

        <div className="mt-4 text-center text-sm text-gray-400">
          <strong>NCC Executive Command:</strong> All department CEOs are directly accountable to AZ PRIME through this oversight system.
          Real-time monitoring ensures compliance with Security 10 Directive and task execution standards.
        </div>
      </Panel>
    </div>
  );
};

export default CSuiteOversight;