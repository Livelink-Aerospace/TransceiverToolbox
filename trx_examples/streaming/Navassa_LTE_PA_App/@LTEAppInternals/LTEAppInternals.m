classdef LTEAppInternals < LTETestModelWaveform
    properties (SetObservable = true, AbortSet = true)
        CyclicPrefix
        FrameOffset
        SamplingRate
        NCellID
        FreqOffset
        IQOffset
        
        PSD_y
        PSD_x
        
        DemodSyms = struct
        EqGridStruct = struct
        
        evm_pbch_RMS
        evm_pcfich_RMS
        evm_pdcch_RMS
        evm_phich_RMS
        evm_rs_RMS
        evm_pss_RMS
        evm_sss_RMS
        
        nFrame
        count
        evmSymbol = struct
        evmSC = struct
        evmRB = struct        
        FrameEVM = struct
        FinalEVM
        PDSCHevm
    end
    
    properties 
        SubFrameIndex
        ADRV9002Tx
        ADRV9002Rx
        FrequencyCorrection
    end
    
    properties (Access = private)
        StopTest = false  
        test_settings = ...
            struct(...
            'TxGain', -30,...
            'RxDigitalGainControlMode', 'ManualGainCorrection',...
            'Attenuation', 3, ... 
            'SamplingRate', 1e6)        
    end
    
    methods (Access = private)
        dataRx = ADRV9002Radio(obj, app, eNodeBOutput, countTx)
    end
    
    methods
        function obj = LTEAppInternals(app_obj)
            addlistener(app_obj,'Play',@obj.handlePlayEvnt);
            addlistener(app_obj,'Stop',@obj.handleStopEvnt);
        end
    end
    
    methods (Static)
        %{
        function PlutoConnectionFcn(app)
            connectedRadios = findADRV9002Radio;
            app.NumRadios = numel(connectedRadios);
            if numel(connectedRadios) > 1
                status = sprintf('Found %d Plutos.', numel(connectedRadios));
                app.Label.Text = {status};
                app.PlutoNotFound = false;
                app.TxDropDown.Items={};
                app.RxDropDown.Items={};
                for ii = 1:numel(connectedRadios)
                    app.TxDropDown.Items = [app.TxDropDown.Items connectedRadios(ii).RadioID];
                    app.RxDropDown.Items = [app.RxDropDown.Items connectedRadios(ii).RadioID];
                end
            elseif numel(connectedRadios) == 1
                status = 'Found 1 Pluto.';
                app.Label.Text = {status};
                app.PlutoNotFound = false;
                app.TxDropDown.Items={};
                app.RxDropDown.Items={};
                app.TxDropDown.Items = {connectedRadios.RadioID};
                app.RxDropDown.Items = {connectedRadios.RadioID};
            elseif numel(connectedRadios) == 0
                status = 'Pluto not found.';
                app.Label.Text = {status};
                app.TxDropDown.Items={};
                app.RxDropDown.Items={};
                return;
            end            
        end
        %}
    end
       
    methods (Access = private)
        function handlePlayEvnt(obj, app, ~)
           if strcmp(app.StepOrPlayButton, 'play')
               app.PlayStopButton.Icon = which('stop.png');
           end
           
           % extract settings from app
           BW = app.BWDropDown.Value;
           BW = BW(~isspace(BW));
           TMN = app.TMNValue;
           
           countTx = 1;
           while (true)
               if obj.stopTest(app)
                   return;
               end
                                
               %% generate test waveform
               [eNodeBOutput, etm] = LTEAppInternals.Tx(TMN, BW);
               app.LTEAppInternalsProp.CyclicPrefix = etm.CyclicPrefix;           
               app.LTEAppInternalsProp.NCellID = etm.NCellID;
               app.LTEAppInternalsProp.SamplingRate = etm.SamplingRate;

               % scale the signal and cast to int16
               backoff = -5; % dB
               Output_max = max([max(abs(real(eNodeBOutput))) max(abs(imag(eNodeBOutput)))]);
               eNodeBOutput = eNodeBOutput.*(10^(backoff/20))/Output_max;
               eNodeBOutput = int16(eNodeBOutput*2^15);

               %% transmit waveform using ADALM-PLUTO over a loopback cable and
               % receive waveform
               dataRx = obj.ADRV9002Radio(app, eNodeBOutput, countTx);
               countTx = countTx+1;
               
               %% demodulate received waveform and compute metrics
               [dataRx, FreqOffset, frameOffset] = ...
                   LTEAppInternals.CorrectFreqFrameOffset(dataRx, etm);
%                obj.FrequencyCorrection = obj.FrequencyCorrection + ...
%                    FreqOffset/obj.ADRV9002Tx.CenterFrequency*1e6;
               app.LTEAppInternalsProp.FreqOffset = FreqOffset;
               app.LTEAppInternalsProp.FrameOffset = frameOffset/etm.SamplingRate;

               % compute freq offset and IQ offset
               cec.PilotAverage = 'TestEVM';            
               [FreqOffset2, IQOffset_temp, refGrid, rxGridLow, rxGridHigh, ...
                   rxWaveform, nSubframes, nFrames, alg, frameEVM] = ...
                   LTEAppInternals.Sync(etm, cec, dataRx);
%                obj.FrequencyCorrection = obj.FrequencyCorrection + ...
%                    FreqOffset2/obj.ADRV9002Tx.CenterFrequency*1e6;
               app.LTEAppInternalsProp.IQOffset = IQOffset_temp;

               % stop test if needed
               if obj.stopTest(app)
                   return;
               end
               
               % estimate channel
               [psd_frame, f, HestLow, HestHigh, allPRBSet] = ...
                   LTEAppInternals.EstimateChannel(etm, ...
                   rxWaveform, nSubframes, cec, rxGridLow, rxGridHigh);
               app.LTEAppInternalsProp.PSD_x = f;
               app.LTEAppInternalsProp.PSD_y = psd_frame;

               % compute EVM measurements           
               gridDims = lteResourceGridSize(etm);
               L = gridDims(2);    
               evmSymbolPlot = app.evmSymsAxes;
               evmSymbolPlot.XLim = [0 (L*nSubframes)-1];

               app.LTEAppInternalsProp.count = 1;           
               for i=0:nSubframes-1
                   app.SummaryTable1_Data{1} = app.LTEAppInternalsProp.CyclicPrefix;
                   app.SummaryTable1_Data{2} = app.LTEAppInternalsProp.NCellID;
                   % stop test if needed
                   if obj.stopTest(app)
                       return;
                   end
                   msg = sprintf('Processing Subframe #%d\n', i); 
                   app.Label.Text = {msg};
                   drawnow; 
                    
                   app.LTEAppInternalsProp.SubFrameIndex = i;

                   [EqGridStruct, EVMStruct, evm, allocatedSymbols, rxSymbols, ...
                       refSymbols, pdsch_ind, etm] = ...
                       LTEAppInternals.EVMSubframe(i, nSubframes, etm, allPRBSet, ...
                       refGrid, rxGridLow, rxGridHigh, HestLow, HestHigh);
                   if (etm.CellRefP ~= 1) && (etm.CellRefP ~= 2) && (etm.CellRefP ~= 4)
                       obj.StopTest = true;
                       status = sprintf...
                           ('Test stopped. RF loopback cable likely disconnected. For the demodulated parameter field CellRefP, the value (%d) is not one of the set (1, 2, 4).',...
                           etm.CellRefP);
                       app.Label.Text = {status};   
                       app.PlayStopButtonState = ~app.PlayStopButtonState;
                       app.PlayStopButton.Icon = which('play.png');
                   end
                   if obj.stopTest(app)
                       return;
                   end
                   app.LTEAppInternalsProp.EqGridStruct = EqGridStruct;
                   app.LTEAppInternalsProp.DemodSyms = ...
                       struct('Rec', rxSymbols, 'Ref', refSymbols);

                   if isfield(EVMStruct, 'PBCH')
                       app.LTEAppInternalsProp.evm_pbch_RMS = 100*EVMStruct.PBCH;
                   end               
                   if isfield(EVMStruct, 'PCFICH')
                       app.LTEAppInternalsProp.evm_pcfich_RMS = 100*EVMStruct.PCFICH;
                   end
                   if isfield(EVMStruct, 'PHICH')
                       app.LTEAppInternalsProp.evm_phich_RMS = 100*EVMStruct.PHICH;
                   end
                   if isfield(EVMStruct, 'PDCCH')
                       app.LTEAppInternalsProp.evm_pdcch_RMS = 100*EVMStruct.PDCCH;
                   end
                   if isfield(EVMStruct, 'RS')
                       app.LTEAppInternalsProp.evm_rs_RMS = 100*EVMStruct.RS;
                   end
                   if isfield(EVMStruct, 'PSS')
                       app.LTEAppInternalsProp.evm_pss_RMS = 100*EVMStruct.PSS;
                   end
                   if isfield(EVMStruct, 'SSS')
                       app.LTEAppInternalsProp.evm_sss_RMS = 100*EVMStruct.SSS;
                   end

                   [SymbEVM, ScEVM, RbEVM, frameLowEVM, frameHighEVM, frameEVM, etm,...
                       app.LTEAppInternalsProp.count, app.LTEAppInternalsProp.nFrame] = ...
                       LTEAppInternals.DemodSymbs(i, pdsch_ind, nFrames, ...
                       app.LTEAppInternalsProp.count, alg, etm, evm, ...
                       allocatedSymbols, frameEVM, nSubframes);
                   SymbEVM.evmSymbolRMS(1) = SymbEVM.evmSymbolRMS(2);
                   SymbEVM.evmSymbolPeak(1) = SymbEVM.evmSymbolPeak(2);
                   app.LTEAppInternalsProp.evmSC = ...
                       struct('RMS', ScEVM.evmSubcarrierRMS, 'Peak', ScEVM.evmSubcarrierPeak, ...
                       'EVMGrid', ScEVM.evmGrid); 
                   PDSCHevm_temp = ScEVM.evmGrid(:);
                   app.LTEAppInternalsProp.PDSCHevm = mean(PDSCHevm_temp(PDSCHevm_temp~=0));
                   app.LTEAppInternalsProp.evmRB = ...
                       struct('RMS', RbEVM.evmRBRMS, 'Peak', RbEVM.evmRBPeak);  
                   app.LTEAppInternalsProp.evmSymbol = ...
                       struct('RMS', SymbEVM.evmSymbolRMS, 'Peak', SymbEVM.evmSymbolPeak);
                   
                   if (mod(i, 10)==9 || (nFrames==0 && i==nSubframes-1))                       
                       app.LTEAppInternalsProp.FrameEVM = ...
                           struct('Low', frameLowEVM, ...
                           'High', frameHighEVM, 'Overall', frameEVM);                                       
                   end    
                   
                   if (i == 0)
                       app.SummaryTable1.Data(:, 2) = app.SummaryTable1_Data;
                   end                   
                   
                   app.SummaryTable2.Data(:, 3) = app.SummaryTable2_Data;
                   if (i == nSubframes-1)
                       temp_SummaryTable3 = cell(8, 1);
                       for ii = 1:8
                           app.SummaryTable3_Data(ii, 3) = ...
                               app.SummaryTable3_Data(ii, 1)/app.SummaryTable3_Data(ii, 2);
                           if strcmp(app.dBPercentDropDown.Value, 'dB')
                               temp_SummaryTable3{ii} = ...
                                   sprintf('%2.3f', 20*log10(0.01*app.SummaryTable3_Data(ii, 3)));
                           else
                               temp_SummaryTable3{ii} = sprintf('%2.3f', app.SummaryTable3_Data(ii, 3));
                           end
                       end
                       app.SummaryTable3.Data(:, 2) = temp_SummaryTable3;
                       app.SummaryTable1.Data{end, 2} = temp_SummaryTable3{end};
                   end
                   if (strcmp(app.StepOrPlayButton, 'step') && (i == nSubframes-1))
                       app.Label.Text = {'Test stopped.'};
                       app.EnableDisableGUIComponents('on');
                       % app.TxDropDown.Value = obj.ADRV9002Tx.RadioID;
                       % app.RxDropDown.Value = obj.ADRV9002Rx.RadioID;
                       % obj.ADRV9002Rx.FrequencyCorrection = 0;
                       obj.ADRV9002Rx();
                       obj.ADRV9002Rx.release();
                       drawnow; 
                       return;
                   end                   
               end
               % Final Mean EVM across all frames
               app.LTEAppInternalsProp.FinalEVM = lteEVM(cat(1, frameEVM(:).EV));               
           end
        end
        
        function handleStopEvnt(obj, app, ~)
            obj.StopTest = true;
            obj.ADRV9002Tx.release();
            % obj.ADRV9002Rx.FrequencyCorrection = 0;
            obj.ADRV9002Rx();
            obj.ADRV9002Rx.release();
            app.PlayStopButton.Icon = which('play.png');
            drawnow; 
        end          
        
        function killtest = stopTest(obj, app)
            killtest = obj.StopTest;
            if (killtest)
                app.EnableDisableGUIComponents('on');
                % app.TxDropDown.Value = obj.ADRV9002Tx.RadioID;
                % app.RxDropDown.Value = obj.ADRV9002Rx.RadioID;
                drawnow;  
                obj.StopTest = false;                
            end
        end
   end
end