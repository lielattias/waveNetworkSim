function VacantRelaySensors = GetVacantRelaySensors(SensorCovering, SensorsInTooSmallNeighbourGroups)
    VacantRelaySensors  	= SensorCovering > 0;   % Add discovered and already routed sensors as possible relay sensors in the current time group
    for gInd=1:numel(SensorsInTooSmallNeighbourGroups)
        % also, include groups who are too small to route as possible relay units
        % as they are shurely wont be part of the current blocks
        VacantRelaySensors(SensorsInTooSmallNeighbourGroups{gInd}) = 1;
    end
end