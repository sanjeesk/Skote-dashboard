import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CreatorsRoutingModule } from './creators-routing.module';
import { CreatorsComponent } from './creators.component';

@NgModule({
  imports: [
    CreatorsComponent,
    CommonModule,
    CreatorsRoutingModule
  ]
})
export class CreatorsModule { }
