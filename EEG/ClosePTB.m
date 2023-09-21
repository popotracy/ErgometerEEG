function ClosePTB
dvc=GetKeyboardIndices;
[keyisdown, secs, keyflags, deltaSecs] = KbCheck(dvc)
if  keyisdown
    while keyflags(KbName('esc'))==1
        Screen('CloseAll');
        break
    end
end 
end
