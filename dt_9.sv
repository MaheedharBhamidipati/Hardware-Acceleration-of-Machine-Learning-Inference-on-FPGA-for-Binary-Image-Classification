module decision_tree_classifier #(
    parameter int IMG_SIZE = 64,  // Image has 64 pixels (8x8)
    parameter int BIN_COUNT = 64, // 6-bit quantization (0-63 bins)
    parameter int TRAINED_BIN_42 = 100, // Pretrained histogram bin 42 threshold
    parameter int TRAINED_BIN_59 = 200  // Pretrained histogram bin 59 threshold
)(
    input logic clk, rst,           // Clock and reset
    output logic class_out          // Classification output (0 = Healthy, 1 = Diseased)
);

    // **ROM to hold image data (Quantized Values)**
    logic [5:0] rom [0:IMG_SIZE-1]; // 6-bit quantized pixel data
    initial $readmemh("output2.mem", rom); // Load image from .mem file

    // **Pipeline registers**
    logic [5:0] quantized_pixel [0:IMG_SIZE-1]; // Quantized pixel values
    logic [15:0] histogram [0:BIN_COUNT-1]; // 64-bin histogram
    logic [15:0] test_bin_42, test_bin_59;  // Values of bins 42 and 59

    // **Step 1 - Pixel Quantization**
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < IMG_SIZE; i++)
                quantized_pixel[i] <= 6'd0;
        end else begin
            for (int i = 0; i < IMG_SIZE; i++)
                quantized_pixel[i] <= rom[i]; // Read quantized values from ROM
        end
    end

    // **Step 2 - Histogram Computation**
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int j = 0; j < BIN_COUNT; j++)
                histogram[j] <= 16'd0;
        end else begin
            for (int i = 0; i < IMG_SIZE; i++)
                histogram[quantized_pixel[i]] <= histogram[quantized_pixel[i]] + 1;
        end
    end

    // **Step 3 - Extract Test Bins**
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            test_bin_42 <= 16'd0;
            test_bin_59 <= 16'd0;
        end else begin
            test_bin_42 <= histogram[42];
            test_bin_59 <= histogram[59];
        end
    end

    // **Step 4 - Decision Tree Classification**
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            class_out <= 1'b0;
        else
            class_out <= (test_bin_42 != TRAINED_BIN_42) || (test_bin_59 != TRAINED_BIN_59);
    end

endmodule


module tb_9_decision_tree_classifier;

    logic clk, rst;
    logic class_out;

    // Instantiate the Decision Tree Classifier module
    decision_tree_classifier dut (
        .clk(clk),
        .rst(rst),
        .class_out(class_out)
    );

    // Generate clock signal
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        #10 rst = 0; // Release reset

        #100; // Wait for pipeline stages to complete

        // Display results
        $display("Classification Output: %b", class_out);
        
        $finish;
    end

endmodule

