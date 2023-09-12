%%
clear, close all,  clc 
%%
s = serialport('COM1',9600);
ioObj=io64;%create a parallel port handle
status=io64(ioObj);%if this returns '0' the port driver is loaded & ready
address=hex2dec('03F8') ;

%fopen(s) ;

%%
a=serialportlist('available')

s = serialport('COM1',9600);

% setRTS(s,true)
% 
% setRTS(s,false)
% 
% setDTR(s,true)
% 
% setDTR(s,false)

debut=GetSecs
tic

while GetSecs<debut+10;
    io64(ioObj,address,1)  ; pause(1); io64(ioObj,address,0);  pause(0.1);


end

 %io64(ioObj,address,1)  ; pause(0.2); io64(ioObj,address,0);  pause(0.1);



%fclose(s) ; clear ; clc
%% 
a=serialportlist('available')
s = serialport('COM1',9600);

%15
setRTS(s,false);
setDTR(s,false);
io64(ioObj,address,1)  ; pause(1); 
 
%15
setRTS(s,true);
setDTR(s,true);
io64(ioObj,address,1)  ; pause(1);
 
%13
setRTS(s,true);
setDTR(s,false);
io64(ioObj,address,1)  ; pause(1);
 
%11
setRTS(s,false);
setDTR(s,true);
io64(ioObj,address,1)  ; pause(1);



 
 

