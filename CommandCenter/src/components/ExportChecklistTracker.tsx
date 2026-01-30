import React, { useState } from 'react';
import './ExportChecklistTracker.css';

const checklist = [
  {
    section: 'Visual Layout',
    items: [
      'All widgets and panels are visible and not overlapping',
      'AZ PRIME avatar is always visible and animates',
      'Buttons are clearly labeled and interactive',
      'Background is dynamic and visible',
    ],
  },
  {
    section: 'Data Display',
    items: [
      'Live metrics (projects, ops packets, alerts) are correct',
      'Priority list and timeline/activity feed are populated',
      'Bank account/motivational driver is shown',
    ],
  },
  {
    section: 'Interactivity',
    items: [
      'Buttons (Refresh, Add Widget, Settings, AZ Emoji) work as expected',
      'AZ PRIME emoji/animation triggers on events',
      'No console errors in browser',
    ],
  },
  {
    section: 'Responsiveness',
    items: [
      'Layout adapts to different screen sizes',
      'No scrollbars unless necessary',
    ],
  },
  {
    section: 'Build & Export',
    items: [
      'App builds with no errors or warnings',
      'All assets load correctly',
      'Ready for export or deployment',
    ],
  },
];

const ExportChecklistTracker: React.FC = () => {
  const [checked, setChecked] = useState(
    checklist.map(section => section.items.map(() => false))
  );
  const [notes, setNotes] = useState('');

  const handleCheck = (sectionIdx: number, itemIdx: number) => {
    setChecked(prev => {
      const updated = prev.map(arr => [...arr]);
      updated[sectionIdx][itemIdx] = !updated[sectionIdx][itemIdx];
      return updated;
    });
  };

  const totalItems = checklist.reduce((sum, sec) => sum + sec.items.length, 0);
  const completed = checked.flat().filter(Boolean).length;
  const percent = Math.round((completed / totalItems) * 100);

  return (
    <div className="export-checklist-tracker">
      <h2>Export/Deployment Manual Review Tracker</h2>
      <div className="progress-bar">
        <div className="progress" style={{ width: `${percent}%` }} />
        <span>{percent}% Complete</span>
      </div>
      {checklist.map((section, sIdx) => (
        <div className="section" key={section.section}>
          <h3>{section.section}</h3>
          <ul>
            {section.items.map((item, iIdx) => (
              <li key={item}>
                <label>
                  <input
                    type="checkbox"
                    checked={checked[sIdx][iIdx]}
                    onChange={() => handleCheck(sIdx, iIdx)}
                  />
                  {item}
                </label>
              </li>
            ))}
          </ul>
        </div>
      ))}
      <div className="notes-section">
        <label htmlFor="export-notes">Notes for Issues Found:</label>
        <textarea
          id="export-notes"
          value={notes}
          onChange={e => setNotes(e.target.value)}
          placeholder="Add notes for any issues found during review..."
        />
      </div>
    </div>
  );
};

export default ExportChecklistTracker;
