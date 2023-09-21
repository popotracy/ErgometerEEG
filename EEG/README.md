# Installation and environment
1) Download this folder, and set the path to your current folder. 
2) Check the address of the serial port sending the trigger from your computer (Device manager -> COM & Serial port -> Resources). You can test the address in "test_TTL.m", preferably via MATLAB 2020.
3)  If step 2 works, edit the address in the Matlab files (Ergometer_Baseline.m & EEG_ramping_GUI_APP.m).
4) Make sure Psychtoolbox (PTB) is downloaded in your MATLAB (if none, check here: http://psychtoolbox.org/download.html).
5) Run "Ergometer_Baseline.m" to record baseline and MVC.
6) Run "EEG_ramping_GUI_APP.m" to start the experiment.

# What's the purpose of each file?
1) Ergometer_Baseline.m: To record the baseline of the toques (open the .m file to read more), and the MVC. 
2) EEG_ramping_GUI_APP.m: To implement the visual feedback for the experiment. 
3) ClosePTB.m: The built function is used to close the PTB screen by pressing the "esc" key. 
4) io64.mexw64: A Mex-File Plug-in for MATLAB Port I/O. *Make sure it is in the same folder as the others.
5) test_TTL.m: A short m. file to test the address of the serial port and trigger I/O markers.

# Port I/O markers:
We use the two MATLAB functions to control (open/close) the 8-pin serial port, so that we can change the name of the marker displayed in the EEG.
https://www.mathworks.com/help/matlab/ref/serialport.html

- SetRTS: It's used to set the "Request To Send (RTS)" serial pin, and it corresponds to pin7 (https://www.mathworks.com/help/matlab/ref/serialport.setrts.html#responsive_offcanvas)
- SetDTR: It's used to set the "Data Terminal Ready (DTR)", and it corresponds to pin4 (https://www.mathworks.com/help/matlab/ref/serialport.setdtr.html)

Four combinations:
1. SetRTS(device, false) + SetDTR(device, false) 
2. SetRTS(device, true) + SetDTR(device, true)
3. SetRTS(device, true) + SetDTR(device, false)
4. SetRTS(device, false) + SetDTR(device, true)
