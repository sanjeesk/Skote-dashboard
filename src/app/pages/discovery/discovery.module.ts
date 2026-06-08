import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DiscoveryRoutingModule } from './discovery-routing.module';
import { DiscoveryComponent } from './discovery.component';

@NgModule({
  imports: [
    DiscoveryComponent,
    CommonModule,
    DiscoveryRoutingModule
  ]
})
export class DiscoveryModule { }
