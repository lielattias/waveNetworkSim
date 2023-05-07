function packet = PacketGenerator(signatures, networkID, signatureValids, config)

% assume inputs are logic arrays with the correct lengths 

% 1. Concatenating the 24 signatures 
packet = signatures;

% 2. adding packet header
header = [networkID; signatureValids]; % signatures valid + network ID
packet = [header; packet];

% 3. adding CRC
packet = config.crcgenerator(packet); 

% 4. Randomizing - xor with LFSR
packet = xor(packet, config.LFSRsequence);

% 5. Encoding using a Convolutional code
packet = config.conEnc(packet);

% 6. Adding Sync and Preamble
packet = [config.preamble; config.syncword; packet];

% 7. Interleaving (optional) - TBD
% ? 

end
