classdef NRAP < handle
    % NRAP - Network Resource Allocation Process 
    % The GW sends to each RU an NRAP which provide it with all the info
    % regarded communication scheme 
    
    properties %(SetAccess = private)
        NumTsFrame         (1,1)   {mustBeInteger}                   % number of TS in frame (9 bits)
        SigIndex           (1,1)   {mustBeInteger}                   % signature index (4 bits)
        freqChOfBlock      (1,1)   {mustBeInteger}                   % freq for ULRxTx, ULTx, DLRxTX and DLRx

        % uplink parameters transmits 

        ULRxTx                                                       % The RU receives a packet at TS, and transmits (adding its own signature)
                                                                     % at the sequential time slot (9 bits)
                                                                     
        ULRxTxRelay = struct('TS', cell(5,1), 'freqCH', cell(5,1));  % TS indexes &  freqs in which RU receives a messege and transmits
                                                                     % it in the next TS (65? bits)

        ULRxWait    = struct('TS', cell(3,1));                       % TS indexes & freqs in which RU receives a message, saves it
                                                                     % in its memory, and waits till the next Rx/RxWait (27 bits)
        
        ULTx                                                         % The RU transmits a packet at TS. 
                                                                     % This fresh packet contain only this RU s signature 
                                                                     % (i.e. this RU is the first in the block) (9 bits)
                                                      
        % downlink parameters 
        % GW will provide only the UL parameters. The DL parameters will be
        % calculated by the RU. 

        DLRxTx                                                       % TS indexes (relative to frame start) & freqs 
                                                                     % in which RU receives a message, extract its NRAP from it,
                                                                     % saves the whole message and transmits it in the 
                                                                     % next TS 

        DLRxRelayTx = struct('TS', cell(5,1), 'freqCH', cell(5,1));  % TS indexes &  freqs in which RU receives a message and 
                                                                     % transmits it in the sequential time slot, 
                                                                     % without saving any part of the message in its memory

        DLTxWait    = struct('TS', cell(3,1));                       % TS indexes & freqs in which RU transmits the message 
                                                                     % it stored in its memory 

        DLRx        
       
    end
    
    methods
        function obj = NRAP()
        % empty constructor 
        end
        
        function NRAPmessege = createBitMessege(obj)
            % createBitMessege forms the properties into one string of bits
            % that represents the NRAP
            NRAPmessege = strcat(dec2bin(obj.NumTsFrame, 10), ...
                                 dec2bin(obj.SigIndex, 5),...
                                 dec2bin(obj.ULRxTx.TS, 10), dec2bin(obj.ULRxTx.freqCH, 5),...
                                 dec2bin(obj.ULRxTxRelay(1).TS, 10),dec2bin(obj.ULRxTxRelay(1).freqCH, 5),...
                                 dec2bin(obj.ULRxTxRelay(2).TS, 10),dec2bin(obj.ULRxTxRelay(2).freqCH, 5));
            %.... 
        end
    end
end

