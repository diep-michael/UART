`timescale 1ns / 1ps
/*********************************************************
 * File Name: bit_9_10_decoder.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: March 8, 2018
 *
 * Purpose: This module will determine the ninth and tenth bits
 *          of our outgoing tx data. By using the logical XOR
 *          operator, we can determine the value of the parity bit.
 *
 *          Inputs
 *          ------
 *          eight    - determines if data is 7 or 8 bits
 *          pen      - parity enable
 *          ohel     - odd high, even low (when parity is enabled)
 *          ldata    - 8-bit incoming data
 *          
 *          Outputs
 *          -------
 *          bit_nine - ninth bit of our outgoing tx data
 *          bit_ten  - tenth bit of our outgoing tx data
 *
 * Notes: 
 *********************************************************/
module bit_9_10_decoder(ldata, eight, pen, ohel, bit_nine, bit_ten);

   input       eight, pen, ohel;
   input [7:0] ldata;
   
   output reg  bit_nine, bit_ten;
               
   wire        ep7, op7, ep8, op8;
   
   // even parity 7 bits
   assign ep7 = (^ldata[6:0]);
   
   // odd parity 7 bits
   assign op7 = ~(^ldata[6:0]);
   
   // even parity 8 bits
   assign ep8 = (^ldata);
   
   // odd parity 8 bits
   assign op8 = ~(^ldata);
   
   always @ (*)
      case ({eight,pen,ohel})
         // 7-bit data, parity is disabled
         3'b000: {bit_ten, bit_nine} = {1'b1, 1'b1};
         3'b001: {bit_ten, bit_nine} = {1'b1, 1'b1};
         
         // 7-bit data, parity is enabled
         3'b010: {bit_ten, bit_nine} = {1'b1, ep7};
         3'b011: {bit_ten, bit_nine} = {1'b1, op7};
         
         // 8-bit data, parity is disabled
         3'b100: {bit_ten, bit_nine} = {1'b1, ldata[7]};
         3'b101: {bit_ten, bit_nine} = {1'b1, ldata[7]};
         
         // 8-bit data, parity is enabled
         3'b110: {bit_ten, bit_nine} = {ep8, ldata[7]};
         3'b111: {bit_ten, bit_nine} = {op8, ldata[7]};
      endcase
      
endmodule
