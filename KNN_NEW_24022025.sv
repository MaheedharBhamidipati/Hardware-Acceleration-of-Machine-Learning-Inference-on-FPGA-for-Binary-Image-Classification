module Image_Dataset_ROM #(
    parameter DATA_WIDTH = 16,  // Width of each pixel data
    parameter IMG_WIDTH = 32,   // Image width in pixels
    parameter IMG_HEIGHT = 32,  // Image height in pixels
    parameter NUM_IMAGES = 250, // Total number of images
    parameter ADDR_WIDTH = 16,  // Address width
    parameter ROM_DEPTH = IMG_WIDTH * IMG_HEIGHT * NUM_IMAGES  // Total memory entries
)(
    input  logic clk,  // Clock signal
    input  logic [$clog2(NUM_IMAGES)-1:0] image_index, // Image selector
    input  logic [$clog2(IMG_WIDTH*IMG_HEIGHT)-1:0] pixel_addr, // Pixel selector
    output logic [DATA_WIDTH-1:0] data  // Output pixel data
);

    // ROM storage for all images
    logic [DATA_WIDTH-1:0] rom [0:ROM_DEPTH-1];

    // Load image dataset from a memory file
    initial begin
        $readmemh("hex_data3.mem", rom);  // Load all images from a hex file
    end

    // Compute memory address by combining image index and pixel address
    logic [ADDR_WIDTH-1:0] addr;
    always_comb begin
        addr = (image_index * (IMG_WIDTH * IMG_HEIGHT)) + pixel_addr;
    end

    // Synchronous read operation
    always_ff @(posedge clk) begin
        data <= rom[addr];
    end
endmodule

module KNN_Classifier #(
    parameter DATA_WIDTH = 16,
    parameter IMG_WIDTH = 32,
    parameter IMG_HEIGHT = 32,
    parameter NUM_IMAGES = 250,
    parameter K = 3  // Number of neighbors to consider
)(
    input logic clk,
    input logic [DATA_WIDTH-1:0] new_image [0:IMG_WIDTH*IMG_HEIGHT-1], // New image data
    output logic [1:0] classified_label // Output class label
);

    // Internal signals
    logic [$clog2(NUM_IMAGES)-1:0] image_index;
    logic [$clog2(IMG_WIDTH*IMG_HEIGHT)-1:0] pixel_addr;
    logic [DATA_WIDTH-1:0] dataset_pixel;
    logic [31:0] distances [0:NUM_IMAGES-1];
    logic [$clog2(NUM_IMAGES)-1:0] nearest_indices [0:K-1];
    logic [1:0] labels [0:NUM_IMAGES-1]; // Assuming 2-bit labels
    logic [1:0] vote_count [0:3]; // For counting votes for 4 possible classes

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

    // Initialize labels (this should be replaced with actual label loading)
    initial begin
        // Example: Initialize all labels to 0
        for (int i = 0; i < NUM_IMAGES; i++) begin
            labels[i] = 2'b00; // Replace with actual label initialization
        end
    end

    // Compute distances between new image and dataset images
    always_ff @(posedge clk) begin
        for (image_index = 0; image_index < NUM_IMAGES; image_index++) begin
            distances[image_index] = 0;
            for (pixel_addr = 0; pixel_addr < (IMG_WIDTH * IMG_HEIGHT); pixel_addr++) begin
                distances[image_index] = distances[image_index] +
                    (dataset_pixel - new_image[pixel_addr]) * (dataset_pixel - new_image[pixel_addr]);
            end
        end
    end

    // Sort distances to find K nearest neighbors
    // Simple bubble sort for demonstration (consider more efficient sorting for large NUM_IMAGES)
    always_ff @(posedge clk) begin
        // Initialize nearest_indices
        for (int i = 0; i < NUM_IMAGES; i++) begin
            nearest_indices[i] = i;
        end
        // Bubble sort
        for (int i = 0; i < NUM_IMAGES-1; i++) begin
            for (int j = 0; j < NUM_IMAGES-i-1; j++) begin
                if (distances[nearest_indices[j]] > distances[nearest_indices[j+1]]) begin
                    // Swap indices
                    automatic logic [$clog2(NUM_IMAGES)-1:0] temp_idx = nearest_indices[j];
                    nearest_indices[j] = nearest_indices[j+1];
                    nearest_indices[j+1] = temp_idx;
                end
            end
        end
    end

    // Majority voting among K nearest neighbors
    always_ff @(posedge clk) begin
        // Reset vote counts
        for (int i = 0; i < 4; i++) begin
            vote_count[i] = 0;
        end
        // Count votes
        for (int i = 0; i < K; i++) begin
            vote_count[labels[nearest_indices[i]]] += 1;
        end
        // Determine the class with the highest vote count
        classified_label = 2'b00;
        for (int i = 1; i < 4; i++) begin
            if (vote_count[i] > vote_count[classified_label]) begin
                classified_label = i;
            end
        end
    end
endmodule

`timescale 1ns / 1ps

module knn_tb_24_022025_1230;
    // Parameters
    parameter DATA_WIDTH = 16;
    parameter IMG_WIDTH = 32;
    parameter IMG_HEIGHT = 32;
    parameter NUM_IMAGES = 250;
    parameter K = 3;

    // Clock signal
    logic clk;

    // New image data (flattened 1D array)
    logic [DATA_WIDTH-1:0] new_image [0:IMG_WIDTH*IMG_HEIGHT-1];

    // Classified label output
    logic [1:0] classified_label;

    // Instantiate the KNN_Classifier
    KNN_Classifier #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .NUM_IMAGES(NUM_IMAGES),
        .K(K)
    ) knn_inst (
        .clk(clk),
        .new_image(new_image),
        .classified_label(classified_label)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Initialize new image with test values
    initial begin
        // Example: Initialize the new image with a simple pattern or specific test values
        // Replace this with actual image data as needed
        for (int i = 0; i < IMG_WIDTH*IMG_HEIGHT; i++) begin
            new_image[i] = i % 256; // Example pattern
        end

        // Wait for a few clock cycles to allow processing
        #100;

        // Display the classified label
        $display("Classified Label: %0d", classified_label);

        // End simulation
        $finish;
    end
endmodule

