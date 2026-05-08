----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
entity full_adder is
    Port ( A : in  STD_LOGIC;
           B : in  STD_LOGIC;
           Cin : in  STD_LOGIC;
           S : out  STD_LOGIC;
           Cout : out  STD_LOGIC);
end full_adder;

architecture Behavioral of full_adder is

    component full_adder is
        port (
            A     : in std_logic;
            B     : in std_logic;
            Cin   : in std_logic;
            S     : out std_logic;
            Cout  : out std_logic
            );
        end component full_adder;
        
begin

        S <= A XOR B XOR Cin;
        Cout <= (A AND B) OR (B AND Cin) OR (A AND Cin);
        
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ripple_adder is
    Port ( A : in STD_LOGIC_VECTOR (7 downto 0);
           B : in STD_LOGIC_VECTOR (7 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (7 downto 0);
           Cout : out STD_LOGIC);
end ripple_adder;

-- Declare components here
architecture Behavioral of ripple_adder is

    component full_adder is
        port (
            A     : in std_logic;
            B     : in std_logic;
            Cin   : in std_logic;
            S     : out std_logic;
            Cout  : out std_logic
            );
        end component full_adder;
    
    -- Declare signals here
signal w_carry  : STD_LOGIC_VECTOR(6 downto 0); -- for ripple between adders
begin
-- PORT MAPS -----------
    full_adder_0: full_adder
    port map(
        A     => A(0),
        B     => B(0),
        Cin   => Cin,   -- Directly to input here
        S     => S(0),
        Cout  => w_carry(0)
    );

    full_adder_1: full_adder
    port map(
        A     => A(1),
        B     => B(1),
        Cin   => w_carry(0),
        S     => S(1),
        Cout  => w_carry(1)
    );
    
    full_adder_2: full_adder
    port map(
        A     => A(2),
        B     => B(2),
        Cin   => w_carry(1),
        S     => S(2),
        Cout  => w_carry(2)
    );
    
    full_adder_3: full_adder
    port map(
        A     => A(3),
        B     => B(3),
        Cin   => w_carry(2),
        S     => S(3),
        Cout  => w_carry(3)
    );
    
    full_adder_4: full_adder
    port map(
        A     => A(4),
        B     => B(4),
        Cin   => w_carry(3),
        S     => S(4),
        Cout  => w_carry(4)
    );
    
    full_adder_5: full_adder
    port map(
        A     => A(5),
        B     => B(5),
        Cin   => w_carry(4),
        S     => S(5),
        Cout  => w_carry(5)
    );
    
    full_adder_6: full_adder
    port map(
        A     => A(6),
        B     => B(6),
        Cin   => w_carry(5),
        S     => S(6),
        Cout  => w_carry(6)
    );
    
    full_adder_7: full_adder
    port map(
        A     => A(7),
        B     => B(7),
        Cin   => w_carry(6),
        S     => S(7),
        Cout  => Cout
    );

end Behavioral;

library IEEE;
use ieee.STD_LOGIC_1164.ALL;
entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
signal w_B : STD_LOGIC_VECTOR (7 downto 0);
signal w_sum : STD_LOGIC_VECTOR (7 downto 0);
signal w_result : STD_LOGIC_VECTOR (7 downto 0);
signal w_Cout : STD_LOGIC;
    component ripple_adder is 
        port (
            A : in std_logic_vector;
            B : in std_logic_vector;
            Cin : in std_logic;
            S : out std_logic_vector;
            Cout : out std_logic
            );
        end component ripple_adder;
    
    component ALU is
        port (
            i_A : in std_logic_vector;
            i_B : in std_logic_vector;
            i_op : in std_logic_vector;
            o_result : out std_logic_vector;
            o_flags : out std_logic_vector
            );
        end component ALU;

begin
-- PORT MAPS --------
    ripple_adder_0 : ripple_adder
    port map(
        A     => i_A,
        B     => w_B,
        Cin   => i_op(0),
        S     => w_sum,
        Cout  => w_Cout
    );
    
    -- ALU_0: ALU
    -- port map(
        -- i_A      => i_A,
        -- i_B      => i_B,
        -- i_op     => i_op,
        -- o_result => w_result,
        -- o_flags  => o_flags
    -- );
    
    -- take -B when subtracting
    with i_op(0) select
        w_B <= i_B when '0',
        not i_B when '1',
        i_B when others;
    
    -- 4:1 mux for 4 operations (add, sub, and, or)
    with i_op (1 downto 0) select
        w_result <= w_sum when "00",
        w_sum when "01",
        i_A and i_B when "10",
        i_A or i_B when "11",
        i_A when others;
    
    o_result <= w_result;
    -- set o_flags according to ALU diagram
    -- oVerflow
    o_flags(0) <= (not (i_op(0) xor i_A(7) xor i_B(7))) and (i_A(7) xor w_Sum(7)) and not i_op(1);
    -- Carry
    o_flags(1) <= w_Cout and not i_op(1);
    -- Zero (there is most definitely a better way to do this)
    o_flags(2) <= not (w_result(0) or w_result(1) or w_result(2) or w_result(3) or w_result(4) or w_result(5) or w_result(6) or w_result(7));
    -- Negative
    o_flags(3) <= w_result(7);
    
end Behavioral;
