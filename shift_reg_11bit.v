`timescale 1ns / 1ps
/*********************************************************
 * File Name: shift_reg_11bit.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: March 8, 2018
 *
 * Purpose: This module is an 11-bit shift register that
 *          shifts in from the right and outputs the bit
 *          shifted off.
 *
 *
 * Notes: 
 *********************************************************/
module shift_reg_11bit(clk, reset, data, ld, sh, sdi, sdo);

   input        clk, reset, ld, sh, sdi;
   input [10:0] data;
   
   output       sdo;
   
   reg   [10:0] sr;
   
   always @(posedge clk, posedge reset)
      if (reset)
         sr <= 11'b11111111111; else
      if (ld)
         sr <= data; else
      if (sh)
         sr <= {sdi,sr[10:1]};
      else
         sr <= sr;
         
   assign sdo = sr[0];

endmodule
