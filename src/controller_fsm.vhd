----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           i_clk : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    signal f_sel    : unsigned(1 downto 0) := "00";
    signal btn_prev : std_logic;
    signal debounce_cnt : integer range 0 to 500000 := 0;
    signal btn_stable     : std_logic := '0';

    constant DEBOUNCE_LIMIT : integer := 250000;

begin

    -- 2 Bit counter Process ----------------------------
	-- counter rolls over automatically
	-- synchronous reset to "00"
	twoBitCounter_proc : process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '1' then
                f_sel         <= "00";
                btn_prev      <= '0';
                btn_stable    <= '0';
                debounce_cnt  <= 0;
            else
            ----------------------------------------------------------------
            -- DEBOUNCE LOGIC (this section was done with ChatGPT)
            ----------------------------------------------------------------
            -- If input is stable, reset counter
                if i_adv = btn_stable then
                    debounce_cnt <= 0;

                else
                    debounce_cnt <= debounce_cnt + 1;

                    if debounce_cnt = DEBOUNCE_LIMIT then
                        btn_stable   <= i_adv;
                        debounce_cnt <= 0;

                    -- ONLY act on rising edge AFTER debounce
                        if i_adv = '1' and btn_prev = '0' then
                            f_sel <= f_sel + 1;
                        end if;

                        btn_prev <= i_adv;

                    end if;
                end if;

            end if;

        end if;
    end process twoBitCounter_proc;
	
	o_cycle <= "0001" when f_sel = "00" else
	           "0010" when f_sel = "01" else
	           "0100" when f_sel = "10" else
	           "1000";

end FSM;
