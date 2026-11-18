# COE758 FPGA Pong

This project implements a two-player Pong game (Simple Video Game Processor) in VHDL for a Xilinx Spartan-3E FPGA (`xc3s500e-5fg320`) using Xilinx ISE 13. It drives a 640x480 @ 60 Hz VGA display through a 24-bit RGB video DAC and reads player input from four on-board slide switches.

The FPGA top-level entity is `top_level` (`top_level.vhd`). It divides the 50 MHz system oscillator (`clk_50`) down to a 25 MHz VGA pixel clock (`clk_25`), paces game physics at 60 Hz via a single-cycle end-of-frame strobe, and integrates Xilinx ChipScope `ICON` and `ILA` cores for hardware debugging.

![Two-player Pong running on the Spartan-3E FPGA over 640x480 VGA](docs/hardware_demo.jpg)

*Live 640x480 @ 60 Hz VGA output captured on an LG Flatron L1530S monitor during a 4–0 match.*

## 1. Architecture and module breakdown

- **`constants.vhd`**: Defines VGA timing parameters—horizontal (`640` active, `16` front porch, `96` sync pulse, `48` back porch = `800` total) and vertical (`480` active, `10` front porch, `2` sync pulse, `33` back porch = `525` total)—along with court wall boundaries (`wall_inset = 21`, playable court `x = 30..611`, `y = 30..451`, goal gates `y = 151..350`), paddle geometry (`15x100` px, `paddle_step = 2` px/frame), and ball geometry (`10x10` px, `ball_step = 2` px/frame).
- **`clock_divider_2.vhd`**: Divides the 50 MHz system clock (`clk_50`) by 2 using a toggling flip-flop (`clk_25_s`) to generate the 25 MHz VGA pixel clock (`clk_25`).
- **`count_gen.vhd`**: Counts horizontal pixels (`0..799`) and vertical lines (`0..524`) on each rising edge of `clk_25`, emitting a single-cycle `new_frame` strobe at `(799, 524)` to pace game logic at 60 Hz.
- **`sync_gen.vhd`**: Generates registered active-low `h_sync` (`656 <= h_count < 752`) and `v_sync` (`490 <= v_count < 492`) signals on the same clock edge as the registered RGB output.
- **`paddle.vhd`**: Synchronizes the four slide switches through a 2-stage `ASYNC_REG` flip-flop chain (`switches_meta`, `switches_sync`), debounces them over two consecutive frames (`controls = previous`), updates `left_y` and `right_y` by `±2` px/frame within `[30, 349]`, and outputs active pixel masks `left_paddle` and `right_paddle`.
- **`ball.vhd`**: Updates ball position and velocity on `ball_new_frame_s` (delayed by 1 clock cycle after `new_frame` in `top_level.vhd` so paddles update before collision checks). Reflects off paddle front/back faces and top/bottom ends (`bounce_off_end`), includes a pinch guard when a moving paddle traps the ball against a top or bottom wall, bounces off top/bottom/side walls, enters `exiting` mode (`goal_ball = '1'`) when passing through a goal (`151 <= y` and `y + 10 <= 350`) until completely offscreen (`x = -10` or `x = 640`), and respawns at the center (`x = 315, y = 235`).
- **`VGA.vhd`**: Implements a 9-layer priority RGB multiplexer and a 7-segment scoreboard (`draw_digit`, `20x36` px digits at `x = 280..299` and `340..359`, `y = 45..80`) that increments once per goal using `goal_seen_in_frame` and `goal_scored_locked` and resets to `0-0` after reaching `9`.
- **`top_level.vhd` & `mapping.ucf`**: Integrates all RTL modules, connects ChipScope `ICON` and `ILA` debug probes (`ila_data`, `trig0`), and constrains all Spartan-3E FPGA pins and clock domains (`TS_board_clock` at 50 MHz and `TS_pixel_clock` at 25 MHz).

## 2. Set up ISE and ChipScope

Use the FPGA part, package, speed grade, and oscillator pin details printed on your board or listed in its manual.

1. Create a VHDL project in Xilinx ISE 13 targeting `xc3s500e-5fg320`.
2. Add all RTL source files (`constants.vhd`, `clock_divider_2.vhd`, `count_gen.vhd`, `sync_gen.vhd`, `paddle.vhd`, `ball.vhd`, `VGA.vhd`, and `top_level.vhd`) and `mapping.ucf` to the project.
3. Generate the ChipScope `ICON` and `ILA` cores matching the `ila_data` and `trig0` port widths wired in `top_level.vhd`, and place their generated `.ngc` files in the project directory (or comment out the ChipScope instances if building without debug cores).
4. Verify the pin assignments and clock constraints in `mapping.ucf`:

| Signal | Direction | Pin | Role / Constraint |
| --- | --- | --- | --- |
| `clk_50` | Input | Board oscillator | 50 MHz system clock (`TS_board_clock`) |
| `clk_25` | Output | `A4` | 25 MHz VGA DAC pixel clock (`TS_pixel_clock`) |
| `h_sync` | Output | `C5` | Active-low horizontal sync (`656 <= h_count < 752`) |
| `v_sync` | Output | `D5` | Active-low vertical sync (`490 <= v_count < 492`) |
| `Rout<7:0>`, `Gout<7:0>`, `Bout<7:0>` | Output | Video DAC pins | 24-bit registered RGB pixel bus |
| `left_up` | Input | `H18` | Left paddle up slide switch |
| `left_down` | Input | `N17` | Left paddle down slide switch |
| `right_up` | Input | `L13` | Right paddle up slide switch |
| `right_down` | Input | `L14` | Right paddle down slide switch |

5. Run **Synthesize - XST**, **Implement Design** (Translate, Map, Place & Route), and **Generate Programming File**.
6. Inspect the synthesis, MAP, and static timing reports to confirm that the design fits within the Spartan-3E slice budget and that both `TS_board_clock` (50 MHz) and `TS_pixel_clock` (25 MHz) meet timing with zero violations.
7. Program `top_level.bit` onto the Spartan-3E FPGA using **iMPACT**.

## 3. Run the board demo

1. Save the hardware photo to `docs/hardware_demo.jpg` in your repository so the embedded image renders on GitHub.
2. Connect a 640x480-capable VGA monitor to the board's VGA port and power on the FPGA.
3. Set all four slide switches (`H18`, `N17`, `L13`, `L14`) to `0` (`OFF`) so both paddles remain stationary on startup.
4. Slide `H18` (`left_up`) or `N17` (`left_down`) to `1` to move the left cyan paddle (`±2` px/frame within `y = 30..349`).
5. Slide `L13` (`right_up`) or `L14` (`right_down`) to `1` to move the right amber paddle (`±2` px/frame within `y = 30..349`).
6. *(Optional)* Open **ChipScope Analyzer**, arm the `ILA` on `trig0`, and capture frame-level state transitions (`ila_data`) during paddle collisions or goal events.

## 4. Show the TA

Demonstrate the rendering layers, collision physics, and scoreboard state machine on the VGA monitor:

| Test Case | Stimulus / Condition | Expected Result |
| --- | --- | --- |
| **Display & Court Layout** | Board powered on, idle switches | Stable 640x480 @ 60 Hz VGA frame with slate walls (`wall_inset = 21`), goal openings (`y = 151..350`), dashed center line, and `0-0` score |
| **Paddle Control & Clamping** | Hold `H18`/`N17` or `L13`/`L14` high | Debounced over 2 frames; paddle moves at `2` px/frame and stops cleanly at `y = 30` and `y = 349` |
| **Paddle Bounce & Pinch Guard** | Strike ball with paddle face, end, or near top/bottom wall | Reverses horizontal velocity on front/back hit, reverses vertical velocity on `bounce_off_end`, and prevents wall trapping via pinch guard |
| **Goal Detection & Exit** | Ball enters left or right gate (`151 <= y` and `y + 10 <= 350`) | Enters `exiting` mode (`goal_ball = '1'`), turns red (`#FF5260`) until `x = -10` or `x = 640`, then respawns at `(315, 235)` |
| **Scoreboard & Rollover** | Score multiple goals up to `9` | Increments once per goal (`goal_seen_in_frame` / `goal_scored_locked`) on `20x36` 7-segment digits (`x = 280..299`, `340..359`, `y = 45..80`); resets to `0-0` after `9` |

### VGA RGB Priority Multiplexer (`VGA.vhd`)

| Priority | Layer | Hex Color | Dimensions / Region |
| --- | --- | --- | --- |
| 1 | VGA Blanking | `#000000` | Outside `640x480` active video |
| 2 | Goal Ball (`goal_ball = '1'`) | `#FF5260` (Red) | `10x10` px exiting through goal gate |
| 3 | Active Ball | `#FFF6E2` (Cream) | `10x10` px inside court |
| 4 | Left Paddle | `#42D9F2` (Cyan) | `15x100` px (`y = 30..349`) |
| 5 | Right Paddle | `#FFC46B` (Amber) | `15x100` px (`y = 30..349`) |
| 6 | 7-Segment Score Digits | Paddle colors / foreground | `20x36` px at `x = 280..299` & `340..359`, `y = 45..80` |
| 7 | Court Walls | `#839AB6` (Slate) | Border around `x = 30..611`, `y = 30..451` (open at `y = 151..350`) |
| 8 | Dashed Center Line | `#40536D` (Muted Blue) | Vertical centerline divider |
| 9 | Playable Court / Margin | `#121D30` / `#090F1C` | Inner court (`#121D30`) and outer margin (`#090F1C`) |

Bring the ISE utilization and static timing reports (`TS_board_clock` and `TS_pixel_clock`), the RTL block diagram, and any saved ChipScope `ILA` captures to the demo.

## What has been checked

- Complete RTL synthesis, MAP, Place & Route, and bitstream generation in Xilinx ISE 13 targeting `xc3s500e-5fg320`.
- Physical hardware execution on the Spartan-3E board driving a 640x480 @ 60 Hz VGA monitor, verifying two-player paddle debouncing, ball reflections, goal exit transitions, and 7-segment score increments.
- ChipScope `ICON` and `ILA` debug cores (`ila_data`, `trig0`) wired in `top_level.vhd` for on-chip waveform capture.

## Files and references

- `constants.vhd` — VGA timing, court boundaries, paddle/ball geometry, and step constants
- `clock_divider_2.vhd` — 50 MHz to 25 MHz pixel clock divider
- `count_gen.vhd` & `sync_gen.vhd` — 800x525 pixel/line counters, `new_frame` strobe, and registered `h_sync`/`v_sync`
- `paddle.vhd` & `ball.vhd` — Switch synchronizer/debouncer, paddle clamping, collision detection, pinch guard, and goal state machine
- `VGA.vhd` — 9-layer priority RGB multiplexer and 7-segment score renderer
- `top_level.vhd` & `mapping.ucf` — Top-level structural integration, ChipScope `ICON`/`ILA` wiring, and Spartan-3E pin/clock constraints
- `docs/hardware_demo.jpg` — Hardware verification capture on a 640x480 VGA monitor

## Contributors and attribution

Developed for **COE758 (Digital Systems Engineering)** at Toronto Metropolitan University (formerly Ryerson University). Generated Xilinx ChipScope `.ngc` IP cores and ISE build artifacts are excluded from version control.
