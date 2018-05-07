`timescale 1ns / 1ps
/*********************************************************
 * File Name: rx.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: May 3, 2018
 *
 * Purpose: This module is our receive engine that is to be implemented in our
 *          UART. This engine will intake data serially. Once we detect a start bit
 *          "0", we will intake the data for half the original bit-time. This is to
 *          to be in the middle of the bit-time as were taking our data. This ensures
 *          that we are at the correct bit when inputting. After fully intaking the 
 *          start bit, we then revert back to regular bit-time. Bit-time 'k' is to be 
 *          determined by our baud rate decoder. When the specific amount of bits 
 *          of our data are finished, we will output to our status register that our
 *          data is ready.
 *          
 *          Along with the receive engine we also have error checking to ensure the 
 *          correct data is received. There is combinational logic to check, 
 *          overflow, parity, and framing. 
 * 
 *          Inputs
 *          ------
 *          rx           - incoming serial data
 *          eight        - determines if data is 7 or 8 bits
 *          pen          - parity enable
 *          ohel         - odd high, even low (when parity is enabled)
 *          reset_errors - when current receive data is read, reset error flags
 *          k            - count value for bit-time
 *          kd2          - k divided by 2
 *          
 *          Outputs
 *          -------
 *          uart_rdata   - full outgoing receive data
 *          rx_status    - outgoing serial data
 *
 * Notes:   
 *********************************************************/
module rx(clk, reset, rx, eight, pen, ohel, reset_errors, k, kd2, uart_rdata, rx_status);
   
   input        clk, reset, rx, eight, pen, ohel, reset_errors;
   input  [18:0] k, kd2;
         
   output  [7:0] uart_rdata;
   output  [3:0] rx_status;
      
   wire          btu, done, ovf, ferr, perr, rxrdy, 
                 eighth_bit_parity, parity_bit, stop_bit_err, full_parity_data,
                 remap7, remap8, remap9;
   wire    [3:0] num_bits;
   wire    [9:0] remap_combo;
   wire    [7:0] remap_out;
   wire   [18:0] start_k;
   
   reg           start, doit;
   reg     [1:0] p_state, n_state, n_output;
   reg     [3:0] bit_counter_d, bit_counter_q;
   reg    [18:0] bit_time_counter_d, bit_time_counter_q;

   ///////////////////////////////////////////////
   //              CONTROL BEGIN                //
   ///////////////////////////////////////////////
        
   always @ (posedge clk, posedge reset)
      if (reset)
         begin
         {p_state, start, doit} <= 4'b0;
         bit_time_counter_q <= 19'b0;
         bit_counter_q <= 4'b0;
         end
      else
         begin
         {p_state, start, doit} <= {n_state, n_output};
         bit_time_counter_q <= bit_time_counter_d;
         bit_counter_q <= bit_counter_d;
         end
         
   always @(*)
      begin
      casex ({p_state, rx, btu, done})
         // wait until we see the start bit
         5'b00_1_x_x: {n_state, n_output} = {2'b00, 2'b00};
         
         // when we receive the start bit, we move to next state
         5'b00_0_x_x: {n_state, n_output} = {2'b01, 2'b11};
         
         // if we detect a 1 before we finish recieving the start bit
         // we go back to the first state
         5'b01_1_x_x: {n_state, n_output} = {2'b00, 2'b00};
         
         // if the start bit is not done being received we stay
         // in the current state
         5'b01_0_0_x: {n_state, n_output} = {2'b01, 2'b11};
         
         // if btu is high, we are ready to receive the actual data
         5'b01_0_1_x: {n_state, n_output} = {2'b10, 2'b01};
         
         // if we are not done with the receive, keep taking in bits
         5'b10_x_x_0: {n_state, n_output} = {2'b10, 2'b01};
         
         // if we received all the bits needed, go back to reset state
         5'b10_x_x_1: {n_state, n_output} = {2'b00, 2'b00};
             default: {n_state, n_output} = {2'b00, 2'b00};
      endcase
          
      case({doit,btu})
            ////////////////// doit is low////////////////////////////
            2'b00: {bit_time_counter_d, bit_counter_d} = {19'b0, 4'b0};
            2'b01: {bit_time_counter_d, bit_counter_d} = {19'b0, 4'b0};
            
            
            //////////////////////// doit is high////////////////////////////////////
                                                         // btu is low, keep counting
            2'b10: {bit_time_counter_d, bit_counter_d} = {bit_time_counter_q + 19'b1,
                                                         //        keep value
                                                               bit_counter_q};
            
                                                         // btu is high/1-bit finished
            2'b11: {bit_time_counter_d, bit_counter_d} = {19'b0, 
                                                         //    inc bit count  
                                                         bit_counter_q + 4'b1};
      endcase
      end
   
   // at the start, set the bit-time to half to get into the middle of the bit
   // afterwards we go back to regular bit-time
   assign start_k = (start) ? kd2 : k;   
   
   assign btu = (bit_time_counter_q == start_k);          // bit time up when count
                                                          // value is met
                     // start bit,7-bits data, stop bit                                    
   assign num_bits = ({eight, pen} == 2'b00) ?  4'b1001 :
   
                     // start bit, 8-bits data, parity bit, stop bit
                     ({eight, pen} == 2'b11) ?  4'b1011 :
                     
                     // start bit, 8-bits data, stop bit
                     // start bit, 7-bits data, parity bit, stop bit
                                                4'b1010;
                     
                     
   
   assign done = (bit_counter_q == num_bits);             // done when all bits 
                                                          // have been transmitted
   
   ///////////////////////////////////////////////
   //                CONTROL END                //
   ///////////////////////////////////////////////
   
   
   ///////////////////////////////////////////////
   //                 DATA BEGIN                //
   ///////////////////////////////////////////////
   
   shift_reg_10bit
      sr10b(.clk(clk), 
            .reset(reset), 
            .sh(btu && ~start),
            .sdi(rx),
            .sr(remap_combo));
            
   remap_combo
      rmpc (.eight(eight),
            .pen(pen),
            .data_in(remap_combo), 
            .remap7(remap7), 
            .remap8(remap8), 
            .remap9(remap9), 
            .remap_out(remap_out));   
            
   assign uart_rdata = remap_out;
   
   // assigning bit 8 the correct value
   assign eighth_bit_parity = (eight) ? remap7 : 0;
   
   // deciding which bit is the parity bit
   assign parity_bit = (eight) ? remap8 : remap7;
   
   // checking to see if the parity bit matches
   assign full_parity_data = ((ohel == 1'b0)) ? 
   
  (^{eighth_bit_parity,remap_out[6:0]}) : ~((^{eighth_bit_parity,remap_out[6:0]}));
   
   // checking if the stop bit is at the correct location
   assign stop_bit_err = ({eight,pen} == 2'b00) ? remap7 :
                         ({eight,pen} == 2'b11) ? remap9 : remap8;
   
   assign rx_status = {ovf, ferr, perr, rxrdy};
   
   sr_flop  
      RXRDY(.clk(clk), 
            .reset(reset), 
            .S(done), 
            .R(reset_errors), 
            .Q(rxrdy)),
                     
      PERR (.clk(clk), 
            .reset(reset), 
            .S((pen & done & (parity_bit ^ full_parity_data))), 
            .R(reset_errors), 
            .Q(perr)),
            
      FERR (.clk(clk), 
            .reset(reset), 
            .S((done & ~stop_bit_err)), 
            .R(reset_errors), 
            .Q(ferr)),
            
      OVFER(.clk(clk), 
            .reset(reset), 
            .S((done & rxrdy)), 
            .R(reset_errors), 
            .Q(ovf));
   
   //////////////////////////////////////////////
   //                 DATA END                 //
   ///////////////////////////////////////////////
   
endmodule
