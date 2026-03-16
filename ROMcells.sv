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
        $readmemh("D:\FPGA PROJECT\hex_files_for_CNN\hex_files.mem", rom);  // Load all images in a single file
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

