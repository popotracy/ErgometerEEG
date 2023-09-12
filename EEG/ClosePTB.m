function ClosePTB
dvc=GetKeyboardIndices;
[keyisdown, secs, keyflags, deltaSecs] = KbCheck(dvc)
if  keyisdown
    while keyflags(KbName('escape'))==1
        save([pwd,'/Variables.mat']); 
        Screen('CloseAll');
        break
    end
end 
end
