function [SensorAtomIndex, AtomGridLenX, AtomGridLenY] = GetAtomIndices(SensorPosX, SensorPosY, AtomGridSizeX, AtomGridSizeY, GatewayAtomDepth)

    AtomGridX0 = min(min(SensorPosX));
    AtomGridY0 = min(min(SensorPosY)) - (AtomGridSizeY - GatewayAtomDepth); %TODO: what is the meaning of the last operation?
    AtomGridX = AtomGridX0:AtomGridSizeX:max(max(SensorPosX));
    AtomGridY = AtomGridY0:AtomGridSizeY:max(max(SensorPosY));
    AtomGridLenX = numel(AtomGridX);
    AtomGridLenY = numel(AtomGridY);
    
    SensorAtomIndexX = floor((SensorPosX - AtomGridX0) / AtomGridSizeX) + 1;
    SensorAtomIndexY = floor((SensorPosY - AtomGridY0) / AtomGridSizeY) + 1;
    
    SensorAtomIndex         = int16(sub2ind([AtomGridLenX, AtomGridLenY], SensorAtomIndexX, SensorAtomIndexY));
end