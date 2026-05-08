--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- clock divider reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	signal w_clk : STD_LOGIC; -- clock signal from divider to TDM
	signal w_cycle : STD_LOGIC_VECTOR (3 downto 0); -- clock cycle (one-hot)
	signal w_A : STD_LOGIC_VECTOR (7 downto 0); -- input A to ALU
	signal w_B : STD_LOGIC_VECTOR (7 downto 0); -- input B to ALU
	signal w_result : STD_LOGIC_VECTOR (7 downto 0); -- output from ALU
	signal w_flags : STD_LOGIC_VECTOR (3 downto 0); -- flags from ALU output
	signal w_bin : STD_LOGIC_VECTOR (7 downto 0); -- binary input to twos_comp
	signal w_sign : STD_LOGIC_VECTOR (3 downto 0); -- twos_comp sign
	signal w_hund : STD_LOGIC_VECTOR (3 downto 0); -- twos_comp hundred place
	signal w_tens : STD_LOGIC_VECTOR (3 downto 0); -- twos_comp tens place
	signal w_ones : STD_LOGIC_VECTOR (3 downto 0); -- twos_comp ones place
	signal w_data : STD_LOGIC_VECTOR (3 downto 0); -- data from TDM bound for decoder
	signal w_sel : STD_LOGIC_VECTOR (3 downto 0); -- selector for anodes, turns all anodes off for stage 1
	signal w_seg : STD_LOGIC_VECTOR (6 downto 0); -- sends 7-seg bits to display
	
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component controller_fsm is
        port (
            i_reset : in STD_LOGIC;
            i_adv : in STD_LOGIC;
            i_clk : in STD_LOGIC;
            o_cycle : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component controller_fsm;
    
    component ALU is
        port (
            i_A : in STD_LOGIC_VECTOR (7 downto 0);
            i_B : in STD_LOGIC_VECTOR (7 downto 0);
            i_op : in STD_LOGIC_VECTOR (2 downto 0);
            o_result : out STD_LOGIC_VECTOR (7 downto 0);
            o_flags : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component ALU;
    
    component clock_divider is
        generic ( constant k_DIV : natural := 2 );
        port (
            i_clk : in STD_LOGIC;
            i_reset : in STD_LOGIC;
            o_clk : out STD_LOGIC
        );
    end component clock_divider;
    
    component twos_comp is
        port (
            i_bin : in STD_LOGIC_VECTOR (7 downto 0);
            o_sign : out STD_LOGIC;
            o_hund : out STD_LOGIC_VECTOR (3 downto 0);
            o_tens : out STD_LOGIC_VECTOR (3 downto 0);
            o_ones : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component twos_comp;
  
    component TDM4 is
        generic (constant k_WIDTH : natural := 4);
        port (
            i_clk : in STD_LOGIC;
            i_reset : in STD_LOGIC;
            i_D3 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D2 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D1 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            i_D0 : in STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_data : out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
            o_sel : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component TDM4;
  
begin
	-- PORT MAPS ----------------------------------------
    controller_inst : controller_fsm
        port map (
            i_reset => btnU,
            i_adv => btnC,
            i_clk => clk,
            o_cycle => w_cycle
        );
        
    clock_div_inst : clock_divider
        generic map ( k_DIV => 100000 )
        port map (
            i_clk => clk,
            i_reset => btnL,
            o_clk => w_clk
        );
        
    ALU_inst : ALU
        port map (
            i_A => w_A,
            i_B => w_B,
            i_op => sw(2 downto 0),
            o_result => w_result,
            o_flags => w_flags
        );
	
	twos_comp_inst : twos_comp
	   port map (
	       i_bin => w_bin,
	       o_sign => w_sign(0),
	       o_hund => w_hund,
	       o_tens => w_tens,
	       o_ones => w_ones
	   );
	   
	TDM4_inst : TDM4
	   generic map (k_WIDTH => 4)
	   port map (
	       i_clk => w_clk,
	       i_reset => btnU,
	       i_D3 => w_sign,
	       i_D2 => w_hund,
	       i_D1 => w_tens,
	       i_D0 => w_ones,
	       o_data => w_data,
	       o_sel => w_sel
	   );
    
    sevenseg_inst : sevenseg_decoder
        port map (
            i_Hex => w_data,
            o_seg_n => w_seg
        );
	
	-- CONCURRENT STATEMENTS ----------------------------
	-- set A and B for the ALU at the proper time
	w_A <= sw(7 downto 0) when rising_edge(w_cycle(1));
	w_B <= sw(7 downto 0) when rising_edge(w_cycle(2));
	
	with w_cycle (3 downto 0) select
	   w_bin <= w_A when "0010",
	            w_B when "0100",
	            w_result when "1000",
	            "00000000" when others;
	
	w_sign (3 downto 1) <= "111"; -- bit 0 is set by negative output. Negative is "1111", Positive is "1110"
	with w_seg (6 downto 0) select
	   seg <= "0111111" when "0001110", -- negative output reads as "F"
	          "1111111" when "0000110", -- positive output reads as "E"
	          w_seg when others;
	
	with w_cycle(0) select
	   an <= "1111" when '1', -- turn display off when first stage
	         w_sel when others; -- normal display when other stages
	
	led(3 downto 0) <= w_cycle;
	led(15 downto 12) <= w_flags;
	
end top_basys3_arch;
