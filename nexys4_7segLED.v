
/*
Nexys4DDR display 7 segment LEDS that use commmon anode AN0..AN7 to multplex
its eight 7 segments LEDs display.
*/

module nexys4_7segLED (
    input [3:0] hex,     /* hex value to be displayed  */
    input dot,
    output reg [7:0] segs      /* leds segments a(msb)..g(lsb) and a dot */
    );  

    /* Both anode and segments (cathodes) are inverted to illuminate */

    always@(hex) begin
        case (hex)            /*  abc_defg */  
            4'h0: segs[6:0] = ~7'b111_1110;
            4'h1: segs[6:0] = ~7'b011_0000;
            4'h2: segs[6:0] = ~7'b110_1101;
            4'h3: segs[6:0] = ~7'b111_1001;
            4'h4: segs[6:0] = ~7'b011_0011;
            4'h5: segs[6:0] = ~7'b101_1011;
            4'h6: segs[6:0] = ~7'b101_1111;
            4'h7: segs[6:0] = ~7'b111_0000;
            4'h8: segs[6:0] = ~7'b111_1111;
            4'h9: segs[6:0] = ~7'b111_0011;
            4'ha: segs[6:0] = ~7'b111_0111;
            4'hb: segs[6:0] = ~7'b001_1111;
            4'hc: segs[6:0] = ~7'b100_1110;
            4'hd: segs[6:0] = ~7'b011_1101;
            4'he: segs[6:0] = ~7'b100_1111;
            default: segs[6:0] = ~7'b100_0111;
        endcase
        segs[7] = dot;
        end
endmodule
