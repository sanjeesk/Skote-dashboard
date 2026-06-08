import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpportunityRoutingModule } from './opportunity-routing.module';
import { OpportunityComponent } from './opportunity.component';

@NgModule({
  imports: [
    OpportunityComponent,
    CommonModule,
    OpportunityRoutingModule
  ]
})
export class OpportunityModule { }
