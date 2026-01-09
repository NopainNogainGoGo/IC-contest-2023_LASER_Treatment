module LASER (
    input CLK,
    input RST,
    input  [3:0] X,
    input  [3:0] Y,
    output reg [3:0] C1X,
    output reg [3:0] C1Y,
    output reg [3:0] C2X,
    output reg [3:0] C2Y,
    output reg DONE
);

reg [2:0] current_state, next_state;
localparam READ     = 3'd0;
localparam FIND_C1  = 3'd1;
localparam FIND_C2  = 3'd2;
localparam CHECK    = 3'd3; 
localparam FINISH   = 3'd4;

reg last_find_state;
localparam FROM_C1 = 1'b0;
localparam FROM_C2 = 1'b1;

reg  [5:0] cnt_input;
wire cnt_done = (cnt_input == 6'd39);

reg [3:0] mem_x [0:39];
reg [3:0] mem_y [0:39];

wire [3:0] current_x = mem_x[cnt_input];
wire [3:0] current_y = mem_y[cnt_input];

reg [3:0] scan_x, scan_y;
wire scan_done_row = (scan_x == 4'd15);
wire scan_done_all = (scan_y == 4'd15 && scan_x == 4'd15);  
wire [7:0] coord = {scan_y, scan_x};

reg [3:0] abs_x, abs_y;
reg [8:0] dist_sq;
wire is_inside_scan;

reg [7:0] coordinate1;
reg [7:0] coordinate2;
reg [7:0] best_coord_temp;

wire [3:0] fixed_x = (current_state == FIND_C1) ? coordinate2[3:0] : coordinate1[3:0];
wire [3:0] fixed_y = (current_state == FIND_C1) ? coordinate2[7:4] : coordinate1[7:4];
reg [3:0] dist_x_fixed, dist_y_fixed;
reg [8:0] dist_sq_fixed;
wire is_in_fixed;

reg [5:0] union_sum;
// 新增：組合邏輯計算下一個 union_sum
wire [5:0] union_sum_next;
reg [5:0] best_union_sum;
reg [5:0] prev_best_union_sum;
reg change_update; 

// Current state
always @(posedge CLK) begin
    if (RST)
        current_state <= READ;
    else
        current_state <= next_state;
end

// Next state
always @(*) begin
    case (current_state)
        READ:    next_state = cnt_done ? FIND_C1 : READ;
        
        FIND_C1: begin
            if (scan_done_all && cnt_done)
                next_state = CHECK;
            else
                next_state = FIND_C1;
        end
        
        FIND_C2: begin
            if (scan_done_all && cnt_done)
                next_state = CHECK;
            else
                next_state = FIND_C2;
        end

        CHECK: begin
            if (change_update) begin
                if (last_find_state == FROM_C1)
                    next_state = FIND_C2;
                else
                    next_state = FIND_C1;
            end else
                next_state = FINISH;
        end
        
        FINISH:  next_state = READ;
        default: next_state = READ;
    endcase
end

always @(posedge CLK) begin
    if (RST) 
        change_update <= 0;
    else if ((current_state == FIND_C1 || current_state == FIND_C2) && 
             (scan_x == 0 && scan_y == 0 && cnt_input == 0)) begin
        change_update <= 0;
    // 修改：使用 union_sum_next 來比較
    end else if ((current_state == FIND_C1 || current_state == FIND_C2) && 
        cnt_done && (union_sum_next > prev_best_union_sum)) begin
        change_update <= 1;
    end
end

always @(posedge CLK) begin
    if (RST)
        last_find_state <= FROM_C1;
    else if (current_state == FIND_C1 && next_state == CHECK)
        last_find_state <= FROM_C1;
    else if (current_state == FIND_C2 && next_state == CHECK)
        last_find_state <= FROM_C2;
end

always @(posedge CLK) begin
    if (RST) begin
        for (int i=0; i<40; i=i+1) begin
            mem_x[i] <= 0;
            mem_y[i] <= 0;      
        end
    end else if (current_state == READ) begin
        mem_x[cnt_input] <= X;
        mem_y[cnt_input] <= Y;
    end
end

always @(posedge CLK) begin
    if (RST)
        cnt_input <= 0;
    else if (current_state == READ || current_state == FIND_C1 || current_state == FIND_C2) begin
        if (cnt_done)
            cnt_input <= 0;
        else
            cnt_input <= cnt_input + 1;
    end else
        cnt_input <= 0;
end

always @(posedge CLK) begin
    if (RST) begin
        scan_x <= 0;
        scan_y <= 0;
    end else if (current_state == FIND_C1 || current_state == FIND_C2) begin 
        if (scan_done_all && cnt_done) begin  
            scan_x <= 0;
            scan_y <= 0;
        end else if (scan_done_row && cnt_done) begin
            scan_x <= 0;
            scan_y <= scan_y + 1;
        end else if (cnt_done)
            scan_x <= scan_x + 1;
    end else if (current_state == CHECK) begin
        scan_x <= 0;
        scan_y <= 0;
    end
end

always @(*) begin
    abs_x = (current_x > scan_x) ? (current_x - scan_x) : (scan_x - current_x);
    abs_y = (current_y > scan_y) ? (current_y - scan_y) : (scan_y - current_y);
    dist_sq = abs_x * abs_x + abs_y * abs_y;
end
assign is_inside_scan = (dist_sq <= 9'd16);

always @(*) begin
    dist_x_fixed = (current_x > fixed_x) ? (current_x - fixed_x) : (fixed_x - current_x);
    dist_y_fixed = (current_y > fixed_y) ? (current_y - fixed_y) : (fixed_y - current_y);
    dist_sq_fixed = dist_x_fixed * dist_x_fixed + dist_y_fixed * dist_y_fixed;
end
assign is_in_fixed = (dist_sq_fixed <= 9'd16);

// 組合邏輯：計算加上當前點後的總和
wire valid = (is_inside_scan || is_in_fixed);
assign union_sum_next = union_sum + valid;

// union_sum 更新邏輯
always @(posedge CLK) begin
    if (RST)
        union_sum <= 0;
    else if (current_state == FIND_C1 || current_state == FIND_C2) begin
        if (cnt_done) 
            union_sum <= 0;
        else
            union_sum <= union_sum_next;  // 重要!! 使用組合邏輯計算的值 計算交給comb，之後再存進seq
    end else
        union_sum <= 0;
end

// 修改：使用 union_sum_next 來比較
always @(posedge CLK) begin
    if (RST) begin
        best_union_sum <= 0;
        best_coord_temp <= 0;
    end else if (current_state == FIND_C1 || current_state == FIND_C2) begin
        if (scan_x == 0 && scan_y == 0 && cnt_input == 0) begin
            best_union_sum <= 0;
            best_coord_temp <= 0;
        end else if (cnt_done && (union_sum_next > best_union_sum)) begin
            best_union_sum <= union_sum_next;
            best_coord_temp <= coord;
        end
    end
end

// 修改後的座標更新與 change 判定邏輯
always @(posedge CLK) begin
    if (RST) begin
        coordinate1 <= 8'h00; 
        coordinate2 <= 8'h00;
        prev_best_union_sum <= 0;
    end else if (current_state == CHECK) begin
        if (last_find_state == FROM_C1) begin
            // 只要現在找到的最佳座標(best_coord_temp)跟原本的不一樣，就繼續優化
            if (best_coord_temp != coordinate1) begin
                coordinate1 <= best_coord_temp;
                prev_best_union_sum <= best_union_sum;
            end
        end else begin
            if (best_coord_temp != coordinate2) begin
                coordinate2 <= best_coord_temp;
                prev_best_union_sum <= best_union_sum;
            end
        end
    end
end

always @(posedge CLK) begin
    if (RST) begin
        C1X <= 0; C1Y <= 0;
        C2X <= 0; C2Y <= 0;
    end else if (current_state == FINISH) begin
        C1X <= coordinate1[3:0];
        C1Y <= coordinate1[7:4];
        C2X <= coordinate2[3:0];
        C2Y <= coordinate2[7:4];
    end
end

always @(posedge CLK) begin
    if (RST)
        DONE <= 0;
    else if (current_state == FINISH)
        DONE <= 1;
    else
        DONE <= 0;
end

endmodule

/*
致命錯誤：第 40 個點被遺漏 (The 40th Point Bug)
在 Verilog 中，always @(posedge CLK) 是在時脈邊緣觸發更新。 當 cnt_input == 39 (cnt_done 為 high) 時：
union_sum 暫存器裡面存放的是 第 0 到 第 38 個點 的加總（共39個點）。
第 39 個點（最後一個點）的 valid 訊號雖然已經算出來了，但還沒加進 union_sum。
你的程式碼在 cnt_done 時直接拿 union_sum (0~38的合) 去跟 best_union_sum 比較。
結果：每個座標掃描時，都少算了最後一個點。

計算要用comb，再存進reg

使用組合邏輯 union_sum_next = union_sum + valid 來預先計算「加上當前點後」的總和。
當 cnt_input == 39 時：
- valid 是第39個點的有效性
- union_sum = sum(0~38)
- union_sum_next = sum(0~38) + valid[39] = sum(0~39) ← 完整的40個點！
在同一個時脈週期內：
- 用 union_sum_next 來做比較（包含所有40個點）
- 在下個週期才更新 union_sum ← 保持原有的累加邏輯
這樣既解決了「第40個點遺漏」的問題，又不會因為延遲造成重複計算第0個點。


pattern 2 3 6都差一點...
*/

