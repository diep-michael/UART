`timescale 1ns / 1ps
/*********************************************************
 * File Name: sr_flop_txrdy.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: March 8, 2018
 *
 * Purpose: This module is a modified SR-Flop made for our
 *          tx engine. On reset we are ready to transmit
 *          therefore, on reset Q recieves a 1'b1.
 *          On the active edge of the clock, if S is high
 *          Q recieves 1, else if R is high Q recieves a 0.
 *
 * Notes: 
 *********************************************************/
module sr_flop_txrdy(clk, reset, S, R, Q);

   input      clk, reset, S, R;
   output reg Q;
   
   always @ (posedge clk, posedge reset)
      if (reset)
         Q <= 1'b1; else 
      if (S)
         Q <= 1'b1; else
      if (R)
         Q <= 1'b0;
         
endmodule

