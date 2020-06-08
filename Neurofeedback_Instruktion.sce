# Instructions:
# Instructions were saved as png-Files in the folder Stimuli/Instruktion/
# Subject can switch forward and backward through the instruction slides
# After Trial 9 there is an example experiment

default_background_color = 125,125,125;
default_text_color = 0, 0, 0;
default_text_align = align_center;
default_font_size = 52;
default_font = "Arial";

active_buttons = 3;   
button_codes = 1,2,3;
default_all_responses = true;

response_logging = log_all;
response_matching = simple_matching;

begin;

array {
	LOOP $pic_nr '2';
		$pic = '$pic_nr + 1';
		bitmap { filename = "Folie$pic.png"; 
					preload = true;
					width = 1400;
				scale_factor = scale_to_width;
				};
	ENDLOOP;
} instr_array;

array {
	LOOP $pic_nr '6';
		$pic = '$pic_nr + 1';
		bitmap { filename = "feedback\\feedback$pic.png"; preload = true;};
	ENDLOOP;
} bar_array;

array {
	text { caption = "Regulieren"; description = "1"; font_size=48;} reg;
	text { caption = "Betrachten"; description = "2"; font_size=48;} bel;
} demo_instr_array;

array {
	bitmap { filename = "example1.jpg"; }placeholder; 
	bitmap { filename = "example2.jpg"; };
} demo_bit_array;

text { caption = "+"; description = "5"; font_size=48;} plus;
bitmap { filename = "Feedback\\grey.png"; } bar;

trial {                                  
    trial_type = first_response;     
		picture { bitmap { filename = "Folie1.png"; }; x=0; y=0; } instr_pic;
		time = 0;
		duration = response;
} instr_trial; 

trial {
	trial_type = fixed;
	trial_duration = 2000;
	picture { text reg; x=0; y=0;} demo_instr_pic;
	time=0;
} demo_instr_trial;

trial {
	trial_type = fixed;
	trial_duration=1000;
	picture { bitmap placeholder; x = 0; y = 0; bitmap bar; x = -596; y = 0; bitmap bar; x = 596; y = 0;} demo_pic;
	time = 0;
} demo_trial;

trial {
	trial_type = fixed;
	trial_duration=6000;
	picture { text plus; x=0; y=0; };
} rest;

begin_pcl;

int slide_nr=1;
int nr_of_instructionslides=2;
int goforwardorbackward;

loop until slide_nr>nr_of_instructionslides begin
	
	instr_pic.set_part(1,instr_array[slide_nr]);
	
	goforwardorbackward=0;
	
	instr_trial.present();
	if response_manager.last_response()==1 then
		goforwardorbackward=-1;
	elseif response_manager.last_response()==2 then
		goforwardorbackward=1;
	end;
	
	if (slide_nr==1 && goforwardorbackward==-1) || slide_nr>nr_of_instructionslides then
	else
		slide_nr=slide_nr+goforwardorbackward;
	end;
	
end;

array <int> bar_arrangement[11] = {3,4,5,6,5,4,3,2,1,2,3};

loop int nr_demo_trial=1 until nr_demo_trial>2 begin
	rest.present();
	demo_instr_pic.set_part(1,demo_instr_array[nr_demo_trial]);
	demo_pic.set_part(1,demo_bit_array[nr_demo_trial]);
	demo_instr_trial.present();
	if nr_demo_trial==1 then 
		loop int nr_TR=1 until nr_TR>11 begin
		demo_pic.set_part(2,bar_array[bar_arrangement[nr_TR]]);
		demo_pic.set_part(3,bar_array[bar_arrangement[nr_TR]]);
		demo_trial.present();
		nr_TR=nr_TR+1;
		end;
	else 
		loop int nr_TR=1 until nr_TR>11 begin
		demo_pic.set_part(2,bar);
		demo_pic.set_part(3,bar);
		demo_trial.present();
		nr_TR=nr_TR+1;
		end;
	end;
	nr_demo_trial=nr_demo_trial+1;
end;
