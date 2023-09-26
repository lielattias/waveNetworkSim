clc; clear; close all;

%% Set-up 
addpath("RoutingUtility\");
Config; % Params struct

threshold = 10;

% for now I am using this scenario creation, maybe I'll write my own later
[SensorConnectivityGraph, GatewaySensors] = GenerateConnectivityMatrix(14);

% save the info at the channel 
SNRGateway = zeros(length(SensorConnectivityGraph), 1);
SNRGateway(GatewaySensors) = threshold;
channel = Channel(SensorConnectivityGraph*threshold, SNRGateway); % for now make all SNR 6 db

% assign general params structs
channel.setgetGeneralParams(Params.General);
RemoteUnit.setgetChannel(channel);
RemoteUnit.setgetGeneralParams(Params.General);
Gateway.setgetChannel(channel);
Gateway.setgetGeneralParams(Params.General);
ULMessage.setgetMsgParams(Params.Msg);
DLMessage.setgetMsgParams(Params.Msg);

% calculate the Routing --- not relevant to the real network
GW = Gateway(SensorConnectivityGraph, GatewaySensors); % this matrix should be built during the network operation
numOfRemainingSensors = GW.routing();
GW.createNRAPList(); 

%% external events inputs

%% main loop: network operation (no joining protocol)

direction = 'UL';
% direction = 'DL';
simulationLevel = 1; % "packet-wise"

% build RUs list
RUs(GW.NumAssociatedRUs, 1) = RemoteUnit();
for i=1:GW.NumAssociatedRUs
    RUs(i,1).setID(i);
    RUs(i,1).setNRAP(GW.NRAPList(i)); % assign NRAP for each RU (assumption) - unnecessary for the simulation
end

% UL
if strcmp(direction, 'UL')
    % use the freq-time matrix and go over the columns
    for epoch = 1:width(GW.TimeFreqMatrix)
        currentEpoch = GW.TimeFreqMatrix(:, epoch); % matrix column

        for freqIndex = 1:height(GW.TimeFreqMatrix)
            cell = currentEpoch(freqIndex);

            % activate RU
            if ~isempty(cell.TxRelay)
                RUs(cell.TxRelay).activate(direction, 'TxRelay', freqIndex);
            end
            if ~isempty(cell.Tx)
                RUs(cell.Tx).activate(direction, 'Tx', freqIndex);
            end
            if ~isempty(cell.Rx)
                if cell.Rx == 0
                    % GW "reads" the packet and saves it
                    GW.activate(direction, freqIndex, epoch); % do it like RU
                else
                    RUs(cell.Rx).activate(direction, 'Rx', freqIndex);
                end
            end
            if ~isempty(cell.RxWait)
                RUs(cell.RxWait).activate(direction, 'RxWait', freqIndex);
            end

        end
    end

% DL
elseif strcmp(direction, 'DL')
    % use the freq-time matrix and go over the columns
    for epoch = width(GW.TimeFreqMatrix):-1:1 % end to begginig 
        currentEpoch = GW.TimeFreqMatrix(:,epoch); % matrix column

        for freqIndex = 1:height(GW.TimeFreqMatrix)
            cell = currentEpoch(freqIndex);

            % activate RU
            if ~isempty(cell.Rx) % DL: Tx
                if cell.Rx == 0
                    % GW creates a packet & sends it 
                    GW.activate(direction, freqIndex, epoch);
                else
                    RUs(cell.Rx).activate(direction, 'Tx', freqIndex);
                end
            end
            if ~isempty(cell.RxWait) % DL: TxWait
                RUs(cell.RxWait).activate(direction, 'TxWait', freqIndex);
            end
            if ~isempty(cell.TxRelay) % DL: RxRelay
                RUs(cell.TxRelay).activate(direction, 'RxRelay', freqIndex);
            end
            if ~isempty(cell.Tx) % DL: Rx
                RUs(cell.Tx).activate(direction, 'Rx', freqIndex);
            end

        end
    end
end 

%% general structure

% for frame=1:numOfFrames
%     for link=1:numOfLinksInFrame*2
%         for ts=0:lengthOfLink
%         % external event - based on the external event, changes to the
%         % Channel object will occur here.
% 
%             % UL
%             % RUs send info to GW
%             if mod(link,2) == 1
%                 
% 
%             % DL
%             % GW sends info to RUs
%             else
%                 
%             end
% 
%         end
%     end
% 
%     % GW assessments 
% 
%     % track lost packets
%     % try to identify the RUs that caused the problem.
%     % try to infer RU's state - connected, disconnected, poorley connected
%     % and act accordingly. 
% 
%     % rerouting 
%     % * if packets were lost and some RU's states were changed,
%     % rerout the network. note that the next frame will still be routed
%     % according to the "old" rerouting. 
%     % * if new sensors were "discovered", the GW will reroute. 
% 
%     % if the RUs send bits, the GW should save all the payload bits.
% 
% end
% 
