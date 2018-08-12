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
// �������������( VibesIC )�ṩ���������Ʒ����֤ͨ�����������ڴ˻������޸ģ�// 
// ���Ʋ��ַ�,������������Ȩ�������֡����ǲ�����ŵ����ƿ���������ҵ��Ʒ��ͬʱ// 
// ���ǲ���֤��Ƶ�ͨ���ԡ�Ϊ�˷�������Լ��޸��뱣����Ƶİ汾��Ϣ���������� // 
// �޸Ĳ�������㹻��ע�͡������������������,�뵽��վ�������ۡ�              // 
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
  //HC164��������������Լ�LEDָʾ�ƣ���̬ɨ������ܵ��������Ӿ����������Խ����� 
  //ʾ���������˵��Ӿ�ӡ���ھ�����ʧ����������Ĥ�ϱ���0��1���ʱ������Ӿ��� 
  //�������Խ�����ˢ�����ʿ���Ϊ10Hz(0.1s)��ͬʱ������Ҫ����λ���ݽ���ɨ�裬��� 
  //����ˢ���������Ӧ��Ϊ10Hz��4����߿���Ϊ50MHz(HC164���Թ�����50��175MHz)�� 
  //����ʵ��������ǿ��Զ�Ϊ 762.939453125 = 50MHz/2**16, 
  //��˽ӿڴ�led,seg_value,dot���ݵı仯��������ܳ���Ϊ50MHz/2**14 
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
  //  led[3:0] :       led3-led0 ��Ӧԭ��ͼ��D5,D4,D3,D2��λLED�ƣ��ߵ�ƽ��Ч�� 
  //  seg_value[15:0] :��λ������������ʾ�����ݣ��Ӹߵ���ÿ4bitΪ�����һλ�� 
  //  dot[3:0] :       ��λ�������������ʾ��С����λ���Ӹߵ��� 
  //  hc_si :          ��ģ�����ݴ��������hc164���ݴ������롣 
  //  hc_cp :          ��ģ�������hc164ʱ�����롣 
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
  //  �ź�����˵�� 
  //  hc_data : �͵�����hc164��16bit�����ݣ�ÿ��hc164��8bit����hc164 data input 
  //  hc_data_44bit: hc_data�ĵ��ĸ�4BIT���ݣ� 
  //                 LED��ʾ�źţ���Ӧԭ��ͼ��HC_Q15,HC_Q14,HC_Q13,HC_Q12��λ�� 
  //                 ��������D5,D4,D3,D2��λLED�ƣ��ߵ�ƽ��Ч�� 
  //  hc_data_34bit: hc_data�ĵ�����4bit���ݣ���hc_data[11:8];��Ӧԭ��ͼ�� 
  //                 HC_Q11,HC_Q10,HC_Q9,HC_Q8�����λѡ�źţ��͵�ƽ��Ч�� 
  //  hc_data_31bit: hc_data�ĵ�����1bit���ݣ���hc_data[2];��Ӧԭ��ͼ��HC_Q2���� 
  //                 ���С����λ���ߵ�ƽ��Ч��  
  //  hc_data[7:0]: ����hc_data_31bit����8bit������Ϊ����ܶ�ѡ�źţ��ߵ�ƽ��Ч 
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
  //  ֮������Ҫȡ��������Ϊ��hc_si��ֵʱ�����λ��ʼ,��ԭ��ͼ�����ϣ�������λ 
  //  ��ʼ�������ݡ� 
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
  //  ���ݹ�4λ������������������������ÿλ��ֵ��λ�룬�Լ�ÿλ��С��������� 
  //  ��Ϣ��ÿһλ��ֵ��ͨ��hex2ledģ��任�������λ�롣 
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
      case (hex)                        //��ֵ  
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
  // HC164 �� hc_si �Լ�hc_cp�źŵĲ�����ͨ��һ��6λ�ļ�����������.hc_si���ź� 
  // hc_data_inv�����λ��ʼ���ͣ�ԭ��ͼ����Ҫ�����λ���ͣ�����ڴ�֮ǰ��Ҫ���� 
  // ���ź�ȡ���� 
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
