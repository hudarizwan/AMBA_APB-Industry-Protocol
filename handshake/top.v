module top(

    input clk,
    input reset,
    input start,
    input rw,

    output [3:0] dataFpga,
    output valid,
    output ready

);

reg [7:0] received_data;

reg [1:0] target_address = 2'd1;
reg [7:0] transfer_data = 8'd10;

wire master_valid;
wire slave_acknowledge;

wire [1:0] bus_address;
wire bus_rw;
wire [7:0] bus_data;

master M1(

    .clk(clk),
    .reset(reset),
    .request(start),
    .acknowledge(slave_acknowledge),

    .input_address(target_address),
    .input_rw(rw),
    .input_data(transfer_data),

    .transaction_valid(master_valid),
    .transaction_address(bus_address),
    .transaction_rw(bus_rw),
    .transaction_data(bus_data)

);

slave S1(

    .clk(clk),
    .reset(reset),

    .transaction_valid(master_valid),
    .transaction_rw(bus_rw),

    .transaction_address(bus_address),
    .transaction_data(bus_data),

    .acknowledge(slave_acknowledge),
    .output_data(received_data)

);

assign valid = master_valid;
assign ready = slave_acknowledge;

assign dataFpga = received_data[3:0];

endmodule
