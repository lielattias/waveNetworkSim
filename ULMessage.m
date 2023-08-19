classdef ULMessage < handle

    properties
        MACs          % Ctrl: MAC (9 bits each) 
        SNR           % Ctrl: SNR (4 bits each)
        Data          % data to transmit (temperatures etc.) (8 bits each)
        CRC
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
    
        function obj = ULMessage(sigIndex, ctrl, data)
            msgParams = obj.setgetMsgParams();
            obj.MACs = zeros(msgParams.NumSigPerPacket, 1);
            obj.SNR = zeros(msgParams.NumSigPerPacket, 1);
            obj.Data =  zeros(msgParams.NumSigPerPacket, 1);
            if nargin
                % obj.MACs(sigIndex) = zeros(16, MsgParams.NumCtrlBitsPerSig); % Ctrl = MAC + SNR
                obj.MACs(sigIndex) = ctrl;
                obj.SNR(sigIndex) = ctrl; % for now...
                % obj.Data = zeros(16, MsgParams.NumDataBitsPerSig);
                obj.Data(sigIndex) = data;
            end
        end

        function obj = addSig(obj, sigIndex, ctrl, data)
            % add info to the message & update CRC
            obj.MACs(sigIndex) = ctrl;
            obj.SNR(sigIndex) = ctrl; % for now...
            obj.Data(sigIndex) = data;
        end
    end
end
