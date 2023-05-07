function [BorderSensors] = GetBorderSensors(SensorConnectivityGraph, SensorCovering)
% Update list of all neighbours:

% From the whole list of covered sensors, take only the ones that
% have connectivity with vertices outside of the covered group

SensorCoveringMat = repmat(SensorCovering.', numel(SensorCovering), 1);
CoveredSensors = find(SensorCovering > 0);
ConnectivityMapExcludingCoveredSensors = SensorConnectivityGraph & (SensorCoveringMat == 0);
BorderSensorsConnections = sum(ConnectivityMapExcludingCoveredSensors(CoveredSensors,:), 2);
BorderSensorsIndexes = find(BorderSensorsConnections > 0);
BorderSensors = CoveredSensors(BorderSensorsIndexes);

end