//////////////////////////////////////////////////////////////////////////////// 
//                __     ___ _               ___ ____                         // 
//                \ \   / (_) |__   ___  ___|_ _/ ___|                        // 
//                 \ \ / /| | '_ \ / _ \/ __|| | |                            // 
//                  \ V / | | |_) |  __/\__ \| | |___                         // 
//                   \_/  |_|_.__/ \___||___/___\____|                        // 
//                                                                            // 
//////////////////////////////////////////////////////////////////////////////// 
// 	   Copyright (C) 2003-2006 VibesIC, Inc.   All rights reserved.           // 
//----------------------------------------------------------------------------// 
// This source code is provided by VibesIC,and be verified on VibesIC FPGA    // 
// development kit. The source code may be used and distributed without       // 
// restriction provided that this copyright statement is not removed from the // 
// file and that any derivative work contains the original copyright notice   // 
// and the associated disclaimer.                                             // 
//----------------------------------------------------------------------------// 
// THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED     // 
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF       // 
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE// 
// AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,     // 
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES(INCLUDING, BUT NOT LIMITED TO,// 
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,OR PROFITS; // 
// OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,   // 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR    // 
// OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF     // 
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.                                 // 
//----------------------------------------------------------------------------// 
// 本设计由威百仕( VibesIC )提供，并在其产品中验证通过，您可以在此基础上修改，// 
// 复制并分发,但请您保留版权声明部分。我们并不承诺本设计可以用做商业产品，同时// 
// 我们不保证设计的通用性。为了方便更新以及修改请保留设计的版本信息，并对自行 // 
// 修改部分添加足够的注释。对设计如有其他建议,请到网站进行讨论。              // 
//                                                                            // 
//////////////////////////////////////////////////////////////////////////////// 
//  Company:       www.richic.com                                             // 
//  Company bbs:   www.edacn.net                                              // 
//  Engineer:      alex_yang                                                  // 
//                                                                            // 
//  Target Device: XC3S400-PQ208                                              // 
//  Tool versions: Simulation:    ModelSim SE 6.2a                            // 
//                 Synthesis:     XST(ise8.1...sp3)                           // 
//                 Place&Routing: ISE8.1...sp3                                // 
//                 Others tools:  UltraEdit-32 12.10a                         // 
//  Create Date:   2006-12-21 14:19                                           // 
//  Description:                                                              // 
//                                                                            // 
//  LOG:                                                                      // 
//       1. Revision 1.0 (Initial version)  2006-12-21 14:19  alex_yang       // 
//                                                                            // 
//       2. Revision 1.1  2006-12-26 9:11   alex_yang                         // 
//          Modify for VX-SP306                                               // 
//////////////////////////////////////////////////////////////////////////////// 
`timescale 1ns/1ns 
 
module i2c_top(clk, rst_n, sda, scl, hc_cp, hc_si); 
  input  clk; 
  input  rst_n; 
  inout  sda; 
  output scl; 
  output hc_cp; 
  output hc_si; 
 
  reg  wr;  //write eeprom command 
  reg  rd;  //read eeprom command 
  reg  [10:0] addr;   //write or read address. 
  reg  [7:0]  data_w; //write data to eeprom 
  wire ack;           //i2c write or read complete 
  wire [7:0] data_r;  //read data from eeprom 
  
  reg [15:0] data_rep; //存储显示在七段数码管上的数据 
  reg show_ok;   //正确显示后的标志 
  reg wr_flag;   //记录是否已经发送过write,read command 
   
  reg [6:0]  cs,ns; 
  parameter  IDLE    = 7'b0000001, 
             WR_BYTE = 7'b0000010, 
             WR_ACK  = 7'b0000100, 
             DELAY   = 7'B0001000, 
             RD_BYTE = 7'b0010000, 
             RD_ACK  = 7'b0100000, 
             SHOW    = 7'b1000000; 
              
 
  //-------------产生时钟clk分频----------------------------------------------- 
  reg [11:0] clk_cnt;  
  reg [12:0] clk_div_cnt; 
  reg clk_div; 
  always @ (posedge clk or negedge rst_n) 
    if (!rst_n)  
      clk_cnt <= 12'd0; 
    else if (clk_cnt == 12'd1250)  //get 20khz SCL clock   
      clk_cnt <= 12'd0; 
    else  
      clk_cnt <= clk_cnt + 1'b1; 
       
  always @ (posedge clk or negedge rst_n) 
    if (!rst_n) 
      clk_div <= 1'b0; 
    else if (clk_cnt == 12'd1250) 
      clk_div <= ~clk_div;       //20khz 
       
  always @ (posedge clk_div or negedge rst_n) 
    if (!rst_n) 
      clk_div_cnt <= 13'd0; 
    else 
      clk_div_cnt <= clk_div_cnt + 1'b1; 
       
  //---------State machine------------------ 
  always @ (posedge clk_div or negedge rst_n) 
    if (!rst_n) 
      cs <= IDLE; 
    else  
      cs <= ns; 
       
  always @ ( * ) 
    case (cs) 
      IDLE: 
        if (clk_div_cnt == 13'd1000) 
          ns = WR_BYTE; 
        else 
          ns = IDLE; 
      WR_BYTE: 
        if (ack) 
          ns = WR_ACK; 
        else 
          ns = WR_BYTE; 
      WR_ACK: 
        if (!ack) 
            ns = DELAY; 
        else 
          ns = WR_ACK; 
      DELAY://eeprom写数据需要时间(请参考SPEC),故：等待数据写完后再进行读操作 
        if (clk_div_cnt == 13'd1300) 
          ns = RD_BYTE; 
        else 
          ns = DELAY; 
      RD_BYTE: 
        if (ack) 
          ns = RD_ACK; 
        else 
          ns = RD_BYTE; 
      RD_ACK: 
        if (!ack) 
          ns = SHOW; 
        else 
          ns = RD_ACK; 
      SHOW: 
        if (show_ok) 
          ns = IDLE; 
        else 
          ns = SHOW; 
      default: 
        ns = IDLE; 
    endcase 
     
  always @ (posedge clk_div or negedge rst_n) 
    if (!rst_n) 
      begin 
        wr <= 1'b0; 
        rd <= 1'b0; 
        addr <= 11'd0; 
        data_w <= 8'd0; 
//        data_w <= 8'h58; 
        show_ok <= 1'b0; 
        wr_flag <= 1'b0; 
      end 
    else if (data_w == 8'd255) //计数到255就重新开始 
      begin 
        addr <= 11'd0; 
        data_w <= 8'd0; 
//        data_w <= 8'h58; 
      end 
    else 
      case (cs) 
        IDLE: 
          begin 
            wr <= 1'b0; 
            rd <= 1'b0; 
            show_ok <= 1'b0; 
            wr_flag <= 1'b0; 
          end 
        WR_BYTE: 
          if (wr_flag == 1'b0) 
            begin 
              wr <= 1'b1; 
              wr_flag <= 1'b1; 
            end 
          else 
            wr <= 1'b0; 
        WR_ACK: 
          wr_flag <= 1'b0; 
        DELAY: 
          begin 
            wr <= 1'b0; 
            rd <= 1'b0; 
            show_ok <= 1'b0; 
            wr_flag <= 1'b0; 
          end 
        RD_BYTE: 
          if (wr_flag == 1'b0) 
            begin 
              rd <= 1'b1; 
              wr_flag <= 1'b1; 
            end 
          else 
            rd <= 1'b0; 
        RD_ACK: 
          begin 
            wr_flag <= 1'b0; 
            show_ok <= 1'b1;  
          end 
        SHOW: 
          begin 
            show_ok <= 1'b0; 
            addr <= addr + 1'b1; 
            data_w <= data_w + 1'b1; 
          end 
        default: 
          begin 
            wr <= 1'b0; 
            rd <= 1'b0; 
            show_ok <= 1'b0; 
            wr_flag <= 1'b0; 
          end 
      endcase 
       
  always @ (posedge clk_div or negedge rst_n) 
    if (!rst_n) 
      data_rep <=16'h0000; 
    else if (show_ok) 
      data_rep <= {data_w,data_r}; //将写入eeprom和从eeprom中读出的数据进行对比输出 
     
  // --------------------------------------------------------------------------- 
  // 例化EEPROM: 24C02的驱动程序 
  // --------------------------------------------------------------------------- 
  i2c_wr	i2c_wr_inst( 
      .clk          (clk_div), 
      .rst_n        (rst_n), 
      .wr           (wr), 
	    .rd           (rd), 
	    .addr         (addr), 
	    .data_w       (data_w), 
	    .data_r       (data_r), 
	    .ack          (ack), 
      .scl          (scl), 
      .sda          (sda) 
	    ); 
 
  // --------------------------------------------------------------------------- 
  // 例化hc164的驱动程序 
  // --------------------------------------------------------------------------- 
 
  hc164_driver hc164_driver_inst( 
      .clk         ( clk ), 
      .rst_n       ( rst_n ), 
      .led         ( {4{ ack }} ), 
      .dot         ( 4'b0000 ), 
      .seg_value   ( data_rep ), 
      .hc_cp       ( hc_cp ),  
      .hc_si       ( hc_si )   
      ); 
       
       
endmodule