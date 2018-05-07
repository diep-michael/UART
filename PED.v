`timescale 1ns / 1ps
/*********************************************************
 * File Name: PED.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: February 8, 2018
 *
 * Purpose: This module is used for positive edge detection.
 *          It delays the original signal by one clock cycle, 
 *          then takes its inverse, performs an "AND" with
 *          the original and outputs it.
 *          
 *
 * Notes: 
 *********************************************************/
module PED(clk, reset, in, out);

   input  clk, reset, in;
   output out;
   
   reg    edge_detect;

   always @ (posedge clk, posedge reset)
      if (reset)
         edge_detect <= 1'b0;
      else
         edge_detect <= in;
         
   assign out = (in & ~edge_detect);

endmodule
