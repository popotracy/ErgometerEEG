% Ergometer_Baseline_MVC.m
%  
% 23 Aug., 2023
%
% You can uncomment the coding to enter the name of the subject_ID and the preferred language...
% 
% The Baseline will be firstly started and saved for the MVC measurement. 
% Subject should relax and sit still while during the recording...
% Afterward, subject squeezes as hard as possible for at least two times for the MVC measurements.
% 
% The Baseline and three MVC measurements will be saved in the current folder.
% The variables in the workspace will be saved and exported for the further usage. 
%
% Paramenters:
%     Subject_ID :   "EEG"   
%     lang (fr/eng): "eng"
%
% Triggers:
%     "0" : the onset of Baseline measurement. 
%     "1" : the onset of MVC measurement.
%     "2" : the offset of MVC measurement.
%
% Default variables: 
%     Baseline_duration         : 10s 
%     MVC_duration              : 3s                                                      
%     Rest_duration             : 3mins (180s)                                                    
%     Ready_duration            : 5s
%     MVC_measurement_n         : 3 times 
%   
% OUTPUT:
%     SubjectID_Baseline.mat    : the recorded torque as the Baseline.
%     SubjectID_MVC_n.mat       : the recorded torque as the maximal voluntary contraction.
%     Variables.mat             : the screen setup variables, calculated Baseline and MVC values for the fatigue experiment. 

clear, close all,  clc 

%% Data aqusition with NI
DebugMode = 1; % If 1,(debug) small screen
DAQMode=1 ; 

if DAQMode 
d = daq("ni");                                                              % Create DataAcquisition Object
ch=addinput(d,"cDAQ1Mod1","ai23","Voltage");                                % Add channels and set channel properties:'Measurement Type (Voltage)', 
ch.TerminalConfig = "SingleEnded";                                          % 'Terminal  Config (SingleEnded)', if any...
end
%% Participant ID
Subject_ID='EEG'
Lang='eng';

%Subject_ID = input('Please enter the Subject ID number:','s');             % You can uncomment this to creat the file for the subject. 

% lang = input('Please choose the language (fr/eng):','s');                 % Select the preferred language, either "fr" or "eng".
% while sum(strcmp(lang,{'fr','eng'}))==0 ;                                 % If the response doesn't match the answer, it will ask you again.
%     lang = input('There is an error, please choose the language (french/english):','s');
% end;
%% Creat Parallel port 
if ~DebugMode
t = serialport('COM1', 9600) ;
ioObj=io64;%create a parallel port handle
status=io64(ioObj);%if this returns '0' the port driver is loaded & ready
address=hex2dec('03F8') ;

%fopen(t) ;
end

%% Screen set-up
sampleTime      = 1/60;                                                     % screen refresh rate at 60 Hz (always check!!)

Priority(2);                                                                % raise priority for stimulus presentation
screens=Screen('Screens');
screenid=max(screens);
white=WhiteIndex(screenid);                                                 % Find the color values which correspond to white and black: Usually
black=BlackIndex(screenid);                                                 % black is always 0 and white 255, but this rule is not true if one of
                                                                            % the high precision framebuffer modes is enabled via the
                                                                            % PsychImaging() commmand, so we query the true values via the
                                                                            % functions WhiteIndex and BlackIndex
Screen('Preference', 'SkipSyncTests', 1);                                   % You can force Psychtoolbox to continue, despite the severe problems, by adding the command.

if DebugMode % Use this smaller screen for debugging
        [theWindow,screenRect] = Screen('OpenWindow',screenid, black,[500 100 1500 1000],[],2);
else
        [theWindow,screenRect] = Screen('OpenWindow',screenid, black,[],[],2);
        HideCursor;
end

oldTextSize=Screen('TextSize', theWindow, 30);                              % Costumize the textsize witht the monitor.  

%% Baseline 

Baseline_duration = 10;
torque_cal=[];

switch Lang
    case 'eng'
        text1 = ['Prepare for the Baseline measurement...']
        text2 = ['Please relax and stay still on the ergometer... '];
        text3 = ['Baseline measurement is done.']
    case 'fr'
        text1 = ['Préparez-vous à serrer votre main le plus fort possible pour ',num2str(trialTime),' secondes'];
end


DrawFormattedText(theWindow, text1,'center','center',255);
Screen(theWindow,'Flip',[],0);
WaitSecs(2);

startTime = GetSecs; 
if ~DebugMode  io64(ioObj,address,0); end
if DAQMode, 
    start(d,"continuous");  
    n = ceil(d.Rate/10); 
    
    while GetSecs < startTime + Baseline_duration;
        torque_cal_data = read(d,n);                                        % Read the data in timetable format.
        torque_cal = [torque_cal; torque_cal_data];
        cla;
        
        %Base_disp=[num2str(Baseline_duration-round(GetSecs-startTime)),'s'];
        DrawFormattedText(theWindow,text2,'center','center',255);
        Screen(theWindow,'Flip',[],0);  % 0:delete previous, 1:keep 
    end ;
    stop(d);
end

DrawFormattedText(theWindow,text3,'center','center', white,255);
Screen(theWindow,'Flip',[],0);
WaitSecs(2);

save([pwd,'/',Subject_ID,'_Baseline.mat'],"torque_cal"); 
Baseline=mean(torque_cal.cDAQ1Mod1_ai23);                                   % Baseline is caculated and saved in the workspace. 

%% MVC measurement 

MVC_duration = 3;                                                           % 3 seconds as default
Rest_duration = 60;                                                         %  1min as default.
Ready_duration = 5;
MVC_measurement_n=3;                                                        % Number of trials for measuring MVC. 
Nm=50;                                                                      % Transform the voltage to torque force (based on the value from the ergoneter brochure).
MVCC=[]; i=1;                                                               % Record the MVC values of each measurement in the matrix. 


switch Lang
    case 'eng'
        text1 = ['Be ready to push your arm as hard as possible for the MVC measurement.']
        text2 = ['Ready...'];
        text3 = ['Go! '];
        text4 = ['Good job! Relax your arm for...'];
        text5 = ['MVC measurement is done.'];
    case 'fr'
        text1 = ['Préparez-vous à serrer votre main ', Hand, ' le plus fort possible pour 3 seconds'];
        text2 = [];
        text3 = [];
        text4 = [];
end

DrawFormattedText(theWindow,text1,'center','center',255);
Screen(theWindow,'Flip',[],0); 
WaitSecs(5);


while MVC_measurement_n>0; 

    %Ready to do MVC in 5s.
    startTime = GetSecs;    
    while GetSecs < startTime + Ready_duration;
        MVC_disp=[num2str(Ready_duration-round(GetSecs-startTime)),'s']
        DrawFormattedText(theWindow,[text2 MVC_disp],'center','center',255);
        Screen(theWindow,'Flip',[],0);                                      % 0:delete previous, 1:keep
    end ;
    
    %MVC for 3s. 
    startTime = GetSecs;
    torque_mvc = []; 
    
    if DAQMode, start(d,"continuous");        
        if ~DebugMode  io64(ioObj,address,1); end % trigger 1: the onset of MVC measurement.       
        while GetSecs < startTime + MVC_duration
            torque_mvc_data = read(d,n);
            torque_mvc_data.cDAQ1Mod1_ai23 = (torque_mvc_data.cDAQ1Mod1_ai23-Baseline)*Nm;
            torque_mvc_data.cDAQ1Mod1_ai23=-(torque_mvc_data.cDAQ1Mod1_ai23);
            torque_mvc = [torque_mvc; torque_mvc_data];
            cla;
            
            timer_disp=[num2str(MVC_duration-round(GetSecs-startTime)),'s']
            DrawFormattedText(theWindow,[text3 timer_disp],'center','center', white,255);Screen(theWindow,'Flip',[],0);                                      % 0:delete previous, 1:keep
        end ;     
        stop(d);   
        if ~DebugMode  io64(ioObj,address,2); end % trigger 2: the offset of MVC measurement. 
    end 

    save([pwd,'/',Subject_ID,'_MVC_',num2str(MVC_measurement_n),'.mat'],"torque_mvc"); % Save the MVC for the subject. 
    MVCC(i)=max(movmean(torque_mvc.Variables,d.Rate*0.5));                  % A 0.5s moving average window was used to calculate for MVC technique. 
    i=i+1;
    MVC=max(MVCC);                                                          % Find the largest MVC value in the measurements. 
    save([pwd,'/Variables.mat']);   
    % Save the variables for further experiment. 
    % Resting for the next MVC for 3mins.
    startTime = GetSecs;     
    while GetSecs < startTime + Rest_duration;
        ClosePTB
        MVC_disp=[num2str(Rest_duration-round(GetSecs-startTime)),'s'];
        DrawFormattedText(theWindow,[text4 MVC_disp],'center','center', white,255);
        Screen(theWindow,'Flip',[],0); 
    end ;
    MVC_measurement_n=MVC_measurement_n-1;
end
                                                         
DrawFormattedText(theWindow,text5,'center','center', white,255);
Screen(theWindow,'Flip',[],0);                                              % 0:delete previous, 1:keep   

%% End

%if ~DebugMode fclose(t); end 

Screen('CloseAll');
