library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity paddle is
    port (
        clk : in std_logic;
        new_frame : in std_logic;
        h_count : in natural range 0 to h_total - 1;
        v_count : in natural range 0 to v_total - 1;
        left_up : in std_logic;
        left_down : in std_logic;
        right_up : in std_logic;
        right_down : in std_logic;
        left_pos : out natural range 0 to v_active - v_paddle - 1;
        right_pos : out natural range 0 to v_active - v_paddle - 1;
        left_paddle : out std_logic;
        right_paddle : out std_logic
    );
end paddle;

architecture Behavioral of paddle is
    signal switches_meta : std_logic_vector(3 downto 0) := (others => '0');
    signal switches_sync : std_logic_vector(3 downto 0) := (others => '0');
    signal previous_switches : std_logic_vector(3 downto 0) := (others => '0');
    signal left_y, right_y : natural range paddle_min_y to paddle_max_y := 150;
	 
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of switches_meta, switches_sync : signal is "TRUE";

   function move_paddle(y : natural; controls, previous : std_logic_vector(1 downto 0))
        return natural is
        variable next_y : natural;
    begin
        next_y := y;
        -- Sample a stable direction on two consecutive frames.
        if controls = previous then
            if controls = "10" and y > paddle_min_y then
                 next_y := y - paddle_step;
            elsif controls = "01" and y < paddle_max_y then
                 next_y := y + paddle_step;
            end if;
        end if;
        return next_y;
    end function;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            switches_meta <= left_up & left_down & right_up & right_down;
            switches_sync <= switches_meta;
            if new_frame = '1' then
                left_y <= move_paddle(left_y, switches_sync(3 downto 2), previous_switches(3 downto 2));
                right_y <= move_paddle(right_y, switches_sync(1 downto 0), previous_switches(1 downto 0));
                previous_switches <= switches_sync;
            end if;
        end if;
    end process;

    left_pos <= left_y;
    right_pos <= right_y;
    left_paddle <= '1' when h_count >= left_paddle_x and h_count < left_paddle_x + h_paddle
                           and v_count >= left_y and v_count < left_y + v_paddle else '0';
    right_paddle <= '1' when h_count >= right_paddle_x and h_count < right_paddle_x + h_paddle
                            and v_count >= right_y and v_count < right_y + v_paddle else '0';
end Behavioral;
