library ieee;
use ieee.std_logic_1164.all;

entity clock_divider_2 is
    port (
        clk_50 : in std_logic;
        clk_25 : out std_logic
    );
end clock_divider_2;

architecture Behavioral of clock_divider_2 is
    signal clk_25_s : std_logic := '0';
begin
    process(clk_50)
    begin
        if rising_edge(clk_50) then
            clk_25_s <= not clk_25_s;
        end if;
    end process;

    clk_25 <= clk_25_s;
	 
end Behavioral;
