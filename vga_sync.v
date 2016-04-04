`timescale 1 ns / 100 ps
/*
Generate sync signals and pixel clock for VGA 640x480@60HZ
*/
module vga_sync (
    input clk,_rst,  //Note: input clock for this board is 100MHZ, _rst is active low.
    output _hsync, _vsync, video_on, p_tick,
    output [9:0] pixel_x, pixel_y
    );

    /* Constant declaration
        640x480@60HZ VGA sync parameters. Actual area is 800 x 525 where
        some areas area blacked out during sync/retrace.
        Define below are the parameter.
     */
    //Values in pixels
    localparam HD = 640; //displayable Horizontal
    localparam HB = 48;  //Horz back porch
    localparam HF = 16;  //Horz front porch
    localparam HR = 96;  //horizonal retrace, Hsync time
    /* 96(HR)+48(HB)+640+16(HF) = 800 */
    localparam VD = 480;  //displayable vertical pixels
    //Values in lines
    localparam VF = 10;  //vfront porch, top border
    localparam VB = 33;  //vback, vertical back porch, bottom border
    localparam VR = 2;  //vretrace

    /* pixel clock rate is : 800 * 60HZ * 525 ~ 25MHZ */
    /* For 100 MHZ board clock, to get 25MHZ will need mod-4 counter, but we will use
    bit 1 of counter to trigger the wrap  */
    reg [1:0] mod4_cnt;
    //hsync, vsync counters
    reg [9:0] hcnt, vcnt;
    wire h_end,v_end;

    /*initial begin //for simulation
        #1 hcnt = 0;
        #1 vcnt = 0;
        @(posedge clk) mod4_cnt = 2'b00;
    end*/ 

    always@(posedge clk, negedge _rst )
        if (~_rst ) begin
            mod4_cnt <= 2'b00;
        end
        else begin
            mod4_cnt <= mod4_cnt + 1'b1;
        end

    assign p_tick = mod4_cnt[1]; // tick at 25MHZ rate

    assign h_end = (hcnt >= (HD+HF+HB+HR-1)); //end of H counter@800-1 count
    assign v_end = (vcnt >= (VD+VF+VB+VR)); //end of V counter@525 count

    //modulo 800 counter and modulo 525 counter
    always@(posedge p_tick, negedge _rst ) begin
		if (~_rst) begin
            hcnt <= 0;
            vcnt <= 0;
		end else begin
        if (h_end) begin
            hcnt <= 10'b0;
            vcnt <= vcnt + 1'b1;
        end
        else
            hcnt <= hcnt + 1'b1;

        if (v_end)
            vcnt <= 10'b0;
		end
    end
    assign _hsync = ( (hcnt <= (HD+HF)) || (hcnt >= (HD+HF+HR)) );
    assign _vsync = ( ( vcnt <= (VD+VF)) || (vcnt >= (VD+VF+VR)) );

	assign video_on = (hcnt <= (HD-1)) && (vcnt <= (VD-1));
    assign pixel_x = (hcnt <= (HD-1) ) ? hcnt:10'b11_1111_1111;
    assign pixel_y = (vcnt <= (VD-1) ) ? vcnt:10'b11_1111_1111;

endmodule
