function [ExtendedLeaf, ConqueredSensor, ConqueredSensorFound, IsLeafExtension] = ExtendBlock(BlockID, NeighboursCovering, NeighboursDegree, NeighboursConnectivity)
    
    ConqueredSensorFound = 1;
    IsLeafExtension = 1;
    % First try to match vertices that will extend Blocks
    CurrentBlockSensors             = find(NeighboursCovering == BlockID);
    CurrentBlockLeaves              = find(NeighboursDegree == 1 & NeighboursCovering == BlockID);
    NeighboursCoveringMat           = repmat(NeighboursCovering.', numel(CurrentBlockLeaves), 1);
    OptionalSensorsToExtendBlock	= find(~NeighboursCoveringMat & NeighboursConnectivity(CurrentBlockLeaves, :));
    
    if(isempty(OptionalSensorsToExtendBlock))
        NeighboursCoveringMat = repmat(NeighboursCovering.', numel(CurrentBlockSensors), 1);
        OptionalSensorsToExtendBlock = find(~NeighboursCoveringMat & NeighboursConnectivity(CurrentBlockSensors, :));
        if(isempty(OptionalSensorsToExtendBlock))
            ConqueredSensor = 0;
            ExtendedLeaf = 0;
            ConqueredSensorFound = 0;
            return
        end
        IsLeafExtension = 0;
        ConqueredSensorConnection = OptionalSensorsToExtendBlock(randi(numel(OptionalSensorsToExtendBlock)));
        [ExtendedLeafInd, ConqueredSensor] = ind2sub(size(NeighboursCoveringMat), ConqueredSensorConnection);
        ExtendedLeaf = CurrentBlockSensors(ExtendedLeafInd);
        return
    end
    ConqueredSensorConnection = OptionalSensorsToExtendBlock(randi(numel(OptionalSensorsToExtendBlock)));
    [ExtendedLeafInd, ConqueredSensor] = ind2sub(size(NeighboursCoveringMat), ConqueredSensorConnection);
    ExtendedLeaf = CurrentBlockLeaves(ExtendedLeafInd);
end