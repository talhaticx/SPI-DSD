module seven_seg_mux (
    input  logic [2:0]  sel,         // Slower display clock
    input  logic [6:0]  seg0, seg1, seg2, seg3, seg4, seg5,
    output logic [6:0]  seg,         // Common segment output
    output logic [5:0]  an           // Active low anode
);

    always_comb begin
        case (sel)
            3'd0: begin seg = seg0; an = 6'b111110; end
            3'd1: begin seg = seg1; an = 6'b111101; end
            3'd2: begin seg = seg2; an = 6'b111011; end
            3'd3: begin seg = seg3; an = 6'b110111; end
            3'd4: begin seg = seg4; an = 6'b101111; end
            3'd5: begin seg = seg5; an = 6'b011111; end
            default: begin seg = 7'b111_1111; an = 6'b111111; end
        endcase
    end
endmodule
