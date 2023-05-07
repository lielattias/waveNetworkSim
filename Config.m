%% configuration file

Params.General.NumTsFrameMax    = 500;
Params.General.NumSigPerPacket  = 16;
Params.General.NumFreqCh        = 16;
Params.General.TsTime           = 0.01;
Params.General.GuardTime        = 0.001;
Params.General.BaudRate         = 116000;
Params.General.NumMacAddressMax = 16384;
Params.General.NumBitsPerSig    = 24;
Params.General.NumNetworkMax    = 256;
Params.General.SimLevel         = 1;

Params.Msg.Npre                 = 32;
Params.Msg.Nuw                  = 32;
Params.Msg.Ncrc                 = 24;
Params.Msg.Nheader              = 24;
Params.Msg.CodeRate             = 0.5;
Params.Msg.NumBitsMac           = 14;
Params.Msg.NumBitsSnr           = 2;
Params.Msg.NumBitsPerSig        = 24;
Params.Msg.NumCtrlBitsPerSig    = 16;
Params.Msg.NumDataBitsPerSig    = 8;

Params.Msg.Pre                  = [0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1].'; 
Params.Msg.Uw                   = [0 0 0 0 0 1 1 0 0 0 0 1 0 0 0 0 0 0 1 1 0 0 1 1 1 1 0 1 0 1 1 0].';
Params.Msg.ULHeader             = randi([0 1], Params.Msg.Nheader, 1);


%% construction (just a reference)
% unique/sync word (uw)
% uwLFSR1              = comm.PNSequence('Polynomial', 'z^5 + z^4 + z^3 + z^2 + 1', 'InitialConditions', [0 1 0 1 0], 'SamplesPerFrame', MsgParams.Nuw);
% uwLFSR2              = comm.PNSequence('Polynomial', 'z^5 + z^2 + 1', 'InitialConditions', [0 1 0 1 0], 'SamplesPerFrame', MsgParams.Nuw);
% syncword             = xor(uwLFSR1(),uwLFSR2());
