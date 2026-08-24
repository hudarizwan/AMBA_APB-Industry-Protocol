module master(

    input clk,
    input reset,
    input request,
    input acknowledge,

    input [1:0] input_address,
    input input_rw,
    input [7:0] input_data,

    output reg transaction_valid,
    output reg [1:0] transaction_address,
    output reg transaction_rw,
    output reg [7:0] transaction_data

);

parameter IDLE_STATE = 2'b00,
          SEND_STATE = 2'b01,
          WAIT_STATE = 2'b10;

reg [1:0] current_state;
reg [1:0] upcoming_state;

always @(posedge clk or posedge reset)
begin
    if (reset)
        current_state <= IDLE_STATE;
    else
        current_state <= upcoming_state;
end

always @(*)
begin

    upcoming_state = IDLE_STATE;

    case (current_state)

        IDLE_STATE:
        begin
            if (request)
                upcoming_state = SEND_STATE;
            else
                upcoming_state = IDLE_STATE;
        end

        SEND_STATE:
        begin
            upcoming_state = WAIT_STATE;
        end

        WAIT_STATE:
        begin
            if (acknowledge)
                upcoming_state = IDLE_STATE;
            else
                upcoming_state = WAIT_STATE;
        end

        default:
        begin
            upcoming_state = IDLE_STATE;
        end

    endcase

end

always @(*)
begin

    transaction_valid   = 1'b0;
    transaction_address = 2'b00;
    transaction_rw      = 1'b0;
    transaction_data    = 8'b0;

    case (current_state)

        IDLE_STATE:
        begin
            transaction_valid = 1'b0;
        end

        SEND_STATE:
        begin
            transaction_valid   = 1'b1;
            transaction_address = input_address;
            transaction_rw      = input_rw;
            transaction_data    = input_data;
        end

        WAIT_STATE:
        begin
            transaction_valid   = 1'b1;
            transaction_address = input_address;
            transaction_rw      = input_rw;
            transaction_data    = input_data;
        end

        default:
        begin
            transaction_valid   = 1'b0;
            transaction_address = 2'b00;
            transaction_rw      = 1'b0;
            transaction_data    = 8'b0;
        end

    endcase

end

endmodule
