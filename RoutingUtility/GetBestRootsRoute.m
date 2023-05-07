function [SelectedRelayRouting, BlockRoots, SensorRoutingWeights, SensorUsages] = GetBestRootsRoute(BlockRoots, BlockRelayRoutingPermutations, VacantRelaySensors, SensorRoutingWeights, NumOfSensors, GatewaySensors, SensorUsages)
        %  Generate Shortest Routes From GW to New Block Roots
        BlockRootsPermutations       = zeros(numel(BlockRoots), BlockRelayRoutingPermutations);
        BlockRelayRouting       = cell(numel(BlockRoots), BlockRelayRoutingPermutations);
        BlockRelayRoutingCost   = zeros(numel(BlockRoots), BlockRelayRoutingPermutations);
        
        
        RoutingCostGraphWithVirtualGateway	= SensorRoutingWeights;
        % Connect all gateway neighbours to a virtual vertex that
        % represents the gateway node TODO_lior: replace NumOfSensors+1
        % here with new variable: VirtualGWSensorID/VirtualGWSensorIndex.
        RoutingCostGraphWithVirtualGateway(NumOfSensors+1,NumOfSensors+1)  	= 0;
        RoutingCostGraphWithVirtualGateway(NumOfSensors+1, GatewaySensors)	= 1;
        RoutingCostGraphWithVirtualGateway(GatewaySensors, NumOfSensors+1)	= 1;
        
        for pInd=1:BlockRelayRoutingPermutations
            % Route each block from the root to the gateway. Do it for
            % BlockRelayRoutingPermutations times, each iteration will
            % give different priorities to the routing order of each block.
            % Each route will substracted from the available sensors (so no
            % sensor will be used twice by two different routes in order to
            % avoid from collissions), so the next block will be routed by
            % the remaining sensors
            
            BlockRootsPermutations(:,pInd)	= randperm(numel(BlockRoots));
            TempVacantRelaySensors          = VacantRelaySensors;
            
            for bInd=1:numel(BlockRoots)
                CurrentBlockRoot = BlockRoots(BlockRootsPermutations(bInd, pInd));
                % Create routing cost map for current block
                TempRoutingCostGraph    = RoutingCostGraphWithVirtualGateway;
                SensorsUsedAsRelayForCurrentBlock = TempVacantRelaySensors;
                SensorsUsedAsRelayForCurrentBlock(CurrentBlockRoot) = 1;
                TempRoutingCostGraph(find(~SensorsUsedAsRelayForCurrentBlock),:) = 0;  % Remove sensors that can't be used as relay from graph
                TempRoutingCostGraph(:,find(~SensorsUsedAsRelayForCurrentBlock)) = 0;
                [RelayDist, RelayPath, pred] =      graphshortestpath(TempRoutingCostGraph, CurrentBlockRoot, NumOfSensors+1);
                RelayPath = RelayPath(1:end-1);                 % Remove virtual gateway sensor from path
                BlockRelayRouting{bInd, pInd} =     RelayPath;  % Save routing
                BlockRelayRoutingCost(bInd, pInd) =	RelayDist;  % Save routing cost (= sum of weights of the RelayPath)
                TempVacantRelaySensors(RelayPath) = 0;          % Remove from group of vacant relay sensors
            end
        end
        
        % Select best Relay Routing
        NumOfBlocksRouted = sum(BlockRelayRoutingCost < inf, 1); %TODO Lior - why is that correct ? A: max cost is equivalent to max routed 
        PermutationIndexesWithMostBlocksRouted = find( NumOfBlocksRouted == max(NumOfBlocksRouted));
        BlockRelayRoutingCost = BlockRelayRoutingCost(:, PermutationIndexesWithMostBlocksRouted);
        BlockRelayRoutingCost(BlockRelayRoutingCost == inf) = 0;
        [~, PermutationIndexWithOptimalBlockRoutingCost] = min(sum(BlockRelayRoutingCost, 1));
        BestRelayPermutation = PermutationIndexesWithMostBlocksRouted(PermutationIndexWithOptimalBlockRoutingCost);
        
        % Update Roots with the optimal routing
        SelectedPermutation     = BlockRootsPermutations(:, BestRelayPermutation);
        SelectedRootsIndexes	= find(BlockRelayRoutingCost(:, PermutationIndexWithOptimalBlockRoutingCost) < inf);
        BlockRoots              = BlockRoots(SelectedPermutation(SelectedRootsIndexes));
        SelectedRelayRouting    = BlockRelayRouting(SelectedRootsIndexes, BestRelayPermutation);
        % Update usage map accordingly
        for rInd=1:numel(SelectedRelayRouting)
            SensorRoutingWeights(SelectedRelayRouting{rInd},:) = (SensorRoutingWeights(SelectedRelayRouting{rInd},:) + 1) .* (SensorRoutingWeights(SelectedRelayRouting{rInd},:) > 0);
            SensorRoutingWeights(:,SelectedRelayRouting{rInd}) = (SensorRoutingWeights(:,SelectedRelayRouting{rInd}) + 1) .* (SensorRoutingWeights(:,SelectedRelayRouting{rInd}) > 0);
            SensorUsages(SelectedRelayRouting{rInd}) = SensorUsages(SelectedRelayRouting{rInd}) + 1;
            % TODO: Add relay actions to DB           
        end

end