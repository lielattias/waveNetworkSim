%% clear
clear
clc
close all

fieldSizes = (20:10:90).';
maxRxWait = zeros(length(fieldSizes), 1);
maxTxRelay = zeros(length(fieldSizes), 1);
maxTx = zeros(length(fieldSizes), 1);
numOfSensorsPerIteration = zeros(length(fieldSizes), 1);

for i=1:length(fieldSizes)

%% Generate Connectivity Matrix 
% required config
SensorDist                    = 0.5;
FieldSizeFactorX              = fieldSizes(i); % bug - doens't work for numbers smaller than 14 
FieldSizeFactorY              = fieldSizes(i); 
FieldSize                     = [FieldSizeFactorX*SensorDist, FieldSizeFactorY*SensorDist];
LocationNoise                 = SensorDist*0.7;
AtomGridSizeX                 = SensorDist*6;
AtomGridSizeY                 = SensorDist*6;
GatewayAtomDepth              = SensorDist*6;
MeanSensorConnections         = 9;
ConnectionSearchRadiusInAtoms = 1;
ChannelGradeTh                = 2; 
ChannelGradeFunc              = @(Xa, Ya, Xb, Yb) abs(Xb-Xa).^2 + abs(Yb-Ya).^2;
GatewayAtomsX                 = 2;
GatewayAtomsY                 = 1:2;


% Generate Field Scenario
[SensorPosX, SensorPosY] = GenerateFieldScenario(...
    SensorDist,...
    FieldSize,...
    LocationNoise...
    );
numOfSensors =  numel(SensorPosX);

% Sort into Atoms
[SensorAtomIndex, AtomGridLenX, AtomGridLenY] = GetAtomIndices(...
    SensorPosX,...
    SensorPosY,...
    AtomGridSizeX,...
    AtomGridSizeY,...
    GatewayAtomDepth...
    );

% Generate Sensor Connectivity Graph
SensorConnectivityGraph = GetConnectivityGraph(...
    numOfSensors,...
    MeanSensorConnections,...
    AtomGridLenX,...
    AtomGridLenY,...
    ConnectionSearchRadiusInAtoms,...
    SensorAtomIndex,...
    SensorPosX,...
    SensorPosY,...
    ChannelGradeFunc,...
    ChannelGradeTh...
    );

% Find gateway neighbours
GatewaySensors = FindGWAtoms(...
                             GatewayAtomsX,...
                             GatewayAtomsY,...
                             AtomGridLenX,...
                             AtomGridLenY,...
                             SensorAtomIndex...
                             );
%% Calculate the Routing 

[numOfRemainingSensors, blockChainsDB, SensorUsages, SensorCovering, RelayRoutingBlocks] = Routing(SensorConnectivityGraph, GatewaySensors);
[numOfSensors, ~] = size(SensorConnectivityGraph);

% %% visualize
% 
% % the graph
% G = graph(SensorConnectivityGraph);
% p = plot(G);
% 
% % the chains
% [numOfBlocks, lengthOfChains] = size(blockChainsDB);
% for i=1:numOfBlocks
%     color = rand(1,3);
%     currentBlock = blockChainsDB(i,:);
%     for j=1:lengthOfChains
%         edge = [0,0];
%         source = currentBlock(j).Rx;
%         if isempty(source)
%             source = currentBlock(j).RxWait;
%         end
%         dest = currentBlock(j).Tx;
%         if isempty(dest)
%             dest = currentBlock(j).TxRelay;
%         end
% 
%         if ~isempty(source)
%             highlight(p, source, 'NodeColor',color, 'LineWidth',3);
%             edge(1,1) = source;
%         end
%         if ~isempty(dest)
%             highlight(p, dest, 'NodeColor',color, 'LineWidth',3);
%             edge(1,2) = dest;
%         end
%         if sum(edge==[0,0])==0
%             highlight(p, edge, 'EdgeColor',color, 'LineWidth',3);
%         end
%         % waitforbuttonpress;
%         %pause(0.05);
%     end
% end

%% analyze

% fprintf("Number of total sensors: %d\n", numOfSensors);
% fprintf("Number of unrouted sensors: %d\n", numOfRemainingSensors);

%% NRAP params
% max RxWait actions for RU
RxWaitList = [blockChainsDB(:).RxWait];
counts = histc(RxWaitList, unique(RxWaitList));
maxRxWait(i) = max(counts);

% max TxRelay actions for RU
TxRelayList = [blockChainsDB(:).TxRelay];
counts = histc(TxRelayList, unique(TxRelayList));
maxTxRelay(i) = max(counts);

% sanity check - max Tx actions for RU
TxList = [blockChainsDB(:).Tx];
counts = histc(TxList, unique(TxList));
maxTx(i) = max(counts);

numOfSensorsPerIteration(i) = numOfSensors;
end