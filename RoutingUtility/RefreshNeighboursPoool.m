function [CloseNeighbours, NeighboursDegree, NeighboursCovering, NeighboursRoutingWeights, SensorCovering, NeighboursConnectivity, SensorRoutingWeights, NeighboursPoolRefreshed] = RefreshNeighboursPoool(SensorCovering, CloseNeighbours, NeighboursDegree, NeighboursCovering, NeighboursRoutingWeights, SensorConnectivityGraph, SensorRoutingWeights)
    % Update block routing data
    SensorCovering(CloseNeighbours)	= NeighboursCovering;
    SensorRoutingWeights(CloseNeighbours,CloseNeighbours) = NeighboursRoutingWeights;

    % Fetch new neighbours
    NeighboursPoolRefreshed     = 1;
    NewCloseNeighbours          = GetBorderSensors(SensorConnectivityGraph, ~SensorCovering);
    NewNeighboursDegree         = zeros(numel(NewCloseNeighbours), 1);

    % Add sensors and and use unique to eliminate dualities
    [CloseNeighbours, ~ , UniqueOrdRow] = unique([ CloseNeighbours;        NewCloseNeighbours ]);
    NeighboursDegree                = [ NeighboursDegree;       NewNeighboursDegree ];
    NeighboursDegree(UniqueOrdRow)	= NeighboursDegree;
    NeighboursDegree(numel(CloseNeighbours)+1:end) = [];
    % Update network data structures
    NeighboursConnectivity      = SensorConnectivityGraph(CloseNeighbours, CloseNeighbours);
    NeighboursRoutingWeights    = SensorRoutingWeights(CloseNeighbours, CloseNeighbours);
    NeighboursCovering          = SensorCovering(CloseNeighbours);
end
