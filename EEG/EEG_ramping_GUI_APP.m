% EEG_ramping_GUI_APP.m
%  
% 23rd Aug., 2023
%
% 
% The Variables recorded from the "Ergometer_Baseline_MVC.m" will be firstly imported. 
% Subject should follow the request on the screen to perform the task. 
% 
% Phase 1: Ready...
% Phase 2: Perform the force (ball) to stay in the tunnel until reaching the threshold. 
% Phase 3: Stay in the top of the tunnel (threshold) for 1 min.
% Phase 4: Resting state for 1 min and be ready for next trial again. 
%
% Triggers: 
%     "0" : close the portal handle. 
%     "1" : the onset of a trial.
%     "2" : the onset of the ramping.
%     "3" : the onset of the threshold.
%     "4" : the offset of the threshold.
%     "5" : the offset of the ramping.
%     "6" : the offset of a trial.
%
% Default parameters:   
%     post_Threshold_t (staying top)  : 60s 
%     Rest_t (resting state)          : 60s  
%     
%     Threshold                       : 10% 
%     Error_acceptance                : 2% 
%     Trial_n (number of total trials): 10
%
% OUTPUT:
%     No variables will be saved...
%     Only visual feedback will be needed. 

clear, close all,  clc 
%%
DebugMode = 0;
DAQMode=1;

if DebugMode, MVC=184; Baseline=0.28; Lang='eng'; % If 1,(debug) small screen
else  load ('Variables.mat', 'MVC','Baseline','Lang','Subject_ID');    
end
%% DAQ 
if DAQMode
d=daq("ni");                                                              % Create DataAcquisition Object
ch=addinput(d,"cDAQ1Mod1","ai23","Voltage");                                % Add channels and set channel properties:'Measurement Type (Voltage)', 
ch.TerminalConfig = "SingleEnded";                                          % 'Terminal  Config (SingleEnded)', if any...
end
%% Create parallel port handle
if ~DebugMode
t = serialport('COM1', 9600) ;
ioObj=io64; %create a parallel port handle
status=io64(ioObj); %if this returns '0' the port driver is loaded & ready
address=hex2dec('03F8') ;
%fopen(t) ;
end
%% Experiment Set-up
PER = 0.7 ;                                                                 % Percentage of the inner screen to be used.
Threshold=0.1;  
Error=0.02;

% other color
green   = [0 255 0];
red     = [255 0 0];
orange  = [255 100 0];
grey    = [200 200 200];
%% Screen set-up
sampleTime      = 1/60;                                                     % screen refresh rate at 60 Hz (always check!!)
Priority(2);                                                                % raise priority for stimulus presentation
screens=Screen('Screens');

screenid=max(screens);
white=WhiteIndex(screenid);                                                 % Find the color values which correspond to white and black: Usually
black=BlackIndex(screenid);                                                 % black is always 0 and white 255, but this rule is not true if one of
                                                                            % the high precision framebuffer modes is enabled via the
                                                                            % PsychImaging() commmand, so we query the true values via the                                                                          % functions WhiteIndex and BlackIndex
Screen('Preference', 'SkipSyncTests', 1);             
if DebugMode % Use this smaller screen for debugging
        [theWindow,screenRect] = Screen('OpenWindow',screenid, black,[1000 100 2000 1000],[],2);
else
        [theWindow,screenRect] = Screen('OpenWindow',screenid, black,[],[],2);
        HideCursor;
end
oldTextSize=Screen('TextSize', theWindow, 30);                              % Costumize the textsize witht the monitor.  

scrnWidth   = screenRect(3) - screenRect(1);
scrnHeight  = screenRect(4) - screenRect(2);

% Inner screen
frameWidth=(scrnHeight-PER *scrnHeight)/2; 
InScr=floor([screenRect(1:2)+frameWidth screenRect(3:4)-frameWidth]);
inScrnWidth  = InScr(3)-InScr(1);
inScrnHeight = InScr(4)-InScr(2);
Block_W=inScrnWidth/4;
Block_H=inScrnHeight/4;
R=Block_H/4;

% Extra retangular
ExtraTop=floor([InScr(1), InScr(2)-1.3*R, InScr(3), InScr(2)]);
ExtraBottom=floor([InScr(1), InScr(4), InScr(3), InScr(4)+1.3*R]);

%% EEG experiment variables
% tunnel

% (InScr(1), InScr(2))   #o __ __ __ __
%                        |     #3_#4   |
%                        |    /    \   |
%           (Axn, Ayn) #1|_#2/    #5\__|#6 
%                        |__ __ __ __ _|#e (InScr(3), InScr(4))
%            

% #1 
Ax1 = InScr(1);
Ay1 = InScr(4);
% #2 
Ax2 = (InScr(1)*7+ InScr(3))/8;
Ay2 = InScr(4);
% #3
Ax3 = (InScr(1)+ InScr(3))/2-R;
Ay3 = InScr(4)-3*Block_H;
% #4
Ax4 = (InScr(1)+ InScr(3))/2+R;
Ay4 = InScr(4)-3*Block_H;
% #5
Ax5 = (InScr(1)+ InScr(3)*7)/8;
Ay5 = InScr(4);
% #6
Ax6 = InScr(3);
Ay6 = InScr(4);

%% Tunnel
torque_eeg=[];
Ball_percentage=[];
Trial_n=10; 

%Parameters of duration
Ramping_t=Threshold*2/0.1;               % According to reference: 10% for 2s-ramping.
Velocity=((Ax3+Ax4)/2-Ax2)/Ramping_t;
pre_Ramping_t=(Ax2-Ax1)/Velocity         % #1-#2
pre_Threshold_t=(inScrnWidth/2)/Velocity % #1-#2-#3 
post_Threshold_t=pre_Threshold_t;        % #6-#7-#8 
Threshold_t=60;                          % #4-#5 Default is 60.
Rest_t=60;
Trial_t=pre_Threshold_t+Threshold_t+post_Threshold_t;

%Language
switch Lang
    case 'eng'
        text1 = ['The experiment will start soon...'];
        text2 = ['Please maintain the ball in the tunnel by adding the force.']
        text3 = ['Ready...']
        text4 = ['Go! '];
        text5 = ['Ready for the next trial '];
        text6 = ['Press the key "esc" to quit the experiment.'];
    case 'fr'
        text1 = ['Préparez-vous à serrer votre main ', Hand, ' le plus fort possible pour ',num2str(trialTime),' secondes'];
        text2 = [];
        text3 = [];
        text4 = [];
end
%% Ready to start...
DrawFormattedText(theWindow,text1,'center','center', white,255);
DrawFormattedText(theWindow, text6,'center',750, white,255); 
Screen(theWindow,'Flip',[],0);                                              % 0:delete previous, 1:keep
WaitSecs(3);
DrawFormattedText(theWindow,text2,'center','center', white,255);
DrawFormattedText(theWindow, text6,'center',750, white,255); 
Screen(theWindow,'Flip',[],0);                                              % 0:delete previous, 1:keep
WaitSecs(3);

%% Trail
timing_check=[]

while Trial_n >0
    %Background setup
    Screen('FillRect',theWindow,white,InScr);
    Screen('FillRect',theWindow,white,ExtraTop);
    Screen('FillRect',theWindow,white,ExtraBottom);
    
    %Tunnel setup
    ratio=(Ay2-Ay3)/(Ax3-Ax2);
    for i=1:1:(Ax2-Ax1), Screen('FillOval', theWindow, red,[(Ax1-1.3*R)+i, Ay1-1.3*R, (Ax1+1*R)+i, Ay1+1.3*R]);end 
    for i=1:1:(Ax3-Ax2), Screen('FillOval', theWindow, red,[(Ax2-1.3*R)+i, (Ay2-1.3*R)-i*ratio, (Ax2+1.3*R)+i, (Ay2+1.3*R)-i*ratio]);end 
    for i=1:1:(Ax4-Ax3), Screen('FillOval', theWindow, red,[(Ax3-1.3*R)+i, (Ay3-1.3*R), (Ax3+R)+i, (Ay3+1.3*R)]);end 
    for i=1:1:(Ax5-Ax4), Screen('FillOval', theWindow, red,[(Ax4-1.3*R)+i, (Ay4-1.3*R)+i*ratio, (Ax4+1.3*R)+i, (Ay4+1.3*R)+i*ratio]);end 
    for i=1:1:(Ax6-Ax5), Screen('FillOval', theWindow, red,[(Ax5-1.3*R)+i, Ay5-1.3*R, (Ax5+1.3*R)+i, Ay5+1.3*R]);end
    DrawFormattedText(theWindow,text3,Ax1,Ay1-70, black,255); 
    Screen('FillOval', theWindow, black,[Ax1-R, Ay1-R, Ax1+R, Ay1+R])
    Screen(theWindow,'Flip',[],1); 
    WaitSecs(2);
    DrawFormattedText(theWindow,text4,Ax1+120,Ay1-70, black,255); 
    WaitSecs(2); 
    Screen(theWindow,'Flip',[],0); 
    
    %Phase1: onset of a trial.
    
    Onset_ramping=true; 
    Offset_ramping=true;

    start(d,"continuous"); n = ceil(d.Rate/10);
    startTime = GetSecs;  
        if ~DebugMode, triger1_check = GetSecs-startTime, timing_check=[timing_check; triger1_check]; setRTS(t, false); setDTR(t, false); io64(ioObj,address,1);  end % trigger 1: the onset of MVC measurement.   

    while GetSecs <= startTime + Trial_t      
        ClosePTB
        timer=GetSecs-startTime; 
        if ~DebugMode
            %Phase2: onset of the ramping. 
            if GetSecs-startTime>=round(pre_Ramping_t,2) && Onset_ramping == true
              triger2_check = GetSecs-startTime, timing_check=[timing_check; triger2_check];
              setRTS(t, true); setDTR(t, false); io64(ioObj,address,2); Onset_ramping = false ; end           
            %Phase3: onset of the threshold. 
            if GetSecs-startTime >=round(pre_Threshold_t,2) && Offset_ramping == true
             triger3_check = GetSecs-startTime, timing_check=[timing_check; triger3_check];
              setRTS(t, false); setDTR(t, true); io64(ioObj,address,3); Offset_ramping = false ; end
        end

        %Background setup
        Screen('FillRect',theWindow,white,InScr);
        Screen('FillRect',theWindow,white,ExtraTop);
        Screen('FillRect',theWindow,white,ExtraBottom);
        %Tunnel setup
        ratio=(Ay2-Ay3)/(Ax3-Ax2);
        for i=1:1:(Ax2-Ax1), Screen('FillOval', theWindow, red,[(Ax1-1.3*R)+i, Ay1-1.3*R, (Ax1+1*R)+i, Ay1+1.3*R]);end 
        for i=1:1:(Ax3-Ax2), Screen('FillOval', theWindow, red,[(Ax2-1.3*R)+i, (Ay2-1.3*R)-i*ratio, (Ax2+1.3*R)+i, (Ay2+1.3*R)-i*ratio]);end 
        for i=1:1:(Ax4-Ax3), Screen('FillOval', theWindow, red,[(Ax3-1.3*R)+i, (Ay3-1.3*R), (Ax3+R)+i, (Ay3+1.3*R)]);end 
        for i=1:1:(Ax5-Ax4), Screen('FillOval', theWindow, red,[(Ax4-1.3*R)+i, (Ay4-1.3*R)+i*ratio, (Ax4+1.3*R)+i, (Ay4+1.3*R)+i*ratio]);end 
        for i=1:1:(Ax6-Ax5), Screen('FillOval', theWindow, red,[(Ax5-1.3*R)+i, Ay5-1.3*R, (Ax5+1.3*R)+i, Ay5+1.3*R]);end

        %Data acqusition
        torque_eeg_data = read(d,n);
        torque_eeg_data.cDAQ1Mod1_ai23 = -((torque_eeg_data.cDAQ1Mod1_ai23-Baseline)*50);
        torque_eeg = [torque_eeg; torque_eeg_data];
        Ball_percentage=[Ball_percentage; mean(torque_eeg_data.Variables)*100/MVC];
        Percentage_scale=3*Block_H/Threshold;
        Ball_RealtimeHeight=mean(torque_eeg_data.Variables)*Percentage_scale/MVC;
       
        %Ball vertical vibration
        if mean(torque_eeg_data.Variables)/MVC > Threshold+Error
           Starting_H=(Threshold+Error)*Percentage_scale;
           Percentage_scale=Block_H/(1-Threshold);
           Ball_RealtimeHeight=Starting_H+(mean(torque_eeg_data.Variables)/MVC-Threshold-Error)*Percentage_scale;  
        end
          
       % Ball horizontal displacement 
        if timer <= pre_Threshold_t
            Bx1=(Ax1-R)+Velocity*(timer);
            Bx2=(Ax1+R)+Velocity*(timer);           
        elseif timer > pre_Threshold_t && timer <= pre_Threshold_t+Threshold_t
            Bx1=(Ax3+Ax4)/2-R; % stay in the end
            Bx2=(Ax3+Ax4)/2+R; % stay in the end                               
        else 
            Bx1=(Ax1-R)+Velocity*(timer-Threshold_t);
            Bx2=(Ax1+R)+Velocity*(timer-Threshold_t);   
        end
          By1=(Ay2-R)-Ball_RealtimeHeight;
          By2=(Ay2+R)-Ball_RealtimeHeight; 
          Ball=floor([Bx1, By1, Bx2, By2]);
          cla
 
      %Realtime ball display
      Screen('FillOval', theWindow, black,Ball);   
      if DebugMode
      %timer
      timerdisplay=num2str(round(GetSecs-startTime));
      DrawFormattedText(theWindow,timerdisplay,'center','center', red,255); 
      end 
      Screen(theWindow,'Flip',[],0);
    end 
    stop(d)
       
    % Phase4
    Screen('FillRect',theWindow,white,ExtraTop);
    Screen('FillRect',theWindow,white,ExtraBottom);
    Screen('FillRect',theWindow,white,InScr);
    Screen(theWindow,'Flip',[],0);
    WaitSecs(3);
    
    startTime = GetSecs; 
    while GetSecs < startTime + Rest_t
        ClosePTB
        %inner screen setup
        Screen('FillRect',theWindow,white,ExtraTop);
        Screen('FillRect',theWindow,white,ExtraBottom);
        Screen('FillRect',theWindow,white,InScr);
        %timer
        timer_disp=[num2str(Rest_t-round(GetSecs-startTime)),'s.'];
        DrawFormattedText(theWindow,[text5 timer_disp],'center','center', black,255); 
        Screen(theWindow,'Flip',[],0);                  
    end   
    Trial_n=Trial_n-1;    
end 

%% End
DrawFormattedText(theWindow,'Thank you for your participation.','center','center', white,255);
Screen(theWindow,'Flip',[],0);                                              % 0:delete previous, 1:keep
WaitSecs(5);

%if ~DebugMode, fclose(t) ; end 
Screen('CloseAll');
