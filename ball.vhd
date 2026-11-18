library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity ball is
    port (
        clk : in std_logic;
        new_frame : in std_logic;
        h_count : in natural range 0 to h_total - 1;
        v_count : in natural range 0 to v_total - 1;
        left_pos : in natural range 0 to v_active - v_paddle - 1;
        right_pos : in natural range 0 to v_active - v_paddle - 1;
        ball : out std_logic;
        goal_ball : out std_logic
    );
end ball;

architecture Behavioral of ball is
    constant left_face : integer := left_paddle_x + h_paddle;
    constant right_face : integer := right_paddle_x - ball_size;
    constant left_back : integer := left_paddle_x - ball_size;
    constant right_back : integer := right_paddle_x + h_paddle;
    constant bottom_limit : integer := court_bottom - ball_size;

    signal x : integer range -ball_size to h_active := 320;
    signal y : integer range court_top to bottom_limit := 150;
    signal dx : integer range -ball_step to ball_step := ball_step;
    signal dy : integer range -ball_step to ball_step := ball_step;
    signal exiting : boolean := false;

    function overlaps(a, a_size, b, b_size : integer) return boolean is
    begin
        return a < b + b_size and b < a + a_size;
    end function;

    procedure bounce_off_end(paddle_y, old_y : in integer;
                            next_y, next_dy : inout integer) is
    begin
        -- Allow for a paddle that just moved one step into the ball's edge.
        if next_dy > 0 and old_y + ball_size <= paddle_y + paddle_step
            and next_y + ball_size > paddle_y then
            next_y := paddle_y - ball_size;
            next_dy := -ball_step;
        elsif next_dy < 0 and old_y >= paddle_y + v_paddle - paddle_step
            and next_y < paddle_y + v_paddle then
            next_y := paddle_y + v_paddle;
            next_dy := ball_step;
        end if;
    end procedure;
begin
    process(clk)
        variable next_x, next_y, next_dx, next_dy : integer;
    begin
        if rising_edge(clk) and new_frame = '1' then
            next_x := x + dx;
            if exiting then
                -- Roll through the gate until the ball is entirely offscreen.
                if x = -ball_size or x = h_active then
                    x <= (h_active - ball_size) / 2;
                    y <= (v_active - ball_size) / 2;
                    dx <= -dx;
                    if dx < 0 then
                        dy <= ball_step;
                    else
                        dy <= -ball_step;
                    end if;
                    exiting <= false;
                elsif next_x < -ball_size then
                    x <= -ball_size;
                elsif next_x > h_active then
                    x <= h_active;
                else
                    x <= next_x;
                end if;
            else
                next_y := y + dy;
                next_dx := dx;
                next_dy := dy;

                -- Resolve horizontal movement first, then the paddle ends.
                if dx < 0 and x >= left_face and next_x <= left_face
                    and overlaps(y, ball_size, left_pos, v_paddle) then
                    next_x := left_face;
                    next_dx := ball_step;
                elsif dx > 0 and x <= right_face and next_x >= right_face
                    and overlaps(y, ball_size, right_pos, v_paddle) then
                    next_x := right_face;
                    next_dx := -ball_step;
                elsif dx > 0 and x <= left_back and next_x >= left_back
                    and overlaps(y, ball_size, left_pos, v_paddle) then
                    next_x := left_back;
                    next_dx := -ball_step;
                elsif dx < 0 and x >= right_back and next_x <= right_back
                    and overlaps(y, ball_size, right_pos, v_paddle) then
                    next_x := right_back;
                    next_dx := ball_step;
                end if;

                if overlaps(next_x, ball_size, left_paddle_x, h_paddle) then
                    bounce_off_end(left_pos, y, next_y, next_dy);
                elsif overlaps(next_x, ball_size, right_paddle_x, h_paddle) then
                    bounce_off_end(right_pos, y, next_y, next_dy);
                end if;

                if next_y <= court_top then
                    next_y := court_top;
                    next_dy := ball_step;
                elsif next_y >= bottom_limit then
                    next_y := bottom_limit;
                    next_dy := -ball_step;
                end if;

                -- A moving paddle can close the gap against the top or bottom wall.
                -- If the ball is still inside the paddle, push it back into the court.
                if overlaps(next_x, ball_size, left_paddle_x, h_paddle)
                    and overlaps(next_y, ball_size, left_pos, v_paddle) then
                    next_x := left_face;
                    next_dx := ball_step;
                elsif overlaps(next_x, ball_size, right_paddle_x, h_paddle)
                    and overlaps(next_y, ball_size, right_pos, v_paddle) then
                    next_x := right_face;
                    next_dx := -ball_step;
                end if;

                if next_x < court_left or next_x + ball_size > court_right then
                    if next_y >= goal_top and next_y + ball_size <= goal_bottom then
                        -- Keep the ball within the opening while it exits.
                        exiting <= true;
                    elsif next_x < court_left then
                        next_x := court_left;
                        next_dx := ball_step;
                    else
                        next_x := court_right - ball_size;
                        next_dx := -ball_step;
                    end if;
                end if;

                x <= next_x;
                y <= next_y;
                dx <= next_dx;
                dy <= next_dy;
            end if;
        end if;
    end process;

    ball <= '1' when h_count < h_active and h_count >= x and h_count < x + ball_size
                     and v_count >= y and v_count < y + ball_size else '0';
    goal_ball <= '1' when exiting else '0';
end Behavioral;
