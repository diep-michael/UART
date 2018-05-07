//****************************************************************//
//  This document contains information proprietary to the         //
//  CSULB student that created the file - any reuse without       //
//  adequate approval and documentation is prohibited             //
//                                                                //
//  Class: CECS 460                                               //
//  Project name: TRAMBLAZE PROCESSOR                             //
//  File name: tramelblaze_top.v                                  //
//  Release: 1.0 Release Date 17Feb2016                           //
//                                                                //
//  Created by John Tramel on 20Feburary2016                      //
//  Copyright  2016 John Tramel. All rights reserved.             //
//  Copyright  2017 John Tramel. All rights reserved.             //
//                                                                //
//  Abstract: Top level for TRAMBLAZE processor                   //
//  Edit history: 2016JAN25 - created                             //
//  20FEB - top created for processor and memory                  //
//          tramelblaze_top                                       //
//               - tramelblaze                                    //
//               - tramelblaze_mem                                //
//                                                                //
//  02march2017 release 3.0                                       //
//
//  In submitting this file for class work at CSULB               //
//  I am confirming that this is my work and the work             //
//  of no one else.                                               //
//                                                                //
//  In the event other code sources are utilized I will           //
//  document which portion of code and who is the author          //
//                                                                //
// In submitting this code I acknowledge that plagiarism          //
// in student project work is subject to dismissal from the class //
//****************************************************************//

`timescale 1ns/1ns

module tramelblaze_top (CLK, RESET, IN_PORT, INTERRUPT, 
                        OUT_PORT, PORT_ID, READ_STROBE, WRITE_STROBE, INTERRUPT_ACK);

input         CLK;
input         RESET;
input  [15:0] IN_PORT;
input         INTERRUPT;

output [15:0] OUT_PORT;
output [15:0] PORT_ID;
output        READ_STROBE;
output        WRITE_STROBE;
output        INTERRUPT_ACK;

wire   [15:0] INSTRUCTION;
wire   [11:0] ADDRESS;

tramelblaze tramelblaze 
      (
      .CLK(CLK), 
      .RESET(RESET), 
      .IN_PORT(IN_PORT), 
      .INTERRUPT(INTERRUPT), 
                        
      .OUT_PORT(OUT_PORT), 
      .PORT_ID(PORT_ID), 
      .READ_STROBE(READ_STROBE), 
      .WRITE_STROBE(WRITE_STROBE), 
      .INTERRUPT_ACK(INTERRUPT_ACK),
                
      .ADDRESS(ADDRESS),
      .INSTRUCTION(INSTRUCTION)
      );
                
tb_rom tb_rom 
      (
      .clka(CLK),                   // input clka
      .addra(ADDRESS),              // input [11 : 0] addra
      .douta(INSTRUCTION)           // output [15 : 0] douta
      );

endmodule
