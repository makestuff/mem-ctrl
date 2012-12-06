library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rom_data_pkg is
	type RomType is array (0 to 255) of std_logic_vector(15 downto 0);
	constant INIT_DATA : RomType := (
		x"8ca9", x"a2b6", x"426a", x"85c0", x"ef79", x"a7a1", x"9fc1", x"3287",
		x"3e92", x"0a60", x"8b0c", x"1427", x"9cc8", x"bdbf", x"c6b5", x"2fb0",
		x"61ae", x"d116", x"a38f", x"5f25", x"7f4c", x"9ad3", x"2c71", x"81e7",
		x"8342", x"73f8", x"7f85", x"06f5", x"dc1b", x"35b5", x"f11a", x"bbcc",
		x"566b", x"d1bc", x"346e", x"1912", x"f03b", x"7847", x"724e", x"8329",
		x"35fb", x"abb7", x"91ad", x"c510", x"b29e", x"30c0", x"5d58", x"6861",
		x"63f5", x"d8d4", x"731b", x"e10d", x"f6b6", x"13db", x"7e99", x"bad3",
		x"0f7f", x"1b7b", x"1d91", x"5a44", x"8c1a", x"49b2", x"f049", x"41b4",
		x"5f2d", x"ae88", x"1b55", x"7d3e", x"1ee6", x"3fbe", x"5882", x"43af",
		x"3d87", x"3e2e", x"1594", x"d546", x"a7b2", x"b61b", x"cc78", x"aafc",
		x"e5c6", x"65bc", x"5036", x"527d", x"3326", x"6381", x"2920", x"161d",
		x"7900", x"0aa8", x"9910", x"e84c", x"517e", x"f76c", x"b84c", x"16e1",
		x"df5a", x"8df9", x"2342", x"da58", x"bedf", x"c3eb", x"b6e7", x"9a25",
		x"b13e", x"1939", x"addd", x"1cd5", x"1d02", x"11ed", x"fe93", x"bb08",
		x"e79d", x"4093", x"e3fc", x"1048", x"3f00", x"8bd9", x"df7f", x"b8ae",
		x"9c65", x"178a", x"99eb", x"bb45", x"ca90", x"1d0a", x"0194", x"db92",
		x"8668", x"2593", x"c15a", x"04a7", x"84bf", x"2cae", x"05c6", x"ac6b",
		x"a400", x"07c7", x"3cd7", x"9bcd", x"9579", x"be03", x"2902", x"4863",
		x"07b6", x"81bb", x"1339", x"273c", x"ae63", x"74b7", x"49a8", x"7cca",
		x"dd9b", x"b5f8", x"fd0c", x"63fb", x"5902", x"16f3", x"69d9", x"aea4",
		x"30e8", x"27b8", x"e722", x"2c4c", x"531a", x"3923", x"44a6", x"48da",
		x"0d6d", x"c12f", x"d7fc", x"e4f1", x"e2b2", x"c2f2", x"0573", x"c055",
		x"05c0", x"c645", x"40e6", x"1003", x"d521", x"76c8", x"e1e3", x"5286",
		x"89b5", x"b3bc", x"455e", x"3870", x"41f1", x"957e", x"d3fd", x"161b",
		x"1b47", x"7169", x"1e82", x"292a", x"2c81", x"b998", x"a20d", x"861d",
		x"921f", x"87fb", x"435a", x"3aa9", x"77ba", x"837a", x"231a", x"44a4",
		x"48b1", x"fadd", x"2db6", x"7a76", x"6667", x"8f42", x"5541", x"93d0",
		x"7557", x"a74e", x"2031", x"6bb9", x"d6a1", x"b363", x"b6c1", x"1c33",
		x"43f8", x"d53c", x"5978", x"bf53", x"79d7", x"fead", x"2701", x"bb61",
		x"7ecc", x"b1c4", x"15ad", x"b37e", x"bd58", x"31f6", x"fb25", x"1b6b",
		x"bbd7", x"ead9", x"8558", x"ec5d", x"9534", x"8135", x"0ea8", x"2f21",
		x"9487", x"e12a", x"4d24", x"b8f1", x"7147", x"25e9", x"b78f", x"002a"
	);
end package;
