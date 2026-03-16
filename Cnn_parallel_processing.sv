module cnn_parallel (
    input logic clk, rst_n,
    input logic [23:0] rgb_in [0:8],  // Accepts 3x3 pixel block in parallel
    output logic health_status
);
    logic [7:0] grayscale [0:8], binary [0:8], resized [0:8];
    logic [15:0] feature_out [0:8], pooled_out;
    logic [7:0] filter [0:8];

    // Parallel Image Preprocessing
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : preprocess
            image_preprocessing ip (
                .clk(clk),
                .rst_n(rst_n),
                .rgb_in(rgb_in[i]),
                .grayscale_out(grayscale[i]),
                .binary_out(binary[i]),
                .resized_out(resized[i])
            );
        end
    endgenerate

    // Parallel Convolution
    generate
        for (i = 0; i < 9; i = i + 1) begin : conv
            convolution_adder_tree conv (
                .clk(clk),
                .rst_n(rst_n),
                .pixel_in({resized[i], resized[i], resized[i], resized[i], resized[i], resized[i], resized[i], resized[i], resized[i]}),
                .filter(filter),
                .feature_out(feature_out[i])
            );
        end
    endgenerate

    // Max Pooling (Collect all convolution outputs and select max)
    max_pooling pool (
        .clk(clk),
        .rst_n(rst_n),
        .feature_in(feature_out),
        .pooled_out(pooled_out)
    );

    // Classification
    classification classify (
        .clk(clk),
        .rst_n(rst_n),
        .pooled_in(pooled_out),
        .health_status(health_status)
    );
endmodule



module cnn_parallel_tb;
    logic clk;
    logic rst_n;
    logic [23:0] rgb_in [0:8];
    logic health_status;

    // Instantiate CNN Parallel Module
    cnn_parallel uut (
        .clk(clk),
        .rst_n(rst_n),
        .rgb_in(rgb_in),
        .health_status(health_status)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;
    // Test Image Data (3x3 Blocks)
    logic [23:0] test_blocks [0:2][0:2];

    initial begin
        $display("Starting Parallel CNN Testbench...");
        clk = 0;
        rst_n = 0;

        // Apply Reset
        #20 rst_n = 1;

        // Test Image Blocks (Simulated Malaria Data)
        test_blocks[0][0] = 24'hA12F4C; 
test_blocks[0][1] = 24'h3C7D91; 
test_blocks[0][2] = 24'hF0A512; 
test_blocks[1][0] = 24'h78D456; 
test_blocks[1][1] = 24'hE9E9E9; 
test_blocks[1][2] = 24'hA12F4C; 
test_blocks[2][0] = 24'h3C7D91; 
test_blocks[2][1] = 24'hF0A512; 
test_blocks[2][2] = 24'h78D456; 

        // Load the 3x3 block into input array
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                rgb_in[i * 3 + j] = test_blocks[i][j];
            end
        end

        #20; // Allow parallel processing time
        $display("Parallel CNN Classification Output: Health Status = %b", health_status);

        $display("Parallel CNN Testbench Completed!");
        $stop;
    end
endmodule


