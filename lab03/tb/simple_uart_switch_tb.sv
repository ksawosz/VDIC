/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

 History:
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge bfm.clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */

module top;
    switch_bfm bfm();
    switch_tbgen tbgen_i (bfm);
    switch_coverage coverage_i (bfm);
    switch_scoreboard scoreboard_i(bfm);
    
    simple_switch_uart DUT (
        .clk(bfm.clk), .rst_n(bfm.rst_n),
        .sin(bfm.sin), .prog(bfm.prog), .sout0(bfm.sout0),
        .sout1(bfm.sout1));

endmodule : top
    