classdef DLMessage < handle
    
    properties         
        MAC      (?, 1) {mustBeVector}     % Ctrl: MAC
        NRAP     (?, 1) {mustBeVector}     % Ctrl: NRAP 
        Data     (?, 1) {mustBeVector}    % data to transmit (temp...) (8 bits each)
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
            %...
        end
        
        function obj = AddInfo(ctrl, data, sigIndex)
            % add info to the message & update CRC
            
        end
    end
end
