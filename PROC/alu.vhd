LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY alu IS
    PORT (x  				: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  				: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          alu_u			: IN STD_LOGIC_VECTOR(1 DOWNTO 0); 
			 op				: IN STD_LOGIC_VECTOR(2 downto 0);
			 z					: OUT STD_LOGIC;
			 div_zero 		: OUT STD_LOGIC;
          w  				: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END alu;


ARCHITECTURE Structure OF alu IS
	-- COMPONENTS
	COMPONENT arithmetic_logic_operations_unit IS
		PORT (x  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
				y  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
				op  	: IN STD_LOGIC_VECTOR(2 downto 0);
				w  	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT cmp_operations_unit IS
    PORT (x  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  	: IN STD_LOGIC_VECTOR(2 downto 0);
          w  	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT ext_arithmetic_logic_operations_unit IS
    PORT (x  			: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  			: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  			: IN STD_LOGIC_VECTOR(2 downto 0);
			 div_zero 	: OUT STD_LOGIC;
          w  			: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;
	
	COMPONENT others_operations_unit IS
    PORT (x  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  	: IN STD_LOGIC_VECTOR(2 downto 0);
          w  	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
	END COMPONENT;

		
	-- SIGNALS
	signal arit_log_result, cmp_result, ext_arit_log_result, others_op_result, final_alu_result : STD_LOGIC_VECTOR(15 DOWNTO 0);
	-- Flags
	signal tmp_div_zero : std_logic := '0';
BEGIN
	-- ALU UNITS ---------------------------------------------------------------------------
	arit_logic_op_unit 		: arithmetic_logic_operations_unit 		port map(x => x, y => y, op => op, w => arit_log_result);
	cmp_op_unit			 		: cmp_operations_unit 						port map(x => x, y => y, op => op, w => cmp_result);
	ext_arit_logic_op_unit 	: ext_arithmetic_logic_operations_unit port map(x => x, y => y, op => op, w => ext_arit_log_result, div_zero => tmp_div_zero);
	others_op_unite			: others_operations_unit 					port map(x => x, y => y, op => op, w => others_op_result);
	-- --------------------------------------------------------------------------------------
	
    -- Alu Operation multiplexor -----------------------------------------------------------
	 
	 with alu_u select
		final_alu_result <=  arit_log_result  		when "00",
									cmp_result 				when "01",
									ext_arit_log_result	when "10",
									others_op_result		when "11",
									x"DEAD"      			when others;
									
	
	z <= '1' when y = x"0000" else '0'; -- Zero Frag
	div_zero <= tmp_div_zero when alu_u = "10" else '0'; -- Div Zero Flag
	w <= final_alu_result; -- ALU return
	-- --------------------------------------------------------------------------------------  
END Structure;


-- ALU UNITS

-- ARITHMETIC LOGIC OPERATION UNIT
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY arithmetic_logic_operations_unit IS
    PORT (x  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  	: IN STD_LOGIC_VECTOR(2 downto 0);
          w  	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END arithmetic_logic_operations_unit;


ARCHITECTURE Structure OF arithmetic_logic_operations_unit IS
	signal sha_result, shl_result : std_logic_vector(15 downto 0);
	alias shift_bits : std_logic_vector(4 downto 0) is y(4 downto 0);

BEGIN

	--  SHIFT OPERATIONS
	sha_result <= std_logic_vector(shift_left(unsigned(x),conv_integer(shift_bits))) 	when shift_bits(4) = '0' else std_logic_vector(shift_right(signed(x),conv_integer(std_logic_vector(-signed(shift_bits)))));
	shl_result <= std_logic_vector(shift_left(unsigned(x),conv_integer(shift_bits))) when shift_bits(4) = '0' else std_logic_vector(shift_right(unsigned(x),conv_integer(std_logic_vector(-signed(shift_bits)))));
	
	-- Unit Operation multiplexor -----------------------------------------------------------
	 
	with op select
		w <=  
				x and y  		 									when "000",
				x or y 			 									when "001",
				x xor y			 									when "010",
				not x				 									when "011",
				std_logic_vector(signed(x) + signed(y))	when "100",
				std_logic_vector(signed(x) - signed(y))   when "101",
				sha_result											when "110",
				shl_result											when "111",
				x"DEAD"      when others;
	-- --------------------------------------------------------------------------------------  
END Structure;

-- CMP OPERATION UNIT
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY cmp_operations_unit IS
    PORT (x  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  	: IN STD_LOGIC_VECTOR(2 downto 0);
          w  	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END cmp_operations_unit;


ARCHITECTURE Structure OF cmp_operations_unit IS
	signal ltu, lts, eq : std_logic_vector(15 downto 0);
BEGIN
	-- CMP OPERATION ------------------
	ltu <= x"0001" when unsigned(x) < unsigned(y) 	else x"0000";
	lts <= x"0001" when signed(x) < signed(y) 		else x"0000";
	eq <=  x"0001" when x = y								else x"0000";
	
	-- Unit Operation multiplexor -----------------------------------------------------------	 
	with op select
		w <=  
				lts  		 											when "000",
				lts or eq		 									when "001",
				eq					 									when "011",
				ltu				 									when "100",
				ltu or eq											when "101",
				x"DEAD"      when others;
	-- --------------------------------------------------------------------------------------  
END Structure;

-- EXTENDED ARITHMETIC LOGIC OPERATION UNIT
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY ext_arithmetic_logic_operations_unit IS
    PORT (x  			: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  			: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  			: IN STD_LOGIC_VECTOR(2 downto 0);
			 div_zero 	: OUT STD_LOGIC;
          w  			: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END ext_arithmetic_logic_operations_unit;


ARCHITECTURE Structure OF ext_arithmetic_logic_operations_unit IS
	signal multu_result, mults_result : std_logic_vector(31 downto 0);
	signal divu_result, divs_result : std_logic_vector(15 downto 0);
BEGIN
	-- Multi Operation
	multu_result <= std_logic_vector(unsigned(x) * unsigned(y));
	mults_result <= std_logic_vector(signed(x) * signed(y));
	
	-- Div Operation
	divu_result <= std_logic_vector(unsigned(x) / unsigned(y));
	divs_result <= std_logic_vector(signed(x) / signed(y));
	
	-- Unit Operation multiplexor -----------------------------------------------------------
	 
	with op select
		w <=  
				multu_result(15 downto 0)		when "000", 
				mults_result(31 downto 16)		when "001",
				multu_result(31 downto 16)		when "010",
				divs_result							when "100",
				divu_result							when "101",
				x"DEAD"   	  						when others;
	-- -------------------------------------------------------------------------------------- 

	-- Flags --------------------------------------------------------------------------------
	div_zero <= '1' when (op = "100" or op = "101") and y = 0  else '0';
	-- --------------------------------------------------------------------------------------
END Structure;

-- OTHERS OPERATIONS UNIT
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY others_operations_unit IS
    PORT (x  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          y  	: IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			 op  	: IN STD_LOGIC_VECTOR(2 downto 0);
          w  	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END others_operations_unit;


ARCHITECTURE Structure OF others_operations_unit IS
	
BEGIN
	-- Unit Operation multiplexor -----------------------------------------------------------
	 
	with op select
		w <=  
				((15 downto 8 => y(7)) & y(7 downto 0))	when "000", -- MOVI
				(y(7 downto 0) & x(7 downto 0))				when "001", -- MOVHI
				x														when "010", -- PASS X
				x"DEAD"      when others;
	-- --------------------------------------------------------------------------------------  
END Structure;