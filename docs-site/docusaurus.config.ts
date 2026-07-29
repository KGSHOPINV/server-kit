import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Server Kit',
  tagline: 'Your complete self-hosted server infrastructure — from zero to production',
  favicon: 'img/favicon.ico',

  future: {
    v4: true,
  },

  url: 'https://server-kit.netlify.app',
  baseUrl: '/',

  organizationName: 'KGSHOPINV',
  projectName: 'server-kit',

  onBrokenLinks: 'warn',

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          routeBasePath: '/',
          editUrl: 'https://github.com/KGSHOPINV/server-kit/tree/master/docs-site/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Server Kit',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'mainSidebar',
          position: 'left',
          label: 'Docs',
        },
        {
          href: 'https://github.com/KGSHOPINV/server-kit',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            { label: 'Quick Start', to: '/' },
            { label: 'Services', to: '/services/overview' },
            { label: 'Commands', to: '/commands/quick-reference' },
          ],
        },
        {
          title: 'Guides',
          items: [
            { label: 'How Do I...', to: '/how-to/deploy-a-project' },
            { label: 'Troubleshooting', to: '/troubleshooting/containers' },
            { label: 'Security', to: '/security/defense-layers' },
          ],
        },
        {
          title: 'Links',
          items: [
            { label: 'GitHub', href: 'https://github.com/KGSHOPINV/server-kit' },
          ],
        },
      ],
      copyright: `Server Kit — self-hosted infrastructure toolkit`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'json', 'yaml', 'ini'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
