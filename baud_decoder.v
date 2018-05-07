`timescale 1ns / 1ps
/*********************************************************
 * File Name: baud_decoder.v
 * Project: UART
 * Designer: Michael Diep
 * Email: michaelkhangdiep@gmail.com
 * Rev. Date: March 8, 2018
 *
 * Purpose: This module will decode our baud rate into values verilog 
 *          can operate with. We do this by holding the value on our wire
 *          for a specific time. Since we are using this module with the 
 *          Nexys4, our frequency will be 100Mhz making our clock 10ns. 
 *          In order to transmit data at the correct baud rate we must 
 *          calculate the amount of clocks the value should be held for. 
 *
 *          These are common standard baud rates, and the corresponding values. 
 *          
 *           RATE    BIT TIME    COUNT VALUE
 *          ------   ---------   -----------
 *             300   3.3333 ms       333,333
 *            1200   833.33 us        83,333
 *            2400   416.66 us        41,667
 *            4800   208.33 us        20,833
 *            9600   104.16 us        10,417
 *           19200   52.083 us         5,408
 *           38400   26.041 us         2,604
 *           57600   17.361 us         1,736
 *          115200   8.6806 us           868
 *          230400   4.3403 us           434
 *          460800   2.1701 us           217
 *          921600   1.0851 us           109
 *
 * Notes: 
 *********************************************************/
module baud_decoder(baud, k);
    
    input       [3:0] baud;
    output reg [18:0] k;
        
    always@(*)
      case (baud)
         // 4-bit values are not significant and only chosen in 
         // descending order to be intuitive to user
         4'b0000: k = 19'd333333;
         4'b0001: k = 19'd83333;
         4'b0010: k = 19'd41667;
         4'b0011: k = 19'd20833;
         4'b0100: k = 19'd10417;
         4'b0101: k = 19'd5208;
         4'b0110: k = 19'd2604;
         4'b0111: k = 19'd1736;
         4'b1000: k = 19'd868;
         4'b1001: k = 19'd434;
         4'b1010: k = 19'd217;
         4'b1011: k = 19'd109;
      endcase
  
endmodule
