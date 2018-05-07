`timescale 1ns / 1ps
/*********************************************************
 * File Name: UART.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: May 3, 2018
 * Purpose: This module is our universal asynchronous receiver
 *          transmitter. This module is made up of our baud decoder,
 *          our transmit engine and our receive engine. The baud 
 *          decoder will take in the 4-bit baud value and decode
 *          to determine the rate at which our tx will output
 *          and rx will input.
 *
 *          Inputs
 *          ------
 *          load     - load enable for transmit data
 *          eight    - determines if data is 7 or 8 bits
 *          pen      - parity enable
 *          ohel     - odd high, even low (when parity is enabled)
 *          out_port - incoming 8-bit data to be transmitted
 *          baud     - baud rate to be decoded
 *          rx       - incoming serial data
 *          r_status - flag to output status register 
 *          r_data   - flag to output data
 *          
 *          Outputs
 *          -------
 *          uart_int - uart interrupt flag
 *          uart_ds  - uart outgoing receive data or status register
 *          tx       - outgoing serial data    
 *
 *
 * Notes:   Baud rate values can be seen in baud_decoder module.          
 *********************************************************/
module UART(clk, reset, load, out_port, eight, pen, ohel, 
            baud, tx, rx, r_status, r_data, uart_int, uart_ds);

   input        clk, reset, load, eight, pen, ohel, rx, r_status, r_data;
   input  [3:0] baud;
   input  [7:0] out_port;
   
   output       tx, uart_int;
   output [7:0] uart_ds;
   
   wire         tx_rdy, tx_rdy_PED, rx_rdy_PED;
   wire  [18:0] k, kd2;
   wire   [7:0] uart_rdata;
   wire   [3:0] rx_status;
   wire   [7:0] status;
   
   baud_decoder
      bd(.baud(baud), 
         .k(k));
         
   assign kd2 = k >> 1;             // divide baud rate by two, placing us
                                    // in the middle of the bit when were recieving
                                    // to ensure that were recieving the correct bit
   
   tx
      transmit(.clk(clk), 
               .reset(reset), 
               .load(load), 
               .out_port(out_port), 
               .eight(eight), 
               .pen(pen), 
               .ohel(ohel), 
               .k(k), 
               .txrdy(txrdy), 
               .tx(tx));
         
   rx
      receive (.clk(clk), 
               .reset(reset), 
               .rx(rx), 
               .eight(eight), 
               .pen(pen), 
               .ohel(ohel), 
               .reset_errors(r_data), 
               .k(k), 
               .kd2(kd2), 
               .uart_rdata(uart_rdata), 
               .rx_status(rx_status));
   
   // 7        6        5        4        3        2        1        0
   //        N O T          | overflow framing   parity     tx       rx   
   //       U S E D         |  error    error    error     ready    ready
   //                       
   assign status = {3'b0, rx_status[3:1], txrdy, rx_status[0]};
   
   
   // positive edge detects to trigger our interrupt
   PED
      TX_RDY(.clk(clk), 
             .reset(reset), 
             .in(txrdy), 
             .out(tx_rdy_PED)),
             
      RX_RDY(.clk(clk), 
             .reset(reset), 
             .in(rx_status[0]), 
             .out(rx_rdy_PED));
   
   assign uart_ds = (r_status) ? status : uart_rdata;    
      
   // interrupt will trigger from tx or rx
   assign uart_int = tx_rdy_PED | rx_rdy_PED;
   
endmodule
