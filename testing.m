clc;clear;close all;

addpath("RoutingUtility\");

%% set up examples
Config;
channel = Channel(Params.General, 10*ones(100), 10*ones(100,1));
techChannel = Channel(Params.General, 10*ones(100), 10*ones(100,1));


RemoteUnit.setgetChannel(channel);
RemoteUnit.setgetTechChannel(techChannel);
RemoteUnit.setgetGeneralParams(Params.General);
RU1 = RemoteUnit(1);
RU2 = RemoteUnit(2);
RU1.setgetChannel()
RU1.setgetTechChannel()
RU2.setgetGeneralParams()

RU1.activate('UL', 'Tx', 1);
RU2.activate('UL', 'Tx', 2);
RU1.activate('UL', 'Rx', 1);

ULMessage.setgetMsgParams(Params.Msg);

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
GW.createNRAPList();
