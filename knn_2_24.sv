module Image_Dataset_ROM #(
    parameter DATA_WIDTH = 16,  // Width of each pixel data (modify if needed)
    parameter IMG_WIDTH = 32,   // Image width in pixels
    parameter IMG_HEIGHT = 32,  // Image height in pixels
    parameter NUM_IMAGES = 250, // Total number of images
    parameter ADDR_WIDTH = 16,  // Address width (log2 of total memory size)
    parameter ROM_DEPTH = IMG_WIDTH * IMG_HEIGHT * NUM_IMAGES  // Total memory entries
)(
    input  logic clk,                     // Clock signal
    input  logic [$clog2(NUM_IMAGES)-1:0] image_index, // Selects which image to access
    input  logic [$clog2(IMG_WIDTH*IMG_HEIGHT)-1:0] pixel_addr, // Selects pixel in image
    output logic [DATA_WIDTH-1:0] data   // Output pixel data
);

    // ROM storage for all images
    logic [DATA_WIDTH-1:0] rom [0:ROM_DEPTH-1];

    // Load image dataset from a memory file
    initial begin
        $readmemh("hex_data3.mem", rom);  // Load all images in a single file
    end

    // Compute memory address (concatenating image index and pixel address)
    logic [ADDR_WIDTH-1:0] addr;
    always_comb begin
        addr = (image_index * (IMG_WIDTH * IMG_HEIGHT)) + pixel_addr;
    end

    // Synchronous read operation
    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
endmodule

// KNN Classifier Module
module KNN_Classifier #(
    parameter DATA_WIDTH = 16,
    parameter IMG_WIDTH = 32,
    parameter IMG_HEIGHT = 32,
    parameter NUM_IMAGES = 250,
    parameter K = 3  // Number of neighbors to consider
)(
    input logic clk,
    input logic [$clog2(NUM_IMAGES)-1:0] query_image_index,
    output logic [1:0] classified_label // Output class label (modify as needed)
);

    logic [$clog2(IMG_WIDTH * IMG_HEIGHT)-1:0] pixel_addr;
    logic [DATA_WIDTH-1:0] query_pixel, dataset_pixel;
    logic [$clog2(NUM_IMAGES)-1:0] image_index;
    logic [31:0] distances [NUM_IMAGES-1:0];
    
    // Instantiate ROM for image dataset
    Image_Dataset_ROM #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .NUM_IMAGES(NUM_IMAGES)
    ) rom_instance (
        .clk(clk),
        .image_index(image_index),
        .pixel_addr(pixel_addr),
        .data(dataset_pixel)
    );

    // Compute distances between query image and dataset images
    always_ff @(posedge clk) begin
        for (image_index = 0; image_index < NUM_IMAGES; image_index = image_index + 1) begin
            distances[image_index] = 0;
            for (pixel_addr = 0; pixel_addr < (IMG_WIDTH * IMG_HEIGHT); pixel_addr = pixel_addr + 1) begin
                distances[image_index] = distances[image_index] + (dataset_pixel - query_pixel) * (dataset_pixel - query_pixel);
            end
        end
    end

    // Simple K-NN logic: Find K nearest images (modify as needed)
    always_ff @(posedge clk) begin
        // Sort and determine class based on nearest neighbors (simplified logic here)
        classified_label <= distances[0] < distances[1] ? 2'b01 : 2'b10; // Example logic
    end
endmodule


`timescale 1ns / 1ps

module knn_tb_24_02_12w;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter IMG_WIDTH = 32;
    parameter IMG_HEIGHT = 32;
    parameter NUM_IMAGES = 250;
    parameter ADDR_WIDTH = 16;
    parameter ROM_DEPTH = IMG_WIDTH * IMG_HEIGHT * NUM_IMAGES;

    // Signals
    logic clk;
    logic [$clog2(NUM_IMAGES)-1:0] image_index;
    logic [$clog2(IMG_WIDTH*IMG_HEIGHT)-1:0] pixel_addr;
    logic [DATA_WIDTH-1:0] data;

    // Instantiate the ROM module
    Image_Dataset_ROM #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .NUM_IMAGES(NUM_IMAGES),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ROM_DEPTH(ROM_DEPTH)
    ) dut (
        .clk(clk),
        .image_index(image_index),
        .pixel_addr(pixel_addr),
        .data(data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        $display("Starting ROM Test...");
        $readmemh("hex_data3.mem", dut.rom); // Load test data

        // Apply stimulus
        image_index = 0;
        pixel_addr = 0;
        #10;

        for (int img = 0; img < 3; img++) begin // Test first 3 images
            for (int px = 0; px < 10; px++) begin // Test first 10 pixels
                image_index = img;
                pixel_addr = px;
                #10;
                $display("Image: %0d, Pixel: %0d, Data: %h", image_index, pixel_addr, data);
            end
        end
        
        $display("ROM Test Completed.");
        $finish;
    end
endmodule

