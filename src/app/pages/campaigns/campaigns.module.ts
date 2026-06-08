import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CampaignsRoutingModule } from './campaigns-routing.module';
import { CampaignsComponent } from './campaigns.component';

@NgModule({
  imports: [
    CampaignsComponent,
    CommonModule,
    CampaignsRoutingModule
  ]
})
export class CampaignsModule { }
