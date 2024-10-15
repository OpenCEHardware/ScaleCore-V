module cpu_inst(
    input clk, reset,
    input [1:0] switcher,
    input [2:0] keys,
    output [6:0] minutesDisplay0,
    output [6:0] minutesDisplay1,
    output [6:0] hoursDisplay0,
    output [6:0] hoursDisplay1,
    output buzzer
);

	reg clean_reset, last, reset_meta, reset_sync;

	// 671ms para reloj de 50MHz
	reg[24:0] clean_for;

	cpu u0 (
		 .clk_clk                                    (clk),                                  // clk.clk
		 .reset_reset_n                              (clean_reset),                          // reset.reset_n (active low if needed)
		 .pio_switches_external_connection_export    (switcher),                             // pio_switches_external_connection.export
		 .pio_key_0_external_connection_export       (keys[0]),                              // pio_key_0_external_connection.export
		 .pio_key_1_external_connection_export       (keys[1]),                              // pio_key_1_external_connection.export
		 .pio_key_2_external_connection_export       (keys[2]),								        //       pio_key_2_external_connection.export
		 .leds_minutes_ls_external_connection_export (minutesDisplay0),                      // leds_minutes_ls_external_connection.export
		 .leds_minutes_ms_external_connection_export (minutesDisplay1),                      // leds_minutes_ms_external_connection.export
		 .leds_hours_ls_external_connection_export   (hoursDisplay0),                        // leds_hours_ls_external_connection.export
		 .leds_hours_ms_external_connection_export   (hoursDisplay1),                        // leds_hours_ms_external_connection.export
		 .pio_buzzer_external_connection_export      (buzzer)                                // pio_buzzer_external_connection.export
	);

	always @(posedge clk) begin
		reset_meta <= reset;
		reset_sync <= reset_meta;

		last <= reset_sync;
		clean_for <= last == reset_sync ? clean_for + 1 : 0;

		if(&clean_for)
			clean_reset <= last;
	end

	initial begin
		last = 0;
		clean_for = 0;
		clean_reset = 0;
	end

endmodule
