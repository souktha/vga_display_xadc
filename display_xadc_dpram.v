/*
 *  Display output from XADC on VGA 640x480@60HZ
 *
 * Copyright (C) 2016 by Soukthavy Sopha
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 *  $Date: 2016-04-03 15:49:57 -0700 (Sun, 03 Apr 2016) $
 *  $Rev $
 */

`timescale 1 ns / 100 ps
module vga_display_xadc (
    input CLK100MHZ, CPU_RESETN,
    input vauxn3, vauxp3,
    input BTNC,
    input [1:0] SW,
    output [3:0] LED,
    output [1:0] JA,
    output VGA_HS, VGA_VS,
    output [3:0] VGA_R, VGA_G, VGA_B,
    output CA,CB,CC,CD,CE,CF,CG,
    output [7:0] AN
    );
    wire video_on, p_tick;
    wire [9:0] x, y; //(x,y) coordinate output from vga_sync
    reg [11:0] rgb;
    wire xadc_bsy, xadc_drdy, xadc_eos,xadc_alarm;//,vp, vn;
    wire [4:0] chout;
    wire [15:0] dp_rdata; //data read from DP RAM
    wire [15:0] xadc_dout; //conversion data from XADC
    wire [7:0] clk_scale;
    wire dp_we;
    wire clk8MHZ; //ADC clock is %2 for this
    reg [9:0] xadc_waddr;
    reg [9:0] count;


	assign VGA_R = rgb[11:8];
	assign VGA_G = rgb[7:4];
	assign VGA_B = rgb[3:0];

	assign LED[0] = dp_we;
	assign LED[1] = xadc_bsy;
	assign LED[2] = xdc_alarm;
	assign LED[3] = video_on;

	//assign clk_scale = SW;
	assign JA[0] = (count < 'd100);  //use as test pulse (500KHZ) if connects to JXADC PMOD pin1,pin7

	display_mux show_value(
		.clk(CLK100MHZ),
		.data(xdc_data),
		.led({1'b1,CA,CB,CC,CD,CE,CF,CG}),
		.an(AN)
		);

    vga_sync vga_drawgraph (.clk(CLK100MHZ),
                         ._rst(CPU_RESETN),
                         ._hsync(VGA_HS),
                         ._vsync(VGA_VS),
                         .video_on(video_on),
                         .p_tick(p_tick),
                         .pixel_x(x), //output of (x,y)
                         .pixel_y(y));

	
	always@(posedge CLK100MHZ, negedge CPU_RESETN)
		if (!CPU_RESETN || (count >= 'd200))
			count <= 10'h0;
		else 
			count <= count + 1'b1;

	/* Plotting data of array data[x], x=0..639 along the (x,y) axis 
	*
		|   
		|   |    |
		|   |  | |
	 ---------------------	>x direction
	 d0 d1  d2  d4   d6 ..	
	* */
    /* continuous conversion required den_in, eco_out connected together ! Also the
    daddr_in is to connected to address that correspond to vaux channel (Table 4.2, page 56 of ug480).
    This information came from sample code of basys3.
    Input to xadc: PMOD JXADC, pin1 A13 (AD3P), pin7 A14(AD3N).
    */
    xadc_wiz_0 XADC_INST(
        .daddr_in(8'd19), //19 for vaux3
        .dclk_in(CLK100MHZ),  //4*time FS. This is set in the IP wizard.
        .den_in(dp_we),  //connect this to eoc_out for continuous sampling.
        .di_in(),  //not use
        .dwe_in(),  //not use
        .reset_in(),
        .vauxp3(vauxp3), 
        .vauxn3(vauxn3), 
        .busy_out(xadc_bsy), 
        .channel_out(chout), 
        .do_out(xadc_dout), 
        .drdy_out(xadc_drdy), 
        .eoc_out(dp_we), 
        .eos_out(xadc_eos), 
        .alarm_out(xdc_alarm), 
        .vp_in(), 
        .vn_in()
        );

    ram_dual_port #(
        .DATA_WIDTH(16), 
        .ADDR_WIDTH(10))
     dp_ram(
        .clk(CLK100MHZ),
        .we(xadc_drdy & SW[0]), //write on every DRDY as enabled by SW[0]
        .data(xadc_dout), //data from xadc to be stored
        .read_addr(x), //location to be read for VGA x-coordinate
        .write_addr(xadc_waddr), //location to store on EOC
        .q(dp_rdata) //Y data read correspond to x-coordinate
        );

    always@(posedge dp_we or negedge CPU_RESETN)
        if (!CPU_RESETN)
            xadc_waddr <= 10'b0;
        else 
            xadc_waddr <= xadc_waddr + 1'b1;

	//wire [11:0] xdc_data = {3'b0,dp_rdata[15:7]};   //use only upper 9 bits instead of 12 bit ADC
    wire [11:0] xdc_data = {2'b0,dp_rdata[15:5]};   // scaled 12 bit ADC


    always@(posedge p_tick)
		if (video_on ) begin
            //if ( (y >= 'd470-xdc_data) && (y < 'd470) )
            if ( (y == 'd470-xdc_data) && (y < 'd470) )
                rgb <= 12'hf00;
            else
                if ( y == 'd470 )
                    rgb <= 12'h0f0;
                else
                    rgb <= 12'h0;
		end 
        else 
			rgb <= 12'h0;

 endmodule
