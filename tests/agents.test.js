const fs = require('fs');
const path = require('path');

describe('Golden prompts agents configuration', () => {
  const configPath = path.resolve(process.env.HOME, '.openclaw', 'openclaw.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const ids = config.agents.list.map(a => a.id);
  const expected = [
    'researcher',
    'monitor',
    'communicator',
    'orchestrator',
    'coordinator',
    'software_architect',
    'code_review',
    'post_task',
    'git_workflow'
  ];
  test('All golden agents are present', () => {
    expected.forEach(id => {
      expect(ids).toContain(id);
    });
  });
});
