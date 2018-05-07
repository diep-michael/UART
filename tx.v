`timescale 1ns / 1ps
/*********************************************************
 * File Name: tx.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: March 8, 2018
 *
 * Purpose: This module is our transmit engine that is to be implemented in our
 *          UART. This engine will transmit 11 bits of data holding each for a 
 *          specific bit-time 'k'. k is to be determined by our baud rate decoder.
 *          When all 11-bits of our data are finished transmitted, our output
 *          will signal that it is ready to transmit another 11-bit value.
 *          Our 11-bit value, from 11 through 0, consists of our 2 parity bits,
 *          either an 8-bit or 7-bit value, a start bit, and a mark bit.
 * 
 *          Inputs
 *          ------
 *          load     - load enable for transmit data
 *          eight    - determines if data is 7 or 8 bits
 *          pen      - parity enable
 *          ohel     - odd high, even low (when parity is enabled)
 *          out_port - incoming 8-bit data to be transmitted
 *          k        - count value for bit-time
 *          
 *          Outputs
 *          -------
 *          txrdy    - determines when tx is ready to transmit
 *          tx       - outgoing serial data
 *
 *
 * Notes: 
 *********************************************************/
module tx(clk, reset, load, out_port, eight, pen, ohel, k, txrdy, tx);

   input        clk, reset, load, eight, pen, ohel;
   input  [7:0] out_port;
   input [18:0] k;                                  // count value for bit-time            
   
   output       txrdy, tx;
   
              //bit-time up, tx done, start tx, parity bits
   wire         btu,          done,    doit,   bit_nine, bit_ten , sr_to_tx;
   wire   [7:0] ldata;
   
   reg          loaddi;
   reg    [3:0] bit_counter_d, bit_counter_q;
   reg   [18:0] bit_time_counter_d, bit_time_counter_q;
   
   sr_flop_txrdy                                    // when reset, Q gets 1;
      TXRDY(.clk(clk), 
            .reset(reset), 
            .S(done), 
            .R(load), 
            .Q(txrdy));
            
   sr_flop      
      DOIT( .clk(clk), 
            .reset(reset), 
            .S(loaddi), 
            .R(done), 
            .Q(doit));
          
   ld_reg_8bit
      LR1(  .clk(clk), 
            .reset(reset), 
            .ld(load), 
            .D(out_port), 
            .Q(ldata));

   bit_9_10_decoder
      BDC(  .ldata(ldata), 
            .eight(eight), 
            .pen(pen), 
            .ohel(ohel), 
            .bit_nine(bit_nine), 
            .bit_ten(bit_ten));
          
          
   shift_reg_11bit
      SHR(  .clk(clk), 
            .reset(reset), 
            //        decoded bits  , load data , start 
            .data({bit_ten, bit_nine, ldata[6:0], 1'b0, 1'b1}),
            .ld(loaddi),
            .sh(btu),  // shift when bit time is finished
            .sdi(1'b1), 
            .sdo(sr_to_tx));
     
   always @ (posedge clk, posedge reset)
      if (reset)
         begin
         loaddi <= 1'b0;
         bit_time_counter_q <= 19'b0;
         bit_counter_q <= 4'b0;
         end
      else
         begin
         loaddi <= load;
         bit_time_counter_q <= bit_time_counter_d;
         bit_counter_q <= bit_counter_d;
         end
         
   always @(*)
      case({doit,btu})
         // doit is low
         2'b00: {bit_time_counter_d, bit_counter_d} = {19'b0, 4'b0};
         2'b01: {bit_time_counter_d, bit_counter_d} = {19'b0, 4'b0};
         
         // doit is high
                                                    // btu is low, keep counting 
         2'b10: {bit_time_counter_d, bit_counter_d} = {bit_time_counter_q + 19'b1,
                                                    //        keep value
                                                            bit_counter_q};
         
                                                    // btu is high/1-bit finished 
         2'b11: {bit_time_counter_d, bit_counter_d} = {19'b0, 
                                                    //    inc bit count  
                                                      bit_counter_q + 4'b1};
      endcase
   
   assign btu = (bit_time_counter_q == k);          // bit time up when count 
                                                    // value is met

   assign done = (bit_counter_q == 11);             // done when all 11 bits 
                                                    // have been transmitted
   
   assign tx = sr_to_tx;                            // buffer 
                                                    
endmodule
