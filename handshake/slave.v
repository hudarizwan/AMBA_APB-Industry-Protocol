module slave(

    input clk,
    input reset,

    input transaction_valid,
    input transaction_rw,

    input [1:0] transaction_address,
    input [7:0] transaction_data,

    output reg acknowledge,
    output reg [7:0] output_data

);

parameter IDLE_STATE   = 2'b00,
          ACCESS_STATE = 2'b01,
          DONE_STATE   = 2'b10;

reg [1:0] current_state;
reg [1:0] upcoming_state;

reg [7:0] data_memory [3:0];

always @(posedge clk or posedge reset)
begin
    if (reset)
        current_state <= IDLE_STATE;
    else
        current_state <= upcoming_state;
end

always @(*)
begin

    case (current_state)

        IDLE_STATE:
        begin
            if (transaction_valid)
                upcoming_state = ACCESS_STATE;
            else
                upcoming_state = IDLE_STATE;
        end

        ACCESS_STATE:
        begin
            upcoming_state = DONE_STATE;
        end

        DONE_STATE:
        begin
            if (transaction_valid)
                upcoming_state = DONE_STATE;
            else
                upcoming_state = IDLE_STATE;
        end

        default:
        begin
            upcoming_state = IDLE_STATE;
        end

    endcase

end

always @(posedge clk)
begin

    if (current_state == ACCESS_STATE)
    begin

        if (transaction_rw)
            data_memory[transaction_address] <= transaction_data;
        else
            output_data <= data_memory[transaction_address];

    end

end

always @(*)
begin

    acknowledge = 1'b0;

    case (current_state)

        IDLE_STATE:
            acknowledge = 1'b0;

        ACCESS_STATE:
            acknowledge = 1'b0;

        DONE_STATE:
            acknowledge = 1'b1;

    endcase

end

endmodule
