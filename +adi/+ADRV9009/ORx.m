classdef ORx < adi.ADRV9009.Base & adi.common.Rx
    % adi.ADRV9009.ORx Receive data from the ADRV9009 transceiver observation receiver
    %   The adi.ADRV9009.ORx System object is a signal source that can receive
    %   complex data from the ADRV9009. This object is used for both
    %   observation and sniffer paths since they share ADCs within the
    %   transceiver itself.
    %
    %   rx = adi.ADRV9009.ORx;
    %   rx = adi.ADRV9009.ORx('uri','192.168.2.1');
    %
    %   <a href="http://www.analog.com/media/en/technical-documentation/data-sheets/ADRV9009.pdf">ADRV9009 Datasheet</a>    
    properties
        %Gain Gain
        %   Rx gain, specified as a scalar from 0 dB to 52 dB. The acceptable
        %   minimum and maximum gain setting depends on the center
        %   frequency.
        Gain = 10;
        %AUXFrequency AUX Center Frequency
        %   RF center frequency of AUX PLL, specified in Hz as a scalar. The
        %   default is 2.4e9.  This property is tunable.
        AUXFrequency = 2.4e9;
    end

    properties (Nontunable, Logical) % MUST BE NONTUNABLE OR SIMULINK WARNS
        %EnableQuadratureTracking Enable Quadrature Tracking
        %   Option to enable quadrature tracking, specified as true or
        %   false. When this property is true, IQ imbalance compensation is
        %   applied to the input signal.
        EnableQuadratureTracking = true;
    end
    
    properties
        %LOSourceSelect LO Source Select
        %    'OBS_TX_LO' – ORx operates in observation mode on ORx1 with
        %       RxTx LO synthesizer
        %    'OBS_AUX_LO' – ORx operates in observation mode on ORx2 with
        %       AUX LO synthesizer
        LOSourceSelect = 'OBS_TX_LO';
    end
    
    properties(Constant, Hidden)
        LOSourceSelectSet = matlab.system.StringSet({ ...
            'OBS_TX_LO','OBS_SN_LO'});
    end
    
    properties (Hidden, Nontunable, Access = protected)
        isOutput = false;
    end
    
    properties(Nontunable, Hidden, Constant)
        Type = 'Rx';
        channel_names = {'voltage0_i','voltage0_q','voltage1_i','voltage1_q'};
    end
    
    properties (Nontunable, Hidden)
        devName = 'axi-adrv9009-rx-obs-hpc';
    end
    
    methods
        %% Constructor
        function obj = ORx(varargin)
            coder.allowpcode('plain');
            obj = obj@adi.ADRV9009.Base(varargin{:});
        end
        % Check LOSourceSelect
        function set.LOSourceSelect(obj, value)
            obj.LOSourceSelect = value;
            if obj.ConnectedToDevice
                obj.setAttributeRAW('voltage2','rf_port_select',value,false);
            end
        end
        % Check Gain
        function set.Gain(obj, value)
            validateattributes( value, { 'double','single' }, ...
                { 'real', 'scalar', 'finite', 'nonnan', 'nonempty', '>=', -4,'<=', 71}, ...
                '', 'Gain');
            assert(mod(value,1/4)==0, 'Gain must be a multiple of 0.25');
            obj.Gain = value;
            if obj.ConnectedToDevice
                obj.setAttributeLongLong('voltage2','hardwaregain',value,false);
            end
        end
        % Check EnableQuadratureTracking
        function set.EnableQuadratureTracking(obj, value)
            obj.EnableQuadratureTracking = value;
            if obj.ConnectedToDevice
                obj.setAttributeBool('voltage2','quadrature_tracking_en',value,false);
            end
        end
    end
    
    methods (Access=protected)
        
        function AUXFrequencySet(obj,value)
            if obj.ConnectedToDevice
                obj.setAttributeLongLong('altvoltage1','AUX_OBS_RX_LO_frequency',value,true);
            end
        end
        function CenterFrequencySet(obj,value)
            if obj.ConnectedToDevice
                obj.setAttributeLongLong('altvoltage0','frequency',value,true);
            end
        end

    end
    
    %% API Functions
    methods (Hidden, Access = protected)
                
        function setupInit(obj)
            % Write all attributes to device once connected through set
            % methods
            % Do writes directly to hardware without using set methods.
            % This is required sine Simulink support doesn't support
            % modification to nontunable variables at SetupImpl
            
            if obj.EnableCustomProfile
                writeProfileFile(obj);
            end
            
            % Power everything down first
            obj.setAttributeBool('voltage0', 'powerdown', true, false);
            obj.setAttributeBool('voltage1', 'powerdown', true, false);
            obj.setAttributeBool('voltage2', 'powerdown', true, false);
            obj.setAttributeBool('voltage3', 'powerdown', true, false);
            % Only bring ORx back up
            obj.setAttributeBool('voltage2', 'powerdown', false, false);
            if obj.getAttributeLongLong('voltage0','sampling_frequency',true) < 250e6
                obj.setAttributeBool('voltage3', 'powerdown', false, false);
            end
            % Set all remaining attributes
            obj.setAttributeBool('voltage2','quadrature_tracking_en',obj.EnableQuadratureTracking,false);
            obj.setAttributeLongLong('altvoltage1','AUX_OBS_RX_LO_frequency',obj.AUXFrequency,true);
            obj.setAttributeLongLong('altvoltage0','frequency',obj.CenterFrequency,true);            
            obj.setAttributeRAW('voltage2','rf_port_select',obj.LOSourceSelect,false);
            obj.setAttributeLongLong('voltage2','hardwaregain',obj.Gain,false);
                        
        end
        
    end
    
end

