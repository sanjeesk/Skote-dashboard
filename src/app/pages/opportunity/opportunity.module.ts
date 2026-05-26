import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { OpportunityRoutingModule } from './opportunity-routing.module';
import { OpportunityComponent } from './opportunity.component';

@NgModule({
  declarations: [OpportunityComponent],
  imports: [CommonModule, OpportunityRoutingModule]
})
export class OpportunityModule { }
