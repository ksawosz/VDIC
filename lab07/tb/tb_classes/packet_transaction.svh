class packet_transaction extends uvm_transaction;
    `uvm_object_utils(packet_transaction)

//------------------------------------------------------------------------------
// transaction variables
//------------------------------------------------------------------------------

    rand bit              rst_n;
    rand bit              prog;
    rand logic [10:0]             addr, data;
    rand bit              port;
    rand bit              is_err;

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

    constraint data_c {
        data dist {[8'b0:8'b01111111]:=1};
    }

//------------------------------------------------------------------------------
// transaction functions: do_copy, clone_me, do_compare, convert2string
//------------------------------------------------------------------------------

    function void do_copy(uvm_object rhs);
        packet_transaction copied_transaction_h;

        if(rhs == null)
            `uvm_fatal("PACKET TRANSACTION", "Tried to copy from a null pointer")

        super.do_copy(rhs); // copy all parent class data

        if(!$cast(copied_transaction_h,rhs))
            `uvm_fatal("PACKET TRANSACTION", "Tried to copy wrong type.")

        addr = copied_transaction_h.addr;
        data = copied_transaction_h.data;
        port = copied_transaction_h.port;
        prog = copied_transaction_h.prog;
        rst_n = copied_transaction_h.rst_n;
        is_err = copied_transaction_h.is_err;

    endfunction : do_copy


    function packet_transaction clone_me();
        
        packet_transaction clone;
        uvm_object tmp;

        tmp = this.clone();
        $cast(clone, tmp);
        return clone;
        
    endfunction : clone_me


    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        
        packet_transaction compared_transaction_h;
        bit same;

        if (rhs==null) `uvm_fatal("RANDOM TRANSACTION",
                "Tried to do comparison to a null pointer");

        if (!$cast(compared_transaction_h,rhs))
            same = 0;
        else
            same = super.do_compare(rhs, comparer) &&
            (compared_transaction_h.addr == addr) &&
            (compared_transaction_h.data == data) &&
            (compared_transaction_h.prog == prog);

        return same;
        
    endfunction : do_compare


    function string convert2string();
        string s;
        s = $sformatf("addr: %b  data: %b port: %b is_err: %b",
        addr, data, port, is_err);
        return s;
    endfunction : convert2string

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new (string name = "");
        super.new(name);
    endfunction : new

endclass : packet_transaction