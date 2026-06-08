import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RolesRoutingModule } from './roles-routing.module';
import { RolesComponent } from './roles.component';

@NgModule({
  imports: [
    RolesComponent,
    CommonModule,
    RolesRoutingModule
  ]
})
export class RolesModule { }
