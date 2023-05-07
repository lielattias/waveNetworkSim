classdef ULMessage < handle
    
    properties         
        MACs     (16, 1) {mustBeVector}     % Ctrl: MAC (9 bits each)
        SNR      (16, 1) {mustBeVector}     % Ctrl: SNR (4 bits each)
        Data     (16, 1) {mustBeVector}     % data to transmit (temp...) (8 bits each)
    end
    
    methods (Static)
       % define persistent variables:
       % MsgParams
       % since those are the same for all instances

       function out = setgetMsgParams(msgParams)
           persistent MsgParams;
           if nargin
               MsgParams = msgParams;
           end
           out = MsgParams;
       end
    end

    methods
        function obj = ULMessage()
            MsgParams = obj.setgetMsgParams();
            obj.Ctrl = zeros(16, MsgParams.NumCtrlBitsPerSig); % Ctrl = MAC + SNR 
            obj.Data = zeros(16, MsgParams.NumDataBitsPerSig);
        end
        
        function obj = AddInfo(ctrl, data, sigIndex)
            % add info to the message & update CRC
            
        end
    end
end
