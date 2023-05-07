clc;clear;close all;

addpath("RoutingUtility\");
Config; %Params struct

%% Senario creation  

threshold = 6;

% for now I am using this scenario creation, maybe I'll write my own later
[SensorConnectivityGraph, GatewaySensors] = GenerateConnectivityMatrix(14);

% save the info at the channel 
SNRGateway = zeros(length(SensorConnectivityGraph), 1);
SNRGateway(GatewaySensors) = threshold;
channel = Channel(SensorConnectivityGraph*threshold, SNRGateway, Params.General); % for now make all SNR 6 db

% calculate the Routing 
GW = Gateway(Params.General, SensorConnectivityGraph, GatewaySensors);
numOfRemainingSensors = GW.routing();
GW.createNRAPList(); %-------------fails since I changed the NRAP

%% external events inputs

%% general structure

for frame=1:numOfFrames
    for link=1:numOfLinksInFrame*2
        for ts=0:lengthOfLink
        % external event - based on the external event, changes to the
        % Channel object will occur here.

            % UL
            % RUs send info to GW
            if mod(link,2) == 1
                

            % DL
            % GW sends info to RUs
            else
                
            end

        end
    end

    % GW assessments 

    % track lost packets
    % try to identify the RUs that caused the problem.
    % try to infer RU's state - connected, disconnected, poorley connected
    % and act accordingly. 

    % rerouting 
    % * if packets were lost and some RU's states were changed,
    % rerout the network. note that the next frame will still be routed
    % according to the "old" rerouting. 
    % * if new sensors were "discovered", the GW will reroute. 

    % if the RUs send bits, the GW should save all the payload bits.

end

