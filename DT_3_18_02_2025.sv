module decision_tree_parallel_18_02_25 #(
    parameter int N = 8  // Number of parallel images
) (
    input  logic clk, rst,
    input  logic [7:0] r[N-1:0], g[N-1:0], b[N-1:0],
    output logic class_out[N-1:0]
);

    // Internal signals
    logic [5:0] quantized_pixel[N-1:0];
    logic [15:0] histogram[N-1:0][0:63];
    logic [15:0] test_bin_42[N-1:0], test_bin_59[N-1:0];
    logic [15:0] trained_bin_42, trained_bin_59;
    logic [N-1:0][31:0] dt_features; // Features for decision tree engine
    logic [N-1:0] dt_class_out;      // Decision tree classification outputs

    // Stage 1: Image Quantization
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            quantized_pixel <= '{default:0};
        else
            for (int i = 0; i < N; i++)
                quantized_pixel[i] <= {r[i][7:6], g[i][7:6], b[i][7:6]};
    end

    // Stage 2: Histogram Computation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < N; i++)
                for (int j = 0; j < 64; j++)
                    histogram[i][j] <= 0;
        end else begin
            for (int i = 0; i < N; i++)
                histogram[i][quantized_pixel[i]] <= histogram[i][quantized_pixel[i]] + 1;
        end
    end

    // Stage 3: Load Pretrained Histogram Values
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            trained_bin_42 <= 57230;
            trained_bin_59 <= 57230;
        end
    end

    // Stage 4: Extract Test Image Histogram Values
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            test_bin_42 <= '{default:0};
            test_bin_59 <= '{default:0};
        end else begin
            for (int i = 0; i < N; i++) begin
                test_bin_42[i] <= histogram[i][42];
                test_bin_59[i] <= histogram[i][59];
            end
        end
    end

    // Stage 5: Prepare Features for Decision Tree Engine
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            dt_features <= '{default:0};
        else
            for (int i = 0; i < N; i++)
                dt_features[i] <= {test_bin_42[i], test_bin_59[i]};
    end

    // Instantiate Decision Tree Engine for each image
    generate
        for (genvar i = 0; i < N; i++) begin : dt_engine_instances
            DTEngine dt_inst (
                .clk(clk),
                .rst(rst),
                .features(dt_features[i]),
                .class_out(dt_class_out[i])
            );
        end
    endgenerate

    // Stage 6: Collect Classification Outputs
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            class_out <= '{default:0};
        else
            class_out <= dt_class_out;
    end

endmodule

