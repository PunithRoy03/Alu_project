// defines
`include "Alu_rtl.v"
`include "define.vh"
`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 160

// Test bench for ALU design

module test_bench_alu();
        parameter width = 8, N = 4;
        `ifdef MUL
                localparam WIDTH = 2*width; // operation when multiplication is involved !!
        `else
                localparam WIDTH = width + 1; // usual operation
        `endif

        localparam packet_size = 8+2+(2*width)+N+1+1+1+WIDTH+1+3+1+1;

        reg [packet_size-1:0] curr_test_case = 0;
        reg [packet_size-1:0] stimulus_mem [0:`no_of_testcase-1];
        reg [packet_size+WIDTH+6:0] response_packet;

//Decl for giving the Stimulus
        integer i,j;
        reg CLK,RST,CE;
        reg [1:0] INP_VALID; //inputs
        event fetch_stimulus;
        reg [width-1:0]OPA,OPB; //inputs
        reg [N-1:0]CMD; //inputs
        reg MODE,CIN; //inputs
        reg [7:0] Feature_ID;
        reg [2:0] Comparison_EGL;  //expected output
        reg [WIDTH-1:0] Expected_RES; //expected output data
        reg err,cout,ov;

//Decl to Cop UP the DUT OPERATION
        wire  [WIDTH-1:0] RES;
        wire ERR,OFLOW,COUT;
        wire [2:0]EGL;
        wire [WIDTH+1+3+1:0] expected_data;
        reg [WIDTH+1+3+1:0]exact_data;

//READ DATA FROM THE TEXT VECTOR FILE
        task read_stimulus();
                begin
                #10 $readmemb ("stimulus.txt",stimulus_mem);
               end
        endtask

   Alu_rtl inst_dut (.OPA(OPA),.OPB(OPB),.CIN(CIN),.CLK(CLK),.INP_VALID(INP_VALID),.CMD(CMD),.CE(CE),.MODE(MODE),.COUT(COUT),.OFLOW(OFLOW),.RES(RES),.G(EGL[1]),.E(EGL[2]),.L(EGL[0]),.ERR(ERR),.RST(RST));

//STIMULUS GENERATOR

integer stim_mem_ptr = 0,stim_stimulus_mem_ptr = 0,fid =0 , pointer =0 ;

        always@(fetch_stimulus)
                begin
                        curr_test_case=stimulus_mem[stim_mem_ptr];
                        $display ("stimulus_mem data = %0b \n",stimulus_mem[stim_mem_ptr]);
                        $display ("packet data = %0b \n",curr_test_case);
                        stim_mem_ptr=stim_mem_ptr+1;
                end

//INITIALIZING CLOCK
        initial
                begin CLK=0;
                        forever #60 CLK=~CLK;
                end

//DRIVER MODULE
        task driver ();
                begin
                  ->fetch_stimulus;
                  @(posedge CLK);
                  Feature_ID    =curr_test_case[((2*width)+N+WIDTH+18):((2*width)+N+WIDTH+11)];
                  INP_VALID =curr_test_case[((2*width)+N+WIDTH+9+1):((2*width)+N+WIDTH+9)];
                  OPA           =curr_test_case[((2*width)+N+WIDTH+8):width+N+WIDTH+9];
                  OPB           =curr_test_case[width+N+WIDTH+8:N+WIDTH+9];
                  CMD           =curr_test_case[N+WIDTH+8:WIDTH+9];
                  CIN           =curr_test_case[WIDTH+5+3];
                  CE            = curr_test_case[WIDTH+5+2];
                  MODE          =curr_test_case[WIDTH+5+1];
                  Expected_RES =curr_test_case[WIDTH+5:6];
                  cout =curr_test_case[5];
                  Comparison_EGL=curr_test_case[4:2];
                  ov =curr_test_case[1];
                  err           =curr_test_case[0];
                 $display("At time (%0t), Feature_ID = %8b, INP_VALID = %2b, OPA = %8b, OPB = %8b, CMD = %4b, CIN = %1b, CE = %1b, MODE = %1b, expected_result = %b, cout = %1b, Comparison_EGL = %3b, ov = %1b, err = %1b",$time,Feature_ID,INP_VALID,OPA,OPB,CMD,CIN,CE,MODE, Expected_RES,cout,Comparison_EGL,ov,err);
                end
        endtask

//GLOBAL DUT RESET
        task dut_reset ();
                begin
                CE=1;
                #10 RST=1;
                #20 RST=0;
                end
        endtask

//GLOBAL INITIALIZATION
        task global_init ();
                begin
                curr_test_case=0;
                response_packet=0;
                stim_mem_ptr=0;
                end
        endtask


//MONITOR PROGRAM


task monitor ();
                begin
                `ifdef MUL
                        repeat(4) @(posedge CLK);
                `else
                        repeat(3) @(posedge CLK);
                `endif
                #5 response_packet[packet_size-1:0]=curr_test_case;
                response_packet[packet_size]    =ERR;
                response_packet[packet_size+1]  =OFLOW;
                response_packet[(packet_size+2)+2:packet_size+2]        ={EGL};
                response_packet[packet_size+5]  =COUT;
                response_packet[(packet_size+6)+WIDTH-1:packet_size+6]  =RES;
                //response_packet[(packet_size+6)+WIDTH]        =0; // Reserved Bit
                $display("Monitor: At time (%0t), RES = %b, COUT = %1b, EGL = %3b, OFLOW = %1b, ERR = %1b",$time,RES,COUT,{EGL},OFLOW,ERR);
                exact_data ={RES,COUT,{EGL},OFLOW,ERR};
                end
        endtask

assign expected_data = {Expected_RES,cout,Comparison_EGL,ov,err};

//SCORE BOARD PROGRAM TO CHECK THE DUT OP WITH EXPECTD OP

   reg [40:0] scb_stimulus_mem [0:`no_of_testcase-1];

task score_board();
   reg [WIDTH+5:0] expected_res;
   reg [7:0] feature_id;
   reg [WIDTH+5:0] response_data;
                begin
                #5;
                feature_id = curr_test_case[((2*width)+N+WIDTH+18):((2*width)+N+WIDTH+11)];
                expected_res = curr_test_case[WIDTH+5:6];
                response_data = response_packet[packet_size+WIDTH+5:packet_size];
                $display("expected result = %b ,response data = %b",expected_data,exact_data);
                 if(expected_data === exact_data)
                     scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`PASS};
                 else
                     scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`FAIL};
            stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
        end
endtask


//Generating the report `no_of_testcase-1
task gen_report;
integer file_id,pointer;
reg [packet_size-8:0] status;
                begin
                   file_id = $fopen("results.txt", "w");
                   for(pointer = 0; pointer <= `no_of_testcase-1 ; pointer = pointer+1 )
                   begin
                     status = scb_stimulus_mem[pointer];
                     if(status[0])
                       $fdisplay(file_id, "Feature ID %8b : PASS", status[packet_size-9 -: 8]);
                     else
                       $fdisplay(file_id, "Feature ID %8b : FAIL", status[packet_size-9 -: 8]);
                   end
                end
endtask


initial
               begin
                #10;
                global_init();
                dut_reset();
                read_stimulus();
                for(j=0;j<=`no_of_testcase-1;j=j+1)
                begin
                        fork
                          driver();
                          monitor();
                         join
                        score_board();
               end

               gen_report();
               $fclose(fid);
               #300 $finish();
               end
endmodule
