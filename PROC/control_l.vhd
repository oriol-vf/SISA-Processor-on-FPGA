LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY control_l IS 
	PORT (
			ir 				: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			zero_flag		: IN STD_LOGIC; -- Alu zero Flag
			intr				: IN STD_LOGIC;
			excep 			: IN STD_LOGIC;
			alu_u				: OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- ALU UNIT 2 bits
			op					: OUT STD_LOGIC_VECTOR(2 downto 0); -- ALU Selected Unit Operation 3 bits
			ldpc 				: OUT STD_LOGIC;
			wrd				: OUT STD_LOGIC;
			addr_a			: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			addr_b 			: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			addr_d 			: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			immed 			: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			wr_m 				: OUT STD_LOGIC;
			in_d 				: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			immed_x2 		: OUT STD_LOGIC;
			Rb_N	 			: OUT STD_LOGIC;
			word_byte 		: OUT STD_LOGIC;
			tknbr				: OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			save_pc			: OUT STD_LOGIC;
			rd_in				: OUT STD_LOGIC;
			wr_out			: OUT STD_LOGIC;
			link_pc 			: OUT STD_LOGIC;
			mem_access		: OUT STD_LOGIC;
			is_store			: OUT STD_LOGIC;
			-- Interrupcion
			is_inter 		: OUT  STD_LOGIC; -- Is interrupcion
			sys_inst 		: OUT STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00(NON), 01(EI), 10(DI), 11(RETI)
			d_sys  			: OUT  STD_LOGIC;
			a_sys  			: OUT  STD_LOGIC;
			inta				: OUT STD_LOGIC;
			-- Excepcion
			illegal_inst	: OUT STD_LOGIC;
			protected_inst : OUT STD_LOGIC; --NEW
			calls_inst		: OUT STD_LOGIC;  --NEW 
			-- TLB
			tlb_flush		: OUT STD_LOGIC;
			tlb_conf_en : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
			);
END control_l;


ARCHITECTURE Structure OF control_l IS
	-- Inter. Signals
	signal immed_high, immed_low : std_logic_vector(7 downto 0);
	
	-- Signal Alias
	alias opcode : std_logic_vector(3 downto 0) is ir(15 downto 12);
	
	-- INSTRUCTION OPCODES

	constant 	OP_AR_LOG		: std_logic_vector(3 downto 0)	:= "0000"; -- Arithmetic Logic Operations
	constant 	OP_CMP			: std_logic_vector(3 downto 0)	:= "0001"; -- Comparison Operations
	constant 	OP_ADDI			: std_logic_vector(3 downto 0)	:= "0010"; -- ADDI 
	constant 	OP_LD 			: std_logic_vector(3 downto 0) 	:= "0011"; -- Load Word (16bits)
	constant 	OP_ST 			: std_logic_vector(3 downto 0) 	:= "0100"; -- Store Word (16bits)
	constant 	OP_MOVI_MOVHI 	: std_logic_vector(3 downto 0) 	:= "0101"; -- MOVI and MOVHI
	constant		OP_EX_AR			: std_logic_vector(3 downto 0) 	:= "1000"; -- Extension Arithmetic Operations (Mult, Div)
	constant 	OP_LDB 			: std_logic_vector(3 downto 0) 	:= "1101"; -- Load Byte (8 bits)
	constant 	OP_STB 			: std_logic_vector(3 downto 0) 	:= "1110"; -- Store Byte (8 bits)
	constant 	OP_CBR			: std_logic_vector(3 downto 0)	:= "0110"; -- Condicional branches with pc relative mode: BR, BNZ
	constant 	OP_JBR			: std_logic_vector(3 downto 0)	:= "1010"; -- JZ, JNZ, JMP, JAL, CALLS, ...
	constant 	OP_IN_OUT		: std_logic_vector(3 downto 0)	:= "0111"; -- IN and OUT
	constant 	OP_SPC			: std_logic_vector(3 downto 0)	:= "1111"; -- Special instruccions (RDS, WRS, EI, DI, RETI)
	
	-- Temporal signals
	
	signal tmp_alu_u, tmp_in_d, tmp_sys_inst : std_logic_vector(1 downto 0);
	signal tmp_op	: std_logic_vector(2 downto 0);
	signal tmp_wr_m, tmp_wrd, tmp_ldpc, tmp_illegal_inst_op, tmp_illegal_alu_op, tmp_illegal_br_inst, tmp_illegal_sys_inst : std_logic;
BEGIN
	-- Illegal Instruccions
	with opcode select
		tmp_illegal_inst_op <= 	'0' when OP_AR_LOG | OP_CMP | OP_ADDI | 
											OP_LD | OP_ST | OP_MOVI_MOVHI | 
											OP_EX_AR | OP_LDB | OP_STB |
											OP_CBR | OP_JBR | OP_IN_OUT | OP_SPC,
								'1' when others;
	
	tmp_illegal_alu_op <= 
								'1' when (opcode = OP_CMP) and (ir(5 downto 3) = "010" or ir(5 downto 3) = "110" or ir(5 downto 3) = "111") else -- CMP not implemented instruccions
								'1' when (opcode = OP_EX_AR) and (ir(5 downto 3) = "011" or ir(5 downto 3) = "110" or ir(5 downto 3) = "111") else -- EX_AR not implemented instruccions
								'0';
								
	tmp_illegal_br_inst <= 
								'1' when (opcode = OP_JBR) and (ir(5 downto 3) /= "000" or ir(2 downto 0) = "010" or ir(2 downto 0) = "101" or ir(2 downto 0) = "110") else 
								'0';
	
	tmp_illegal_sys_inst <= 
								 '1' when (opcode = OP_SPC) and 
											 ((ir(5 downto 0) /= "101100") and -- RDS 
											 (ir(5 downto 0) /= "110000") and -- WRS
											 (ir(5 downto 0) /= "100100") and -- RETI
											 (ir(5 downto 0) /= "100000") and -- EI
											 (ir(5 downto 0) /= "100001") and -- DI
											 (ir(5 downto 0) /= "101000") and -- GETIID
											 (ir(5 downto 0) /= "110100")	and -- WRPI
											 (ir(5 downto 0) /= "110101") and -- WRVI
											 (ir(5 downto 0) /= "110110")	and -- WRPD
											 (ir(5 downto 0) /= "110111") and -- WRVD
											 (ir(5 downto 0) /= "111000") and -- FLUSH
											 (ir(15 downto 0) /= x"FFFF"))     -- HALT
								 else '0';
	
	illegal_inst <= tmp_illegal_inst_op or tmp_illegal_sys_inst or tmp_illegal_alu_op or tmp_illegal_br_inst;
	
	protected_inst <= '1' when (opcode = OP_SPC and (
                            ir(5 downto 0) = "101100" or -- RDS
                            ir(5 downto 0) = "110000" or -- WRS
                            ir(5 downto 0) = "100000" or -- EI
                            ir(5 downto 0) = "100001" or -- DI
                            ir(5 downto 0) = "101000" or -- GETIID
                            ir(5 downto 0) = "100100" or -- RETI
									 ir(5 downto 0) = "110100"	or -- WRPI
									 ir(5 downto 0) = "110101" or -- WRVI
									 ir(5 downto 0) = "110110"	or -- WRPD
									 ir(5 downto 0) = "110111" or -- WRVD
									 ir(5 downto 0) = "111000"))  -- FLUSH
                      else '0';
	
	calls_inst <= '1' when (opcode = OP_JBR and ir(5 downto 0) = "000111") else '0';
	
	-- Mem access
	with opcode select
		mem_access <= '1' when OP_LD | OP_ST | OP_LDB | OP_STB,
						  '0' when others;
	
	is_store <= '1' when opcode = OP_ST or opcode = OP_STB else '0';
	
	 -- Write Permission Gestion --------------
	 tmp_wrd <= '1' when (opcode = OP_MOVI_MOVHI or 
							opcode = OP_LD         or 
							opcode = OP_LDB        or 
							opcode = OP_AR_LOG     or 
							opcode = OP_CMP        or 
							opcode = OP_ADDI       or 
							opcode = OP_EX_AR) else
				'1' when (opcode = OP_JBR and ir(5 downto 0) = "000100") else -- JAL
				'1' when (opcode = OP_IN_OUT and ir(8) = '0') else
				'1' when (opcode = OP_SPC and (
															ir(5 downto 0) = "101100" or -- RDS
															ir(5 downto 0) = "110000" or -- WRS
															ir(5 downto 0) = "100000" or -- EI
															ir(5 downto 0) = "100001" or -- DI
															ir(5 downto 0) = "101000" or -- GETIID
															ir(5 downto 0) = "100100")) else -- RETI
				'0';
	 
	 wrd <= tmp_wrd when intr = '0' and excep = '0' else '0';
	 
	 with opcode select	  
		tmp_wr_m <= '1' when OP_ST | OP_STB, -- write memory permission only when ir = ST or STB 
				  '0' when others;
	 wr_m <= tmp_wr_m when intr = '0' and excep = '0' else '0'; 
	 -- ---------------------------------------
	 
	 -- Addr Gestion --------------------------
	 addr_a <= ir(8 downto 6) when (
												opcode = OP_LD or -- LD
												opcode = OP_ST or -- ST
												opcode = OP_LDB or -- LDB
												opcode = OP_STB or -- STB
												opcode = OP_AR_LOG or -- ARIT and LOGIC
												opcode = OP_CMP or -- CMP
												opcode = OP_ADDI or -- ADDI
												opcode = OP_EX_AR or -- EXT ARIT (Mult, Div)
												opcode = OP_JBR or -- JBR
												(opcode = OP_SPC and (ir(5 downto 0) = "101100" or ir(5 downto 0) = "110000" or 
												ir(5 downto 0) = "110100" or ir(5 downto 0) = "110101" or ir(5 downto 0) = "110110" or ir(5 downto 0) = "110111" or
												ir(5 downto 0) = "111000")) -- RDS, WRS, WRPI, WRVI, WRPD, WRVD, FLUSH
												) else
					 "001"			when opcode = OP_SPC and (ir(5 downto 0) = "100100") else -- S1
					 ir(11 downto 9);
	
	 with opcode select 
		addr_b <= ir(2 downto 0)  	when OP_AR_LOG | OP_CMP | OP_EX_AR, -- ARIT and LOGIC, CMP and EXT ARIT (Mult, Div)
					 ir(11 downto 9) 	when others;
					 
	 addr_d <= ir(11 downto 9);
	 -- ---------------------------------------
	 
	 -- Load Program Counter (PC) Permission Signal 
	 tmp_ldpc <= '0' when ir = x"FFFF" else '1';
	 ldpc <= tmp_ldpc when intr = '0' and excep = '0' else '1'; -- Interrupcion => update PC
	 -- Immed Gestion -------------------------
	 immed_low 	<= ir(7 downto 0);
	 immed_high <= (others => ir(7));
	 
	 with opcode select 
		immed <= (15 downto 6 => immed_low(5)) & immed_low(5 downto 0) 	when OP_LD | OP_ST | OP_LDB | OP_STB | OP_ADDI, -- LD, ST, LDB, STB, ADDI 
					immed_high & immed_low 					when others;
	 -- ---------------------------------------
	 

	 -- ALU UNIT ----------------------------
		tmp_alu_u <= 
					"00" 			when (
											opcode = OP_LD or
											opcode = OP_ST or
											opcode = OP_LDB or
											opcode = OP_STB or
											opcode = OP_AR_LOG or
											opcode = OP_ADDI or
											opcode = OP_IN_OUT) else
					"01"			when 	opcode = OP_CMP else
					"10"			when 	opcode = OP_EX_AR else
					"11" 			when (
											opcode = OP_MOVI_MOVHI or 
											opcode = OP_JBR or
											(opcode = OP_SPC and (ir(5 downto 0) = "101100" or ir(5 downto 0) = "110000")) or -- RDS or WRS
											(opcode = OP_SPC and (ir(5 downto 0) = "100100")) -- RETI
											) else
					"11";
		
		alu_u <= tmp_alu_u when intr = '0' and excep = '0' else "11";
	 -- ---------------------------------------
	 
	 -- ALU UNIT Operation -------------------
		tmp_op <= 	
					"000"				when opcode = OP_IN_OUT else -- AND
					"100" 			when ( -- ADD
												opcode = OP_LD or
												opcode = OP_ST or
												opcode = OP_LDB or
												opcode = OP_STB or
												opcode = OP_ADDI) else 
					ir(5 downto 3) when (
												opcode = OP_AR_LOG or
												opcode = OP_CMP or
												opcode = OP_EX_AR) else
					"00" & (ir(8)) when opcode = OP_MOVI_MOVHI else
					"010" 			when ( -- PASS X  
												opcode = OP_JBR or 
												(opcode = OP_SPC and (ir(5 downto 0) = "101100" or ir(5 downto 0) = "110000")) or -- RDS or WRS
												(opcode = OP_SPC and (ir(5 downto 0) = "100100")) -- RETI
												) else 
					"111";
					
	 op <= tmp_op when intr = '0' and excep = '0' else "010";
	 -- ---------------------------------------
	 
	 -- Data Multiplexor signal (ALU(0), MEM(1) or IO(2))
		tmp_in_d <= 
				 "01" when (	opcode = OP_LD or 
									opcode = OP_ST or 
									opcode = OP_LDB or
									opcode = OP_STB or
									opcode = OP_CBR) else
				  "10" when (opcode = OP_IN_OUT and ir(8) = '0') or (opcode = OP_SPC and (ir(5 downto 0) = "101000")) else -- IN and GETIID
				  "00";
		
		in_d <= tmp_in_d when intr = '0' and excep = '0' else "00";
	 -- ---------------------------------------
	
	-- Y ALU input port Multiplexor signal (REGB(0) or IMMED(1))
	with opcode select 
		Rb_N <= '1' when OP_LD | OP_ST | OP_LDB | OP_STB | OP_ADDI | OP_MOVI_MOVHI,
				  '0' when others;
				  
	
	-- Immed or Immed * 2 ---------------------
	 with opcode select 
		immed_x2 <= '1' when OP_LD | OP_ST,
						'0' when others;
	
	 -- ---------------------------------------
	 
	 -- Byte or Word Access -------------------
	 with opcode select 
		word_byte <= '1' when OP_LDB | OP_STB,	
						 '0' when others;
	 -- ---------------------------------------
	 
	 -- Branch Gestion
	 tknbr <= "01" when (zero_flag = '1' and opcode = OP_CBR and ir(8) = '0') else -- BZ
				 "01" when (zero_flag = '0' and opcode = OP_CBR and ir(8) = '1') else -- BNZ
				 "10" when (zero_flag = '1' and opcode = OP_JBR and ir(5 downto 0) = "000000") else -- JZ
				 "10" when (zero_flag = '0' and opcode = OP_JBR and ir(5 downto 0) = "000001") else -- JNZ
				 "10" when (opcode = OP_JBR and ir(5 downto 0) = "000011") else -- JMP
				 "10" when (opcode = OP_JBR and ir(5 downto 0) = "000100") else -- JAL
				 --"10" when (opcode = OP_JBR and ir(5 downto 0) = "000111") else -- CALLS
				 "00";
				 
	save_pc <= '1' when ((opcode = OP_JBR and ir(5 downto 0) = "000100") or intr = '1' or excep = '1') else '0'; -- JAL and Interrupcion
	link_pc <= '1' when intr = '0' and excep = '0' and ((opcode = OP_JBR and ir(5 downto 0) = "000100")) else '0'; -- JAL (Link PC)
	
	-- IO Gestion
	rd_in <= '1' when intr = '0' and excep = '0' and (((opcode = OP_IN_OUT) and (ir(8) = '0')) or (opcode = OP_SPC and (ir(5 downto 0) = "101000"))) else '0'; -- IN and GETIID
	wr_out <= '1' when intr = '0' and excep = '0' and (opcode = OP_IN_OUT) and (ir(8) = '1') else '0';
	
	-- Interupcion Gestion
	is_inter <= '0' when (opcode = OP_SPC and (ir(5 downto 0) = "101000")) else intr; 
	inta <= '1' when (opcode = OP_SPC and (ir(5 downto 0) = "101000")) else '0'; -- GETIID
	d_sys <= '1' when opcode = OP_SPC and (ir(5 downto 0) = "110000" or ir(5 downto 0) = "100000" or ir(5 downto 0) = "100001" or ir(5 downto 0) = "100100") else '0'; -- WRS, EI, DI, RETI
	a_sys <= '1' when opcode = OP_SPC and (ir(5 downto 0) = "101100" or ir(5 downto 0) = "100100") else '0'; -- RDS, RETI
	
	with (opcode & ir(5 downto 0)) select
		tmp_sys_inst <= "01" when OP_SPC & "100000", -- EI
						"10" when OP_SPC & "100001", -- DI
						"11" when OP_SPC & "100100", -- RETI
						"00" when others;
	sys_inst <= tmp_sys_inst when intr = '0' and excep = '0' else "00";
	
	-- TLB
	tlb_flush <= '1' when ((opcode = OP_SPC) and ir(5 downto 0) = "111000") else '0';
	
	with (opcode & ir(5 downto 0)) select
		tlb_conf_en <= "101" when OP_SPC & "110100", -- WRPI
							"100" when OP_SPC & "110101", -- WRVI
							"111" when OP_SPC & "110110", -- WRPD
							"110" when OP_SPC & "110111", -- WRVD
							"000" when others;
END Structure;