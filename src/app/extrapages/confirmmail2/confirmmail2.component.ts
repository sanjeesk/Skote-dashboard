import { Component, OnInit } from '@angular/core';
import { OwlOptions } from 'ngx-owl-carousel-o';
import { CommonModule } from '@angular/common';
import { CarouselModule } from 'ngx-owl-carousel-o';

@Component({
  imports: [
    CommonModule,
    CarouselModule
  ],
  standalone: true,
  selector: 'app-confirmmail2',
  templateUrl: './confirmmail2.component.html',
  styleUrls: ['./confirmmail2.component.scss']
})
export class Confirmmail2Component implements OnInit {

  constructor() { }
  // set the currenr year
  year: number = new Date().getFullYear();
  ngOnInit(): void {
  }

  carouselOption: OwlOptions = {
    items: 1,
    loop: false,
    margin: 0,
    nav: false,
    dots: true,
    responsive: {
      680: {
        items: 1
      },
    }
  }
}
