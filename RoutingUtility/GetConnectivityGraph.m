function SensorConnectivityGraph = GetConnectivityGraph(NumOfSensors, MeanSensorConnections, AtomGridLenX, AtomGridLenY, ConnectionSearchRadiusInAtoms, SensorAtomIndex, SensorPosX, SensorPosY, ChannelGradeFunc, ChannelGradeTh)
    % Create n X n sparse graph
    % SensorConnectivityGraph = sparse(NumOfSensors, NumOfSensors);
    SensorConnectivityGraph = logical(spalloc(NumOfSensors, NumOfSensors, MeanSensorConnections*NumOfSensors*NumOfSensors));
    
    % Connect adjacent vertices:
    % 1. Keep the total complexity O(n) by checking only nearest neighbours (search only in near atoms)
    % 2. Use channel model to grade the edge between adjacent Sensors
    
    % Go over all sensors in each atom
    for atomIndX = 1:AtomGridLenX
        for atomIndY = 1:AtomGridLenY
            CurrAtomInd = sub2ind([AtomGridLenX, AtomGridLenY], atomIndX, atomIndY);
            % Find near atoms
            NearAtomsGridX = max(atomIndX-ConnectionSearchRadiusInAtoms, 1):min(atomIndX+ConnectionSearchRadiusInAtoms, AtomGridLenX);
            NearAtomsGridY = max(atomIndY-ConnectionSearchRadiusInAtoms, 1):min(atomIndY+ConnectionSearchRadiusInAtoms, AtomGridLenY);
            [NearAtomsIndexesY, NearAtomsIndexesX] = meshgrid(NearAtomsGridY, NearAtomsGridX);
            NearAtomsIndexes = sub2ind([AtomGridLenX, AtomGridLenY], NearAtomsIndexesX, NearAtomsIndexesY);
            %Notice: the current atom is in the nearest atoms because we want
            %to find the connections between the senesors inside the
            %current atom as well as the connections between sensors inside
            %current atom and the sensors in its nearest neighbors.
            % List all sensors in near atoms (potential connections)
            SensorsInNearAtoms = [];
            for nearAtomInd=1:numel(NearAtomsIndexes)
                SensorsInNearAtom = find(SensorAtomIndex == NearAtomsIndexes(nearAtomInd)); %find all sensors in the current and adjacent atoms 
                SensorsInNearAtoms = [SensorsInNearAtoms ; SensorsInNearAtom];
            end
            
            % Go over all sensors in current atom
            SensorsInCurrentAtom = find(SensorAtomIndex == CurrAtomInd);
            for sensorRunInd = 1:numel(SensorsInCurrentAtom)
                % Check connectivity with potential sensors
                CurrentSensorVec = SensorsInCurrentAtom(sensorRunInd) * ones(numel(SensorsInNearAtoms), 1);
                EdgesGrade = ChannelGradeFunc(SensorPosX(CurrentSensorVec), SensorPosY(CurrentSensorVec), SensorPosX(SensorsInNearAtoms), SensorPosY(SensorsInNearAtoms));
                EdgesSource = CurrentSensorVec;
                EdgesDest = SensorsInNearAtoms;
                
                % Delete edges with poor grade
                EdgesOverTh = EdgesGrade < ChannelGradeTh;
                EdgesGrade(~EdgesOverTh)    = [];
                EdgesDest(~EdgesOverTh)     = [];
                EdgesSource(~EdgesOverTh)	= [];
                
                % Set edges
                EdgeIndexInMatrix = sub2ind([NumOfSensors, NumOfSensors], EdgesSource, EdgesDest);
                %EdgeIndexInMatrix contains the [valid] connections between
                %current node [which is EdgesSource] and the nearest atoms
                %sensors.
                SensorConnectivityGraph(EdgeIndexInMatrix) = EdgesGrade;
                %SensorConnectivityGraph(i,j) = the grade of the connection
                %between node i and j, where i is the linear index of
                %(posX,posY) of some sensor and j is the linear index of
                %(posX, posY) of another sensor
            end
        end
    end
    %convert to logical: 1 means possible connection and 0 means no
    %connection can be made.
    %BTW: the connection between a sensor and itself is not valid this way:
    SensorConnectivityGraph = SensorConnectivityGraph > 0; 
end