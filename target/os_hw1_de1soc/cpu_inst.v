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

	cpu u0 (
		 .clk_clk                                    (clk),                                  // clk.clk
		 .reset_reset_n                              (reset),                               // reset.reset_n (active low if needed)
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
endmodule
