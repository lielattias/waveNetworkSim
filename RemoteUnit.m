classdef RemoteUnit < handle
    
   properties (SetAccess = private)
      MAC               (1,1)  {mustBeInteger}      % MAC address
      ID                (1,1)  {mustBeInteger} = 0  % identifier of the RU inside the network, default is 0 
                                            
      Nrap                                          % RU's NRAP
      NumWakeUpTS       (1,1)  {mustBeInteger}      % number of wake up time slots - for analysis  
      ReachableRUs      (1,:)  {mustBeVector}       % list of reachable RUs and SNR measurements 
      Packet                                   = [] % the actual packet 
      IsAssociated      (1,1)                  = 0  % is the RU connected to the network 
%       data                                          % ?
   end

   methods (Static)
       % define persistent variables:
       % NetworkChannel
       % TechChannel
       % GeneralParam
       % since those are the same for all instances
       function out = setgetChannel(channel)
           persistent NetworkChannel;
           if nargin
               NetworkChannel = channel;
           end
           out = NetworkChannel;
       end

       function out = setgetTechChannel(techChannel)
           persistent TechnicianChannel;
           if nargin
               TechnicianChannel = techChannel;
           end
           out = TechnicianChannel;
       end

       function out = setgetGeneralParams(generalParams)
           persistent GeneralParams;
           if nargin
               GeneralParams = generalParams;
           end
           out = GeneralParams;
       end
   end

   methods     
       % practically any construction of new object would include only the
       % MAC field (the rest is given by the GW) 
       function obj = RemoteUnit(mac, id, nrap)
           if nargin >= 1
               obj.MAC = mac;
               obj.ID = mac;  % for debugging!!!
           end
            
           if nargin >= 2
               obj.ID = id;
           end
           if nargin == 3
               obj.Nrap = nrap;
           end
       end
   
       function obj = setNRAP(obj, nrap)
            % add / change the NRAP field
            obj.Nrap = nrap;
       end
        
       function obj = setID(obj, id)
           obj.ID = id;
       end
      
       function obj = activate(obj, direction, action, freqIndex)
           channel = obj.setgetChannel();
           % UL
           if strcmp(direction, 'UL')

               % Tx
               if strcmp(action, 'Tx')
                   obj.createPacket(direction); % create/modify packet to transmit 
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
%                    fprintf("%d transmitted packet %s\n", obj.ID, obj.Packet);
                   fprintf("%d transmitted packet \n", obj.ID);
                   
                   % delete the packet from RU's memory 
                   obj.Packet = [];  
               end

               % TxRelay
               if strcmp(action, 'TxRelay')
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
               end

               % Rx
               if strcmp(action, 'Rx')
                   if isempty(obj.Packet)
                        obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   else
                       packetToMerge = channel.readFromChannel(freqIndex, obj.ID);
                       idx = find(~obj.Packet.Data); % maybe put some special value like -1 later
                       obj.Packet.Data(idx) = packetToMerge.Data(idx);
                   end
                   fprintf("%d received packet \n", obj.ID);
               end

               % RxWait
               if strcmp(action, 'RxWait')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   fprintf("%d received (and wait...) packet \n", obj.ID);
               end


           % DL
           elseif strcmp(direction, 'DL')

               % Tx
               if strcmp(action, 'Tx')
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
                   fprintf("%d transmitted packet\n", obj.ID);
               end

               % TxWait
               if strcmp(action, 'TxWait')
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
                   fprintf("%d transmitted (wait...) packet\n", obj.ID);
               end

               % Rx
               if strcmp(action, 'Rx')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   % save relevant signature... (bit-wise simulation)
                   % obj.extractPacket???
                   fprintf("%d received packet\n", obj.ID);
               end

               % RxRelay
               if strcmp(action, 'RxRelay')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   % do not save any signature !
                   fprintf("%d received (relay...) packet\n", obj.ID);
               end


           else
               fprintf('link type must be UL/DL');
           end
       end
        
       % create/modify the packet, depends on UL/DL and SimLevel
       function obj = createPacket(obj, direction)
           GeneralParams = obj.setgetGeneralParams();
           if strcmp(direction, 'UL')

               % if "packet" field is empty, there are two possible reasons:
               % 1. this RU is a leaf in its block
               % 2. the received packet was corrupted and therefore wasn't saved

               ctrl = 1; % those two should be fields of the obj
               data = obj.Nrap.SigIndex;

               if isempty(obj.Packet)
                   if GeneralParams.SimLevel
                       obj.Packet = '1';
                   else
                       % ctrl and data should be saved in the RU's
                       % memory and measured before
                       obj.Packet = ULMessage(obj.Nrap.SigIndex, ctrl, data);
                   end
                   fprintf("%d created new packet \n", obj.ID);

               else
                   if ~GeneralParams.SimLevel 
                       obj.Packet.addSig(obj.Nrap.SigIndex, ctrl, data);
                   end
               end

           elseif strcmp(direction, 'DL')
               % there are no packet creations in DL, instead a packet is
               % saved and the relevant fields are parsed (Rx) or just saved
               % to be transmitted again later (RxRelay)
               % here, we'll take care of the Rx operation only 
               if ~GeneralParams.SimLevel
                   % obj.Packet.getData ?
               end

           else
               fprintf('link type must be UL/DL');
           end
       end

   end
end