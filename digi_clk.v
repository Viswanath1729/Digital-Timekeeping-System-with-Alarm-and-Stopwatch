`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.12.2025 21:14:03
// Design Name: 
// Module Name: digi_clk
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module digital_clock_advanced (
    input CLK100MHZ,
    input CPU_RESET,     // Center Button
    input BTNU,          // Increment Hours / Start-Stop Stopwatch
    input BTND,          // Increment Minutes / Reset Stopwatch
    input [1:0] SW,      // Mode Select
    input [2:2] SW_VIEW, // SW[2] for HH:MM vs MM:SS view
    output [6:0] seg,
    output reg [3:0] an,
    output dp,
    output reg LED0 // LED0
);

    // --- 1. Clock Dividers ---
    wire clk_1hz, clk_100hz;
    parameter COUNT_MAX = 27'd49_999_999;
    reg [26:0] counter = 0;
    reg clk_1hz_reg = 0;

    always @(posedge CLK100MHZ or posedge CPU_RESET) begin
        if (CPU_RESET) begin
            counter <= 0;
            clk_1hz_reg <= 0;
        end else begin
            if (counter == COUNT_MAX) begin
                // This toggles every 100 million cycles (1 second period)
                counter <= 0;
                clk_1hz_reg <= ~clk_1hz_reg; 
            end else begin
                counter <= counter + 1;
            end
        end
    end

    assign clk_1hz = clk_1hz_reg; // 1 Hz square wave.
    
    parameter COUNT_MAX_2 = 27'd499_999;
    reg [26:0] counter_2 = 0;
    reg clk_100hz_reg = 0;

    always @(posedge CLK100MHZ or posedge CPU_RESET) begin
        if (CPU_RESET) begin
            counter_2 <= 0;
            clk_100hz_reg <= 0;
        end else begin
            if (counter_2 == COUNT_MAX_2) begin
                counter_2 <= 0;
                clk_100hz_reg <= ~clk_100hz_reg; 
            end else begin
                counter_2 <= counter_2 + 1;
            end
        end
    end

    assign clk_100hz = clk_100hz_reg; // 100 Hz square wave.

// --- 2. Button Debouncing and Edge Detection ---
    wire btnu_clean, btnd_clean;
    reg btnu_d, btnd_d;
    
    debouncer db_u (.clk(CLK100MHZ), .btn_in(BTNU), .btn_out(btnu_clean));
    debouncer db_d (.clk(CLK100MHZ), .btn_in(BTND), .btn_out(btnd_clean));

    always @(posedge CLK100MHZ) begin
        btnu_d <= btnu_clean;
        btnd_d <= btnd_clean;
    end
    
    wire btnu_pulse = btnu_clean & !btnu_d;
    wire btnd_pulse = btnd_clean & !btnd_d;
    
// --- 3. Internal Registers ---
    reg [3:0] s1, s10, m1, m10, h1, h10;       // Time
    reg [3:0] am1, am10, ah1, ah10;            // Alarm
    reg [3:0] sw_ms1, sw_ms10, sw_s1, sw_s10;  // Stopwatch
    reg sw_running = 0;
    reg [3:0] sw_m1, sw_m10;
    reg alarm_active;


    // --- 4. Main FSM / Control Logic ---
    reg tick_1hz_d, tick_100hz_d;
    reg ce_1hz,ce_100hz;
    always @(posedge CLK100MHZ or posedge CPU_RESET) begin

        if (CPU_RESET) begin
            {h10,h1,m10,m1,s10,s1} <= 0;
            {ah10,ah1,am10,am1}   <= 0;
            {sw_s10,sw_s1,sw_ms10,sw_ms1,sw_m1, sw_m10} <= 0;
            sw_running <= 0;
            LED0 <= 0;
        end else begin
            tick_1hz_d   <= clk_1hz;
            tick_100hz_d <= clk_100hz;
            ce_1hz   <= clk_1hz   & ~tick_1hz_d;
            ce_100hz <= clk_100hz & ~tick_100hz_d;
            // ---------------- CLOCK MODE ----------------
            if (ce_1hz) begin
                if (s1 == 9) begin
                    s1 <= 0;
                    if (s10 == 5) begin
                        s10 <= 0;
                        if (m1 == 9) begin
                            m1 <= 0;
                            if (m10 == 5) begin
                                m10 <= 0;
                                if (h10 == 2 && h1 == 3)
                                    {h10,h1} <= 0;
                                else if (h1 == 9) begin
                                    h1 <= 0;
                                    h10 <= h10 + 1;
                                end else
                                    h1 <= h1 + 1;
                            end else m10 <= m10 + 1;
                        end else m1 <= m1 + 1;
                    end else s10 <= s10 + 1;
                end else s1 <= s1 + 1;
            end

            // ---------------- SET TIME ----------------
            if (SW == 2'b01) begin
                if (btnu_pulse) begin
                    if (h10==2 && h1==3) {h10,h1} <= 0;
                    else if (h1==9) begin h1<=0; h10<=h10+1; end
                    else h1<=h1+1;
                end
                if (btnd_pulse) begin
                    if (m1==9) begin m1<=0; m10<=(m10==5)?0:m10+1; end
                    else m1<=m1+1;
                end
            end

            // ---------------- SET ALARM ----------------
            if (SW == 2'b10) begin
                if (btnu_pulse) begin
                    if (ah10==2 && ah1==3) {ah10,ah1}<=0;
                    else if (ah1==9) begin ah1<=0; ah10<=ah10+1; end
                    else ah1<=ah1+1;
                end
                if (btnd_pulse) begin
                    if (am1==9) begin am1<=0; am10<=(am10==5)?0:am10+1; end
                    else am1<=am1+1;
                end
            end

            // ---------------- STOPWATCH ----------------
            if (SW==2'b11) begin
                if (btnu_pulse) sw_running <= ~sw_running;
                if (btnd_pulse) {sw_m10,sw_m1,sw_s10,sw_s1,sw_ms10,sw_ms1} <= 0;
            end

            if (sw_running && ce_100hz) begin
                if (sw_ms1==9) begin
                    sw_ms1<=0;
                    if (sw_ms10==9) begin
                        sw_ms10<=0;
                        if (sw_s1==9) begin
                            sw_s1<=0;
                            if (sw_s10==5) begin
                                sw_s10<=0;
                                if (sw_m1==9) begin
                                    sw_m1<=0;
                                    sw_m10 <= (sw_m10==5)?0:sw_m10+1;
                                end else sw_m1<=sw_m1+1;
                            end else sw_s10<=sw_s10+1;
                        end else sw_s1<=sw_s1+1;
                    end else sw_ms10<=sw_ms10+1;
                end else sw_ms1<=sw_ms1+1;
            end


            // ---------------- ALARM ----------------
            if (ce_1hz &&
                h10==ah10 && h1==ah1 &&
                m10==am10 && m1==am1 &&
                s10==0 && s1==0)
                alarm_active <= 1'b1;

            if (btnu_pulse && SW==2'b00)
                alarm_active <= 1'b0;

            // -------- LED BLINK --------
            if (!alarm_active)
                LED0 <= 0;
            else if (ce_1hz)
                LED0 <= ~LED0;

        end
    end
    // --- 5. Display Multiplexer ---
    reg [3:0] d1, d10, d100, d1000;
    always @(*) begin
        case (SW)
            2'b00: {d1000, d100, d10, d1} = SW_VIEW ? {m10, m1, s10, s1} : {h10, h1, m10, m1};
            2'b01: {d1000, d100, d10, d1} = {h10, h1, m10, m1}; // Setting Time
            2'b10: {d1000, d100, d10, d1} = {ah10, ah1, am10, am1}; // Setting Alarm
            2'b11: begin
                if (SW_VIEW)
                    {d1000,d100,d10,d1} = {sw_m10,sw_m1,sw_s10,sw_s1};   // MM:SS
                else
                    {d1000,d100,d10,d1} = {sw_s10,sw_s1,sw_ms10,sw_ms1}; // SS:MS
            end
        endcase
    end
    reg [17:0] refresh_counter = 0;
    always @(posedge CLK100MHZ) refresh_counter <= refresh_counter + 1;
    reg [3:0] bcd_mux;

    always @(*) begin
        case (refresh_counter[17:16])
            2'b00: begin an = 4'b1110; bcd_mux = d1;    end
            2'b01: begin an = 4'b1101; bcd_mux = d10;   end
            2'b10: begin an = 4'b1011; bcd_mux = d100;  end
            2'b11: begin an = 4'b0111; bcd_mux = d1000; end
        endcase
    end

    assign dp = (refresh_counter[17:16] == 2'b10) ? (SW == 2'b11 ? 1'b0 : ~clk_1hz) : 1'b1;
    bcd_to_7seg decoder (.bcd(bcd_mux), .segment(seg));
endmodule
module bcd_to_7seg (
    input [3:0] bcd,
    output reg [6:0] segment  // segments a, b, c, d, e, f, g (segment[0] is 'a', segment[6] is 'g')
);
    // Assign segments based on the BCD input
    // The outputs are active-low (0 turns on the segment)
    always @(*) begin
        case (bcd)
            4'd0: segment = 7'b1000000; // 0
            4'd1: segment = 7'b1111001; // 1
            4'd2: segment = 7'b0100100; // 2
            4'd3: segment = 7'b0110000; // 3
            4'd4: segment = 7'b0011001; // 4
            4'd5: segment = 7'b0010010; // 5
            4'd6: segment = 7'b0000010; // 6
            4'd7: segment = 7'b1111000; // 7
            4'd8: segment = 7'b0000000; // 8
            4'd9: segment = 7'b0010000; // 9
            default: segment = 7'b1111111; // Off or Error (all segments off)
        endcase
    end
endmodule

module debouncer (
    input clk, btn_in, output reg btn_out
);
    reg [19:0] count = 0;
    reg btn_sync_0, btn_sync_1;
    always @(posedge clk) begin
        btn_sync_0 <= btn_in;
        btn_sync_1 <= btn_sync_0;
        if (btn_sync_1 == btn_out) count <= 0;
        else begin
            count <= count + 1;
            if (count == 20'd1_000_000) btn_out <= btn_sync_1;
        end
    end
endmodule