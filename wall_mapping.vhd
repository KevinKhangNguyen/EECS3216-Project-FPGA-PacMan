library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package wall_mapping is
  subtype mapping_int is integer;
  type up_array is array (0 to 29) of mapping_int;
  type down_array is array (0 to 29) of mapping_int;
  type left_array is array (0 to 29) of mapping_int;
  type right_array is array (0 to 29) of mapping_int;
  
  constant up_mapping : up_array := (1, 1, 1, 1, 1, 1, 
												  0, 1, 0, 0, 1, 0, 
												  0, 0, 1, 1, 0, 0,
												  0, 0, 1, 1, 0, 0,
												  0, 1, 0, 0, 1, 0);
  constant down_mapping : down_array := (0, 1, 0, 0, 1, 0,
													 0, 0, 1, 1, 0, 0,
													 0, 0, 1, 1, 0, 0,
													 0, 1, 0, 0, 1, 0,
													 1, 1, 1, 1, 1, 1);
  constant left_mapping : left_array := (1, 0, 0, 1, 0, 0,
													 1, 1, 0, 0, 0, 1,
													 1, 0, 0, 0, 0, 0,
													 1, 1, 0, 0, 0, 1,
													 1, 0, 0, 1, 0, 0);
  constant right_mapping : right_array := (0, 0, 1, 0, 0, 1,
													  1, 0, 0, 0, 1, 1,
													  0, 0, 0, 0, 0, 1,
													  1, 0, 0, 0, 1, 1,
													  0, 0, 1, 0, 0, 1);
  
end Wall_Mapping;

package body wall_mapping is
end wall_mapping;