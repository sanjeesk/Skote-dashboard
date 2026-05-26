import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

const routes: Routes = [
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },

  { path: 'dashboard',
    loadChildren: () => import('./dashboard/dashboard.module').then(m => m.DashboardModule) },

  { path: 'opportunity',
    loadChildren: () => import('./opportunity/opportunity.module').then(m => m.OpportunityModule) },

  { path: 'campaigns',
    loadChildren: () => import('./campaigns/campaigns.module').then(m => m.CampaignsModule) },

  { path: 'affiliate',
    loadChildren: () => import('./affiliate/affiliate.module').then(m => m.AffiliateModule) },

  { path: 'creators',
    loadChildren: () => import('./creators/creators.module').then(m => m.CreatorsModule) },

  { path: 'discovery',
    loadChildren: () => import('./discovery/discovery.module').then(m => m.DiscoveryModule) },

  { path: 'brands',
    loadChildren: () => import('./brands/brands.module').then(m => m.BrandsModule) },

  { path: 'categories',
    loadChildren: () => import('./categories/categories.module').then(m => m.CategoriesModule) },

  { path: 'finance',
    loadChildren: () => import('./finance/finance.module').then(m => m.FinanceModule) },

  { path: 'users',
    loadChildren: () => import('./users/users.module').then(m => m.UsersModule) },

  { path: 'roles',
    loadChildren: () => import('./roles/roles.module').then(m => m.RolesModule) },

  { path: 'tags',
    loadChildren: () => import('./tags/tags.module').then(m => m.TagsModule) },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule]
})
export class PagesRoutingModule { }
