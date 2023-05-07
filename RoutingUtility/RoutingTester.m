%% clear
clear
clc
close all
addpath('./RoutingUtility');
%% Generate Connectivity Matrix 
% required config
SensorDist                    = 0.5;
FieldSizeFactorX              = 31; % bug - doens't work for numbers smaller than 14 
FieldSizeFactorY              = 31; 
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
%% straight line (minimal connections)

SensorConnectivityGraph = diag(ones(1,50),1); % the elments of the vector ones(1,4) on the 1st diagonal 
SensorConnectivityGraph = SensorConnectivityGraph + SensorConnectivityGraph';
GatewaySensors = 1;

%% straight line (more connections)

SensorConnectivityGraph = diag(ones(1,29),1) + diag(ones(1,28),2) + diag(ones(1,27),3) + diag(ones(1,26),4) + diag(ones(1,25),5); % the elments of the vector ones(1,4) on the 1st diagonal 
SensorConnectivityGraph = SensorConnectivityGraph + SensorConnectivityGraph';
GatewaySensors = [1;2;3;4;5];

%% Calculate the Routing 

[numOfRemainingSensors, blockChainsDB, SensorUsages, SensorCovering, RelayRoutingBlocks] = Routing(SensorConnectivityGraph, GatewaySensors);
[numOfSensors, ~] = size(SensorConnectivityGraph);

%% visualize

% the graph
G = graph(SensorConnectivityGraph);
p = plot(G);

% the chains
[numOfBlocks, lengthOfChains] = size(blockChainsDB);
for i=1:numOfBlocks
    color = rand(1,3);
    currentBlock = blockChainsDB(i,:);
    for j=1:lengthOfChains
        edge = [0,0];
        source = currentBlock(j).Rx;
        if isempty(source)
            source = currentBlock(j).RxWait;
        end
        dest = currentBlock(j).Tx;
        if isempty(dest)
            dest = currentBlock(j).TxRelay;
        end

        if ~isempty(source)
            highlight(p, source, 'NodeColor',color, 'LineWidth',3);
            edge(1,1) = source;
        end
        if ~isempty(dest)
            highlight(p, dest, 'NodeColor',color, 'LineWidth',3);
            edge(1,2) = dest;
        end
        if sum(edge==[0,0])==0
            highlight(p, edge, 'EdgeColor',color, 'LineWidth',3);
        end
        % waitforbuttonpress;
        %pause(0.05);
    end
end

%% analyze

fprintf("Number of total sensors: %d\n", numOfSensors);
fprintf("Number of unrouted sensors: %d\n", numOfRemainingSensors);
% fprintf("Length of longest chain: %d\n\n", lengthOfChains);
