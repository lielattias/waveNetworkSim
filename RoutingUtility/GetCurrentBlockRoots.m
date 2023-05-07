function [BlockRoots, BlockRootsIndexes, BfsGroupsFound, SensorsInTooSmallNeighbourGroups] = GetCurrentBlockRoots(CloseNeighbours, NeighboursCovering, CoveredSensors, SensorConnectivityGraph, BlockMinSize, BlocksPerTimeGroup)
        NeighbourGroupsIndexes     	= [];
        NeighbourGroupsNumOfSensors	= [];
        UnusedNeighbours            = CloseNeighbours(~NeighboursCovering);
        UnusedNeighboursIndexes     = find(~NeighboursCovering);
        SensorsInTooSmallNeighbourGroups = [];
        BlockRoots          = [];
        BlockRootsIndexes	= [];
        % Find all disjoint groups of neighbours by traversing over all
        % connection of a single vertex with high connectivity to previous
        % layers
        while ( ~isempty(UnusedNeighbours) )
            UnusedneighboursConnectivity = SensorConnectivityGraph(UnusedNeighbours,UnusedNeighbours);
            NeighboursNumOfConnectionToCoveredSensors = sum(SensorConnectivityGraph(UnusedNeighbours, CoveredSensors), 2);
            % 1. Select sensor with most connections:
            [ MaxConnections, MaxConnectionsIndex ] = max(NeighboursNumOfConnectionToCoveredSensors);
            % 2. Get the BFS distance of all neighbours from this sensor
             NeighboursOrderingRelatedToRoot = graphtraverse(UnusedneighboursConnectivity, MaxConnectionsIndex, 'Method', 'BFS');
            CurrentGroup = UnusedNeighbours(NeighboursOrderingRelatedToRoot);
            CurrentGroupIndexes = UnusedNeighboursIndexes(NeighboursOrderingRelatedToRoot); %reordered indices
            
            if (numel(CurrentGroup) >= BlockMinSize)
                NeighbourGroupsIndexes{end+1}       = CurrentGroupIndexes;
                NeighbourGroupsNumOfSensors(end+1)  = numel(CurrentGroup);
            else
                SensorsInTooSmallNeighbourGroups{end+1} = CurrentGroup;

            end
            UnusedNeighbours(NeighboursOrderingRelatedToRoot) = [];
            UnusedNeighboursIndexes(NeighboursOrderingRelatedToRoot) = [];
        end % of while ( ~isempty(UnusedNeighbours) ) - on unused neighbors left

        
        % Determine how many roots each group will receive
        ChainsPerNeighbourGroup = floor( BlocksPerTimeGroup * NeighbourGroupsNumOfSensors / sum(NeighbourGroupsNumOfSensors) );
        if (isempty(ChainsPerNeighbourGroup))
            BfsGroupsFound = 0;
            return;
        end
        BfsGroupsFound = 1;
        [GroupMinSize, GroupMinSizeIndex] = min(ChainsPerNeighbourGroup);
        GroupMinSizeIndex = GroupMinSizeIndex(1);
        ChainsPerNeighbourGroup(GroupMinSizeIndex) = ChainsPerNeighbourGroup(GroupMinSizeIndex) + BlocksPerTimeGroup - sum(ChainsPerNeighbourGroup); % help the small group to get chains (might get none at first)
        
        % Shuffle Group Order (notice - this line shuffels the GROUPS, not
        % the sensors in those groups)
        NeighbourGroupsIndexes = NeighbourGroupsIndexes(randperm(numel(NeighbourGroupsIndexes)));
        
        % Find roots for every group
        BlockRootsIndexes	= [];
        BlockRoots          = [];
        for groupInd=1:numel(NeighbourGroupsIndexes)
            CurrentGroupNeigboursIndexes	= NeighbourGroupsIndexes{groupInd};
            CurrentGroupNeigbours           = CloseNeighbours(CurrentGroupNeigboursIndexes);
            % select neighbours with pseudo-equal spacing:
            % done here that way because the CurrentGroupNeigbors are
            % oredered using BFS
            CurrentGroupSelectedRoots       = round(linspace(1,numel(CurrentGroupNeigbours), ChainsPerNeighbourGroup(groupInd))).';
            CurrentGroupSelectedRoots       = unique(CurrentGroupSelectedRoots);
            CurrentGroupBlockRoots          = CurrentGroupNeigbours(CurrentGroupSelectedRoots);
            CurrentGroupBlockRootsIndexes	= CurrentGroupNeigboursIndexes(CurrentGroupSelectedRoots);
            
            BlockRootsIndexes	= [BlockRootsIndexes;	CurrentGroupBlockRootsIndexes];
            BlockRoots          = [BlockRoots;          CurrentGroupBlockRoots];
        end
        

end