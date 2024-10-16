module hub75e_led_matrix
# (
    parameter clk_mhz       = 50,

              screen_width  = 64,
              screen_height = 64,

              brightness    = 1,

              w_x           = $clog2 ( screen_width  ),
              w_y           = $clog2 ( screen_height )
)
(
    input                    clk,
    input                    rst,

    output logic [w_x - 1:0] x,
    output logic [w_y - 1:0] y,

    output logic             ck,
    output logic             oe,
    output logic             st,

    output logic             a,
    output logic             b,
    output logic             c,
    output logic             d,
    output logic             e
);

    //------------------------------------------------------------------------

    localparam w_cnt = 1;

    logic [w_cnt - 1:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'b1;

    wire en = (cnt == w_cnt' (1'b1));

    //------------------------------------------------------------------------

    localparam w_state = brightness + 3;

    localparam [w_state - 1:0]
        state_0    = 0,
        state_1    = 1,
        state_2    = 2,
        state_3    = 3,
        state_last = w_state' (~ 0);

    logic [w_state - 1:0] state, state_d;

    //------------------------------------------------------------------------

    logic [w_x - 1:0] x_d;
    logic [w_y - 1:0] y_d;

    always_comb
    begin
        state_d = state;
        x_d     = x;
        y_d     = y;

        case (state)

        state_0:
        begin
            x_d ++;

            if (x_d == screen_width - 1)
                state_d = state_1;
        end

        state_last:
        begin
            x_d = 0;

            if (y_d == screen_height - 1)
                y_d = '0;
            else
                y_d ++;

            state_d = state_0;
        end

        default:
            state_d ++;

        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (rst)
            ck <= 1'b0;
        else
            ck <= cnt [$left (cnt)] & (state <= state_1);

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            state <= state_0;
            x     <= '0;
            y     <= '0;

            oe    <= 1'b1;
            st    <= 1'b0;
        end
        else if (en)
        begin
            state <= state_d;
            x     <= x_d;
            y     <= y_d;

            oe    <= (state <= state_3 | state == state_last);
            st    <= (state == state_2);
        end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        { e, d, c, b, a } <= y;

endmodule

//----------------------------------------------------------------------------

`ifndef YOSYS

// `define LOCAL_TESTBENCH

`ifdef LOCAL_TESTBENCH

module tb_hub75e_led_matrix;

    logic clk;
    logic rst;

    hub75e_led_matrix dut (.clk (clk), .rst (rst));

    initial
    begin
        clk = 1'b0;

        forever
            # 5 clk = ~ clk;
    end

    initial
    begin
        rst <= 1'bx;
        repeat (2) @ (posedge clk);
        rst <= 1'b1;
        repeat (100) @ (posedge clk);
        rst <= 1'b0;
    end

    initial
    begin
        $dumpvars;
        repeat (10000) @ (posedge clk);
        $finish;
    end

endmodule

`endif
`endif
