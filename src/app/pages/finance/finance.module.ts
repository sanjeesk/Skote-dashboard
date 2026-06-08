import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FinanceRoutingModule } from './finance-routing.module';
import { FinanceComponent } from './finance.component';

@NgModule({
  imports: [
    FinanceComponent,
    CommonModule,
    FinanceRoutingModule
  ]
})
export class FinanceModule { }
