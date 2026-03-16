module cnn_pipelined (
    input logic clk, rst_n,
    input logic [23:0] rgb_in,
    output logic health_status
);
    logic [7:0] grayscale, binary, resized;
    logic [15:0] feature_out, pooled_out;
    logic [7:0] filter [0:8]; // Example filter weights (Assuming they are pre-loaded)

    // Image Preprocessing
    image_preprocessing ip (
        .clk(clk),
        .rst_n(rst_n),
        .rgb_in(rgb_in),
        .grayscale_out(grayscale),
        .binary_out(binary),
        .resized_out(resized)
    );

    // Convolution + Adder Tree
    convolution_adder_tree conv (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_in({resized, resized, resized, resized, resized, resized, resized, resized, resized}),
        .filter(filter),
        .feature_out(feature_out)
    );

    // Max Pooling
    max_pooling pool (
        .clk(clk),
        .rst_n(rst_n),
        .feature_in({feature_out, feature_out, feature_out, feature_out, feature_out, feature_out, feature_out, feature_out, feature_out}),
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

module cnn_pipelined_tb_06;
    // Testbench signals
    logic clk;
    logic rst_n;
    logic [23:0] rgb_in;
    logic health_status;

    // Instantiate CNN Pipelined Module
    cnn_pipelined uut (
        .clk(clk),
        .rst_n(rst_n),
        .rgb_in(rgb_in),
        .health_status(health_status)
    );

    // Clock Generation (10 ns period)
    always #5 clk = ~clk;

    // Test Variables
    integer i;
    logic [23:0] test_images [0:4]; // Test image pixels

    // Testbench Initialization
    initial begin
        $display("Starting Pipelined CNN Testbench...");
        clk = 0;
        rst_n = 0;
        rgb_in = 0;

        // Apply Reset
        #100 rst_n = 1;  // De-assert reset after 100 ns

        // Load Test Images
        test_images[0] = 24'hA12F4C; 
        test_images[1] = 24'h3C7D91; 
        test_images[2] = 24'hF0A512; 
        test_images[3] = 24'h78D456; 
        test_images[4] = 24'hE9E9E9; 

        // Apply test cases with a delay to allow pipeline execution
        for (i = 0; i < 5; i = i + 1) begin
            rgb_in = test_images[i];
            #100; // Delay for processing

            // Debugging: Print intermediate values
            $display("Image %0d: RGB = %h | Health Status = %b | Grayscale = %h | Binary = %b | Resized = %h | Feature Out = %h | Pooled Out = %h",
                     i, rgb_in, health_status, uut.grayscale, uut.binary, uut.resized, uut.feature_out, uut.pooled_out);
        end

        #500; // Extra delay for pipeline completion
        $display("Pipelined CNN Testbench Completed!");
        $stop;
    end
endmodule


