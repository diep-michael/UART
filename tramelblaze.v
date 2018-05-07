//****************************************************************//
//  This document contains information proprietary to the         //
//  CSULB student that created the file - any reuse without       //
//  adequate approval and documentation is prohibited             //
//                                                                //
//  Class: CECS 460                                               //
//  Project name: TRAMBLAZE PROCESSOR                             //
//  File name: tramelblaze.v                                      //
//  Release: 1.0 Release Date 17Feb2016                           //
//  Release: 1.1 Release Date 25Feb2016                           //
//  Release: 1.4 Release Date 04Mar2016                           //
//  Release: 1.5 Release Date 17Mar2016                           //
//  Release: 1.6 Release Date 04May2016                           //
//  Release: 2.0 Release Date 29Aug2016                           //
//  Release: 3.0 Release Date 02mar2017                           //
//  Release: 3.1 Release Date 30mar2017                           //
//  Release: 4.0 Release Date 23aug2017                           //
//  Release: 5.0 Release Date 07nov2017                           //
//                                                                //
//  Created by John Tramel on 25January2016.                      //
//  Copyright  2016 John Tramel. All rights reserved.             //
//  Copyright  2017 John Tramel. All rights reserved.             //
//                                                                //
//  Abstract: Top level for TRAMBLAZE processor                   //
//  Edit history: 2016JAN25 - created                             //
//                2016FEB25 - corrected SHIFT/ROTATE              //
//                made sure that CARRY set correctly              //
//                2016FEB29 - added MEMHIOL                       //
//                MEMHIOL=1 memory access, =0 I/O access          //
//                added 512 x 16 scratchpad ram                   //
//                added 1st FETCH/STORE States                    //
//                2016MAR03 - 512x16 scratch ram debugged         //
//                2016MAR03 - 512x16 scratch ram debugged         //
//                2016MAR17 - 128x16 stack ram debugged           //
//                04May2016 - Stack RAM address fix               //
//                28Feb2017 - Removed MEMHIOL                     //
//                30Mar2017 - Fixed NOP -thanks Chou Thao         //
//                                                                //
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

module tramelblaze (CLK, RESET, IN_PORT, INTERRUPT, 
                    OUT_PORT, PORT_ID, READ_STROBE, WRITE_STROBE, INTERRUPT_ACK,
                    ADDRESS, INSTRUCTION);

input         CLK;
input         RESET;
input  [15:0] IN_PORT;
input         INTERRUPT;

output [15:0] OUT_PORT;
output [15:0] PORT_ID;
output        READ_STROBE;
output        WRITE_STROBE;
output        INTERRUPT_ACK;

output [11:0] ADDRESS;
input  [15:0] INSTRUCTION;

reg    [15:0] inst_reg;                      // instruction register
reg    [15:0] const_reg;                     // constant register
reg    [15:0] pc;                            // program counter
reg    [15:0] regfile [0:15];                // 16 x 16 register file
reg    [16:0] alu_out;                       // output of ALU
reg    [16:0] alu_out_reg;                   // output of ALU registered
reg    [ 3:0] stateX,stateQ;                 // state machine variable
wire   [11:0] ADDRESS;                       // ADDRESS to instruction memory
reg    [15:0] address_mux;                   // mux to select next address
reg           int_enable;                    // enable interrupt
reg           int_proc;                      // processor interrupt
wire          carryPX;                       // preserve carry bit
reg           carryPQ;                       // preserve carry bit
wire          zeroPX;                        // preserve zero bit
reg           zeroPQ;                        // preserve zero bit
reg           zeroX,zeroQ;                   // flag
reg           carryX,carryQ;                 // flag
reg           loadKX,loadKQ;                 // load constant register
reg           ldirX,ldirQ;                   // load instruction register
wire          ldk;                           // load constant register
reg           ldpcX,ldpcQ;                   // load program counter
reg           ldflagX,ldflagQ;               // load carry and zero registers
reg           ldflagPX,ldflagPQ;             // preserve load carry and zero registers
reg           wtrfX,wtrfQ;                   // write register file
reg           wtsrX,wtsrQ;                   // write scratchpad ram
reg           sel_alubX,sel_alubQ;           // select alu operand b
reg           pushX,pushQ;                   // push pc address onto stack
reg           popX,popQ;                     // pop pc address from stack
reg           enintX,enintQ;                 // enable interrupts
reg           disintX,disintQ;               // disable interrupts
reg     [1:0] sel_pcX,sel_pcQ;               // select pc source
reg           sel_portidX,sel_portidQ;       // select source for port id
reg     [2:0] sel_rfwX,sel_rfwQ;             // select reg write data source
reg     [2:0] flag_selX,flag_selQ;           // select source to change zero/carry
reg     [4:0] alu_opX,alu_opQ;               // select which operation alu does
reg           enableportidX,enableportidQ;   // allow port id to switch
reg           enableinportX,enableinportQ;   // allow in port to be read
reg           enableoutportX,enableoutportQ; // allow out port to switch
reg           readstrobeX,readstrobeQ;       // set read strobe output
reg           writestrobeX,writestrobeQ;     // set write strobe output
reg           interruptackX,interruptackQ;   // interrupt acknowledge
wire   [15:0] pc_min1;                       // program counter minus one
wire   [15:0] stackWdata;                    // data written into stack

wire    [6:0] opcode;                        // current opcode being executed
wire    [3:0] regX_adrs, regY_adrs;          // address to x and y registers
reg    [15:0] rf_wdata;                      // data to write into register file
wire   [15:0] stackRdata;                  // contents of stack pointed to (last write)
wire   [15:0] alu_a;                         // input to ALU A
wire   [15:0] alu_b;                         // input to ALUB
wire          INTERRUPT_ACK;
wire          READ_STROBE;
wire          WRITE_STROBE;
wire   [15:0] regA;                          // output of register file - A
wire   [15:0] regB;                          // output of register file - B
wire   [15:0] scratch_dout;                        // scratch pad ram output
wire    [8:0] scratch_adrs;
wire   [15:0] scratch_din;
wire   [ 6:0] stackAdrs;
reg    [ 6:0] stackPointQ;
wire   [ 6:0] stackPointD;

// assume instruction memory is 8K deep (000 - FFF)

parameter INTERRUPT_ADDRESS = 16'H0FFE;

// parameters for STATES

parameter FETCH = 5'H00, DECODE  = 5'H01, SECOND = 5'H02, THIRD   = 5'H03, EXECUTE = 5'H04, 
          ENDIT = 5'H05, ENDCALL = 5'H06, ENDRET = 5'H07, ENDRET2 = 5'H08, ENDRET3 = 5'H09,
          OUTPUT_XK_2 = 5'H0A, OUTPUT_XY_2 = 5'H0B, INPUT_XP_2 = 5'H0C, INPUT_XY_2 = 5'H0D,
          FETCH_XK_2 = 5'H0E, FETCH_XY_2 = 5'H0F, STORE_XK_2 = 5'H10, STORE_XY_2 = 5'H11;

// parameters for ALU OPERATIONS

parameter NOTHING = 5'H00, ADD  = 5'H01, ADDC = 5'H02, AND  = 5'H03, 
          SUB     = 5'H04, OR   = 5'H05, RLX  = 5'H06, RRX  = 5'H07,
          SL0X    = 5'H08, SL1X = 5'H09, SLAX = 5'H0A, SLXX = 5'H0B,
          SR0X    = 5'H0C, SR1X = 5'H0D, SRAX = 5'H0E, SRXX = 5'H0F,
          XOR     = 5'H10, SUBC = 5'H11;

// parameters for OPCODES
//
parameter NOP         = 7'H00, ADD_XK      = 7'H02, ADD_XY      = 7'H04, 
          ADDCY_XK    = 7'H06, ADDCY_XY    = 7'H08, AND_XK      = 7'H0A,
          AND_XY      = 7'H0C, CALL_AAA    = 7'H0E, CALLC_AAA   = 7'H10,
          CALLNC_AAA  = 7'H12, CALLZ_AAA   = 7'H14, CALLNZ_AAA  = 7'H16,
          COMP_XK     = 7'H18, COMP_XY     = 7'H1A, DISINT      = 7'H1C,
          ENINT       = 7'H1E, INPUT_XY    = 7'H20, INPUT_XP    = 7'H22, 
          JUMP_AAA    = 7'H24, JUMPC_AAA   = 7'H26, JUMPNC_AAA  = 7'H28, 
          JUMPZ_AAA   = 7'H2A, JUMPNZ_AAA  = 7'H2C, LOAD_XK     = 7'H2E, 
          LOAD_XY     = 7'H30, OR_XK       = 7'H32, OR_XY       = 7'H34, 
          OUTPUT_XY   = 7'H36, OUTPUT_XK   = 7'H38, RETURN      = 7'H3A, 
          RETURN_C    = 7'H3C, RETURN_NC   = 7'H3E, RETURN_Z    = 7'H40, 
          RETURN_NZ   = 7'H42, RETURN_DIS  = 7'H44, RETURN_EN   = 7'H46, 
          RL_X        = 7'H48, RR_X        = 7'H4A, SL0_X       = 7'H4C, 
          SL1_X       = 7'H4E, SLA_X       = 7'H50, SLX_X       = 7'H52, 
          SR0_X       = 7'H54, SR1_X       = 7'H56, SRA_X       = 7'H58, 
          SRX_X       = 7'H5A, SUB_XK      = 7'H5C, SUB_XY      = 7'H5E, 
          SUBC_XK     = 7'H60, SUBC_XY     = 7'H62, TEST_XK     = 7'H64, 
          TEST_XY     = 7'H66, XOR_XK      = 7'H68, XOR_XY      = 7'H6A, 
          FETCH_XK    = 7'H70, FETCH_XY    = 7'H72, STORE_XK    = 7'H74, 
          STORE_XY    = 7'H76;

assign READ_STROBE = readstrobeQ;
assign WRITE_STROBE = writestrobeQ;
assign INTERRUPT_ACK = interruptackQ;

//////////////////////////////
// address register - PC    //
//////////////////////////////

assign ADDRESS = pc[11:0];

always @(posedge CLK, posedge RESET)
   if (RESET) 
      pc <= 16'b0;
   else
      if (ldpcQ) 
         pc <= address_mux;

always @(*)
   case(sel_pcQ)
      2'b00: address_mux = pc + 16'b1;
      2'b01: address_mux = stackRdata;
      2'b10: address_mux = const_reg;
      2'b11: address_mux = INTERRUPT_ADDRESS;
   endcase

//////////////////////////////
// address stack            //
//////////////////////////////

assign ldsp = popQ | pushQ;

always @(posedge CLK, posedge RESET)
        if (RESET) stackPointQ <= 7'b0; else
        if (ldsp)  stackPointQ <= stackPointD;

assign pc_min1 = pc - 16'b1;
assign stackWdata = int_proc ? pc_min1 : pc;


assign stackAdrs   = pushQ ? stackPointQ      : stackPointQ - 7'b1;
assign stackPointD = pushQ ? stackAdrs + 7'b1 : stackAdrs;

stack_ram stkr (
        .addra(stackAdrs),
        .dina(stackWdata),
        .wea(pushQ),
        .clka(CLK),
        .douta(stackRdata)
        );
   
//////////////////////////////
// instruction register     //
//////////////////////////////

assign opcode    = inst_reg[14:8];       // opcode for instruction decode
assign regY_adrs = inst_reg[7:4];
assign regX_adrs = inst_reg[3:0];
assign ldk  = inst_reg[15] && (stateQ==DECODE);

always @(posedge CLK, posedge RESET)
   if (RESET) inst_reg <= 16'b0; else
   if (ldirQ)  inst_reg <= INSTRUCTION;

//////////////////////////////
// constant register        //
//////////////////////////////

always @(posedge CLK, posedge RESET)
   if (RESET)  const_reg <= 16'b0; else
   if (loadKQ) const_reg <= INSTRUCTION;

//////////////////////////////
// interrupt control        //
//////////////////////////////

always @(posedge CLK, posedge RESET)
   if (RESET)   int_enable <= 1'b0; else
   if (enintQ)  int_enable <= 1'b1; else
   if (disintQ) int_enable <= 1'b0;

always @(posedge CLK, posedge RESET)
   if (RESET)                   int_proc <= 1'b0; else
   if (INTERRUPT_ACK)           int_proc <= 1'b0; else
   if (int_enable & INTERRUPT)  int_proc <= 1'b1;

//////////////////////////////
// register file operations //
//////////////////////////////

assign regA = regfile[regX_adrs];
assign regB = regfile[regY_adrs];

always @(*)
        case (sel_rfwQ)
                3'b000: rf_wdata = alu_out[15:0];
                3'b001: rf_wdata = IN_PORT & {16{enableinportQ}};
                3'b010: rf_wdata = const_reg;
                3'b011: rf_wdata = regB;
                3'b100: rf_wdata = scratch_dout;
               default: rf_wdata = alu_out[15:0];
                endcase

always @(posedge CLK, posedge RESET)
   if (RESET) begin
      regfile[0]  <= 16'b0;
      regfile[1]  <= 16'b0;
      regfile[2]  <= 16'b0;
      regfile[3]  <= 16'b0;
      regfile[4]  <= 16'b0;
      regfile[5]  <= 16'b0;
      regfile[6]  <= 16'b0;
      regfile[7]  <= 16'b0;
      regfile[8]  <= 16'b0;
      regfile[9]  <= 16'b0;
      regfile[10] <= 16'b0;
      regfile[11] <= 16'b0;
      regfile[12] <= 16'b0;
      regfile[13] <= 16'b0;
      regfile[14] <= 16'b0;
      regfile[15] <= 16'b0;
      end else
   if (wtrfQ) begin
      regfile[regX_adrs] <= rf_wdata;
      end

//////////////////////////////
// CARRY/ZERO operations   //
//////////////////////////////

assign zeroPX  = zeroQ;
assign carryPX = carryQ;

always @(posedge CLK, posedge RESET)
   if (RESET)    {zeroPQ,carryPQ} <= 2'b0; else
   if (ldflagPQ) {zeroPQ,carryPQ} <= {zeroPX,carryPX};

always @(posedge CLK, posedge RESET)
   if (RESET)    {zeroQ,carryQ} <= 2'b0; else
   if (ldflagQ)  {zeroQ,carryQ} <= {zeroX,carryX};
      
always @(*)
   case(flag_selQ)
      3'h0: {zeroX, carryX} = {zeroQ, carryQ};
      3'h1: {zeroX, carryX} = {~|alu_out[15:0],1'b0};
      3'h2: {zeroX, carryX} = {~|alu_out[15:0],alu_out[16]};
      3'h3: {zeroX, carryX} = {zeroPQ, carryPQ};
      3'h4: {zeroX, carryX} = {~|alu_out[15:0],alu_out[15]};
      3'h5: {zeroX, carryX} = {~|alu_out[15:0],alu_out[0]};
      3'h6: {zeroX, carryX} = {~|(alu_a & alu_b),^(alu_a & alu_b)};
   default: {zeroX, carryX} = {zeroQ, carryQ};
      endcase

//////////////////////////////
// ALU operations           //
//////////////////////////////

assign alu_a = regA;
assign OUT_PORT = regA & {16{enableoutportQ}};
assign alu_b = (sel_alubQ) ? const_reg : regB;
assign PORT_ID = (sel_portidQ) ? (const_reg & {16{enableportidQ}}) : (alu_b & {16{enableportidQ}});

always @(posedge CLK, posedge RESET)
   if (RESET) alu_out_reg <= 17'b0;
   else       alu_out_reg <= alu_out;

always @(*)
   case(alu_opQ)
      NOTHING: alu_out = alu_out_reg;                        // noop so no change
      ADD:     alu_out = alu_a + alu_b;                      // ADD
      ADDC:    alu_out = alu_a + alu_b + carryQ;             // ADDC
      SUB:     alu_out = alu_a - alu_b;                      // SUB (COMP)
      SUBC:    alu_out = alu_a - alu_b - carryQ;             // SUBC
      AND:     alu_out = alu_a & alu_b;                      // AND
      OR:      alu_out = alu_a | alu_b;                      // OR
      XOR:     alu_out = alu_a ^ alu_b;                      // XOR
      RLX:     alu_out = {alu_a[15],alu_a[14:0],alu_a[15]};  // RL rX
      RRX:     alu_out = {alu_a[ 0],alu_a[0],alu_a[15:1]};   // RR rX
      SL0X:    alu_out = {alu_a[15],alu_a[14:0],1'b0};       // SL0 rX
      SL1X:    alu_out = {alu_a[15],alu_a[14:0],1'b1};       // SL1 rX
      SLAX:    alu_out = {alu_a[15],alu_a[14:0],carryQ};     // SLA rX
      SLXX:    alu_out = {alu_a[15],alu_a[14:0],alu_a[0]};   // SLX rX
      SR0X:    alu_out = {alu_a[ 0],1'b0,alu_a[15:1]};       // SR0 rX
      SR1X:    alu_out = {alu_a[ 0],1'b1,alu_a[15:1]};       // SR1 rX
      SRAX:    alu_out = {alu_a[ 0],carryQ,alu_a[15:1]};     // SRA rX
      SRXX:    alu_out = {alu_a[ 0],alu_a[15],alu_a[15:1]};  // SRX rX
    default: alu_out = 16'b0;
   endcase

///////////////////////////////
// Scratchpad RAM Instance   //
// 512x16 Scratchpad Memory  //
///////////////////////////////

assign scratch_din = alu_a;
assign scratch_adrs = alu_b[8:0];
 
scratch_ram sr (
   .clka(CLK),
   .wea(wtsrQ),
   .addra(scratch_adrs),
   .dina(scratch_din),
   .douta(scratch_dout)
   );

///////////////////////////////
// Instruction Control Logic //
///////////////////////////////


always @(posedge CLK, posedge RESET)
   if (RESET) begin
      stateQ <= FETCH;                  // start up state variable
      ldirQ <= 1'b1;                    // load instruction register
      ldpcQ <= 1'b1;                    // load program counter
      ldflagQ <= 1'b0;                  // load carry and zero registers
      ldflagPQ <= 1'b0;                 // load preserve carry and zero registers
      loadKQ <= 1'b0;                   // load constant register
      wtrfQ <= 1'b0;                    // write register file
      wtsrQ <= 1'b0;                    // write scratch pad ram
      sel_alubQ <= 1'b0;                // select alu operand b
      pushQ <= 1'b0;                    // push pc address onto stack
      popQ <= 1'b0;                     // pop pc address from stack
      enintQ <= 1'b0;                   // enable interrupts
      disintQ <= 1'b0;                  // disable interrupts
      sel_pcQ <= 2'b0;                  // select pc source
      sel_portidQ <= 1'b0;              // select source for port id
      sel_rfwQ <= 3'b0;                 // select reg write data source
      flag_selQ <= 2'b0;                // select source to change zero/carry
      alu_opQ <= 5'b0;                  // select which operation alu does
      enableportidQ <= 1'b0;            // allow port id to switch
      enableinportQ <= 1'b0;            // allow in port to be read
      enableoutportQ <= 1'b0;           // allow out port to switch
      readstrobeQ <= 1'b0;              // set read strobe output
      writestrobeQ <= 1'b0;             // set write strobe output
      interruptackQ <= 1'b0;            // set interrupt ack
      end
  else
      begin
      stateQ <= stateX;                 // update up state variable
      ldirQ <= ldirX;                   // load instruction register
      ldpcQ <= ldpcX;                   // load program counter
      ldflagQ <= ldflagX;               // load carry and zero registers
      ldflagPQ <= ldflagPX;             // load preserve carry and zero registers
      loadKQ <= loadKX;                 // load constant register
      wtrfQ <= wtrfX;                   // write register file
      wtsrQ <= wtsrX;                   // write scratch pad ram
      sel_alubQ <= sel_alubX;           // select alu operand b
      pushQ <= pushX;                   // push pc address onto stack
      popQ <= popX;                     // pop pc address from stack
      enintQ <= enintX;                 // enable interrupts
      disintQ <= disintX;               // disable interrupts
      sel_pcQ <= sel_pcX;               // select pc source
      sel_portidQ <= sel_portidX;       // select source for port id
      sel_rfwQ <= sel_rfwX;             // select reg write data source
      flag_selQ <= flag_selX;           // select source to change zero/carry
      alu_opQ <= alu_opX;               // select which operation alu does
      enableportidQ <= enableportidX;   // allow port id to switch
      enableinportQ <= enableinportX;   // allow in port to be read
      enableoutportQ <= enableoutportX; // allow out port to switch
      readstrobeQ <= readstrobeX;       // set read strobe output
      writestrobeQ <= writestrobeX;     // set write strobe output
      interruptackQ <= interruptackX;   // set interrupt ack
      end

/////////////////////////////////////////
// State Machine Decision Making Block //
/////////////////////////////////////////

always@(*)
   begin
   ldirX = 1'b0;                  // load instruction register
   ldpcX = 1'b0;                  // load program counter
   ldflagX = 1'b0;                // load carry and zero registers
   ldflagPX = 1'b0;               // load preserve carry and zero registers
   loadKX = 1'b0;                 // load constant register
   wtrfX = 1'b0;                  // write register file
   wtsrX = 1'b0;                  // write scratch pad ram
   sel_alubX = 1'b0;               // select alu operand b
   pushX = 1'b0;                  // push pc address onto stack
   popX = 1'b0;                   // pop pc address from stack
   enintX = 1'b0;                 // enable interrupts
   disintX = 1'b0;                // disable interrupts
   sel_pcX = 2'b0;                // select pc source
   sel_portidX = 1'b0;             // select source for port id
   sel_rfwX = 3'b0;               // select reg write data source
   flag_selX = 2'b0;              // select source to change zero/carry
   alu_opX = 5'b0;                // select which operation alu does
   enableportidX = 1'b0;          // allow port id to switch
   enableinportX = 1'b0;          // allow in port to be read
   enableoutportX = 1'b0;         // allow out port to switch
   readstrobeX = 1'b0;            // set read strobe output
   writestrobeX = 1'b0;           // set write strobe output
   interruptackX = 1'b0;          // set interrupt ack
   stateX = FETCH;
   
   case(stateQ)
      FETCH: begin
      if (int_proc) begin
         sel_pcX=2'b11;              // goto interrupt 
         ldpcX=1'b1;                 // update new pc
         pushX  =1'b1;               // push next pc onto stack
         disintX=1'b1;               // entering interrupt clear interrupt
         ldflagPX=1'b1;              // preserve the flag registers
         interruptackX=1'b1;         // set interrupt ack
         stateX=ENDRET2;             // let int_proc reset
         end
      else begin
         ldpcX=1'b0;
         ldirX=1'b0;
         stateX=DECODE;
         end
      end

      DECODE: begin
      if(ldk) begin
         loadKX=1'b1;
         stateX=SECOND;
         end
      else begin
         stateX=EXECUTE;
         end
      end

     SECOND: begin
     ldpcX=1'b1;
     stateX=THIRD;
     end

     THIRD: begin
      stateX=EXECUTE;
      end

      EXECUTE: begin
      case(opcode)
         NOP:stateX=ENDIT;

         ADD_XK: begin
         wtrfX=1'b1;
         sel_alubX=1'b1;
         flag_selX=3'b010;
         ldflagX=1'b1;
         alu_opX=ADD;
         stateX=ENDIT;
         end

         ADD_XY: begin
         wtrfX=1'b1;
         flag_selX=3'b010;
         alu_opX=ADD;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         ADDCY_XK: begin
         wtrfX=1'b1;
         sel_alubX=1'b1;
         flag_selX=3'b010;
         ldflagX=1'b1;
         alu_opX=ADDC;
         stateX=ENDIT;
         end

         ADDCY_XY: begin
         wtrfX=1'b1;
         flag_selX=3'b010;
         ldflagX=1'b1;
         alu_opX=ADDC;
         stateX=ENDIT;
         end

         AND_XK: begin
         wtrfX=1'b1;
         sel_alubX=1'b1;
         flag_selX=3'b001;
         ldflagX=1'b1;
         alu_opX=AND;
         stateX=ENDIT;
         end

         AND_XY: begin
         wtrfX=1'b1;
         alu_opX=AND;
         flag_selX=3'b001;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         CALL_AAA: begin
         pushX=1'b1;
         sel_pcX=2'b10;
         ldpcX=1'b1;
         stateX=ENDCALL;
         end

         CALLC_AAA: begin
         if(carryQ) begin
            pushX=1'b1;
            sel_pcX=2'b10;
            ldpcX=1'b1;
            stateX=ENDCALL;
            end else
         stateX=ENDIT;
         end

         CALLNC_AAA: begin
         if(!carryQ) begin
            pushX=1'b1;
            sel_pcX=2'b10;
            ldpcX=1'b1;
            stateX=ENDCALL;
            end else
         stateX=ENDIT;
         end

         CALLZ_AAA: begin
         if(zeroQ) begin
            pushX=1'b1;
            sel_pcX=2'b10;
            ldpcX=1'b1;
            stateX=ENDCALL;
            end else
         stateX=ENDIT;
         end

         CALLNZ_AAA: begin
         if(!zeroQ) begin
            pushX=1'b1;
            sel_pcX=2'b10;
            ldpcX=1'b1;
            stateX=ENDCALL;
            end else
         stateX=ENDIT;
         end

         COMP_XK: begin
         alu_opX=SUB;
         sel_alubX=1'b1;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         COMP_XY: begin
         alu_opX=SUB;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         DISINT: begin
         disintX=1'b1;
         stateX=ENDCALL;
         end

         ENINT: begin
         enintX=1'b1;
         stateX=ENDCALL;
         end

         STORE_XY:begin
         wtsrX=1'b1;
         stateX=ENDIT;
         end

         STORE_XK: begin
         sel_alubX=1'b1;
         wtsrX=1'b1;
         stateX=ENDIT;
         end

         FETCH_XY:begin
         stateX=FETCH_XY_2;
         end

         FETCH_XK: begin
         sel_alubX=1'b1;
         stateX=FETCH_XK_2;
         end

         INPUT_XY:begin
         enableportidX=1'b1;
         enableinportX=1'b1;
         stateX=INPUT_XY_2;
         end

         INPUT_XP: begin
         enableinportX=1'b1;
         enableportidX=1'b1;
         sel_portidX=1'b1;
         stateX=INPUT_XP_2;
         end

         JUMP_AAA: begin
         sel_pcX=2'b10;
         ldpcX=1'b1;
         ldirX=1'b1;
         stateX=ENDCALL;
         end

         JUMPC_AAA: begin
         if(carryQ) begin
            sel_pcX=2'b10;
            ldpcX=1'b1;
            ldirX=1'b1;
            end
         stateX=ENDCALL;
         end

         JUMPNC_AAA: begin
         if(!carryQ) begin
            sel_pcX=2'b10;
            ldpcX=1'b1;
            ldirX=1'b1;
            end
         stateX=ENDCALL;
         end

         JUMPZ_AAA: begin
         if(zeroQ) begin
            sel_pcX=2'b10;
            ldpcX=1'b1;
            ldirX=1'b1;
            end
         stateX=ENDCALL;
         end

         JUMPNZ_AAA: begin
         if(!zeroQ) begin
            sel_pcX=2'b10;
            ldpcX=1'b1;
            ldirX=1'b1;
            end
         stateX=ENDCALL;
         end

         LOAD_XK: begin
         sel_rfwX=3'b010;
         wtrfX=1'b1;
         
         stateX=ENDIT;
         end

         LOAD_XY: begin
         sel_rfwX=3'b011;
         wtrfX=1'b1;
         stateX=ENDIT;
         end

         OR_XK: begin
         wtrfX=1'b1;
         flag_selX=3'b001;
         alu_opX=OR;
         sel_alubX=1'b1;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         OR_XY: begin
         wtrfX=1'b1;
         flag_selX=3'b001;
         alu_opX=OR;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         OUTPUT_XK: begin
         sel_portidX=1'b1;
         enableportidX=1'b1;
         enableoutportX=1'b1;
         stateX=OUTPUT_XK_2;
         end

         OUTPUT_XY: begin
         enableportidX=1'b1;
         enableoutportX=1'b1;
         stateX=OUTPUT_XY_2;
         end

         RETURN: begin
         popX=1'b1;
         stateX=ENDRET;
         end

         RETURN_C: begin
         if(carryQ) begin
            popX=1'b1;
            stateX=ENDRET;
            end else
         stateX=ENDIT;
         end

         RETURN_NC: begin
         if(!carryQ) begin
            popX=1'b1;
            stateX=ENDRET;
            end else
         stateX=ENDIT;
         end

         RETURN_Z: begin
         if(zeroQ) begin
            popX=1'b1;
            stateX=ENDRET;
            end else
         stateX=ENDIT;
         end

         RETURN_NZ: begin
         if(!zeroQ) begin
            popX=1'b1;
            stateX=ENDRET;
            end else
         stateX=ENDIT;
         end

         RETURN_DIS: begin
         flag_selX=3'b011;
         ldflagX=1'b1;
         disintX=1'b1;
         popX=1'b1;
         stateX=ENDRET;
         end

         RETURN_EN: begin
         flag_selX=3'b011;
         ldflagX=1'b1;
         enintX=1'b1;
         popX=1'b1;
         stateX=ENDRET;
         end

         RL_X: begin
         wtrfX=1'b1;
         alu_opX=RLX;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         RR_X: begin
         wtrfX=1'b1;
         alu_opX=RRX;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SL0_X: begin
         wtrfX=1'b1;
         alu_opX=SL0X;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SL1_X: begin
         wtrfX=1'b1;
         alu_opX=SL1X;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SLA_X: begin
         wtrfX=1'b1;
         alu_opX=SLAX;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SLX_X: begin
         wtrfX=1'b1;
         alu_opX=SLXX;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SR0_X: begin
         wtrfX=1'b1;
         alu_opX=SR0X;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SR1_X: begin
         wtrfX=1'b1;
         alu_opX=SR1X;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SRA_X: begin
         wtrfX=1'b1;
         alu_opX=SRAX;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end
         
         SRX_X: begin
         wtrfX=1'b1;
         alu_opX=SRXX;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SUB_XK: begin
         wtrfX=1'b1;
         sel_alubX=1'b1;
         alu_opX=SUB;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SUB_XY: begin
         wtrfX=1'b1;
         flag_selX=3'b010;
         alu_opX=SUB;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SUBC_XK: begin
         wtrfX=1'b1;
         sel_alubX=1'b1;
         alu_opX=SUBC;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         SUBC_XY: begin
         wtrfX=1'b1;
         alu_opX=SUBC;
         flag_selX=3'b010;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         TEST_XK: begin
         sel_alubX=1'b1;
         alu_opX=AND;
         flag_selX=3'b110;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         TEST_XY: begin
         alu_opX=AND;
         flag_selX=3'b110;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         XOR_XK: begin
         wtrfX=1'b1;
         sel_alubX=1'b1;
         alu_opX=XOR;
         flag_selX=3'b001;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         XOR_XY:begin
         wtrfX=1'b1;
         alu_opX=XOR;
         flag_selX=3'b001;
         ldflagX=1'b1;
         stateX=ENDIT;
         end

         default:stateX=FETCH;

      endcase
      end

      INPUT_XP_2: begin
      enableportidX=1'b1;
      enableinportX=1'b1;
      readstrobeX=1'b1;
      sel_portidX=1'b1;
      sel_rfwX=3'b001;
      wtrfX=1'b1;
      stateX=ENDIT;
      end

      INPUT_XY_2:begin
      enableportidX=1'b1;
      enableinportX=1'b1;
      readstrobeX=1'b1;
      sel_rfwX=3'b001;
      wtrfX=1'b1;
      stateX=ENDIT;
      end

      OUTPUT_XK_2: begin
      sel_portidX=1'b1;
      enableoutportX=1'b1;
      enableportidX=1'b1;
      writestrobeX=1'b1;
      stateX=ENDIT;
      end
      
      OUTPUT_XY_2: begin
      enableoutportX=1'b1;
      enableportidX=1'b1;
      writestrobeX=1'b1;
      stateX=ENDIT;
      end

      FETCH_XK_2:begin
      sel_rfwX=3'b100;
      wtrfX=1'b1;
      stateX=ENDIT;
      end

      FETCH_XY_2:begin
      sel_rfwX=3'b100;
      wtrfX=1'b1;
      stateX=ENDIT;
      end

      ENDCALL: begin
      stateX=ENDIT;
      end

      ENDRET: begin
      sel_pcX=2'b01;
      ldpcX=1'b1;
      stateX=ENDRET2;
      end

      ENDRET2: begin
      stateX=ENDRET3;
      end

      ENDRET3: begin
      ldpcX=1'b1;
      ldirX=1'b1;
      stateX=FETCH;
      end

      ENDIT: begin
      ldpcX=1'b1;
      ldirX=1'b1;
      stateX=FETCH;
      end
      
   endcase
end

endmodule//TRAMBLAZE.v


