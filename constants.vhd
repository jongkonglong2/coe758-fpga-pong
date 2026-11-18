library IEEE;
use IEEE.STD_LOGIC_1164.all;

package constants is
--VGA parameters
constant h_total        : integer := 800;
constant h_frontPorch   : integer := 16;
constant h_syncPulse    : integer := 96;
constant h_backPorch    : integer := 48;
constant h_active       : integer := 640;

constant v_total        : integer := 525;
constant v_frontPorch   : integer := 10;
constant v_syncPulse    : integer := 2;
constant v_backPorch    : integer := 33;
constant v_active       : integer := 480;

constant h_sync1     : integer := h_active+h_frontPorch;
constant h_sync2     : integer := h_active+h_frontPorch+h_syncPulse;

constant v_sync1     : integer := v_active+v_frontPorch;
constant v_sync2     : integer := v_active+v_frontPorch+v_syncPulse;

--Objects
constant edge_size : integer := 10;
constant ball_size : integer := 10;

constant h_paddle : integer := 15;
constant v_paddle : integer := 100;

-- The original drawn border starts at pixel 21 and is nine pixels thick.
constant wall_inset   : integer := 21;
constant court_left   : integer := wall_inset + edge_size - 1;
constant court_right  : integer := h_active - court_left + 1;
constant court_top    : integer := court_left;
constant court_bottom : integer := v_active - court_top + 1;
constant goal_top     : integer := 151;
constant goal_bottom  : integer := 350; -- Exclusive.

constant paddle_wall_gap : integer := 12;
constant left_paddle_x   : integer := court_left + paddle_wall_gap;
constant right_paddle_x  : integer := court_right - paddle_wall_gap - h_paddle;
constant paddle_step    : integer := 2;
constant paddle_min_y   : integer := court_top;
constant paddle_max_y   : integer := v_active - v_paddle - court_top - paddle_step;
constant ball_step      : integer := 2;

end constants;

package body constants is
 
end constants;
