import React from 'react';

const CSuiteFramework: React.FC = () => {
  return (
    <div className="bg-cyan-900 bg-opacity-80 p-6 rounded-lg border border-cyan-400 shadow-lg">
      <h3 className="text-cyan-300 text-xl mb-4 text-center">C33 Doctrine Executive Council Framework</h3>
      <p className="text-cyan-400 text-sm mb-6 text-center">
        Complete 37-agent executive structure aligned with NCC Doctrine hierarchy: 
        AZ PRIME &gt; Safety Captain &gt; Security 10 Division &gt; EMP Response &gt; IT Security
      </p>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
        {/* Command (CDR) */}
        <div className="bg-red-900 bg-opacity-80 p-4 rounded border border-red-400">
          <h4 className="text-red-200 font-semibold mb-3 flex items-center">
            <span className="mr-2">🎖️</span>
            Command (CDR) - CEO Council (10 CEOs)
          </h4>
          <ul className="text-red-300 text-xs space-y-1">
            <li>• Vision & Strategy (CDR)</li>
            <li>• Financial Operations</li>
            <li>• Technology Innovation</li>
            <li>• Operational Excellence</li>
            <li>• Market Leadership</li>
            <li>• Global Expansion</li>
            <li>• Product Development</li>
            <li>• Customer Experience</li>
            <li>• Sustainability</li>
            <li>• Risk Management</li>
          </ul>
        </div>

        {/* Control (XO) */}
        <div className="bg-orange-900 bg-opacity-80 p-4 rounded border border-orange-400">
          <h4 className="text-orange-200 font-semibold mb-3 flex items-center">
            <span className="mr-2">🎯</span>
            Control (XO) - Executive Coordination (8 Roles)
          </h4>
          <ul className="text-orange-300 text-xs space-y-1">
            <li>• Chief of Staff</li>
            <li>• Operations Control</li>
            <li>• Financial Control</li>
            <li>• Human Resources Control</li>
            <li>• Legal Control</li>
            <li>• Communications Control</li>
            <li>• Growth Control</li>
            <li>• Strategic Control</li>
          </ul>
        </div>

        {/* Communications (S6) */}
        <div className="bg-blue-900 bg-opacity-80 p-4 rounded border border-blue-400">
          <h4 className="text-blue-200 font-semibold mb-3 flex items-center">
            <span className="mr-2">📡</span>
            Communications (S6) - Digital & IT (7 Roles)
          </h4>
          <ul className="text-blue-300 text-xs space-y-1">
            <li>• Technology Communications</li>
            <li>• IT Infrastructure</li>
            <li>• Data Communications</li>
            <li>• Digital Marketing</li>
            <li>• Procurement Systems</li>
            <li>• Quality Communications</li>
            <li>• Innovation Labs</li>
          </ul>
        </div>

        {/* Operations (S3) */}
        <div className="bg-green-900 bg-opacity-80 p-4 rounded border border-green-400">
          <h4 className="text-green-200 font-semibold mb-3 flex items-center">
            <span className="mr-2">⚙️</span>
            Operations (S3) - Execution (6 Roles)
          </h4>
          <ul className="text-green-300 text-xs space-y-1">
            <li>• Supply Chain Operations</li>
            <li>• Revenue Operations</li>
            <li>• Customer Success</li>
            <li>• Corporate Development</li>
            <li>• Public Affairs</li>
            <li>• Strategic Alliances</li>
          </ul>
        </div>

        {/* Intelligence/Security (S2) */}
        <div className="bg-purple-900 bg-opacity-80 p-4 rounded border border-purple-400">
          <h4 className="text-purple-200 font-semibold mb-3 flex items-center">
            <span className="mr-2">🔍</span>
            Intelligence/Security (S2) - Threat & Risk (4 Roles)
          </h4>
          <ul className="text-purple-300 text-xs space-y-1">
            <li>• Corporate Security</li>
            <li>• Risk Analytics</li>
            <li>• Crisis Management</li>
            <li>• Diversity & Inclusion</li>
          </ul>
        </div>

        {/* Logistics (S4) */}
        <div className="bg-yellow-900 bg-opacity-80 p-4 rounded border border-yellow-400">
          <h4 className="text-yellow-200 font-semibold mb-3 flex items-center">
            <span className="mr-2">🚛</span>
            Logistics (S4) - Sustainment (3 Roles)
          </h4>
          <ul className="text-yellow-300 text-xs space-y-1">
            <li>• Sustainability Operations</li>
            <li>• Procurement Logistics</li>
            <li>• Quality Assurance</li>
          </ul>
        </div>
      </div>

      {/* Command Hierarchy */}
      <div className="mb-6 p-4 bg-cyan-800 rounded border border-cyan-600">
        <h4 className="text-cyan-200 font-semibold mb-3 text-center">🎖️ C33 Doctrine Command Hierarchy</h4>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
          <div className="text-center">
            <div className="text-red-300 font-semibold mb-2">Command (CDR)</div>
            <div className="text-cyan-300 text-xs">Strategic intent, priorities, authorizations</div>
          </div>
          <div className="text-center">
            <div className="text-orange-300 font-semibold mb-2">Control (XO)</div>
            <div className="text-cyan-300 text-xs">Synchronization, time management, escalation</div>
          </div>
          <div className="text-center">
            <div className="text-blue-300 font-semibold mb-2">Communications (S6)</div>
            <div className="text-cyan-300 text-xs">Networks, radios, EMP shielding, backups</div>
          </div>
          <div className="text-center">
            <div className="text-green-300 font-semibold mb-2">Operations (S3)</div>
            <div className="text-cyan-300 text-xs">Plans, battle rhythm, tasking, reporting</div>
          </div>
          <div className="text-center">
            <div className="text-purple-300 font-semibold mb-2">Intelligence/Security (S2)</div>
            <div className="text-cyan-300 text-xs">Threats, risks, countermeasures</div>
          </div>
          <div className="text-center">
            <div className="text-yellow-300 font-semibold mb-2">Logistics (S4)</div>
            <div className="text-cyan-300 text-xs">Fuel, water, spares, transport</div>
          </div>
        </div>
      </div>

      {/* Ultimate Success Metrics */}
      <div className="p-4 bg-cyan-800 rounded border border-cyan-600">
        <h4 className="text-cyan-200 font-semibold mb-3 text-center">🎯 Ultimate Success Metrics (37-Agent Council)</h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
          <div>
            <div className="text-2xl font-bold text-green-300">100%</div>
            <div className="text-xs text-cyan-400">Market Dominance</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-blue-300">$10B+</div>
            <div className="text-xs text-cyan-400">Revenue Scale</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-red-300">Zero</div>
            <div className="text-xs text-cyan-400">Security Breaches</div>
          </div>
          <div>
            <div className="text-2xl font-bold text-purple-300">24/7</div>
            <div className="text-xs text-cyan-400">EMP Resilience</div>
          </div>
        </div>
        
        {/* Executive Council Stats */}
        <div className="mt-4 grid grid-cols-3 gap-4 text-center text-xs">
          <div>
            <div className="text-lg font-bold text-red-300">10</div>
            <div className="text-cyan-400">Command (CDR)</div>
          </div>
          <div>
            <div className="text-lg font-bold text-orange-300">8</div>
            <div className="text-cyan-400">Control (XO)</div>
          </div>
          <div>
            <div className="text-lg font-bold text-blue-300">7</div>
            <div className="text-cyan-400">Communications (S6)</div>
          </div>
          <div>
            <div className="text-lg font-bold text-green-300">6</div>
            <div className="text-cyan-400">Operations (S3)</div>
          </div>
          <div>
            <div className="text-lg font-bold text-purple-300">4</div>
            <div className="text-cyan-400">Intelligence (S2)</div>
          </div>
          <div>
            <div className="text-lg font-bold text-yellow-300">3</div>
            <div className="text-cyan-400">Logistics (S4)</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CSuiteFramework;