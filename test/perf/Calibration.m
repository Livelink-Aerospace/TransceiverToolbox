classdef Calibration < matlab.unittest.TestCase
    
    properties
        MaxIterations = 10;
        ToleranceHz = 50;
    end
    
    methods (Static)
        function estFrequency(data,fs)
            nSamp = length(data);
            FFTRxData  = fftshift(10*log10(abs(fft(data))));
            df = fs/nSamp;  freqRangeRx = (-fs/2:df:fs/2-df).'/1000;
            figure(1);plot(freqRangeRx, FFTRxData);
        end
    end
    
    methods
        function [y, tf] = ToneGen(~,Tx,~)
            
            tf = fix(Tx.SamplingRate*0.1);
            sw = dsp.SineWave;
            sw.SampleRate = Tx.SamplingRate;
            sw.Frequency = tf;
            sw.SamplesPerFrame = 2^14;
            sw.ComplexOutput = true;
            y = sw();
            powerScaleFactor = 0.8;
            y = y.*(1/max(abs(y))*powerScaleFactor);
            y = int16(y*2^15);
        end
        
        function InstrumentReset(~)
            g = instrfind; %#ok<NASGU>
            instrreset;
        end
        
        function Tx = FrequencyCalibrate(obj,...
                Tx,Rx,...
                ExtendedTxParams,ExtendedRxParams)
            % Generate tone
            [sw, tf] = obj.ToneGen(Tx,Rx);
            error = 0;
            % Custom
            Saved_gain = Rx.Gain;
%             Rx.Gain = 10;
            % Update tone RX position
            samplingRatio = Rx.SamplingRate/Tx.SamplingRate;
            tf = tf*samplingRatio;
            for k = 1:obj.MaxIterations
                % Update Tx Frequency
                obj.InstrumentReset();
                Tx.CenterFrequency = Tx.CenterFrequency - error;
                % Hardware
                out = obj.DeviceToDevice(...
                    Tx,Rx,...
                    ExtendedTxParams,ExtendedRxParams,...
                    sw);
                % Measure offset
                freqEst = meanfreq(double(real(out)),Rx.SamplingRate);
                obj.estFrequency(out,Rx.SamplingRate);
                error = fix((freqEst - tf)*0.5);
                obj.log(1,['Frequency Error: ',num2str(error)]);
                if abs(error)<=obj.ToleranceHz
                    obj.log(1,'Frequency within tolerance');
                    break
                end
            end
            Rx.Gain = Saved_gain;
        end
        
        function Tx = FrequencyCalibratePluto(obj,...
                Tx,Rx,...
                ExtendedTxParams,ExtendedRxParams)
            % Generate tone
            [sw, tf] = obj.ToneGen(Tx);
            error = 0;
            for k = 1:obj.MaxIterations
                obj.log(1,['Calibration iteration ',num2str(k)]);
                % Update Tx Frequency
                Tx.CenterFrequency = Tx.CenterFrequency - error;
                % Hardware
                out = obj.DeviceToDevice(...
                    Tx,Rx,...
                    ExtendedTxParams,ExtendedRxParams,...
                    sw);
                % Estimate tone
                y = fftshift(abs(fft(out)));
                [~,idx] = max(y);
                nSamp = length(out);
                fs = Tx.SamplingRate;
                fReceived = (max(idx)-nSamp/2)/nSamp*fs;
                correctionFactor = (fReceived - tf) / (Tx.CenterFrequency + tf) * 1e6;
                %                 correctionFactor = (fReceived - tf) / (Tx.CenterFrequency + tf);
                errorHz = fReceived - tf;
                figure;plot(abs(fftshift(fft(out))))
                if strcmpi(obj.author,'MathWorks')
                    obj.RxFrequencyCorrectionFactor = obj.RxFrequencyCorrectionFactor + 0.3*correctionFactor;
                else
                    if abs(errorHz) < 20
                        cc = sign(errorHz);
                    else
                        cc = fix(0.3*correctionFactor*100);
                    end
                    %                     v = rx.getDeviceAttributeLongLong('xo_correction') - ...
                    %                         cc;
                    %                     rx.setDeviceAttributeLongLong('xo_correction',v);
                    %                     obj.RxFrequencyCorrectionFactor = rx.getDeviceAttributeLongLong('xo_correction');%rx.FrequencyCorrection;
                    obj.RxFrequencyCorrectionFactor = obj.RxFrequencyCorrectionFactor - cc;
                end
                
                
                msg = sprintf([...
                    '    Tone Freq: %.6f\n',...
                    'Est Tone Freq: %.6f\n',...
                    '        Error: %.6f\n'],tf,fReceived,errorHz);
                obj.log(1,msg);
                
                if abs(errorHz) < obj.ToleranceHz
                    obj.log(1,'Tolerance met... calibration complete');
                    break
                end
            end
        end
        
        
        function Tx = Calibrate(obj,Tx,Rx,ExtendedTxParams,ExtendedRxParams)
            
%             Tx0 = Tx.Device();
            Rx0 = Rx.Device();
            
            obj.log(1,'Staring calibration');
            
            if strcmpi(Rx.Address,Tx.Address)
                obj.log(1,'Skipping calibration since Rx and Tx are the same device');
                return;
            end
            
            if contains(lower(class(Rx0)),'pluto')
                FrequencyCalibratePluto(obj,Tx,Rx,ExtendedTxParams,ExtendedRxParams);
%             elseif contains(lower(class(Rx0)),'pluto')
%                 Tx = FrequencyCalibratePluto(obj,Tx,Rx,ExtendedTxParams,ExtendedRxParams);
            else
                % Generic frequency correction
                Tx = FrequencyCalibrate(obj,Tx,Rx,ExtendedTxParams,ExtendedRxParams);
            end
        end
        
    end
end

