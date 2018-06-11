function handles=acqOCTFluo(handles)
% Funciton to acquire bith OCT and Fluo images. Parameters are specified into the
% GUI and carried here by handles struct. OCT trigger is done by the
% National Instrument DAQ in order to synchronize the piezo and the camera.
% Fluo trigger is done numerically by the frame grabber.

global SignalDAQ acq_state
acq_state=1;

handles.save.t = datestr(now,'yyyy_mm_dd_HH_MM_ss');
mkdir([handles.save.path '\' handles.save.t ])
set(handles.octCam.vid, 'TriggerFrameDelay', 10) % We leave the first 10 frames because the camera is not stable
set(handles.fluoCam.vid, 'TriggerFrameDelay', 10) % We leave the first 10 frames because the camera is not stable

switch handles.exp.piezoMode
    case 1 % Direct image only
        set(handles.octCam.vid, 'FramesPerTrigger', handles.octCam.Naccu*handles.save.Noct, 'LoggingMode', 'memory');
        set(handles.fluoCam.vid, 'FramesPerTrigger', handles.fluoCam.Naccu*handles.save.Nfluo, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~isrunning(handles.fluoCam.vid)
            start(handles.fluoCam.vid);
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,handles.octCam.Naccu*handles.save.Noct*5)
        [data,handles.save.timeOCT]=getdata(handles.octCam.vid,handles.octCam.Naccu*handles.save.Noct,'double');
        stop(handles.octCam.vid);
        if handles.save.allraw
            saveAsTiff(squeeze(data),'all_raw','adimec',handles)
        end
        if handles.save.direct
            direct=zeros(size(data,1),size(data,2),handles.save.Noct);
            for i=1:handles.save.Noct
                direct(:,:,i)=mean(data(:,:,1,(i-1)*handles.octCam.Naccu+1:i*handles.octCam.Naccu),4);
            end
            saveAsTiff(direct,'direct','adimec',handles)
        end
        clear data
        wait(handles.fluoCam.vid,handles.fluoCam.Naccu*handles.save.Nfluo*5)
        [data,handles.save.timeFluo]=getdata(handles.fluoCam.vid,handles.fluoCam.Naccu*handles.save.Nfluo,'double');
        stop(handles.fluoCam.vid);
        stop(handles.DAQ.s);
        if handles.save.fluo
            fluo=zeros(size(data,1),size(data,2),handles.save.Nfluo);
            for i=1:handles.save.Nfluo
                fluo(:,:,i)=mean(data(:,:,1,(i-1)*handles.fluoCam.Naccu+1:i*handles.fluoCam.Naccu),4);
            end
            saveAsTiff(fluo,'fluo','pco',handles)
        end
    case 2 % Two phases imaging
        set(handles.octCam.vid, 'FramesPerTrigger', 2*handles.octCam.Naccu*handles.save.Noct, 'LoggingMode', 'memory');
        set(handles.fluoCam.vid, 'FramesPerTrigger', handles.fluoCam.Naccu*handles.save.Nfluo, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~isrunning(handles.fluoCam.vid)
            start(handles.fluoCam.vid);
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,handles.octCam.Naccu*handles.save.Noct*10)
        [data,handles.save.timeOCT]=getdata(handles.octCam.vid,2*handles.octCam.Naccu*handles.save.Noct,'double');
        stop(handles.octCam.vid);
        imTomo=zeros(size(data,1),size(data,2),handles.save.Noct);
        for i=1:handles.save.Noct
            imTomo(:,:,i)=abs(mean(data(:,:,1,2*(i-1)*handles.octCam.Naccu+1:2:2*i*handles.octCam.Naccu),4)-mean(data(:,:,1,2*(i-1)*handles.octCam.Naccu+2:2:2*i*handles.octCam.Naccu),4));
        end
        if handles.save.allraw
            saveAsTiff(squeeze(data),'all_raw','adimec',handles)
        end
        if handles.save.direct
            direct=zeros(size(data,1),size(data,2),handles.save.Noct);
            for i=1:handles.save.Noct
                direct(:,:,i)=mean(data(:,:,1,2*(i-1)*handles.octCam.Naccu+1:2:2*i*handles.octCam.Naccu),4);
            end
            saveAsTiff(direct,'direct','adimec',handles)
        end
        if handles.save.amplitude
            saveAsTiff(imTomo,'tomo','adimec',handles)
        end
        clear data
        wait(handles.fluoCam.vid,handles.octCam.Naccu*handles.save.Nfluo*10)
        [data,handles.save.timeFluo]=getdata(handles.fluoCam.vid,handles.fluoCam.Naccu*handles.save.Nfluo,'double');
        stop(handles.fluoCam.vid);
        stop(handles.DAQ.s);
        if handles.save.fluo
            fluo=zeros(size(data,1),size(data,2),handles.save.Nfluo);
            for i=1:handles.save.Nfluo
                fluo(:,:,i)=mean(data(:,:,1,(i-1)*handles.fluoCam.Naccu+1:i*handles.fluoCam.Naccu),4);
            end
            saveAsTiff(fluo,'fluo','pco',handles)
        end
    case 3 % 4 phase imaging
        set(handles.octCam.vid, 'FramesPerTrigger', 4*handles.octCam.Naccu*handles.save.Noct, 'LoggingMode', 'memory');
        set(handles.fluoCam.vid, 'FramesPerTrigger', handles.fluoCam.Naccu*handles.save.Nfluo, 'LoggingMode', 'memory');
        handles=AnalogicSignalOCT(handles);
        if ~isrunning(handles.octCam.vid)
            start(handles.octCam.vid);
            trigger(handles.octCam.vid); % Manually initiate data logging.
        end
        if ~isrunning(handles.fluoCam.vid)
            start(handles.fluoCam.vid);
        end
        if ~handles.DAQ.s.IsRunning
            queueOutputData(handles.DAQ.s,SignalDAQ);
            startBackground(handles.DAQ.s);
        end
        wait(handles.octCam.vid,handles.octCam.Naccu*handles.save.Noct*20)
        [data,handles.save.timeOCT]=getdata(handles.octCam.vid,4*handles.octCam.Naccu*handles.save.Noct,'double');
        stop(handles.octCam.vid);
        I1=zeros(size(data,1),size(data,2),handles.save.Noct);
        I2=I1;
        I3=I1;
        I4=I1;
        for i=1:handles.save.Noct
            I1(:,:,i)=mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+1:4:4*i*handles.octCam.Naccu),4);
            I2(:,:,i)=mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+2:4:4*i*handles.octCam.Naccu),4);
            I3(:,:,i)=mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+3:4:4*i*handles.octCam.Naccu),4);
            I4(:,:,i)=mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+4:4:4*i*handles.octCam.Naccu),4);
        end
        imAmplitude=0.5*sqrt((I4-I2).^2+(I1-I3).^2);
        imPhase=angle((I1-I3)./(I4-I2));
        if handles.save.allraw
            saveAsTiff(squeeze(data),'all_raw','adimec',handles)
        end
        if handles.save.direct
            direct=zeros(size(data,1),size(data,2),handles.save.Noct);
            for i=1:handles.save.Noct
                direct(:,:,i)=mean(data(:,:,1,4*(i-1)*handles.octCam.Naccu+1:4:4*i*handles.octCam.Naccu),4);
            end
            saveAsTiff(direct,'direct','adimec',handles)
        end
        if handles.save.amplitude
            saveAsTiff(imAmplitude,'amplitude','adimec',handles)
        end
        if handles.save.phase
            saveAsTiff(imPhase,'phase','adimec',handles)
        end
        clear data
        wait(handles.fluoCam.vid,handles.octCam.Naccu*handles.save.Nfluo*20)
        [data,handles.save.timeFluo]=getdata(handles.fluoCam.vid,handles.fluoCam.Naccu*handles.save.Nfluo,'double');
        stop(handles.fluoCam.vid);
        stop(handles.DAQ.s);
        if handles.save.fluo
            fluo=zeros(size(data,1),size(data,2),handles.save.Nfluo);
            for i=1:handles.save.Nfluo
                fluo(:,:,i)=mean(data(:,:,1,(i-1)*handles.fluoCam.Naccu+1:i*handles.fluoCam.Naccu),4);
            end
            saveAsTiff(fluo,'fluo','pco',handles)
        end
    case 4 % 5 phases
end

set(handles.octCam.vid, 'TriggerFrameDelay', 0)
set(handles.fluoCam.vid, 'TriggerFrameDelay', 0)
acq_state=0;