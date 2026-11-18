library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity top_level is
    port (
        clk_50 : in std_logic;
        left_up : in std_logic;
        left_down : in std_logic;
        right_up : in std_logic;
        right_down : in std_logic;
        clk_25 : out std_logic;
        h_sync : out std_logic;
        v_sync : out std_logic;
        Rout : out std_logic_vector(7 downto 0);
        Bout : out std_logic_vector(7 downto 0);
        Gout : out std_logic_vector(7 downto 0)
    );
end top_level;

architecture Behavioral of top_level is
    component icon
        port (
            CONTROL0 : inout std_logic_vector(35 downto 0)
        );
    end component;

    component ila
        port (
            CONTROL : inout std_logic_vector(35 downto 0);
            CLK : in std_logic;
            DATA : in std_logic_vector(31 downto 0);
            TRIG0 : in std_logic_vector(0 to 0)
        );
    end component;

    signal clk_25_s : std_logic;
    -- mapping.ucf refers to this net for the pixel clock timing constraint.
    attribute KEEP : string;
    attribute KEEP of clk_25_s : signal is "TRUE";

    signal h_count_s : natural range 0 to h_total - 1;
    signal v_count_s : natural range 0 to v_total - 1;
    signal left_paddle_s, right_paddle_s : std_logic;
    signal ball_s, goal_ball_s : std_logic;
    signal ball_new_frame_s : std_logic := '0';
    signal new_frame_s : std_logic;
    signal left_pos_s, right_pos_s : natural range 0 to v_active - v_paddle - 1;
    signal Rout_s, Gout_s, Bout_s : std_logic_vector(7 downto 0);
    signal h_sync_s, v_sync_s : std_logic;

    signal control0 : std_logic_vector(35 downto 0);
    signal ila_data : std_logic_vector(31 downto 0);
    signal trig0 : std_logic_vector(0 to 0);
begin
    Inst_clock_divider_2 : entity work.clock_divider_2
        port map (
            clk_50 => clk_50,
            clk_25 => clk_25_s
        );

    Inst_count_gen : entity work.count_gen
        port map (
            clk => clk_25_s,
            new_frame => new_frame_s,
            h_count => h_count_s,
            v_count => v_count_s
        );

    Inst_sync_gen : entity work.sync_gen
        port map (
            clk => clk_25_s,
            h_count => h_count_s,
            v_count => v_count_s,
            h_sync => h_sync_s,
            v_sync => v_sync_s
        );

    Inst_paddle : entity work.paddle
        port map (
            clk => clk_25_s,
            new_frame => new_frame_s,
            h_count => h_count_s,
            v_count => v_count_s,
            left_up => left_up,
            left_down => left_down,
            right_up => right_up,
            right_down => right_down,
            left_paddle => left_paddle_s,
            right_paddle => right_paddle_s,
            left_pos => left_pos_s,
            right_pos => right_pos_s
        );

    -- Update the paddles one clock before checking collisions.
    process(clk_25_s)
    begin
        if rising_edge(clk_25_s) then
            ball_new_frame_s <= new_frame_s;
        end if;
    end process;

    Inst_ball : entity work.ball
        port map (
            clk => clk_25_s,
            new_frame => ball_new_frame_s,
            h_count => h_count_s,
            v_count => v_count_s,
            left_pos => left_pos_s,
            right_pos => right_pos_s,
            ball => ball_s,
            goal_ball => goal_ball_s
        );

    Inst_VGA : entity work.VGA
        port map (
            clk => clk_25_s,
            h_count => h_count_s,
            v_count => v_count_s,
            ball => ball_s,
            goal_ball => goal_ball_s,
            left_paddle => left_paddle_s,
            right_paddle => right_paddle_s,
            Rout => Rout_s,
            Gout => Gout_s,
            Bout => Bout_s
        );

    Inst_icon : icon
        port map (
            CONTROL0 => control0
        );

    Inst_ila : ila
        port map (
            CONTROL => control0,
            CLK => clk_50,
            DATA => ila_data,
            TRIG0 => trig0
        );

    clk_25 <= clk_25_s;
    Rout <= Rout_s;
    Gout <= Gout_s;
    Bout <= Bout_s;
    h_sync <= h_sync_s;
    v_sync <= v_sync_s;

    -- ChipScope probes for the raster and sprite masks.
    ila_data(0) <= clk_25_s;
    ila_data(1) <= h_sync_s;
    ila_data(2) <= v_sync_s;
    ila_data(3) <= ball_s;
    ila_data(4) <= left_paddle_s;
    ila_data(5) <= right_paddle_s;
    ila_data(6) <= goal_ball_s;
    ila_data(14 downto 7) <= Rout_s;
    ila_data(22 downto 15) <= Gout_s;
    ila_data(30 downto 23) <= Bout_s;
    ila_data(31) <= new_frame_s;
    trig0(0) <= new_frame_s;
end Behavioral;
