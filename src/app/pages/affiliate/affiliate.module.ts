import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AffiliateRoutingModule } from './affiliate-routing.module';
import { AffiliateComponent } from './affiliate.component';

@NgModule({
  imports: [
    AffiliateComponent,
    CommonModule,
    AffiliateRoutingModule
  ]
})
export class AffiliateModule { }
