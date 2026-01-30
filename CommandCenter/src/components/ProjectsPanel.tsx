import React from 'react';

interface Project {
  name: string;
  slug: string;
  category: string;
  status: string;
  progress: number;
  azParticipates: boolean;
  cSuiteParticipates: boolean;
  children?: Project[];
}

interface ProjectsPanelProps {
  projects: Project[];
}

const ProjectsPanel: React.FC<ProjectsPanelProps> = ({ projects }) => {
  return (
    <div className="bg-cyan-900 bg-opacity-80 p-4 rounded-lg border border-cyan-400 shadow-lg">
      <h3 className="text-cyan-300 text-lg mb-4">Active Projects</h3>
      <div className="space-y-2 max-h-64 overflow-y-auto">
        {projects.map((project, index) => (
          <div key={index} className="bg-cyan-800 p-3 rounded border border-cyan-600">
            <div className="flex justify-between items-center mb-2">
              <span className="text-cyan-200 font-semibold">{project.name}</span>
              <span className={`px-2 py-1 rounded text-xs ${
                project.status === 'Active' ? 'bg-green-600' : 'bg-yellow-600'
              }`}>
                {project.status}
              </span>
            </div>
            <div className="text-cyan-400 text-sm mb-2">{project.category}</div>
            <div className="w-full bg-cyan-700 rounded-full h-2 mb-2">
              <div
                className="bg-cyan-400 h-2 rounded-full"
                style={{ width: `${project.progress}%` }}
              ></div>
            </div>
            <div className="text-cyan-500 text-xs">{project.progress}% complete</div>
            {project.children && project.children.length > 0 && (
              <div className="mt-2 pl-4 border-l border-cyan-600">
                <div className="text-cyan-400 text-sm">Sub-projects:</div>
                {project.children.map((child, childIndex) => (
                  <div key={childIndex} className="text-cyan-300 text-xs mt-1">
                    • {child.name} ({child.progress}%)
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default ProjectsPanel;