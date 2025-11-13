package switch_tb_pkg;
  
    typedef struct packed {
        logic [7:0] addr;
        bit          port;
        bit          is_prog;
        bit          is_err;
    } pkt_t;
  
    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color_t;
  
  endpackage : switch_tb_pkg
  