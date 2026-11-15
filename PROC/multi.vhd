library ieee;
USE ieee.std_logic_1164.all;

entity multi is
    PORT(
				 boot      : IN  STD_LOGIC;
				 clk       : IN  STD_LOGIC;
				 ldpc_l    : IN  STD_LOGIC;
				 wrd_l     : IN  STD_LOGIC;
				 wr_m_l    : IN  STD_LOGIC;
				 w_b       : IN  STD_LOGIC;
				 Rb_N_l 	  : IN STD_LOGIC;
				 rd_in_l   : IN STD_LOGIC;
				 wr_out_l  : IN STD_LOGIC;
				 calls_inst_l : IN STD_LOGIC;
				 protected_inst_l : IN STD_LOGIC;
				 mem_access_l : IN STD_LOGIC;
				 -- Interrupcion regfile pins
				 is_inter_l : IN  STD_LOGIC; -- Is interrupcion input
				 intr_enable : IN STD_LOGIC;
				 -- Excepcion
				 excep_l 			: IN STD_LOGIC;
				 illegal_inst_l	: IN STD_LOGIC;
				 ldpc      : OUT STD_LOGIC;
				 wrd       : OUT STD_LOGIC;
				 wr_m      : OUT STD_LOGIC;
				 ldir      : OUT STD_LOGIC;
				 ins_dad   : OUT STD_LOGIC;
				 word_byte : OUT STD_LOGIC;
				 Rb_N	 	  : OUT STD_LOGIC;
				 rd_in			: OUT STD_LOGIC;
				 wr_out			: OUT STD_LOGIC;
				 is_inter 		: OUT  STD_LOGIC; -- Is interrupcion
				 excep			: OUT STD_LOGIC;
				 illegal_inst	: OUT STD_LOGIC;
				 calls_inst 	: OUT STD_LOGIC;
				 protected_inst : OUT STD_LOGIC;
				 mem_access : OUT STD_LOGIC;
				 is_fetch 	: OUT STD_LOGIC
				 );
end entity;

architecture Structure of multi is

    -- Aqui iria la declaracion de las los estados de la maquina de estados
	type t_state is (F, DEMW, SYSTEM); -- Fetch and Execution States
	signal state : t_state := F;
	
begin

    -- FINITE STATE MACHINE
	 process (clk, boot) begin
		if boot = '1' then
			state <= F;
		else
			if rising_edge(clk) then
				case state is
					when F => -- Fetch state
						state <= DEMW;
					
					when DEMW => -- Executon state
						if excep_l = '1' or (is_inter_l = '1' and intr_enable = '1') then
							state <= SYSTEM; -- Interrupcion
						else
							state <= F; -- Normal
						end if;
				
					when SYSTEM => -- System state
						state <= F;
				end case;
			end if;
		end if;
	 end process;
	 
	 -- Outputs 
	 ldpc 			<= ldpc_l 				when (state = DEMW and excep_l = '0') or state = SYSTEM 	else '0';
	 wrd 				<= wrd_l 				when state = DEMW 													else '0';
	 wr_m 			<= wr_m_l 				when state = DEMW 													else '0';
	 word_byte 		<= w_b					when state = DEMW 													else '0';
	 ins_dad 		<= '1'					when state = DEMW														else '0';
	 ldir				<= '1'					when state = F															else '0';
	 Rb_N 			<= Rb_N_l				when state = DEMW														else '1';
	 rd_in   		<= rd_in_l 				when state = DEMW														else '0';
	 wr_out			<= wr_out_l				when state = DEMW														else '0';
	 is_inter		<= is_inter_l 			when state = SYSTEM 													else '0';
	 excep 			<= excep_l				when state = SYSTEM 													else '0';
	 illegal_inst 	<= illegal_inst_l 	when state = DEMW														else '0';
	 calls_inst 	<= calls_inst_l 		when state = DEMW														else '0';
	 protected_inst <= protected_inst_l when state = DEMW														else '0';
	 mem_access <= mem_access_l 			when state = DEMW														else '0';
	 
	 is_fetch <= '1' 							when state = F															else '0';
end Structure;
