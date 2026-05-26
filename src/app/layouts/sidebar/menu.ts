import { MenuItem } from './menu.model';

export const MENU: MenuItem[] = [

  // ─── MAIN MENU ───────────────────────────────────────────
  {
    id: 1,
    label: 'MENUITEMS.MAIN.TEXT',
    isTitle: true
  },
  {
    id: 2,
    label: 'MENUITEMS.DASHBOARD.TEXT',
    icon: 'bxs-dashboard',
    link: '/dashboard',
  },
  {
    id: 3,
    label: 'MENUITEMS.OPPORTUNITY.TEXT',
    icon: 'bx-file-blank',
    link: '/opportunity',
  },
  {
    id: 4,
    label: 'MENUITEMS.CAMPAIGNS.TEXT',
    icon: 'bx-grid-alt',
    subItems: [
      {
        id: 5,
        label: 'MENUITEMS.CAMPAIGNS.LIST.ONGOING',
        link: '/campaigns/ongoing',
        parentId: 4
      },
      {
        id: 6,
        label: 'MENUITEMS.CAMPAIGNS.LIST.COMPLETED',
        link: '/campaigns/completed',
        parentId: 4
      },
      {
        id: 7,
        label: 'MENUITEMS.CAMPAIGNS.LIST.CANCELLED',
        link: '/campaigns/cancelled',
        parentId: 4
      },
      {
        id: 8,
        label: 'MENUITEMS.CAMPAIGNS.LIST.DRAFT',
        link: '/campaigns/draft',
        parentId: 4
      },
    ]
  },
  {
    id: 9,
    label: 'MENUITEMS.AFFILIATE.TEXT',
    icon: 'bx-link-alt',
    subItems: [
      {
        id: 10,
        label: 'MENUITEMS.AFFILIATE.LIST.CAMPAIGNS',
        link: '/affiliate/campaigns',
        parentId: 9
      },
    ]
  },
  {
    id: 11,
    label: 'MENUITEMS.CREATORS.TEXT',
    icon: 'bx-user-circle',
    subItems: [
      {
        id: 12,
        label: 'MENUITEMS.CREATORS.LIST.BROWSE',
        link: '/creators/browse',
        parentId: 11
      },
      {
        id: 13,
        label: 'MENUITEMS.CREATORS.LIST.COLLECTION',
        link: '/creators/collection',
        parentId: 11
      },
    ]
  },
  {
    id: 14,
    label: 'MENUITEMS.DISCOVERY.TEXT',
    icon: 'bx-search-alt',
    subItems: [
      {
        id: 15,
        label: 'MENUITEMS.DISCOVERY.LIST.EXPLORE',
        link: '/discovery/explore',
        parentId: 14
      },
      {
        id: 16,
        label: 'MENUITEMS.DISCOVERY.LIST.SAVED',
        link: '/discovery/saved',
        parentId: 14
      },
    ]
  },
  {
    id: 17,
    label: 'MENUITEMS.BRANDS.TEXT',
    icon: 'bx-briefcase',
    link: '/brands',
  },
  {
    id: 18,
    label: 'MENUITEMS.CATEGORIES.TEXT',
    icon: 'bx-category',
    link: '/categories',
  },
  {
    id: 19,
    label: 'MENUITEMS.FINANCE.TEXT',
    icon: 'bx-dollar-circle',
    subItems: [
      {
        id: 20,
        label: 'MENUITEMS.FINANCE.LIST.LIST',
        link: '/finance/list',
        parentId: 19
      },
      {
        id: 21,
        label: 'MENUITEMS.FINANCE.LIST.DETAILS',
        link: '/finance/details',
        parentId: 19
      },
    ]
  },

  // ─── ADMINISTRATION ───────────────────────────────────────
  {
    id: 22,
    label: 'MENUITEMS.ADMINISTRATION.TEXT',
    isTitle: true
  },
  {
    id: 23,
    label: 'MENUITEMS.USERS.TEXT',
    icon: 'bx-user',
    link: '/users',
  },
  {
    id: 24,
    label: 'MENUITEMS.ROLES.TEXT',
    icon: 'bx-shield',
    link: '/roles',
  },
  {
    id: 25,
    label: 'MENUITEMS.TAGS.TEXT',
    icon: 'bx-purchase-tag',
    link: '/tags',
  },
];
