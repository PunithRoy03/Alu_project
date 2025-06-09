`include "define.vh"
module Alu_rtl#(parameter width = 8,parameter N = 4)
(INP_VALID,OPA,OPB,CIN,CLK,RST,CMD,CE,MODE,COUT,OFLOW,RES,G,E,L,ERR);

`ifdef MUL
  localparam width_out = 2*width;
`else
  localparam width_out = width;
`endif

/*Input output port declaration*/
  input [1:0] INP_VALID;
  input [width-1:0] OPA,OPB;
  input CLK,RST,CE,MODE,CIN;
  input [N - 1:0] CMD;
  output reg [width_out:0] RES;
  output reg COUT ;
  output reg OFLOW;
  output reg G ;
  output reg E ;
  output reg L ;
  output reg ERR;

localparam shift = $clog2(width);
/*Temporary register declaration*/
reg [width-1:0] opa, opb;
reg [N-1:0] cmd;
reg [1:0] inp_valid;
reg signed [(width_out):0] sign_res;
reg [(width_out):0] res,res_delay;
reg mode,cin,cout,oflow,g,l,e,err;
reg [shift-1:0] rotate;

always@(posedge CLK or posedge RST) begin
    if(RST) begin
       opa <= 0;
       opb <= 0;
       cmd <= 0;
       inp_valid <= 0;
       mode <= 0;
       cin <= 0;
    end

    else if(CE) begin
       opa <=OPA;
       opb <= OPB;
       cmd <= CMD;
       inp_valid <= INP_VALID;
       mode <= MODE;
       cin <= CIN;
      end
    else  begin
       opa <= 0;
       opb <= 0;
       cmd <= 0;
       inp_valid <= 0;
       mode <= 0;
       cin <= 0;
    end

  end

always @(*) begin
  res = 0;
  cout = 0;
  oflow = 0;
  g = 0;
  l = 0;
  e = 0;
  err = 0;
  res = 0;

   if (mode) begin
     case(inp_valid)
  2'b11: begin
  case (cmd)
    `ADD: begin
      res = opa + opb;
      cout = res[width_out];
    end
    `SUB: begin
      res = opa - opb;
      oflow = (opa < opb);
    end
    `ADD_CIN: begin
      res = opa + opb + cin;
      cout = res[width_out];
    end
    `SUB_CIN: begin
      res = opa - opb - cin;
      oflow = (opa < (opb + cin));
    end
    `CMP: begin
      if (opa == opb) begin
        e = 1;
        g = 0;
        l = 0;
      end
      else if (opa > opb) begin
        e = 0;
        g = 1;
        l = 0;
      end
      else begin
        e = 0;
        g = 0;
        l = 1;
      end
    end
    `INC_MUL:   res = (opa + 1) * (opb + 1);
    `SHIFT_MUL: res = (opa << 1) * opb;
    `SIGN_ADD: begin
                sign_res = $signed(opa)+$signed(opb);
                res = sign_res;
                oflow = ($signed(opa) > 0 && $signed(opb) > 0 && sign_res < 0 || $signed(opa) < 0  && $signed(opb) < 0  && sign_res >= 0 )? 1 : 0 ;
                cout =($signed(opa) > 0 && $signed(opb) > 0 && sign_res < 0 || $signed(opa) < 0  && $signed(opb) < 0  && sign_res >= 0 )? 1 : 0 ;
                if($signed(opa) == $signed(opb)) begin
                        e = 1'b1;
                        g = 1'b0;
                        l = 1'b0;
                      end
                if($signed(opa) < $signed(opb)) begin
                        e = 1'b0;
                        g = 1'b0;
                        l = 1'b1;
                      end
                else begin
                        e = 1'b0;
                        g = 1'b1;
                        l = 1'b0;
                      end
        end
    `SIGN_SUB: begin
                sign_res = $signed(opa) - $signed(opb);
                res = sign_res;
                oflow = ($signed(opa) > 0 && $signed(opb) > 0 && sign_res < 0 || $signed(opa) < 0  && $signed(opb) < 0  && sign_res >= 0 )? 1 : 0 ;
                cout =($signed(opa) > 0 && $signed(opb) > 0 && sign_res < 0 || $signed(opa) < 0  && $signed(opb) < 0  && sign_res >= 0 )? 1 : 0 ;
                if($signed(opa) == $signed(opb)) begin
                        e = 1'b1;
                        g = 1'b0;
                        l = 1'b0;
                      end
                if($signed(opa) < $signed(opb)) begin
                        e = 1'b0;
                        g = 1'b0;
                        l = 1'b1;
                      end
                else begin
                        e = 1'b0;
                        g = 1'b1;
                        l = 1'b0;
                      end
        end
    default: begin
                err = 1;
                res = 0;
             end
  endcase
end
 2'b10: begin
   case (cmd)
     `INC_A: begin
      res  = opa + 1;
      cout = res[width_out];
     end
     `DEC_A: begin
      res = opa - 1;
      oflow  = res[width_out];
    end
    default: begin
                err = 1;
                res = 0;
             end
  endcase
end
 2'b01: begin
   case (cmd)
     `INC_B: begin
       res  = opb + 1;
       cout = res[width_out];
    end
    `DEC_B: begin
      res = opb - 1;
      oflow  = res[width_out];
    end
    default: begin
                err = 1;
                res = 0;
             end
  endcase
end
        default: begin
                err = 1;
                res = 0;
             end
endcase
end

else begin
case (inp_valid)
  2'b10: begin
    case (cmd)
      `NOT_A:   res = ~opa;
      `SHR1_A:  res = opa >> 1;
      `SHL1_A:  res = opa << 1;
      default: begin
                err = 1;
                res = 0;
             end
    endcase
  end
  2'b01: begin
    case (cmd)
      `NOT_B:   res = ~opb;
      `SHR1_B:  res = opb >> 1;
      `SHL1_B:  res = opb << 1;
      default: begin
                err = 1;
                res = 0;
             end
    endcase
  end
  2'b11: begin
    case (cmd)
      `AND:   res = opa & opb;
      `NAND:  res = ~(opa & opb);
      `OR:    res = opa | opb;
      `NOR:   res = ~(opa | opb);
      `XOR:   res = opa ^ opb;
      `XNOR:  res = ~(opa ^ opb);
      `ROL_A_B: begin
        if (opb[width-1:shift+1])
          err = 1;
        else begin
          rotate = opb[shift-1:0];
          res = (opa << rotate) | (opa >> (width - rotate));
        end
      end
      `ROR_A_B: begin
        if (opb[width-1:shift+1])
          err = 1;
        else begin
          rotate = opb[shift-1:0];
          res = (opa >> rotate) | (opa << (width - rotate));
        end
      end
      default: begin
                err = 1;
                res = 0;
             end
    endcase
  end
  default: begin
                err = 1;
                res = 0;
             end
endcase
end
end
always @(posedge CLK or posedge RST) begin
  if (RST) begin
    RES <= {width_out{1'b0}};
    COUT <= 0;
    OFLOW <= 0;
    G <= 0;
    L <= 0;
    E <= 0;
    ERR <= 0;
  end else if (CE) begin
    if ((cmd == `INC_MUL  || cmd == `SHIFT_MUL) && mode) begin
      res_delay <= res;
      RES <= res_delay;
    end
    else
        RES <= res;
    COUT <= cout;
    OFLOW <= oflow;
    G <= g;
    L <= l;
    E <= e;
    ERR <= err;
  end
 else begin
    RES <= {width_out{1'b0}};
    COUT <= 0;
    OFLOW <= 0;
    G <= 0;
    L <= 0;
    E <= 0;
    ERR <= 0;
  end
end
endmodule
