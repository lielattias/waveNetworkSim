classdef Channel < handle 
    
    properties (SetAccess = private)
        SNRmatrix                    % ground truth - SNR between each pair of RUs
        SNRGatewayMatrix             % ground truth - SNR between each RU and the GW
        FreqCHList                   % a list of freqCH  
        GeneralParams                % struct of general params

        PER                          % packet error rate
        BER                          % bit error rate
    end
    
    methods
        function obj = Channel(GeneralParams, SNRmatrix, SNRGatewayMatrix)
            obj.FreqCHList = struct('RUsource', cell(0), 'packet', cell(0));
            if (nargin == 3)
                obj.SNRmatrix = SNRmatrix;
                obj.SNRGatewayMatrix = SNRGatewayMatrix;
                obj.GeneralParams = GeneralParams;
            end
            obj.PER = load('PER.mat').packetLossErrorRate;
            % obj.BER = load()...
        end

        % write/read to/from channel 
        function obj = writeToChannel(obj, packet, freqCHIndex, RUsource)
            obj.FreqCHList(freqCHIndex) = struct('RUsource', RUsource, 'packet', packet);
        end

        function [packet] = readFromChannel(obj, freqCHIndex, RUdestination)
            % here, we know the source and the destination, thus, we can
            % flip the bits properly 

            % extract RUsource and packet from the desired freqCHIndex
            RUsource = obj.FreqCHList(freqCHIndex).RUsource;
            packet = obj.FreqCHList(freqCHIndex).packet;
            if RUdestination == 0 
                SNR = obj.SNRGatewayMatrix(RUsource);
            elseif RUsource == 0
                SNR = obj.SNRGatewayMatrix(RUdestination);
            else
                SNR = obj.SNRmatrix(RUsource, RUdestination);
            end
            
            if isa(packet, 'char')
                packet = logical(packet-'0'); % convert to logical array
            end

            % "packet-wise"
            if (obj.GeneralParams.SimLevel == 1)
                ber = obj.PER(SNR+1);
            
            % "bit-wise"
            else
                % ber = ...
            end

            isflipped = ber > rand(1,length(packet));
            packet = xor(packet, isflipped);
            
            packet = char(packet+'0'); % convert to chars 

            % delete the packet from the channel
            obj.FreqCHList(freqCHIndex) = struct('RUsource', [], 'packet', []);
        end

    end
end