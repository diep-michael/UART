`timescale 1ns / 1ps
/*********************************************************
 * File Name: shift_reg_10bit.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: May 3, 2018
 *
 * Purpose: This module is an 10-bit shift register that
 *          shifts in from the right and outputs the new
 *          data that has been shiftedd
 *
 *
 * Notes: 
 *********************************************************/
module shift_reg_10bit(clk, reset, sh, sdi, sr);

   input            clk, reset, sh, sdi;
   
   output reg [9:0] sr;
   
   always @(posedge clk, posedge reset)
      if (reset)
         sr <= 10'b1111111111; else
      if (sh)
         sr <= {sdi,sr[9:1]};
      else
         sr <= sr;
      
endmodule
