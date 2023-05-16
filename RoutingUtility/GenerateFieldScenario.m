%@@PLOT 
function [SensorPosX, SensorPosY] = GenerateFieldScenario(SensorDist, FieldSize, LocationNoise)

    [SensorPosY, SensorPosX]     = meshgrid(0:SensorDist:FieldSize(2), 0:SensorDist:FieldSize(1));
    NumOfSensors =  numel(SensorPosX);
    SensorPosX = SensorPosX + LocationNoise*rand(size(SensorPosX));
    SensorPosY = SensorPosY + LocationNoise*rand(size(SensorPosY));
    % randomize locations
    SensorRandomOrdering = randperm(NumOfSensors);
    SensorPosX(SensorRandomOrdering) = SensorPosX;
    SensorPosY(SensorRandomOrdering) = SensorPosY;
    SensorPosX = SensorPosX(:);
    SensorPosY = SensorPosY(:);

%     % Create holes
%     hole_width_factor = 0.07;
%     NumberOfHoles = randi(round(0.01*length(SensorPosX)));
%     HolesInFieldX = zeros(2, NumberOfHoles);
%     HolesInFieldX(1,:) = randi(round(max(SensorPosX)), 1, NumberOfHoles);
%     HolesInFieldX(2,:) = HolesInFieldX(1,:) + randi(round(hole_width_factor*max(SensorPosX)), 1, NumberOfHoles);
%     HolesInFieldY = randi(round(max(SensorPosY)), 1, NumberOfHoles);
%     HolesInFieldY(2,:) = HolesInFieldY(1,:) + randi(round(hole_width_factor*max(SensorPosY)), 1, NumberOfHoles);
%     SensorsIndexesToEliminate = [];
%     for hInd=1:size(HolesInFieldX, 2)
%         CurrentHoleIndexes = find(SensorPosX >= HolesInFieldX(1, hInd) & SensorPosX <= HolesInFieldX(2, hInd) & ...
%                                         SensorPosY >= HolesInFieldY(1, hInd) & SensorPosY <= HolesInFieldY(2, hInd) );
%         SensorsIndexesToEliminate = [ SensorsIndexesToEliminate ; CurrentHoleIndexes ]; 
%     end
%     SensorPosX(SensorsIndexesToEliminate) = [];
%     SensorPosY(SensorsIndexesToEliminate) = [];
     SensorPosX = single(SensorPosX);
     SensorPosY = single(SensorPosY);


end