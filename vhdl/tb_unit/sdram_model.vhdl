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
--library verilog;
--use verilog.vl_types.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_model is
	port(
		-- SDRAM interface
		ramClk_in  : in    std_logic;
		ramCmd_in  : in    std_logic_vector(2 downto 0);
		ramBank_in : in    std_logic_vector(1 downto 0);
		ramAddr_in : in    std_logic_vector(11 downto 0);
		ramData_io : inout std_logic_vector(15 downto 0)
	);
end entity;
