--
-- Copyright (C) 2012 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library verilog;
use verilog.vl_types.all;

architecture behavioural of sdram_model is
begin
	-- Instantiate the SDRAM model for testing
	--sdram: entity work.sdram
	--	port map(
	--		clk  => ramClk_in,
	--		csb  => '0',
	--		cke  => '1',
	--		rasb => ramCmd_in(2),
	--		casb => ramCmd_in(1),
	--		web  => ramCmd_in(0),
	--		ba   => ramBank_in,
	--		ad   => ramAddr_in,
	--		dqm  => "00",
	--		dqi  => ramData_io
	--	);
	sdram: entity work.mt48lc8m16a2
		port map(
			Clk  => ramClk_in,
			Cs_n  => Su0,
			Cke  => Su1,
			Ras_n => ramCmd_in(2),
			Cas_n => ramCmd_in(1),
			We_n  => ramCmd_in(0),
			Ba   => ramBank_in,
			Addr   => ramAddr_in,
			Dqm  => (others => Su0),
			Dq  => ramData_io
		);
end architecture;
