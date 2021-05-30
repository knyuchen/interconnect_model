`define SL_MULTI_MASTER

`define SL_DATA_WIDTH    32
`define SL_ADDR_WIDTH    16
`ifdef SL_MULTI_MASTER
   `define SL_ID_WIDTH       2
`endif

typedef struct packed {
   logic                   wen;
   logic [`SL_ADDR_WIDTH]  waddr;
   logic [`SL_DATA_WIDTH]  wdata;
`ifdef SL_MULTI_MASTER
   logic [`SL_ID_WIDTH]    wid;
`endif
} SL_WREQ; 

typedef struct packed {
   logic                   ren;
   logic [`SL_ADDR_WIDTH]  raddr;
`ifdef SL_MULTI_MASTER
   logic [`SL_ID_WIDTH]    rid;
`endif
} SL_RREQ; 

typedef struct packed {
   logic                   rvalid;
   logic [`SL_DATA_WIDTH]  rdata;
`ifdef SL_MULTI_MASTER
   logic [`SL_ID_WIDTH]    rid;
`endif
} SL_RES;

typedef struct packed {
   SL_WREQ                 wreq;
   SL_RREQ                 rreq;
} SL_REQ; 
