library verilog;
use verilog.vl_types.all;
entity alu is
    port(
        clk             : in     vl_logic;
        rstN            : in     vl_logic;
        start           : in     vl_logic;
        op              : in     vl_logic_vector(1 downto 0);
        a               : in     vl_logic_vector(15 downto 0);
        b               : in     vl_logic_vector(15 downto 0);
        result          : out    vl_logic_vector(15 downto 0);
        done            : out    vl_logic
    );
end alu;
