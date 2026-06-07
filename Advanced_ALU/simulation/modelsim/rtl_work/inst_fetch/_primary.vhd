library verilog;
use verilog.vl_types.all;
entity inst_fetch is
    generic(
        DEPTH           : integer := 32;
        A_LEN           : integer := 5
    );
    port(
        clk             : in     vl_logic;
        rstN            : in     vl_logic;
        stall           : in     vl_logic;
        op              : out    vl_logic_vector(2 downto 0);
        waddr           : out    vl_logic_vector;
        raddr1          : out    vl_logic_vector;
        raddr2          : out    vl_logic_vector;
        pc_out          : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of DEPTH : constant is 1;
    attribute mti_svvh_generic_type of A_LEN : constant is 1;
end inst_fetch;
