import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

const sidebars: SidebarsConfig = {
  mainSidebar: [
    'index',
    'first-time-setup',
    'first-login',
    {
      type: 'category',
      label: 'Services',
      collapsed: false,
      items: [
        'services/overview',
        'services/infrastructure',
        'services/monitoring',
        'services/databases',
        'services/dev-tools',
        'services/ai-stack',
      ],
    },
    {
      type: 'category',
      label: 'Commands & Shortcuts',
      collapsed: false,
      items: [
        'commands/quick-reference',
        'commands/server-tools',
        'commands/docker-shortcuts',
        'commands/linux-essentials',
      ],
    },
    {
      type: 'category',
      label: 'How Do I...',
      items: [
        'how-to/deploy-a-project',
        'how-to/add-a-domain',
        'how-to/set-up-database',
        'how-to/backup-and-restore',
        'how-to/update-everything',
        'how-to/give-someone-access',
        'how-to/github-auto-deploy',
        'how-to/manage-ai-models',
        'how-to/storage-and-raid',
      ],
    },
    {
      type: 'category',
      label: 'Networking',
      items: [
        'networking/how-traffic-flows',
        'networking/docker-networking',
        'networking/cloudflare',
      ],
    },
    {
      type: 'category',
      label: 'Security',
      items: [
        'security/defense-layers',
        'security/tools-reference',
        'security/incident-response',
        'security/checklists',
      ],
    },
    {
      type: 'category',
      label: 'Troubleshooting',
      items: [
        'troubleshooting/containers',
        'troubleshooting/networking',
        'troubleshooting/resources',
        'troubleshooting/common-gotchas',
      ],
    },
    'port-directory',
    'setup-scripts',
  ],
};

export default sidebars;
