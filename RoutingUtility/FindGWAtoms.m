function GatewaySensors = FindGWAtoms(GatewayAtomsX, GatewayAtomsY,AtomGridLenX, AtomGridLenY,SensorAtomIndex)

    [GatewayAtomIndexesY, GatewayAtomIndexesX] = meshgrid(GatewayAtomsY, GatewayAtomsX);
    GatewayAtomIndexes      = sub2ind([AtomGridLenX, AtomGridLenY], GatewayAtomIndexesX(:), GatewayAtomIndexesY(:));
    GatewaySensors          = [];
    for gwAtomInd=1:numel(GatewayAtomIndexes)
        GatewayAtomSensors = find(SensorAtomIndex == GatewayAtomIndexes(gwAtomInd));
        GatewaySensors(end+1:end+numel(GatewayAtomSensors),1) = GatewayAtomSensors;
    end
end