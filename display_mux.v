/* display_mux 7 segments LED display multiplexing for AN0..AN7 to enable
displaying of the eight 7-segment LED.
We only MUX AN bits. The data to be displayed should use nexys4_7segLED module.
*/
`timescale 1 ms / 100 us

module display_mux(
    input clk, rst,
    input [15:0] data,
    output reg [7:0] an,
    output [7:0] led
    );

    localparam N = 20;

    reg [N-1:0] q;
    reg [3:0] hex;

    always@(posedge clk) begin
        q <= q + 1'b1;
        end

    always@(data)
        case (q[N-1:N-2]) /* use three MSB of counter to mux */
            2'b00: begin
             an = 8'b1111_1110;
             hex = data[3:0];
             end
            2'b01: begin 
             an = 8'b1111_1101;
             hex = data[7:4];
             end
            2'b10: begin 
             an = 8'b1111_1011;
             hex = data[11:8];
             end
            2'b11: begin
             an = 8'b1111_0111;
             hex = data[15:12];
             end
            /*
            3'b100: begin 
             an = 8'b1110_1111;
             hex = data[19:16];
             end
            3'b101: begin 
             an = 8'b1101_1111;
             hex = data[23:20];
             end
            3'b110: begin
             an = 8'b1011_1111;
             hex = data[27:24];
             end
            3'b111: begin
             an = 8'b0111_1111;
             hex = data[31:28];
             end */
        endcase

    nexys4_7segLED display_hex(.hex(hex),.segs(led));

endmodule
