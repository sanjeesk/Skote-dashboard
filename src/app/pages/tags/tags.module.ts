import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TagsRoutingModule } from './tags-routing.module';
import { TagsComponent } from './tags.component';

@NgModule({
  imports: [
    TagsComponent,
    CommonModule,
    TagsRoutingModule
  ]
})
export class TagsModule { }
