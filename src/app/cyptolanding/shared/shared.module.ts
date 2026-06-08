import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';

import { ScrollspyDirective } from './scrollspy.directive'

@NgModule({
    imports: [
    ScrollspyDirective,
    CommonModule
  ],
    exports: [ScrollspyDirective]
})
export class SharedModule { }
