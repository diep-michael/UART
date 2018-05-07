`timescale 1ns / 1ps
/*********************************************************
 * File Name: remap_combo.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: May 3, 2018
 *
 * Purpose: This module is used to rearrange the bits from 
 *          our shift register. Our shift register is 10-bits,
 *          but we dont always need all 10 bits. For example,
 *          when we only need 8 bits, we would output bits
 *          [9:2] because we've only shifted that far into our register.
 *          inputs eight and pen are used to determine the amount of bits
 *          that are needed to be shifted.
 *
 * Notes:   
 *********************************************************/
module remap_combo(eight, pen, data_in, remap7, remap8, remap9, remap_out);   

   input       eight, pen;
   input [9:0] data_in;
   
   output reg remap7, remap8, remap9;
   output reg [7:0] remap_out;
   
   always @(*)
      case ({eight, pen})
         2'b00:{remap9, remap8 ,remap7, remap_out} = {2'b0, data_in[9], {1'b0, data_in[8:2]}};
         2'b01:{remap9, remap8 ,remap7, remap_out} = {1'b0, data_in[9], data_in[8], {1'b0, data_in[7:1]}};
         2'b10:{remap9, remap8 ,remap7, remap_out} = {1'b0, data_in[9], data_in[8], data_in[7:1]};
         2'b11:{remap9, remap8 ,remap7, remap_out} = {data_in[9:7], data_in[7:0]};
      endcase
endmodule
