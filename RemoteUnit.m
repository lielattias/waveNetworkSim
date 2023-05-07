classdef RemoteUnit < handle
    
   properties (SetAccess = private)
      MAC               (1,1)  {mustBeInteger}      % MAC address
      ID                (1,1)  {mustBeInteger} = 0  % identifier of the RU inside the network, default is 0 
                                            
      Nrap                                          % RU's NRAP
      NumWakeUpTS       (1,1)  {mustBeInteger}      % number of wake up time slots - for analysis  
      ReachableRUs      (1,:)  {mustBeVector}       % list of reachable RUs and SNR measurements 
      Packet                                   = [] % the actual packet 
      IsAssociated      (1,1)                  = 0  % is the RU connected to the network      
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
                   fprintf("%d transmitted packet %s\n", obj.ID, obj.Packet);
                   
                   % delete the packet from RU's memory 
                   obj.Packet = [];  
               end

               % TxRelay
               if strcmp(action, 'TxRelay')
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
               end

               % Rx
               if strcmp(action, 'Rx')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   fprintf("%d received packet %s\n", obj.ID, obj.Packet);
               end

               % RxWait
               if strcmp(action, 'RxWait')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   fprintf("%d received (and wait...) packet %s\n", obj.ID, obj.Packet);
               end


           % DL
           elseif strcmp(direction, 'DL')

               % Tx
               if strcmp(action, 'Tx')
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
                   fprintf("%d transmitted packet %s\n", obj.ID, obj.Packet);
               end

               % TxWait
               if strcmp(action, 'TxWait')
                   channel.writeToChannel(obj.Packet, freqIndex, obj.ID);
                   fprintf("%d transmitted (wait...) packet %s\n", obj.ID, obj.Packet);
               end

               % Rx
               if strcmp(action, 'Rx')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   % save relevant signature... (bit-wise simulation)
                   fprintf("%d received packet %s\n", obj.ID, obj.Packet);
               end

               % RxRelay
               if strcmp(action, 'RxRelay')
                   obj.Packet = channel.readFromChannel(freqIndex, obj.ID);
                   % do not save any signature !
                   fprintf("%d received (relay...) packet %s\n", obj.ID, obj.Packet);
               end


           else
               fprintf('link type must be UL/DL');
           end
       end
        

       % create/modify the packet, depends on UL/DL and simulationLevel
       function obj = createPacket(obj, link)
           GeneralParams = obj.setgetGeneralParams();
           if strcmp(link, 'UL')

               % if "packet" field is empty, there are two possible reasons:
               % * this RU is a leaf in its block
               % * the received packet was corrupted and therefore wasn't saved 

               if isempty(obj.Packet)
                   if GeneralParams.SimLevel
                       obj.Packet = '1';
                       fprintf("%d created new packet \n", obj.ID);
                   else
                       % "bit-wise" simulation ----- to be continued 
                   end
               else
                   if ~simulationLevel % only for "bit-wise" simulation, add the signature
                       % ....
                   end
               end

           elseif strcmp(link, 'DL')
               %....

           else
               fprintf('link type must be UL/DL');
           end
       end

   end
end