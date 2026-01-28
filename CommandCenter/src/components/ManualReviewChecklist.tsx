import React, { useState } from 'react';
import './ManualReviewChecklist.css';

// Checklist data extracted from MANUAL_REVIEW_CHECKLIST.md
const checklist = [
  {
    section: 'General Review',
    items: [
      'Read through all code changes and comments.',
      'Verify code style and formatting.',
      'Check for clear and descriptive naming conventions.',
      'Ensure code is modular and reusable where possible.',
      'Confirm all new files are necessary and appropriately placed.'
    ]
  },
  {
    section: 'Functionality',
    items: [
      'Test all new and updated features.',
      'Check for broken functionality elsewhere in the app.',
      'Verify edge cases and error handling.',
      'Ensure all requirements are met.'
    ]
  },
  {
    section: 'Documentation',
    items: [
      'Ensure code is commented where necessary.',
      'Update or add relevant documentation files.',
      'Check for clear commit messages.'
    ]
  },
  {
    section: 'Security & Privacy',
    items: [
      'Check for sensitive data exposure.',
      'Review authentication and authorization logic.',
      'Ensure dependencies are up to date and secure.'
    ]
  },
  {
    section: 'Performance',
    items: [
      'Check for unnecessary re-renders or computations.',
      'Review for memory leaks or resource mismanagement.'
    ]
  },
  {
    section: 'Final Steps',
    items: [
      'Approve or request changes with clear feedback.',
      'Merge only when all checks are complete.'
    ]
  }
];

const ManualReviewChecklist: React.FC = () => {
  const [checked, setChecked] = useState(
    checklist.map(section => section.items.map(() => false))
  );

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
    <div className="manual-review-checklist">
      <h2>Manual Review Checklist</h2>
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
    </div>
  );
};

export default ManualReviewChecklist;
