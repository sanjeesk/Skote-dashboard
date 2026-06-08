import { Component, OnInit, AfterViewInit } from '@angular/core';
import { NgApexchartsModule } from 'ng-apexcharts';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import {
  ApexChart,
  ApexAxisChartSeries,
  ApexXAxis,
  ApexDataLabels,
  ApexStroke,
  ApexFill,
  ApexTooltip,
  ApexLegend,
  ApexNonAxisChartSeries,
  ApexPlotOptions,
  ApexResponsive,
} from 'ng-apexcharts';

// ─── Chart option types ───────────────────────────────────────
export type LineChartOptions = {
  series:      ApexAxisChartSeries;
  chart:       ApexChart;
  xaxis:       ApexXAxis;
  dataLabels:  ApexDataLabels;
  stroke:      ApexStroke;
  fill:        ApexFill;
  tooltip:     ApexTooltip;
  legend:      ApexLegend;
  colors:      string[];
};

export type DonutChartOptions = {
  series:    ApexNonAxisChartSeries;
  chart:     ApexChart;
  labels:    string[];
  colors:    string[];
  legend:    ApexLegend;
  plotOptions: ApexPlotOptions;
  responsive: ApexResponsive[];
  tooltip:   ApexTooltip;
};

// ─── Data models ─────────────────────────────────────────────
export interface KpiStat {
  label:      string;
  value:      string;
  change:     string;
  changeType: 'up' | 'flat' | 'down';
  icon:       string;
  colorClass: string;  // si-primary | si-success | si-warning | si-info
  cardClass:  string;  // primary | success | warning | info
}

export interface CampaignCard {
  brandInitials: string;
  brandColor:    string;
  brandName:     string;
  brandSub:      string;
  status:        'ongoing' | 'ending';
  interested:    number;
  accepted:      number;
  tasks:         number;
  approved:      number;
  fillRate:      number;
}

export interface Recruitment {
  initials:   string;
  color:      string;
  name:       string;
  campaign:   string;
  gender:     string;
  tier:       string;
  followers:  string;
  badgeLabel: string;
  badgeClass: string;
  time:       string;
}

export interface TaskApproval {
  initials:   string;
  color:      string;
  name:       string;
  followers:  string;
  campaign:   string;
  platform:   'instagram' | 'tiktok' | 'youtube';
  taskType:   string;
  submitted:  string;
  status:     string;
  statusClass: string;
}

export interface FinanceItem {
  title:       string;
  subtitle:    string;
  amount:      string;
  statusLabel: string;
  statusClass: string; // text-success | text-warning | text-danger
}

export interface ActivityItem {
  dotColor: string;
  html:     string;
  time:     string;
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss']
})
export class DashboardComponent implements OnInit, AfterViewInit {

  today = 'Friday, 22 May 2026';

  // ── KPI Stats ────────────────────────────────────────────
  kpiStats: KpiStat[] = [
    {
      label: 'Total App Signups', value: '8,347',
      change: '+0.76% this week', changeType: 'up',
      icon: 'bx-group', colorClass: 'si-primary', cardClass: 'primary'
    },
    {
      label: 'Bank Details Complete', value: '3,125',
      change: '+0.16% this week', changeType: 'up',
      icon: 'bx-check-shield', colorClass: 'si-success', cardClass: 'success'
    },
    {
      label: 'Available Withdrawal', value: 'RM 470,400',
      change: 'No change', changeType: 'flat',
      icon: 'bx-dollar-circle', colorClass: 'si-warning', cardClass: 'warning'
    },
    {
      label: 'Total Withdrawn', value: 'RM 6.01M',
      change: 'All time', changeType: 'up',
      icon: 'bx-wallet', colorClass: 'si-info', cardClass: 'info'
    },
  ];

  // ── Campaign Cards ───────────────────────────────────────
  activeCampaigns: CampaignCard[] = [
    {
      brandInitials: 'GG', brandColor: '#FF8C00',
      brandName: 'GGS 15th May 2026', brandSub: 'guardian',
      status: 'ending',
      interested: 52, accepted: 23, tasks: 406, approved: 60,
      fillRate: 44
    },
    {
      brandInitials: 'KI', brandColor: '#006400',
      brandName: 'Kickapoo June 2026', brandSub: 'Kickapoo',
      status: 'ongoing',
      interested: 48, accepted: 4, tasks: 14, approved: 0,
      fillRate: 8
    },
    {
      brandInitials: 'VS', brandColor: '#2B6CB0',
      brandName: 'Vaseline Sabah Pub.', brandSub: 'Vaseline',
      status: 'ongoing',
      interested: 9, accepted: 0, tasks: 0, approved: 0,
      fillRate: 0
    },
  ];

  // ── Pending Recruitments ─────────────────────────────────
  recruitments: Recruitment[] = [
    {
      initials: 'SY', color: '#2B5BFF',
      name: 'Sarah Yee', campaign: 'Softlan Complete 5 in 1',
      gender: 'Female', tier: 'Nano', followers: '1.9K',
      badgeLabel: 'New', badgeClass: 'badge-primary-soft', time: '2 hrs ago'
    },
    {
      initials: 'WZ', color: '#e91e8c',
      name: 'wafaa zaharol', campaign: 'GGS 15th May 2026',
      gender: 'Female', tier: 'Micro', followers: '29.8K',
      badgeLabel: 'Shortlisted', badgeClass: 'badge-warning-soft', time: '5 hrs ago'
    },
    {
      initials: 'KA', color: '#34c38f',
      name: 'Khairul Amir', campaign: 'Kickapoo June 2026',
      gender: 'Male', tier: 'Macro', followers: '49.9K',
      badgeLabel: 'New', badgeClass: 'badge-primary-soft', time: '6 hrs ago'
    },
    {
      initials: 'SC', color: '#7B2FBE',
      name: 'Sherlyn Chew', campaign: 'Kickapoo June 2026',
      gender: 'Female', tier: 'Micro', followers: '20.2K',
      badgeLabel: 'Review', badgeClass: 'badge-warning-soft', time: '8 hrs ago'
    },
  ];

  // ── Task Approvals ───────────────────────────────────────
  taskApprovals: TaskApproval[] = [
    {
      initials: 'WZ', color: '#e91e8c',
      name: 'wafaa zaharol', followers: '29.8K',
      campaign: 'GGS 15th May 2026', platform: 'instagram',
      taskType: 'Reels – Posting Link', submitted: '11 Jul 2026',
      status: 'Pending Review', statusClass: 'badge-warning-soft'
    },
    {
      initials: 'KF', color: '#2B5BFF',
      name: 'Kimberly Fong', followers: '19.1K',
      campaign: 'Kickapoo June 2026', platform: 'tiktok',
      taskType: 'TikTok – Insight', submitted: '19 Jul 2026',
      status: 'Pending Review', statusClass: 'badge-warning-soft'
    },
    {
      initials: 'KA', color: '#34c38f',
      name: 'Khairul Amir', followers: '49.9K',
      campaign: 'Kickapoo June 2026', platform: 'instagram',
      taskType: 'Reels – Posting Link', submitted: '11 Jul 2026',
      status: 'New', statusClass: 'badge-primary-soft'
    },
  ];

  // ── Finance Snapshot ─────────────────────────────────────
  financeItems: FinanceItem[] = [
    {
      title: 'Fariha Razak × Samsung', subtitle: 'IO-18-MYNN2676 · Completed',
      amount: 'RM 8,000', statusLabel: 'Available', statusClass: 'text-success'
    },
    {
      title: 'Aiman × Shopee Raya', subtitle: 'IO-18-MYNN2674 · Completed',
      amount: 'RM 5,000', statusLabel: 'Available', statusClass: 'text-success'
    },
    {
      title: 'GGS 15th May 2026', subtitle: 'Active · 60 approved tasks',
      amount: 'RM 12,400', statusLabel: 'Processing', statusClass: 'text-warning'
    },
    {
      title: 'CIMB Always On', subtitle: 'Inactive · Pending IO',
      amount: 'RM 0.00', statusLabel: 'Pending IO', statusClass: 'text-danger'
    },
  ];

  // ── Activity Feed ────────────────────────────────────────
  activityItems: ActivityItem[] = [
    {
      dotColor: '#34c38f',
      html: '<strong>Sherlyn Chew</strong> accepted invitation to Kickapoo June 2026',
      time: '2 minutes ago'
    },
    {
      dotColor: '#f1b44c',
      html: '<strong>wafaa zaharol</strong> submitted Instagram Reel for review — GGS 15th May',
      time: '18 minutes ago'
    },
    {
      dotColor: '#2B5BFF',
      html: '<strong>eMart24 × Butter</strong> campaign completed — 30 tasks approved',
      time: '1 hour ago'
    },
    {
      dotColor: '#e91e8c',
      html: '<strong>Abie Chai</strong> added to Collection by Brenda Sawai',
      time: '3 hours ago'
    },
    {
      dotColor: '#34c38f',
      html: 'Finance payment <strong>RM 8,000</strong> released to Fariha Razak',
      time: 'Yesterday, 4:12 PM'
    },
  ];

  // ── Platform Reach ───────────────────────────────────────
  platformStats = [
    { icon: 'bxl-instagram', iconClass: 'ig-col', label: 'Instagram', count: '5,241' },
    { icon: 'bxl-tiktok',    iconClass: 'tt-col', label: 'TikTok',    count: '1,580' },
    { icon: 'bxl-youtube',   iconClass: 'yt-col', label: 'YouTube',   count: '526'   },
  ];

  // ── Quick Actions ────────────────────────────────────────
  quickActions = [
    { icon: 'bx-user-check',   label: 'Browse Creators', sub: '7,141 available', route: '/creators/browse' },
    { icon: 'bx-plus-circle',  label: 'New Campaign',    sub: '4-step wizard',   route: '/campaigns/ongoing' },
    { icon: 'bx-dollar-circle',label: 'Finance',         sub: 'RM 470K ready',   route: '/finance/list' },
    { icon: 'bx-search-alt-2', label: 'Discovery',       sub: '621K creators',   route: '/discovery/explore' },
  ];

  // ── ApexCharts ───────────────────────────────────────────
  lineChartOptions!:  Partial<LineChartOptions>;
  donutChartOptions!: Partial<DonutChartOptions>;

  ngOnInit(): void {
    this._initLineChart();
    this._initDonutChart();
  }

  ngAfterViewInit(): void {}

  // ── Chart helpers ────────────────────────────────────────
  private _initLineChart(): void {
    this.lineChartOptions = {
      series: [
        {
          name: 'Total Signups',
          data: [6800, 7100, 7350, 7700, 8050, 8347]
        },
        {
          name: 'Bank Details',
          data: [2600, 2700, 2820, 2950, 3040, 3125]
        }
      ],
      chart: {
        type: 'area', height: 200,
        toolbar: { show: false },
        background: 'transparent',
        zoom: { enabled: false }
      },
      colors: ['#2B5BFF', '#34c38f'],
      fill: {
        type: 'gradient',
        gradient: {
          shadeIntensity: 1, opacityFrom: 0.25, opacityTo: 0.02, stops: [0, 90, 100]
        }
      },
      stroke: { curve: 'smooth', width: [2, 2], dashArray: [0, 4] },
      dataLabels: { enabled: false },
      xaxis: {
        categories: ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'],
        axisBorder: { show: false },
        axisTicks:  { show: false },
        labels: { style: { colors: '#a6b0cf', fontSize: '10px' } }
      },
      tooltip: {
        theme: 'dark',
        y: { formatter: (val: number) => val.toLocaleString() }
      },
      legend: { show: false }
    };
  }

  private _initDonutChart(): void {
    this.donutChartOptions = {
      series: [74, 19, 7],
      chart: { type: 'donut', height: 180, background: 'transparent' },
      labels: ['Instagram', 'TikTok', 'YouTube'],
      colors: ['#C13584', '#6c757d', '#ff0000'],
      plotOptions: {
        pie: { donut: { size: '72%' } }
      },
      legend: { show: false },
      responsive: [{ breakpoint: 480, options: { chart: { height: 160 } } }],
      tooltip: {
        theme: 'dark',
        y: { formatter: (val: number) => val + '%' }
      }
    };
  }

  // ── Helpers ──────────────────────────────────────────────
  getFillRateColor(rate: number): string {
    if (rate >= 60) return '#34c38f';
    if (rate >= 30) return '#f1b44c';
    return '#50a5f1';
  }

  getPlatformIcon(platform: string): string {
    const map: Record<string, string> = {
      instagram: 'bxl-instagram',
      tiktok:    'bxl-tiktok',
      youtube:   'bxl-youtube'
    };
    return map[platform] || 'bx-link';
  }

  getPlatformClass(platform: string): string {
    const map: Record<string, string> = {
      instagram: 'ig-col',
      tiktok:    'tt-col',
      youtube:   'yt-col'
    };
    return map[platform] || '';
  }
}
