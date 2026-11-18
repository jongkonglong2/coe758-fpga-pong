library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;

entity sync_gen is
    port (
        clk : in std_logic;
        h_count : in natural range 0 to h_total - 1;
        v_count : in natural range 0 to v_total - 1;
        h_sync : out std_logic;
        v_sync : out std_logic
    );
end sync_gen;

architecture Behavioral of sync_gen is
begin
    -- Register sync and RGB on the same edge for the same raster pixel.
    process(clk)
    begin
        if rising_edge(clk) then
            if h_count >= h_sync1 and h_count < h_sync2 then
                h_sync <= '0';
            else
                h_sync <= '1';
            end if;

            if v_count >= v_sync1 and v_count < v_sync2 then
                v_sync <= '0';
            else
                v_sync <= '1';
            end if;
        end if;
    end process;
end Behavioral;
