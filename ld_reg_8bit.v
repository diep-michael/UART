`timescale 1ns / 1ps
/*********************************************************
 * File Name: ld_reg_8bit.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: February 28, 2018
 *
 * Purpose: This module is a simple 8-bit loadable register
 *          On the active edge of the clock, if ld is high
 *          Q gets D, else Q keeps its value.
 *
 * Notes: 
 *********************************************************/
module ld_reg_8bit(clk, reset, ld, D, Q);

   input            clk, reset, ld;
   input      [7:0] D;
   
   output reg [7:0] Q;
   
   
   always @(posedge clk, posedge reset)
      if (reset)
         Q <= 8'b0; else
      if (ld)
         Q <= D;
      
endmodule
