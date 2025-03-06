module top(
    input           clk,
    input           reset_n,
    output          RS,
    output          EN,
    output  [7:0]   DATA
);

    wire    [127:0] row0;
    wire    [127:0] row1;

    gen_data gen_data_inst(
        .row0   (row0),
        .row1   (row1)
    );

    LCD_display LCD_display_inst(
        .clk    (clk),
        .reset_n(reset_n),
        .row0   (row0),
        .row1   (row1),
        .RS     (RS),
        .EN     (EN),
        .DATA   (DATA)
    );

endmodule
