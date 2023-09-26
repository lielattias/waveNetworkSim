classdef DLMessage < handle & BasicMessage
    
    properties           
        SharedControl             % NRAP+MAC to one RU
        Data                      % data to transmit (temp...) (8 bits each)
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
        function obj = DLMessage(sharedControl, dataArr)
            if nargin
                obj.SharedControl = sharedControl;
                obj.Data = dataArr;
            else 
                % there is no need to actually send information for the
                % simulation purposes (but maybe we'll change our minds...)
                obj.SharedControl = -1;
                obj.Data = -1;
            end
        end
        
        function obj = AddInfo(ctrl, data, sigIndex)
            % add info to the message & update CRC
            
        end
    end
end
