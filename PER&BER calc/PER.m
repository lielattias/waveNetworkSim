% Packet Loss vs. SNR curve

clc;clear;

% load configurations
config = load('Config.mat');

ebno = 0:20;
numOfTests = 100000;
packetLossErrorRate = zeros(21,1);

% signaturs & signaturesValids
signatures = ones(config.NumSigsperPacket*config.NumPayloadBitsperSig, 1); 
signatureValids = ones(config.NumSigsperPacket, 1); 
networkID = ones(config.NnetID, 1);

for j=ebno
    packetLossCtr = 0;

    for i=1:numOfTests

        % generate packet
        packet = PacketGenerator(signatures, networkID, signatureValids, config);

        % pass through channel (add errors)
        ber = config.FSKber(j+1);
        isflipped = ber > rand(length(packet), 1);
        noisedPacket = xor(packet, isflipped);

        % decode packet
        [CRCresult] = PacketDecoder(noisedPacket, config);
        
        if CRCresult
            packetLossCtr = packetLossCtr + 1;
        end
    end
    packetLossErrorRate(j+1) = packetLossCtr/numOfTests;
end