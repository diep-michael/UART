`timescale 1ns / 1ps
/*********************************************************
 * File Name: sr_flop.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: February 8, 2018
 *
 * Purpose: This module is a simple SR-Flop
 *          On the active edge of the clock, if S is high
 *          Q recieves 1, else if R is high Q recieves a 0.
 *
 * Notes: 
 *********************************************************/
module sr_flop(clk, reset, S, R, Q);

   input      clk, reset, S, R;
   output reg Q;
   
   always @ (posedge clk, posedge reset)
      if (reset)
         Q <= 1'b0; else 
      if (S)
         Q <= 1'b1; else
      if (R)
         Q <= 1'b0; else 
         
         Q <= Q;
         
endmodule

