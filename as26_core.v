// aes256_core.v (with intentional errors for debugging practice)

module aes256_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] data_in,
    input  wire [255:0] key_in,
    output reg          busy,
    output reg          done,
    output reg  [127:0] data_out
);

    localparam ROUNDS = 14;

    reg [7:0] state;
    localparam S_IDLE = 0, S_KEYEXP = 1, S_INIT_ADD = 2, S_ROUND = 3, S_FINAL = 4, S_DONE = 5;

    reg [127:0] block;
    reg [127:0] round_key [0:ROUNDS];
    integer rk_i;

    // ERROR: Wrong width! should be [7:0], but written as [3:0]
    function [3:0] aes_sbox;
        input [7:0] in;
        begin
            case (in)
                8'h00: aes_sbox = 8'h63;
                8'h01: aes_sbox = 8'h7c;
                default: aes_sbox = 8'h00;
            endcase
        end
    endfunction

    // ERROR: Missing semicolon after function declaration
    function [7:0] xtime
        input [7:0] b;
        begin
            xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
        end
    endfunction

    function [31:0] mix_column;
        input [31:0] col;
        reg [7:0] a0,a1,a2,a3;
        reg [7:0] r0,r1,r2,r3;
        begin
            a0 = col[31:24]; a1 = col[23:16]; a2 = col[15:8]; a3 = col[7:0];
            r0 = xtime(a0) ^ (a1 ^ xtime(a1)) ^ a2 ^ a3;
            r1 = a0 ^ xtime(a1) ^ (a2 ^ xtime(a2)) ^ a3;
            r2 = a0 ^ a1 ^ xtime(a2) ^ (a3 ^ xtime(a3));
            r3 = (a0 ^ xtime(a0)) ^ a1 ^ a2 ^ xtime(a3);
            mix_column = {r0,r1,r2}; // ERROR: Missing r3
        end
    endfunction

    // ERROR: Wrong signal name (should be "data_in")
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            busy <= 0;
            done <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        block <= input_data; // ERROR: undeclared signal
                        busy <= 1;
                        state <= S_INIT_ADD;
                    end
                end
                S_INIT_ADD: begin
                    block <= block ^ round_key[0];
                    rk_i <= 1;
                    state <= S_ROUND;
                end
                S_ROUND: begin
                    if (rk_i < ROUNDS) begin
                        block <= block ^ round_key[rk_i];
                        rk_i <= rk_i + 1;
                    end else begin
                        state <= S_FINAL;
                    end
                end
                S_FINAL: begin
                    data_out <= block;
                    state <= S_DONE;
                end
                S_DONE: begin
                    busy <= 0;
                    done <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule
