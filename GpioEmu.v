//Opis GpioEmu komponent dla potrzeb SYKT/SYKOM
//Autor:            Aleksander Pruszkowski
//Data:             2021.04.01
//Data modyfikacji: 2021.04.23
//

/* verilator lint_off UNUSED */
/* verilator lint_off MULTIDRIVEN */

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
	reg unsigned[31:0] arg1;
	reg unsigned[31:0] arg2;
	reg unsigned[31:0] result;
	reg unsigned[3:0] state;
	reg done;

    always @(negedge n_reset)
        begin           
            gpio_in_s <= 0;
            gpio_out_s <= 0;
			sdata_out_s <= 0;
			arg1 <= 0;
			arg2 <= 0;
			result <= 0;
			done <= 0;
			state <= 3;
        end 
		
	always @(posedge swr) // gdy będzie zapis przez CPU
		begin
			if(saddress == 16'h810) // uruchomienie pracy modułu
				begin
					done <= 0;
					state <= 0;
					gpio_out_s <= gpio_out_s + 1; //licznik
				end
			if(saddress == 16'h820) // adres pierwszego argumentu
				arg1 <= sdata_in;
			else if(saddress == 16'h830) // adres drugiego argumentu
				arg2 <= sdata_in;
		end
	
		
	always @(posedge srd) // gdy będzie odczyt przez CPU
		begin
			if(saddress == 16'h840) // adres do odczytu
				begin
					if(done==1)
						sdata_out_s <= result;
				end
			else if (saddress == 16'h850) // adres dla statusu
				sdata_out_s <= {31'b0,done};
			else // każdy inny adres powinien dać 0
				sdata_out_s <= 0;
		end
		
	always @(posedge clk)begin
		case(state)
			0: begin				
					if (arg2 == 0) begin
						state <= 2;
					end else begin 
						state <= 1;
					end
				end
			1: begin					
				arg2 <= arg1 % arg2;
				arg1 <= arg2;
				state <= 0;
				end
			2: begin
				result <= arg1;
				done <= 1;
				state <= 3;
				end
			default: begin
				state <= 3;
			end
		endcase
	end
	

    assign gpio_out = {24'h0, gpio_out_s[7:0]};// licznik ma być tylko 8 bitowy
    assign gpio_in_s_insp = gpio_in_s;
    assign sdata_out = sdata_out_s;

endmodule
