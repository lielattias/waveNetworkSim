classdef BasicMessage < handle
    
    properties
        % header - 32 bits
        NetworkID      (1,1)  = 1    % for distinguishing between packets of different networks (8 bits)
        NetworkState   (1,1)         % 00 - Advertising state, 01 - Re-route state (2 bits)
        FrameNumber    (1,1)         % frame number (5 bits)
        SigValids      (1,1)         % how many signatures are valid different meanings for UL / DL (5 bits)
        CRCHeader      (1,1)         % CRC for header (12 bits)

    end
    
    methods
        function obj = BasicMessage()
            % empty constructor
        end
        
    end
end
