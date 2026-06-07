library verilog;
use verilog.vl_types.all;
entity memory is
    generic(
        DEPTH           : integer := 32;
        A_LEN           : integer := 5
    );
    port(
        clk             : in     vl_logic;
        raddr1          : in     vl_logic_vector;
        raddr2          : in     vl_logic_vector;
        rdata1          : out    vl_logic_vector(15 downto 0);
        rdata2          : out    vl_logic_vector(15 downto 0);
        waddr           : in     vl_logic_vector;
        wdata           : in     vl_logic_vector(15 downto 0);
        wen             : in     vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of DEPTH : constant is 1;
    attribute mti_svvh_generic_type of A_LEN : constant is 1;
end memory;
