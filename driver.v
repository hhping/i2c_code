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
//  Engineer:      mail007 (Gavin.xue)                                        // 
//                                                                            // 
//  Target Device: XC3S400-PQ208                                              // 
//  Tool versions: Simulation:    ModelSim SE 6.2a                            // 
//                 Synthesis:     XST(ise8.1...sp3)                           // 
//                 Place&Routing: ISE8.1...sp3                                // 
//                 Others tools:  UltraEdit-32 12.10a                         // 
//  Create Date:   2005-9-15 14:59                                            // 
//  Description:                                                              // 
//                                                                            // 
//  LOG:                                                                      // 
//       1. Revision 1.0 (Initial version)  2005-9-15 14:59    mail007        // 
//                                                                            // 
//       2. Revision 1.1  2006-12-22 11:48   alex_yang                        // 
//          Updata ISE version from v6.3 to v8.1                              // 
//          Modify for VX-SP306                                               // 
//////////////////////////////////////////////////////////////////////////////// 
`timescale 1ns/1ns 
 
  // --------------------------------------------------------------------------- 
  //HC164用来驱动数码管以及LED指示灯，动态扫描数码管的是利用视觉暂留的特性进行显 
  //示景物引起人的视觉印象，在景物消失后还能在视网膜上保持0。1秒的时间叫做视觉暂 
  //留。可以将数据刷新速率可以为10Hz(0.1s)，同时我们需要对四位数据进行扫描，因此 
  //数据刷新速率最低应该为10Hz×4。最高可以为50MHz(HC164可以工作在50－175MHz)。 
  //根据实际情况我们可以定为 762.939453125 = 50MHz/2**16, 
  //因此接口处led,seg_value,dot数据的变化速率最大不能超过为50MHz/2**14 
  // --------------------------------------------------------------------------- 
 
module hc164_driver( 
    clk, 
    rst_n, 
    led, 
    dot, 
    seg_value, 
    hc_cp, 
    hc_si 
    ); 
 
  // --------------------------------------------------------------------------- 
  // 
  //  input signals 
  //  led[3:0] :       led3-led0 对应原理图中D5,D4,D3,D2四位LED灯，高电平有效。 
  //  seg_value[15:0] :四位共阴极数码显示的数据，从高到低每4bit为数码管一位。 
  //  dot[3:0] :       四位共阴极数码管显示的小数点位，从高到低 
  //  hc_si :          本模块数据串行输出，hc164数据串行输入。 
  //  hc_cp :          本模块输出，hc164时钟输入。 
  //   
  // --------------------------------------------------------------------------- 
  input           clk; 
  input           rst_n;   
  input   [3 :0]  led;  
  input   [3 :0]  dot;        
  input   [15:0]  seg_value;  
  output  reg     hc_cp;                //HC164 Clock input active Rising edges 
  output          hc_si;                //HC164 Data input 
 
  reg     [5 :0]  tx_cnt; 
  
  // --------------------------------------------------------------------------- 
  // 
  //  信号命名说明 
  //  hc_data : 送到两个hc164中16bit的数据（每个hc164有8bit），hc164 data input 
  //  hc_data_44bit: hc_data的第四个4BIT数据， 
  //                 LED显示信号，对应原理图中HC_Q15,HC_Q14,HC_Q13,HC_Q12四位， 
  //                 用来点亮D5,D4,D3,D2四位LED灯，高电平有效。 
  //  hc_data_34bit: hc_data的第三个4bit数据，即hc_data[11:8];对应原理图中 
  //                 HC_Q11,HC_Q10,HC_Q9,HC_Q8数码管位选信号，低电平有效。 
  //  hc_data_31bit: hc_data的第三个1bit数据，即hc_data[2];对应原理图中HC_Q2，数 
  //                 码管小数点位，高电平有效。  
  //  hc_data[7:0]: 包括hc_data_31bit，这8bit用来做为数码管段选信号，高电平有效 
  // 
  // --------------------------------------------------------------------------- 
  reg   [6:0]   hex2led;        //hex-to-seven-segment decoder output  
  reg   [3:0]   hc_data_34bit;   
  reg           hc_data_31bit;     
   
  wire  [15:0]  hc_data = {led, 
                          hc_data_34bit, 
                          hex2led[6:2], 
                          hc_data_31bit, 
                          hex2led[1:0] 
                          }; 
  // --------------------------------------------------------------------------- 
  // 
  //  之所以需要取反，是因为对hc_si赋值时从最低位开始,而原理图中设计希望从最高位 
  //  开始发送数据。 
  // 
  // --------------------------------------------------------------------------- 
  wire  [15:0]  hc_data_inv = { 
                          hc_data[0], 
                          hc_data[1], 
                          hc_data[2], 
                          hc_data[3], 
                          hc_data[4], 
                          hc_data[5], 
                          hc_data[6], 
                          hc_data[7], 
                          hc_data[8], 
                          hc_data[9], 
                          hc_data[10], 
                          hc_data[11], 
                          hc_data[12], 
                          hc_data[13], 
                          hc_data[14], 
                          hc_data[15] 
                          }; 
 
  reg [15:0]  clk_cnt; 
  always @ ( posedge clk or negedge rst_n ) 
    if ( !rst_n ) clk_cnt <= 16'd0; 
    else  clk_cnt <= clk_cnt + 1'b1; 
       
  // --------------------------------------------------------------------------- 
  //  
  //  数据管4位计数器，本计数器用来区分每位数值，位码，以及每位的小数点等三个 
  //  信息，每一位数值将通过hex2led模块变换成数码管位码。 
  // 
  // --------------------------------------------------------------------------- 
  reg [1:0] seg_led_num; 
  always @ ( posedge clk or negedge rst_n ) 
    if (!rst_n ) seg_led_num <= 2'b00; 
    else if ( clk_cnt == 16'hFFFF ) seg_led_num <= seg_led_num + 1'b1; 
 
  reg   [3:0] hex; 
  always @ ( * ) 
    case ( seg_led_num ) 
      2'b00: hex = seg_value[15:12]; 
      2'b01: hex = seg_value[11:8]; 
      2'b10: hex = seg_value[7:4]; 
      2'b11: hex = seg_value[3:0]; 
    endcase  
   
  // --------------------------------------------------------------------------- 
  // hex-to-seven-segment decoder 
  // 
  // segment encoding 
  //      11 
  //      ---   
  //  10 |   | 7 
  //      ---   <- 5 
  //  1  |   | 4 
  //      --- .  3 
  //       2  
  //  Q[6:0] = p11 p10 p7 p5 _ p4 p2 p1  
  // --------------------------------------------------------------------------- 
  always @ ( * ) 
    begin 
      case (hex)                        //数值  
	      4'h1  : hex2led = 7'b0010_100;	//1           
	      4'h2  : hex2led = 7'b1011_011;	//2    
	      4'h3  : hex2led = 7'b1011_110;	//3    
	      4'h4  : hex2led = 7'b0111_100;	//4    
	      4'h5  : hex2led = 7'b1101_110;	//5    
	      4'h6  : hex2led = 7'b1101_111;	//6    
	      4'h7  : hex2led = 7'b1010_100;	//7    
	      4'h8  : hex2led = 7'b1111_111;	//8    
	      4'h9  : hex2led = 7'b1111_100;	//9    
	      4'hA  : hex2led = 7'b1111_101;	//A    
	      4'hB  : hex2led = 7'b0101_111;	//b    
	      4'hC  : hex2led = 7'b1100_011;	//C    
	      4'hD  : hex2led = 7'b0011_111;	//d    
	      4'hE  : hex2led = 7'b1101_011;	//E    
	      4'hF  : hex2led = 7'b1101_001;	//F    
	    default : hex2led = 7'b1110_111;	//0    
    endcase 
  end 
  
  always @ ( * ) 
    case ( seg_led_num ) 
      2'b00:hc_data_34bit[3:0] = 4'b0111; 
      2'b01:hc_data_34bit[3:0] = 4'b1011; 
      2'b10:hc_data_34bit[3:0] = 4'b1101; 
      2'b11:hc_data_34bit[3:0] = 4'b1110; 
    endcase   
 
  always @ ( * ) 
    case ( seg_led_num ) 
      2'b00:hc_data_31bit = dot[3]; 
      2'b01:hc_data_31bit = dot[2]; 
      2'b10:hc_data_31bit = dot[1]; 
      2'b11:hc_data_31bit = dot[0]; 
    endcase   
   
  // --------------------------------------------------------------------------- 
  //  
  // HC164 的 hc_si 以及hc_cp信号的产生，通过一个6位的计数器来控制.hc_si从信号 
  // hc_data_inv的最低位开始发送，原理图中需要从最高位发送，因此在此之前需要对整 
  // 个信号取反。 
  // 
  // ---------------------------------------------------------------------------   
  always @ ( posedge clk or negedge rst_n ) 
    if (!rst_n ) tx_cnt <= 6'd0; 
    else if ( clk_cnt[15] ) tx_cnt <= 6'd0;       
    else if ((!clk_cnt[15]) && (tx_cnt <= 6'd32 )) tx_cnt <= tx_cnt + 1'b1; 
 
  always @ ( posedge clk or negedge rst_n ) 
    if (!rst_n)  hc_cp <= 1'b0; 
    else if ( clk_cnt[15] ) hc_cp <= 1'b0; 
    else if ((!clk_cnt[15]) && (tx_cnt < 6'd32 )) hc_cp <= !hc_cp; 
 
  assign  hc_si = hc_data_inv[tx_cnt[4:1]]; 
     
endmodule
