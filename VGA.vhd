library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity VGA is
    port (
        clk : in std_logic;
        h_count : in natural range 0 to h_total - 1;
        v_count : in natural range 0 to v_total - 1;
        ball : in std_logic;
        goal_ball : in std_logic;
        left_paddle : in std_logic;
        right_paddle : in std_logic;
        Rout : out std_logic_vector(7 downto 0);
        Gout : out std_logic_vector(7 downto 0);
        Bout : out std_logic_vector(7 downto 0)
    );
end VGA;

architecture Behavioral of VGA is
    subtype rgb is std_logic_vector(23 downto 0);
    constant margin : rgb := x"090F1C";
    constant court : rgb := x"121D30";
    constant wall : rgb := x"839AB6";
    constant center_mark : rgb := x"40536D";
    constant left_color : rgb := x"42D9F2";
    constant right_color : rgb := x"FFC46B";
    constant ball_color : rgb := x"FFF6E2";
    constant goal_color : rgb := x"FF5260";

    signal left_score  : natural range 0 to 9 := 0;
    signal right_score : natural range 0 to 9 := 0;
    signal goal_seen_in_frame : std_logic := '0';
    signal goal_scored_locked : std_logic := '0';

    -- 20x36 pixel 7-segment digit renderer
    function draw_digit(digit : natural; dx : natural; dy : natural) return boolean is
        variable segs : std_logic_vector(6 downto 0); -- abcdefg
        variable on_seg : boolean;
    begin
        on_seg := false;
        case digit is
            when 0 => segs := "1111110";
            when 1 => segs := "0110000";
            when 2 => segs := "1101101";
            when 3 => segs := "1111001";
            when 4 => segs := "0110011";
            when 5 => segs := "1011011";
            when 6 => segs := "1011111";
            when 7 => segs := "1110000";
            when 8 => segs := "1111111";
            when 9 => segs := "1111011";
            when others => segs := "0000000";
        end case;

        if segs(6) = '1' and dy < 4 then
            on_seg := true;
        elsif segs(5) = '1' and dx >= 16 and dy < 20 then
            on_seg := true;
        elsif segs(4) = '1' and dx >= 16 and dy >= 16 then
            on_seg := true;
        elsif segs(3) = '1' and dy >= 32 then
            on_seg := true;
        elsif segs(2) = '1' and dx < 4 and dy >= 16 then
            on_seg := true;
        elsif segs(1) = '1' and dx < 4 and dy < 20 then
            on_seg := true;
        elsif segs(0) = '1' and dy >= 16 and dy < 20 then
            on_seg := true;
        end if;

        return on_seg;
    end function;

begin
    process(clk)
        variable pixel : rgb;
        variable inside_border, on_wall, on_left_score, on_right_score : boolean;
        variable dash_row : natural range 0 to 31;
    begin
        if rising_edge(clk) then
            -- Score tracking: increment once per goal event, reset when either player hits 9
            if h_count = 0 and v_count = 0 then
                if goal_seen_in_frame = '0' then
                    goal_scored_locked <= '0';
                end if;
                goal_seen_in_frame <= '0';
            elsif ball = '1' and goal_ball = '1' then
                goal_seen_in_frame <= '1';
                if goal_scored_locked = '0' then
                    goal_scored_locked <= '1';
                    if h_count < h_active / 2 then
                        -- Ball in left goal: right player scores
                        if right_score = 9 then
                            left_score <= 0;
                            right_score <= 0;
                        else
                            right_score <= right_score + 1;
                        end if;
                    else
                        -- Ball in right goal: left player scores
                        if left_score = 9 then
                            left_score <= 0;
                            right_score <= 0;
                        else
                            left_score <= left_score + 1;
                        end if;
                    end if;
                end if;
            end if;

            inside_border := h_count >= wall_inset and h_count <= h_active - wall_inset
                         and v_count >= wall_inset and v_count <= v_active - wall_inset;
            on_wall := inside_border and (
                v_count < court_top or v_count >= court_bottom
                or ((h_count < court_left or h_count >= court_right)
                    and (v_count < goal_top or v_count >= goal_bottom)));
            dash_row := v_count mod 32;

            -- Score bounding boxes straddling the center line near the top/middle
            on_left_score := false;
            on_right_score := false;
            if v_count >= 45 and v_count < 81 then
                if h_count >= 280 and h_count < 300 then
                    on_left_score := draw_digit(left_score, h_count - 280, v_count - 45);
                elsif h_count >= 340 and h_count < 360 then
                    on_right_score := draw_digit(right_score, h_count - 340, v_count - 45);
                end if;
            end if;

            if h_count >= h_active or v_count >= v_active then
                pixel := x"000000";
            elsif ball = '1' and goal_ball = '1' then
                pixel := goal_color;
            elsif ball = '1' then
                pixel := ball_color;
            elsif left_paddle = '1' then
                pixel := left_color;
            elsif right_paddle = '1' then
                pixel := right_color;
            elsif on_left_score then
                pixel := left_color;
            elsif on_right_score then
                pixel := right_color;
            elsif on_wall then
                pixel := wall;
            elsif h_count >= h_active / 2 - 1 and h_count <= h_active / 2 + 1
                and v_count >= 64 and v_count < v_active - 64
                and (dash_row < 10 or (dash_row >= 14 and dash_row < 18)) then
                pixel := center_mark;
            elsif inside_border then
                pixel := court;
            else
                pixel := margin;
            end if;

            Rout <= pixel(23 downto 16);
            Gout <= pixel(15 downto 8);
            Bout <= pixel(7 downto 0);
        end if;
    end process;
end Behavioral;
