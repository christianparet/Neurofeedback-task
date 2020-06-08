pcl_file = "Neurofeedback_20200608.pcl";
response_matching = simple_matching;

active_buttons = 3;   
button_codes = 1,2,3;
default_all_responses = true;
response_port_output = false;
pulse_width = 20;

#scenario_type = fMRI_emulation;
scenario_type = fMRI;
pulse_code = 23;
scan_period=2000;
pulses_per_scan = 1;

default_background_color = 75,75,75;
default_text_color = 255,255,255;
default_text_align = align_center;
default_font = "Arial";
default_font_size = 0.8; # with definition of screen parameters, font size is relative to user defined units

screen_width_distance = 16; 
screen_height_distance = 11;
max_y = 5.5;

begin;

###########################################
###             Stimulation             ###
###########################################

$pics = 28 ;

array {
LOOP $pic_nr '$pics';
	$pic = '$pic_nr + 140';
	bitmap { filename = "pics\\pic$pic.jpg"; 
				preload = true;
				width = 12;
				scale_factor = scale_to_width;
			};
ENDLOOP;
} pic_bmps;

array {
LOOP $bar_nr 9;
	$bar = '$bar_nr + 1';
	bitmap { filename = "feedback$bar.png"; 
				preload = true;
				width = 2;
				scale_factor = scale_to_width;
			};
ENDLOOP;
} bars;

bitmap { filename = "pics\\pic1.jpg"; preload = true;} placeholder;
#bitmap { filename = "regulate.png"; 
#			alpha = -1; 
#			preload = true;
#			width = 2;
#			scale_factor = scale_to_width;
#		} regulate_bmp;
#bitmap { filename = "view.png"; 
#			alpha = -1; 
#			preload = true;
#			width = 2;
#			scale_factor = scale_to_width;
#		} view_bmp;

text { caption = "Regulieren"; description = "REGULATE_instruct"; } regulate_text;
text { caption = "Betrachten"; description = "VIEW_instruct"; } view_text;

bitmap { filename = "grey.png"; 
			alpha = -1; 
			preload = true;
			width = 2;
			scale_factor = scale_to_width;
		} bar_bmp;
text { caption = "+"; description = "5"; } plus;
text { caption = "Ende"; description = "end_now"; } end_text;

trial {
	trial_type = fixed;
	picture { text { caption = "Gleich geht's los"; description = "prepare"; }; x = 0; y = 0; };
	code = "prepare";
	duration = next_picture;
} instruction_trial;

trial {
	trial_type = fixed;
   stimulus_event {
      picture { text plus; x = 0; y = 0; };
      time = 0;
		duration = next_picture;
		code = "rest";
   } rest_event;
} rest_trial;

trial {
	trial_type = fixed;
   stimulus_event {
      picture { text regulate_text; x = 0; y = 0; };
      time = 0;
		duration = next_picture;
		code = "DOWN_instruct";
   } regulate_instruct_event;
} regulate_instruct_trial;

trial {
	trial_type = fixed;
   stimulus_event {
      picture { text view_text; x = 0; y = 0; };
      time = 0;
		duration = next_picture;
		code = "VIEW_instruct";
   } view_instruct_event;
} view_instruct_trial;

trial {
	trial_type = fixed;    
	picture { text end_text; x=0; y=0; };
	time = 0;
	code="end_experiment";
	duration = 2000;
} end_trial;

###########################################
###              Thermometer            ###
###########################################

trial {
	trial_type = fixed;
   stimulus_event {
      picture { 
			bitmap placeholder; x = 0; y = 0;
			bitmap bar_bmp; x = -7; y = 0; 
			bitmap bar_bmp; x = 7; y = 0;
		} feedback_pic;
      time = 0;
		duration = next_picture;
   } feedback_event;
} feedback_trial;

###########################################
###                Rating               ###
###########################################

array {
LOOP $pic 10;
	bitmap { filename = "scale$pic.jpg"; 
				preload = true;
				width = 12;
				scale_factor = scale_to_width;
			};
ENDLOOP;
} scale;

bitmap { filename = "scale0.jpg"; 
				preload = true;
				width = 10;
				scale_factor = scale_to_width;
			} scale_default_bmp;
bitmap { filename = "range_reg.jpg"; 
				preload = true;
				width = 12;
				scale_factor = scale_to_width;
			} range_reg_bmp;
bitmap { filename = "reg_erfolg.jpg"; 
				preload = true;
				width = 12;
				scale_factor = scale_to_width;
			} reg_erfolg_bmp;
text { caption = "Bestätigen Sie mit der unteren Taste."; font_size = 0.4;} bestaetigen;

trial {                                  
   trial_type = first_response; 
	stimulus_event {
		picture { bitmap reg_erfolg_bmp; x=0; y=0; bitmap scale_default_bmp; x=0; y=0; bitmap range_reg_bmp; x = 0; y = -1; text bestaetigen; x = 0; y = -2;}scale_default;
		time = 0;
		code="rating";
		duration = response;	
	} rating_event;
} rating_trial; 