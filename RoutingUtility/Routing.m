function [numOfRemainingSensors, blockChainsDB, SensorUsages, SensorCovering, RelayRoutingBlocks] = Routing(SensorConnectivityGraph, GatewaySensors)
% written by Lior 
%% Configuration:

BlockMinSize                                    = 4;        % minimal sensors number for a block
MinBlockExtensionsBeforeUpdatingNeghboursPool   = 1;        % num of blocks that should expand before updating the neighbors sensors group 
BlocksPerTimeGroup                             	= 5;        % num of (max) blocks create each time group (concurrently)
SensorsInBlock                                  = 16;       % num of sensors in a block
SensorsInBlockBackOff                           = 1;%4;     % assign 1 to make 16 sensors for a block (root is part of the block)
BlockRelayRoutingPermutations                  	= 3;        % when calculating the relay routing of the blocks try some permutations 
                                                            % and pick the permutation that yield the best routing 
RatioBetweenActiveAndInactiveWeightsInRouting   = 1.5;      % initial weight
InitialRoutingWeights                           = 1/RatioBetweenActiveAndInactiveWeightsInRouting;

%% Params
tic;

RelayRoutingBlocks = [];
blockChainsDB = struct('Rx', [], 'RxWait', [], 'Tx', [], 'TxRelay', []);
isEmptyStruct = @(s) ~isequaln(s, struct('Rx',[],'RxWait',[],'Tx',[],'TxRelay',[]));

%% Generate Sensor Connectivity Graph

[NumOfSensors, ~] =  size(SensorConnectivityGraph);

%% Iterative Addition of sensors

SimTime                         = 1;
SensorIndexes                   = (1:1:NumOfSensors).';
SensorsInBlockSummary           = [];
BlocksInTimeGroup             	= [];
NumOfBlocks                     = 0;
SensorUsages                    = zeros(size(SensorIndexes));
SensorRoutingWeights            = InitialRoutingWeights*double(SensorConnectivityGraph); % each edge has the same weight (1), and later we will add weight for vertex usage (for all edges entering to it)
SensorCovering                  = zeros(size(SensorIndexes));

% Find gateway neighbours
CloseNeighbours = GatewaySensors;


% Find Neighbours
NeighboursDegree            = zeros(numel(CloseNeighbours), 1);
%NeighboursConnectivity defines a "new" graph (meaning - subgraph)
% and describes the connections between sensors in this "new" graph.
%Eventually NeighboursConnectivity is some kind of "sampled" submatrix
%of NeighboursConnectivity - the connectivities between sensors in the
%current atom neighborhood
NeighboursConnectivity      = SensorConnectivityGraph(CloseNeighbours, CloseNeighbours);

NeighboursRoutingWeights    = SensorRoutingWeights(CloseNeighbours, CloseNeighbours);
NeighboursCovering          = SensorCovering(CloseNeighbours);

TimeGroupIndex	= 0;


while (~isempty(CloseNeighbours))

    %% Allocate New Blocks

    TimeGroupIndex                      = TimeGroupIndex + 1;
    SensorsAddedToBlock               	= zeros(BlocksPerTimeGroup, 1);
    AllBlocksAreClosed                  = 0;
    RoutingUpdatedInLastIter            = 1;

    % Find Border Neighbours
    CoveredSensors = find(SensorCovering > 0);

    %% Find Roots
    [BlockRoots, BlockRootsIndexes, BfsGroupsFound, SensorsInTooSmallNeighbourGroups] = GetCurrentBlockRoots(...
        CloseNeighbours,...
        NeighboursCovering,...
        CoveredSensors,...
        SensorConnectivityGraph,...
        BlockMinSize,...
        BlocksPerTimeGroup);
    if 0 == BfsGroupsFound
        break;
    end

    %% Block Relay Routing

    VacantRelaySensors = GetVacantRelaySensors(SensorCovering, SensorsInTooSmallNeighbourGroups);

    [SelectedRelayRouting, BlockRoots, SensorRoutingWeights, SensorUsages] = GetBestRootsRoute(...
        BlockRoots,...
        BlockRelayRoutingPermutations,...
        VacantRelaySensors,...
        SensorRoutingWeights,...
        NumOfSensors,...
        GatewaySensors,...
        SensorUsages);

    % Initialize block parameters after roots are finally selected
    BlocksInTimeGroup(TimeGroupIndex)    	= numel(BlockRoots);
    NeighboursDegree(BlockRootsIndexes)     = 1;
    NeighboursCovering(BlockRootsIndexes)   = NumOfBlocks + randperm(numel(BlockRootsIndexes)); %holds the block IDs
    IntraBlockCounter                       = 0;
    BlocksExtendedInLastIter                = 1:BlocksPerTimeGroup;
    NeighboursPoolRefreshed                 = 0;
    NumOfBlocks                             = NumOfBlocks + numel(BlockRoots);
    RelayRoutingLength                      = cellfun(@numel, SelectedRelayRouting);
    BlockTime                               = SimTime*ones(size(BlockRoots)) + RelayRoutingLength - 1;

    %% Connect neighbours in the current list (a certain BFS level) to Blocks

    while (~AllBlocksAreClosed && ...
            (RoutingUpdatedInLastIter || ~NeighboursPoolRefreshedInPrevIter) )

        BlockTime                          	= BlockTime + 1;           % next time slot for each block
        IntraBlockCounter                   = IntraBlockCounter + 1;
        RoutingUpdatedInLastIter            = 0;                       % reset flag
        NeighboursPoolRefreshed             = 0;                       % reset flag

        %% Refresh Neighbours Pool If Needed
        if (numel(BlocksExtendedInLastIter) < MinBlockExtensionsBeforeUpdatingNeghboursPool && ...
                NeighboursPoolRefreshedInPrevIter == 0)

            [CloseNeighbours,...
                NeighboursDegree,...
                NeighboursCovering,...
                NeighboursRoutingWeights,...
                SensorCovering,...
                NeighboursConnectivity,...
                SensorRoutingWeights,...
                NeighboursPoolRefreshed]= RefreshNeighboursPoool(...
                SensorCovering,...
                CloseNeighbours,...
                NeighboursDegree,...
                NeighboursCovering,...
                NeighboursRoutingWeights,...
                SensorConnectivityGraph,...
                SensorRoutingWeights);
        end

        NeighboursPoolRefreshedInPrevIter	= NeighboursPoolRefreshed; % save previous state
        %% Find best Greedy Match to existing Blocks

        BlocksExtendedInLastIter = []; %reset flage

        % Give Priority to block with least of sensors
        [~, BlocksByPriority] = sort(SensorsAddedToBlock); % sorts in ascending order
        for blockInd=1:numel(BlockRoots)
            BlockIndex = BlocksByPriority(blockInd);
            if (SensorsAddedToBlock(BlockIndex) >= SensorsInBlock - SensorsInBlockBackOff)
                continue; % too many sensors in block - go on
            end
            if (TimeGroupIndex > 1) % set BlockId - if it is the first time the id gets block's priority
                BlockID = sum(BlocksInTimeGroup(1:TimeGroupIndex-1)) + BlockIndex;
            else
                BlockID = BlockIndex;
            end

            [ExtendedLeaf, ConqueredSensor, ConqueredSensorFound, IsLeafExtension] = ExtendBlock(...
                BlockID,...
                NeighboursCovering,...
                NeighboursDegree,...
                NeighboursConnectivity...
                );
            if ConqueredSensorFound
                % Extend Chain
                SensorsAddedToBlock(BlockIndex)             = SensorsAddedToBlock(BlockIndex) + 1;
                BlocksExtendedInLastIter(end+1)             = BlockIndex;
                RoutingUpdatedInLastIter                    = 1;
                NeighboursDegree(ConqueredSensor)           = NeighboursDegree(ConqueredSensor) + 1;
                NeighboursCovering(ConqueredSensor)         = BlockID;
                NeighboursDegree(ExtendedLeaf)              = NeighboursDegree(ExtendedLeaf) + 1;
                NeighboursCovering(ExtendedLeaf)            = BlockID; %%really necessary?
                NeighboursRoutingWeights(ExtendedLeaf,:)    = (NeighboursRoutingWeights(ExtendedLeaf,:) + 1) .* (NeighboursRoutingWeights(ExtendedLeaf,:) > 0);
                NeighboursRoutingWeights(ConqueredSensor,:) = (NeighboursRoutingWeights(ConqueredSensor,:) + 1) .* (NeighboursRoutingWeights(ConqueredSensor,:) > 0);

                current_leaf = CloseNeighbours(ExtendedLeaf);
                current_conquered = CloseNeighbours(ConqueredSensor);
                SensorUsages(current_conquered) = SensorUsages(current_conquered) + 1;
                
                % Update actions DB
                % Transmit data from conquered sensor
                % save the routing in the DB: concate the current RU
                % that was added to the end of its block chain 
                [rows, ~] = size(blockChainsDB);
                if BlockID > rows
                    len = 1;
                else
                    len = sum(arrayfun(isEmptyStruct,blockChainsDB(BlockID,:)))+1;
                end
                blockChainsDB(BlockID,len).Tx = current_conquered;

                % Receive data in extended leaf
                if IsLeafExtension
                    blockChainsDB(BlockID,len).Rx = current_leaf;

                else % it is a case of extender
                    blockChainsDB(BlockID,len).RxWait = current_leaf;
                    SensorUsages(current_leaf) = SensorUsages(current_leaf) + 1;
                end
            end
        end

        %% Check whether to continue network construction

        AllBlocksAreClosed          = min(SensorsAddedToBlock) >= SensorsInBlock - SensorsInBlockBackOff;

    end

    %% All Blocks are Blocked of Full

    % Advance Simulation Time
    SimTime = max(BlockTime) + 1;

    % Add new blocks data to overall routing variables
    SensorCovering(CloseNeighbours)	= NeighboursCovering;
    SensorRoutingWeights(CloseNeighbours,CloseNeighbours) = NeighboursRoutingWeights;

    SensorsInBlockSummary     	= [SensorsInBlockSummary ; SensorsAddedToBlock ];
    % Get Neighbours
    CloseNeighbours             = GetBorderSensors(SensorConnectivityGraph, ~SensorCovering);
    NeighboursDegree            = zeros(numel(CloseNeighbours), 1);
    NeighboursConnectivity      = SensorConnectivityGraph(CloseNeighbours, CloseNeighbours);
    NeighboursCovering          = SensorCovering(CloseNeighbours);
    NeighboursRoutingWeights    = SensorRoutingWeights(CloseNeighbours, CloseNeighbours);
    
    % save SelectedRelayRouting for each block 
    % make the list according to the actual block numbers
    SortedRelayRouting = {};
    for i=1:length(SelectedRelayRouting)
        if ~isempty(SelectedRelayRouting{i})
            j = mod(SensorCovering(SelectedRelayRouting{i}(1,1)),BlocksPerTimeGroup);
            if j==0 
                j=BlocksPerTimeGroup;
            end
            SortedRelayRouting(j,1) = SelectedRelayRouting(i,1);
        end
    end
    % save the routing 
    RelayRoutingBlocks = [RelayRoutingBlocks; SortedRelayRouting];

end

if (BfsGroupsFound == 0)
    % fprintf('FINISHED Phase #1!\r\r');
end


%% Add Unrouted Sensors To Existing Blocks

RemainingSensors = find(~SensorCovering);
% fprintf('Routing Remaining %d Sensors\r', numel(RemainingSensors));

SensorsBelongToClosedBlock = 1:numel(SensorIndexes);
ClosedBlocks = find(SensorsInBlockSummary >= SensorsInBlock);

for blockInd=1:numel(ClosedBlocks)
    sensorsInCurrentClosedBlock = find(SensorCovering == ClosedBlocks(blockInd));
    SensorsBelongToClosedBlock(sensorsInCurrentClosedBlock) = 1;
end


%% TODO: Handle cases of uncovered sensors

RemainingSensors = find(~SensorCovering);
numOfRemainingSensors = numel(RemainingSensors);
% fprintf('ATTENTION: Still missing %d Sensors\r', numOfRemainingSensors);


%% DB 
%% fix blockChainsDB (for UL) 

% change the order to make UL 
blockChainsDB  = fliplr(blockChainsDB);

%% clear spaces

% align the chains to the beggining of the array 

isEmptyStruct = @(s) ~isequaln(s, struct('Rx',[],'RxWait',[],'Tx',[],'TxRelay',[])); % check the fields of a scalar structure.
[rows, col] = size(blockChainsDB);
for i=1:rows
    currentBlock = blockChainsDB(i,:);
    newRow = struct('Rx', cell(1, col), 'RxWait', cell(1, col),...
                    'Tx', cell(1, col), 'TxRelay', cell(1, col));
    index = 1;
    for j=1:length(currentBlock)
        if isEmptyStruct(currentBlock(1,j))
            newRow(index) = currentBlock(1,j);
            index = index + 1;
        end
    end
    blockChainsDB(i,:) = newRow;
end

%% organize chains 
% the chains needs to be reordered in order to represent an efficient
% routing as planned 

for i=1:rows
    newRow = struct('Rx', cell(1, col), 'RxWait', cell(1, col),...
                    'Tx', cell(1, col), 'TxRelay', cell(1, col));
    currentBlock = blockChainsDB(i,:);
    subBlockChains = {}; % each cell contains the indexes of a sub-chain 
    subBlockChainsIndex = 1;
    currentIndex = 1; % the indexes we currently scan 
    
    lengthOfCurrentBlock = sum(arrayfun(isEmptyStruct,currentBlock)); 
    allIndexes = ones(1,lengthOfCurrentBlock);
    nextRU = 0;

    while sum(allIndexes) ~= 0  
        
        % the begging of a sub-chain 
        if nextRU == 0
            nextRU = currentBlock(1,currentIndex).Tx;
            subBlockChains{1, subBlockChainsIndex} = [];
        end
       
        if currentBlock(1,currentIndex).Tx == nextRU  
            % find match 
            nextRU = currentBlock(1,currentIndex).Rx;
            subBlockChains{1, subBlockChainsIndex} = [subBlockChains{1, subBlockChainsIndex} currentIndex];
            allIndexes(currentIndex) = 0;
            currentIndex = currentIndex + 1;

            if isempty(nextRU) || currentIndex == lengthOfCurrentBlock+1 % end of the subChain 
                subBlockChainsIndex = subBlockChainsIndex +1;
                currentIndex = find(allIndexes, 1, 'first');
                nextRU = 0;
            end

        else
            currentIndex = currentIndex + 1;
        end
    end

    % sort the subChains: the chain that ends first will begin first
    [~,newOrder] = sort(cellfun(@(v) v(end), subBlockChains));
    subBlockChains = subBlockChains(newOrder);
    subBlockChains = [subBlockChains{:}];

    % write the structs by correct order to newRow
    newRow = currentBlock(subBlockChains);

    % rewrite the block to blockChains
    blockChainsDB(i,1:length(newRow)) = newRow;
end

%% add relay routing & trim unused colunms 

for i=1:NumOfBlocks
    if i > rows
        blockChainsDB(i,1) = struct('Rx', [], 'RxWait', [], 'Tx', [], 'TxRelay', []);
    end
    currentBlock = blockChainsDB(i,:);
    idx = sum(arrayfun(isEmptyStruct,currentBlock)); % the index of the last non empty struct in the array.

    % add relay routing
    currentRelayRouting = RelayRoutingBlocks(i,1);
    currentRelayRouting = currentRelayRouting{1,1};
    for j=1:length(currentRelayRouting)
        if j==1
            currentBlock(1,idx+j).Tx = currentRelayRouting(1,j);
        else
            currentBlock(1,idx+j).TxRelay = currentRelayRouting(1,j);
        end
        if (length(currentRelayRouting)>=j+1)
            currentBlock(1,idx+j).Rx = currentRelayRouting(1,j+1);
        end
    end

    % expand the row to fit the block with the routing 
    [~, len] = size(currentBlock);
    blockChainsDB(i,len) = struct('Rx',[],'RxWait',[],'Tx',[],'TxRelay',[]);
    blockChainsDB(i,1:len) = currentBlock;
end

toc;
end

