module LCD_display(
    input           clk,
    input           reset_n,
    input   [127:0] row0,
    input   [127:0] row1,
    output          RS,
    output          EN,
    output    [7:0] DATA
);

    localparam  [2:0]   INITIAL = 3'b000,
                        ADDR_R0 = 3'b001,
                        DATA_R0 = 3'b010,
                        ADDR_R1 = 3'b011,
                        DATA_R1 = 3'b100,
                        STOP    = 3'b101;
    
    wire [7:0]  row0_data   [0:15];
    wire [7:0]  row1_data   [0:15];
    wire [7:0]  cmd         [0:5];
    reg  [2:0]  state;
    reg [20:0]  counter;
    reg  [4:0]  ptr;
    reg  [7:0]  DATA_reg;
    reg         RS_reg;
    reg         EN_reg;

    assign RS   = RS_reg;
    assign EN   = EN_reg;
    assign DATA = DATA_reg;

    assign cmd[0] = 8'h00;      // Power on
    assign cmd[1] = 8'h38;      // Function set: 8 bit, 2 lines, 5x8 font
    assign cmd[2] = 8'h0c;      // Display control: display on, cursor off, blink off
    assign cmd[3] = 8'h01;      // Clear display
    assign cmd[4] = 8'h02;      // Return home   
    assign cmd[5] = 8'h06;      // Entry mode set: increment AC, no shift

    generate
        genvar i;
        for (i = 1; i < 17; i=i+1) begin: for_name
            assign row0_data[16-i] = row0[(i*8)-1:i*8-8];
            assign row1_data[16-i] = row1[(i*8)-1:i*8-8];
        end
    endgenerate

    always @(negedge clk) begin
        if (~reset_n) begin
            state   <= INITIAL;
            counter <= 0;
            ptr     <= 0;
            RS_reg  <= 0;
            EN_reg  <= 0;
            DATA_reg<= 0;
        end else begin
            case (state)
                INITIAL: begin
                    counter <= counter + 1;
                    RS_reg  <= 0;
                    DATA_reg<= cmd[ptr];
                    if (counter == 20) EN_reg <= 1;
                    else if (counter == 60) EN_reg <= 0;
                    else if (counter == 328_000) begin  // 3.28 ms
                        counter <= 0;
                        if (ptr == 5) state <= ADDR_R0;
                        else ptr <= ptr + 1;    
                    end
                end
                ADDR_R0: begin
                    counter <= counter + 1;
                    RS_reg  <= 0;                       // Send command
                    DATA_reg<= 8'h80;                   // Set DDRAM address to 0x00: 1st row, 1st column
                    if (counter == 20) EN_reg <= 1;
                    else if (counter == 60) EN_reg <= 0;
                    else if (counter == 10_000) begin   // 0.1 ms
                        counter <= 0;
                        ptr <= 0;
                        state <= DATA_R0;
                    end
                end
                DATA_R0: begin
                    counter <= counter + 1;
                    RS_reg  <= 1;                       // Send data
                    DATA_reg<= row0_data[ptr];
                    if (counter == 20) EN_reg <= 1;
                    else if (counter == 60) EN_reg <= 0;
                    else if (counter == 10_000) begin   // 0.1 ms
                        counter <= 0;
                        if (ptr == 15) state <= ADDR_R1;
                        else ptr <= ptr + 1;
                    end
                end
                ADDR_R1: begin
                    counter <= counter + 1;
                    RS_reg  <= 0;                           // Send command
                    DATA_reg<= 8'hC0;                       // Set DDRAM address to 0x40: 2nd row, 1st column
                    if (counter == 20) EN_reg <= 1;
                    else if (counter == 60) EN_reg <= 0;
                    else if (counter == 10_000) begin       // 0.1 ms
                        counter <= 0;
                        ptr <= 0;
                        state <= DATA_R1;
                    end
                end
                DATA_R1: begin
                    counter <= counter + 1;
                    RS_reg  <= 1;                           // Send data
                    DATA_reg<= row1_data[ptr];
                    if (counter == 20) EN_reg <= 1;
                    else if (counter == 60) EN_reg <= 0;
                    else if (counter == 10_000) begin       // 0.1 ms
                        counter <= 0;
                        if (ptr == 15) state <= STOP;
                        else ptr <= ptr + 1;
                    end
                end
                STOP: begin
                    counter <= counter + 1;
                    RS_reg  <= 0;
                    DATA_reg<= 8'h02;                       // Clear display
                    if (counter == 20) EN_reg <= 1;
                    else if (counter == 60) EN_reg <= 0;
                    else if (counter == 2_000_000) begin    // 20 ms
                        counter <= 0;
                        state <= ADDR_R0;
                    end
                end
            endcase
        end
    end

endmodule
