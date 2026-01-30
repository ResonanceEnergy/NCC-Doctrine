import { useState, useEffect } from 'react';
import Panel from './Panel';

interface Task {
  id: string;
  title: string;
  description: string;
  priority: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  status: 'ACTIVE' | 'PENDING' | 'COMPLETED';
  assignee: string;
  dueDate: string;
  created: string;
  category: string;
  dependencies: string[];
  progress: number;
  subtasks: { id: string; title: string; completed: boolean }[];
  completedDate?: string;
  lastModified?: string;
  notes?: string;
}

interface DepartmentTasks {
  department: string;
  ceo: string;
  lastUpdate: string;
  security10Compliance: {
    status: string;
    lastAudit: string;
    incidents: number;
    containmentIntegrity: number;
  };
  tasks: Task[];
}

interface TaskData {
  departments: { [key: string]: DepartmentTasks };
  summary: {
    totalDepartments: number;
    activeTasks: number;
    completedTasks: number;
    criticalTasks: number;
  };
}

const TaskManagement = () => {
  const [taskData, setTaskData] = useState<TaskData | null>(null);
  const [selectedDepartment, setSelectedDepartment] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchTasks = async () => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000';
      const response = await fetch(`${apiUrl}/api/tasks`);
      const data = await response.json();
      setTaskData(data);
    } catch (error) {
      console.error('Failed to fetch tasks:', error);
    } finally {
      setLoading(false);
    }
  };

  const updateTask = async (department: string, taskId: string, updates: Partial<Task>) => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000';
      const response = await fetch(`${apiUrl}/api/tasks/${department}/${taskId}/update`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates)
      });
      if (response.ok) {
        await fetchTasks(); // Refresh data
      }
    } catch (error) {
      console.error('Failed to update task:', error);
    }
  };

  const evolveTask = async (department: string, taskType: string, description: string) => {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:4000';
      await fetch(`${apiUrl}/api/tasks/evolve`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ department, taskType, description })
      });
      await fetchTasks();
    } catch (error) {
      console.error('Failed to evolve task:', error);
    }
  };

  useEffect(() => {
    fetchTasks();
    if (autoRefresh) {
      const interval = setInterval(fetchTasks, 30000); // Refresh every 30 seconds
      return () => clearInterval(interval);
    }
  }, [autoRefresh]);

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'CRITICAL': return 'text-red-400 border-red-400';
      case 'HIGH': return 'text-orange-400 border-orange-400';
      case 'MEDIUM': return 'text-yellow-400 border-yellow-400';
      case 'LOW': return 'text-green-400 border-green-400';
      default: return 'text-gray-400 border-gray-400';
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'COMPLETED': return 'text-green-400';
      case 'ACTIVE': return 'text-cyan-400';
      case 'PENDING': return 'text-yellow-400';
      default: return 'text-gray-400';
    }
  };

  if (loading) {
    return (
      <Panel title="Task Management System" accentColor="cyan" className="w-full">
        <div className="text-center text-cyan-400">Loading task data...</div>
      </Panel>
    );
  }

  return (
    <div className="w-full space-y-6">
      {/* Summary Dashboard */}
      <Panel title="NCC Task Management Overview" accentColor="cyan" className="w-full">
        <div className="grid grid-cols-4 gap-4 mb-4">
          <div className="text-center">
            <div className="text-2xl font-bold text-cyan-400">{taskData?.summary.totalDepartments || 0}</div>
            <div className="text-sm text-gray-400">Departments</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-yellow-400">{taskData?.summary.activeTasks || 0}</div>
            <div className="text-sm text-gray-400">Active Tasks</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-green-400">{taskData?.summary.completedTasks || 0}</div>
            <div className="text-sm text-gray-400">Completed</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-red-400">{taskData?.summary.criticalTasks || 0}</div>
            <div className="text-sm text-gray-400">Critical</div>
          </div>
        </div>
        <div className="flex justify-center">
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`px-4 py-2 rounded border ${
              autoRefresh ? 'bg-cyan-600 text-white' : 'bg-gray-600 text-gray-300'
            }`}
          >
            Auto-Refresh: {autoRefresh ? 'ON' : 'OFF'}
          </button>
        </div>
      </Panel>

      {/* Department Selection */}
      <Panel title="Department Task Lists" accentColor="cyan" className="w-full">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {taskData && Object.entries(taskData.departments).map(([deptId, dept]) => (
            <div
              key={deptId}
              className="p-4 border border-cyan-400 rounded cursor-pointer hover:bg-cyan-900 hover:bg-opacity-20 transition"
              onClick={() => setSelectedDepartment(selectedDepartment === deptId ? null : deptId)}
            >
              <div className="font-bold text-cyan-400">{dept.department}</div>
              <div className="text-sm text-gray-400">CEO: {dept.ceo}</div>
              <div className="mt-2 flex justify-between text-xs">
                <span className={getStatusColor('ACTIVE')}>
                  {dept.tasks.filter(t => t.status === 'ACTIVE').length} Active
                </span>
                <span className="text-green-400">
                  {dept.tasks.filter(t => t.status === 'COMPLETED').length} Done
                </span>
              </div>
              <div className="mt-1 text-xs text-gray-500">
                Security 10: {dept.security10Compliance.status} ({dept.security10Compliance.containmentIntegrity}%)
              </div>
            </div>
          ))}
        </div>
      </Panel>

      {/* Selected Department Details */}
      {selectedDepartment && taskData && taskData.departments[selectedDepartment] && (
        <Panel title={`${taskData.departments[selectedDepartment].department} - Task Details`} accentColor="cyan" className="w-full">
          <div className="mb-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <strong>CEO:</strong> {taskData.departments[selectedDepartment].ceo}
              </div>
              <div>
                <strong>Last Update:</strong> {new Date(taskData.departments[selectedDepartment].lastUpdate).toLocaleString()}
              </div>
            </div>
            <div className="mt-2">
              <strong>Security 10 Compliance:</strong>
              <span className={`ml-2 ${taskData.departments[selectedDepartment].security10Compliance.status === 'COMPLIANT' ? 'text-green-400' : 'text-red-400'}`}>
                {taskData.departments[selectedDepartment].security10Compliance.status}
              </span>
              <span className="ml-2 text-sm text-gray-400">
                Integrity: {taskData.departments[selectedDepartment].security10Compliance.containmentIntegrity}%
              </span>
            </div>
          </div>

          {/* Task List */}
          <div className="space-y-4">
            {taskData.departments[selectedDepartment].tasks.map(task => (
              <div key={task.id} className="border border-cyan-400 rounded p-4">
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <h3 className="font-bold text-cyan-400">{task.title}</h3>
                    <p className="text-sm text-gray-300">{task.description}</p>
                  </div>
                  <div className="text-right">
                    <span className={`px-2 py-1 rounded text-xs border ${getPriorityColor(task.priority)}`}>
                      {task.priority}
                    </span>
                    <div className={`text-sm mt-1 ${getStatusColor(task.status)}`}>
                      {task.status}
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 text-sm mb-2">
                  <div><strong>Assignee:</strong> {task.assignee}</div>
                  <div><strong>Due:</strong> {new Date(task.dueDate).toLocaleDateString()}</div>
                  <div><strong>Category:</strong> {task.category}</div>
                  <div><strong>Progress:</strong> {task.progress}%</div>
                </div>

                {/* Progress Bar */}
                <div className="w-full bg-gray-700 rounded-full h-2 mb-2">
                  <div
                    className="bg-cyan-400 h-2 rounded-full transition-all duration-300"
                    style={{ width: `${task.progress}%` }}
                  ></div>
                </div>

                {/* Subtasks */}
                {task.subtasks.length > 0 && (
                  <div className="mb-2">
                    <strong className="text-sm">Subtasks:</strong>
                    <ul className="text-sm ml-4 mt-1">
                      {task.subtasks.map(subtask => (
                        <li key={subtask.id} className={subtask.completed ? 'text-green-400 line-through' : 'text-gray-300'}>
                          {subtask.completed ? '✓' : '○'} {subtask.title}
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Task Controls */}
                <div className="flex gap-2 mt-2">
                  {task.status !== 'COMPLETED' && (
                    <button
                      onClick={() => updateTask(selectedDepartment, task.id, { progress: Math.min(100, task.progress + 10) })}
                      className="px-3 py-1 bg-cyan-600 hover:bg-cyan-500 text-white rounded text-sm"
                    >
                      Progress +10%
                    </button>
                  )}
                  {task.status === 'ACTIVE' && (
                    <button
                      onClick={() => updateTask(selectedDepartment, task.id, { status: 'COMPLETED', progress: 100 })}
                      className="px-3 py-1 bg-green-600 hover:bg-green-500 text-white rounded text-sm"
                    >
                      Complete
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* Add New Task */}
          <div className="mt-6 p-4 border border-dashed border-cyan-400 rounded">
            <h4 className="font-bold text-cyan-400 mb-2">Evolve New Task</h4>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
              <select className="bg-gray-700 text-white p-2 rounded border border-cyan-400">
                <option value="security">Security</option>
                <option value="operations">Operations</option>
                <option value="compliance">Compliance</option>
                <option value="development">Development</option>
              </select>
              <input
                type="text"
                placeholder="Task description..."
                className="bg-gray-700 text-white p-2 rounded border border-cyan-400"
                onKeyPress={(e) => {
                  if (e.key === 'Enter') {
                    const select = e.currentTarget.previousElementSibling as HTMLSelectElement;
                    evolveTask(selectedDepartment, select.value, e.currentTarget.value);
                    e.currentTarget.value = '';
                  }
                }}
              />
              <button
                onClick={(e) => {
                  const container = e.currentTarget.parentElement;
                  const select = container?.querySelector('select') as HTMLSelectElement;
                  const input = container?.querySelector('input') as HTMLInputElement;
                  if (select && input && input.value.trim()) {
                    evolveTask(selectedDepartment, select.value, input.value);
                    input.value = '';
                  }
                }}
                className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 text-white rounded"
              >
                Add Task
              </button>
            </div>
          </div>
        </Panel>
      )}
    </div>
  );
};

export default TaskManagement;