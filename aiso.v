`timescale 1ns / 1ps
/*********************************************************
 * File Name: aiso.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: February 8, 2018
 *
 * Purpose: This is our asynchronous in, synchronous out
 *          module. We use it to make sure all of our other 
 *          modules get a stable synchronous reset. We do this
 *          by using two D-Flops. by hardwiring a 1'b1 into our
 *          first D-Flop, we guarantee that our meta signal will
 *          eventually settle at 1'b1, output our reset, then go low.
 *
 * Notes: 
 *********************************************************/
module aiso(clk, reset, reset_s);

   input  clk, reset;
   output reset_s;
   
   reg    q_meta, q_ok;
   
   always @ (posedge clk, posedge reset)
      if (reset)
         {q_meta, q_ok} <= 2'b0;
      else
         {q_meta, q_ok} <= {1'b1, q_meta};

   assign reset_s = ~(q_ok);
         
endmodule
