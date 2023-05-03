module gpioemu(n_reset,                 //magistrala z CPU
    saddress[15:0], srd, swr, 
    sdata_in[31:0], sdata_out[31:0], 
    gpio_in[31:0], gpio_latch,          //styk z GPIO - in
    gpio_out[31:0],                     //styk z GPIO = out
    clk,                                //sygnaly opcjonalne - zegar 0.1KHz
    gpio_in_s_insp[31:0]);              //sygnaly testowe

	input           clk;
	input           n_reset;

	input [15:0]    saddress;       //magistrala - adres
	input           srd;            //odczyt przez CPU z mag. danych
	input           swr;            //zapis przez CPU do mag. danych 
	input [31:0]    sdata_in;       //magistrala wejsciowa CPU
	output[31:0]    sdata_out;      //magistrala wyjsciowa z CPU
	reg [31:0]      sdata_out_s;    //stan magistrali danych - wyjscie

	input [31:0]    gpio_in;        //dane z peryferii wejscie do modulu 
	reg [31:0]      gpio_in_s;      //stan peryferii wyjsciowych (do polaczenia z np.: klawiszami)
	input           gpio_latch;     //zapis danych na gpio_in
	output[31:0]    gpio_in_s_insp; //debuging

	output[31:0]    gpio_out;       //dane wyjsciowe do peryferii (laczone np.: z LED'ami)
	reg [31:0]      gpio_out_s;     //stan peryferii wejsciowych (stan wyjsc - ale nie laczony z np.: LED'ami)


// ============================================
    reg unsigned [48:0] result;
    reg unsigned[23:0] A2;
    reg unsigned[23:0] A1;
	reg unsigned[32:0] W;
	reg unsigned[23:0] L;
	reg unsigned[1:0] B;
    reg unsigned[15:0] operation_count;
    reg unsigned[3:0] state;
    reg unsigned[23:0] ones_count;
    reg unsigned[23:0] tmp_ones_count;
	
	

    localparam IDLE = 0,
              MULT = 1,
              COUNT_ONES = 2,
              DONE = 3;
			  
			  

    always @(negedge n_reset)
		begin	//zapis
        
			gpio_in_s <= 0;
            gpio_out_s <= 0;
			sdata_out_s <= 0;
            state <= IDLE;
            result <= 0;
            ones_count <= 0;
            tmp_ones_count <= 0;
            operation_count <= 0;
            ready <= 1'b0;
            A1 <= 0;
            A2 <= 0;
			L <= 0;
			B <= 00
			
        end 
		
	always @(posedge swr)
	
	begin
			if(saddress == 16'h3A0 && sdata_out_s[0]) // uruchomienie pracy modułu ??? czy potrzebna ta przypiska
				begin
					ready <= 0;
					state <= IDLE;
					gpio_out_s <= gpio_out_s + 1; //licznik
				end
			if(saddress == 16'h37F) // adres pierwszego argumentu
				A1 <= sdata_in;
			else if(saddress == 16'h37F) // adres drugiego argumentu
				A2 <= sdata_in;
		end
	
	always @(posedge srd) // gdy będzie odczyt przez CPU
		begin
			if(saddress == 16'h390) // adres do odczytu
				begin
					if(ready==1)
						sdata_out_s <= result;
				end
			else if (saddress == 16'h3A0) // adres dla statusu
			sdata_out_s <= {30'b0,B};
				
			else if (saddress == 16'h398) // adres dla statusu
				sdata_out_s <= L;					//????
			else // każdy inny adres powinien dać 0
				sdata_out_s <= 0;
		end
	
	
	
		begin
            case (state)
                IDLE: begin
                    result <= 0;
                    wA2 <= A2;
                    wA1 <= A1;
                    tmp_ones_count <= 0;
                    if (ready) begin
                        state <= MULT;
                    end
                end
   MULT: begin
    for (integer i = 0; i < 24; i = i + 1) begin
        if (wA2[i]) begin
            result <= result + ({24'b0,wA1} << i);
        end
		
    end
    state <= COUNT_ONES;
end 
                COUNT_ONES: begin
                    for (integer i = 0; i < 32; i++) begin
                       if (result[i] == 1) begin
						tmp_ones_count <= tmp_ones_count + 1;
						end
                    end
                    ones_count <= tmp_ones_count;
                    state <= DONE;
                end
                DONE: begin
				
				if (swr && saddress == 16'h390) begin // write B
				B <= sdata_in;
				end else if (swr && saddress == 16'h398) begin // write L
				L <= sdata_in;
				end else if (swr && saddress == 16'h870) begin // write W
				W <= sdata_in;													   
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
	
	
	
	

       assign gpio_out = {24'h0, gpio_out_s[7:0]};// licznik ma być tylko 8 bitowy
    assign gpio_in_s_insp = gpio_in_s;
    assign sdata_out = sdata_out_s;
endmodule
